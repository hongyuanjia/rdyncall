/******************************************************************************
 **
 **       pydc - python dyncall package
 **
 **       python extension package in C
 **       Copyright 2007-2016 Daniel Adler
 **                 2018-2020 Tassilo Philipp
 **
 **       See README.txt for details (about changes, how to use, etc.).
 **
 *****************************************************************************/

#include <Python.h>
#include "dynload.h"
#include <limits.h>



#if (    (PY_VERSION_HEX <  0x02070000) \
     || ((PY_VERSION_HEX >= 0x03000000) \
      && (PY_VERSION_HEX <  0x03010000)) )
#  define DcPyCObject_FromVoidPtr(ptr, dtor)   PyCObject_FromVoidPtr((ptr), (dtor))  // !new ref!
#  define DcPyCObject_AsVoidPtr(ppobj)         PyCObject_AsVoidPtr((ppobj))
#  define DcPyCObject_SetVoidPtr(ppobj, ptr)   PyCObject_SetVoidPtr((ppobj), (ptr))
#else
#  define USE_CAPSULE_API
#  define DcPyCObject_FromVoidPtr(ptr, dtor)   PyCapsule_New((ptr), NULL, (dtor))    // !new ref!
#  define DcPyCObject_AsVoidPtr(ppobj)         PyCapsule_GetPointer((ppobj), NULL)
#  define DcPyCObject_SetVoidPtr(ppobj, ptr)   //@@@ unsure what to do, cannot/shouldn't call this with a null pointer as this wants to call the dtor, so not doing anything: PyCapsule_SetPointer((ppobj), (ptr))  // this might need to call the dtor to behave like PyCObject_SetVoidPtr?
#endif

#if(PY_VERSION_HEX >= 0x03030000)
#  define PYUNICODE_CACHES_UTF8
#endif

#if PY_MAJOR_VERSION >= 3
#  define EXPECT_LONG_TYPE_STR "an int"
#  define DcPyString_GET_SIZE PyBytes_GET_SIZE
#  define DcPyString_Check    PyBytes_Check
#  define DcPyString_AsString PyBytes_AsString
#  define DcPyInt_Check       PyLong_Check
#  define DcPyInt_AsLong      PyLong_AsLong
#  define DcPyInt_AS_LONG     PyLong_AS_LONG
#else
#  define EXPECT_LONG_TYPE_STR "an int or a long"
#  define DcPyString_GET_SIZE PyString_GET_SIZE
#  define DcPyString_Check    PyString_Check
#  define DcPyString_AsString PyString_AsString
#  define DcPyInt_Check       PyInt_Check
#  define DcPyInt_AsLong      PyInt_AsLong
#  define DcPyInt_AS_LONG     PyInt_AS_LONG
#endif

/* PyCObject destructor callback for libhandle */

#if defined(USE_CAPSULE_API)
void free_library(PyObject* capsule)
{
	void* libhandle = PyCapsule_GetPointer(capsule, NULL);
#else
void free_library(void* libhandle)
{
#endif
	if (libhandle != 0)
		dlFreeLibrary(libhandle);
}


/* load function */

static PyObject*
pydc_load(PyObject* self, PyObject* args)
{
	const char* libpath;
	void* libhandle;

	if (!PyArg_ParseTuple(args,"z", &libpath))
		return PyErr_Format(PyExc_RuntimeError, "libpath argument (str) missing");

	libhandle = dlLoadLibrary(libpath);

	if (!libhandle)
		return PyErr_Format(PyExc_RuntimeError, "dlLoadLibrary('%s') failed", libpath);

	return DcPyCObject_FromVoidPtr(libhandle, &free_library);  // !new ref!
}

/* find function */

static PyObject*
pydc_find(PyObject* self, PyObject* args)
{
	PyObject* pcobj;
	const char* symbol;
	void* libhandle;
	void* funcptr;

	if (!PyArg_ParseTuple(args, "Os", &pcobj, &symbol))
		return PyErr_Format(PyExc_RuntimeError, "argument mismatch");

	libhandle = DcPyCObject_AsVoidPtr(pcobj);
	if (!libhandle)
		return PyErr_Format(PyExc_RuntimeError, "libhandle is null");

	funcptr = dlFindSymbol(libhandle, symbol);
	if (!funcptr)
		return PyErr_Format(PyExc_RuntimeError, "symbol '%s' not found", symbol);

	return DcPyCObject_FromVoidPtr(funcptr, NULL);  // !new ref!
}

/* free function */

static PyObject*
pydc_free(PyObject* self, PyObject* args)
{
	PyObject* pcobj;
	void* libhandle;

	if (!PyArg_ParseTuple(args, "O", &pcobj))
		return PyErr_Format(PyExc_RuntimeError, "argument mismatch");

	libhandle = DcPyCObject_AsVoidPtr(pcobj);
	if (!libhandle)
		return PyErr_Format(PyExc_RuntimeError, "libhandle is NULL");

	dlFreeLibrary(libhandle);
	DcPyCObject_SetVoidPtr(pcobj, NULL);

	//don't think I need to release it, as the pyobj is not equivalent to the held handle
	//Py_XDECREF(pcobj); // release ref from pydc_load()

	Py_RETURN_NONE;
}

/* get_path function */

static PyObject*
pydc_get_path(PyObject* self, PyObject* args)
{
	PyObject* pcobj;
	PyObject* retobj;
	void* libhandle;
	char* path;
	int path_bufSize;

	if (!PyArg_ParseTuple(args, "O", &pcobj))
		return PyErr_Format(PyExc_RuntimeError, "argument mismatch");

	libhandle = (pcobj == Py_None)?NULL:DcPyCObject_AsVoidPtr(pcobj);
	path_bufSize = dlGetLibraryPath(libhandle, NULL, 0);
	if (!path_bufSize)
		return PyErr_Format(PyExc_RuntimeError, "library path cannot be found");

	path = malloc(path_bufSize);
	if (path_bufSize != dlGetLibraryPath(libhandle, path, path_bufSize)) {
		free(path);
		return PyErr_Format(PyExc_RuntimeError, "library path cannot be queried");
	}

	retobj = Py_BuildValue("s", path);  // !new ref!  @@@ UTF-8 input...
	free(path);
	return retobj;
}


#include "dyncall.h"
#include "dyncall_signature.h"

DCCallVM* gpCall = NULL;

// helper to temporarily copy string arguments
#define NUM_AUX_STRS 64
static int   n_str_aux;
static char* str_aux[NUM_AUX_STRS]; // hard limit, most likely enough and checked for below @@@ugly though


/* call function */

static PyObject*
pydc_call_impl(PyObject* self, PyObject* args) /* implementation, called by wrapper func pydc_call() */
{
	const char  *sig_ptr;
	char        ch;
	int         pos, ts;
	void*       pfunc;

	pos = 0;
	ts  = PyTuple_Size(args);
	if (ts < 2)
		return PyErr_Format(PyExc_RuntimeError, "argument mismatch");

	// get ptr to func to call
	pfunc = DcPyCObject_AsVoidPtr(PyTuple_GetItem(args, pos++));
	if (!pfunc)
		return PyErr_Format( PyExc_RuntimeError, "function pointer is NULL" );

	// get signature
#if !defined(PYUNICODE_CACHES_UTF8)
	PyObject* sig_obj = NULL;
#endif
	PyObject* so = PyTuple_GetItem(args, pos++);
	if ( PyUnicode_Check(so) )
	{
#if defined(PYUNICODE_CACHES_UTF8)
		sig_ptr = PyUnicode_AsUTF8(so);
#else
		// w/o PyUnicode_AsUTF8(), which caches the UTF-8 representation, itself, create new ref we'll dec below
		if((sig_obj = PyUnicode_AsEncodedString(so, "utf-8", "strict")))  // !new ref!
			sig_ptr = PyBytes_AS_STRING(sig_obj); // Borrowed pointer
#endif
	} else if ( DcPyString_Check(so) )
		sig_ptr = DcPyString_AsString(so); // @@@ test py 2



	if (!sig_ptr)
		return PyErr_Format( PyExc_RuntimeError, "signature is NULL" );


	dcReset(gpCall);
	dcMode(gpCall, DC_CALL_C_DEFAULT);

	for (ch = *sig_ptr; ch != '\0' && ch != DC_SIGCHAR_ENDARG; ch = *++sig_ptr)
	{
		PyObject* po;

		if (pos > ts)
			return PyErr_Format( PyExc_RuntimeError, "expecting more arguments" );

		po = PyTuple_GetItem(args, pos);

		++pos; // incr here, code below uses it as 1-based argument index for error strings

		switch(ch)
		{
			case DC_SIGCHAR_CC_PREFIX:
			{
				if(*(sig_ptr+1) != '\0')
				{
					DCint mode = dcGetModeFromCCSigChar(*++sig_ptr);
					if(mode != DC_ERROR_UNSUPPORTED_MODE)
						dcMode(gpCall, mode);
				}
				--pos; // didn't count as arg
			}
			break;

			case DC_SIGCHAR_BOOL:
				if ( !PyBool_Check(po) )
					return PyErr_Format( PyExc_RuntimeError, "arg %d - expecting a bool", pos );
				dcArgBool(gpCall, (Py_True == po) ? DC_TRUE : DC_FALSE);
				break;

			case DC_SIGCHAR_CHAR:
			case DC_SIGCHAR_UCHAR:
				{
					DCchar c;
					if ( PyUnicode_Check(po) )
					{
#if (PY_VERSION_HEX < 0x03030000)
						Py_UNICODE cu;
						if (PyUnicode_GET_SIZE(po) != 1)
#else
						Py_UCS4 cu;
						if (PyUnicode_GET_LENGTH(po) != 1)
#endif
							return PyErr_Format( PyExc_RuntimeError, "arg %d - expecting a str with length of 1 (a char string)", pos );

#if (PY_VERSION_HEX < 0x03030000)
						cu = PyUnicode_AS_UNICODE(po)[0];
#else
						cu = PyUnicode_ReadChar(po, 0);
#endif
						// check against UCHAR_MAX in every case b/c Py_UCS4 is unsigned
						if ( (cu > UCHAR_MAX))
							return PyErr_Format( PyExc_RuntimeError, "arg %d out of range - expecting a char code", pos );
						c = (DCchar) cu;
					}
					else if ( DcPyString_Check(po) )
					{
						size_t l;
						char* s;
						l = DcPyString_GET_SIZE(po);
						if (l != 1)
							return PyErr_Format( PyExc_RuntimeError, "arg %d - expecting a str with length of 1 (a char string)", pos );
						s = DcPyString_AsString(po);
						c = (DCchar) s[0];
					}
					else if ( DcPyInt_Check(po) )
					{
						long l = DcPyInt_AsLong(po);
						if (ch == DC_SIGCHAR_CHAR && (l < CHAR_MIN || l > CHAR_MAX))
							return PyErr_Format( PyExc_RuntimeError, "arg %d out of range - expecting %d <= arg <= %d, got %ld", pos, CHAR_MIN, CHAR_MAX, l );
						if (ch == DC_SIGCHAR_UCHAR && (l < 0 || l > UCHAR_MAX))
							return PyErr_Format( PyExc_RuntimeError, "arg %d out of range - expecting 0 <= arg <= %d, got %ld", pos, UCHAR_MAX, l );
						c = (DCchar) l;
					}
					else
						return PyErr_Format( PyExc_RuntimeError, "arg %d - expecting a char", pos );
					dcArgChar(gpCall, c);
				}
				break;

			case DC_SIGCHAR_SHORT:
				{
					long l;
					if ( !DcPyInt_Check(po) )
						return PyErr_Format( PyExc_RuntimeError, "arg %d - expecting an int", pos );
					l = DcPyInt_AS_LONG(po);
					if (l < SHRT_MIN || l > SHRT_MAX)
						return PyErr_Format( PyExc_RuntimeError, "arg %d out of range - expecting %d <= arg <= %d, got %ld", pos, SHRT_MIN, SHRT_MAX, l );
					dcArgShort(gpCall, (DCshort)l);
				}
				break;

			case DC_SIGCHAR_USHORT:
				{
					long l;
					if ( !DcPyInt_Check(po) )
						return PyErr_Format( PyExc_RuntimeError, "arg %d - expecting an int", pos );
					l = DcPyInt_AS_LONG(po);
					if (l < 0 || l > USHRT_MAX)
						return PyErr_Format( PyExc_RuntimeError, "arg %d out of range - expecting 0 <= arg <= %d, got %ld", pos, USHRT_MAX, l );
					dcArgShort(gpCall, (DCshort)l);
				}
				break;

			case DC_SIGCHAR_INT:
			case DC_SIGCHAR_UINT:
				if ( !DcPyInt_Check(po) )
					return PyErr_Format( PyExc_RuntimeError, "arg %d - expecting an int", pos );
				dcArgInt(gpCall, (DCint) DcPyInt_AS_LONG(po));
				break;

			case DC_SIGCHAR_LONG:
			case DC_SIGCHAR_ULONG:
				if ( !DcPyInt_Check(po) )
					return PyErr_Format( PyExc_RuntimeError, "arg %d - expecting an int", pos );
				dcArgLong(gpCall, (DClong) PyLong_AsLong(po));
				break;

			case DC_SIGCHAR_LONGLONG:
			case DC_SIGCHAR_ULONGLONG:
#if PY_MAJOR_VERSION < 3
				if ( PyInt_Check(po) )
					dcArgLongLong(gpCall, (DClonglong) PyInt_AS_LONG(po));
				else
#endif
				if ( !PyLong_Check(po) )
					return PyErr_Format( PyExc_RuntimeError, "arg %d - expecting " EXPECT_LONG_TYPE_STR, pos );
				dcArgLongLong(gpCall, (DClonglong)PyLong_AsLongLong(po));
				break;

			case DC_SIGCHAR_FLOAT:
				if (!PyFloat_Check(po))
					return PyErr_Format( PyExc_RuntimeError, "arg %d - expeecting a float", pos );
				dcArgFloat(gpCall, (float)PyFloat_AsDouble(po));
				break;

			case DC_SIGCHAR_DOUBLE:
				if (!PyFloat_Check(po))
					return PyErr_Format( PyExc_RuntimeError, "arg %d - expeecting a float", pos );
				dcArgDouble(gpCall, PyFloat_AsDouble(po));
				break;

			case DC_SIGCHAR_POINTER: // this will only accept integers or mutable array types (meaning only bytearray)
			{
				DCpointer p;
				if ( PyByteArray_Check(po) )
					p = (DCpointer) PyByteArray_AsString(po); // adds an extra '\0', but that's ok
#if PY_MAJOR_VERSION < 3
				else if ( PyInt_Check(po) )
					p = (DCpointer) PyInt_AS_LONG(po);
#endif
				else if ( PyLong_Check(po) )
					p = (DCpointer) PyLong_AsVoidPtr(po);
				else if ( po == Py_None )
					p = NULL;
				else
					return PyErr_Format( PyExc_RuntimeError, "arg %d - expecting a promoting pointer-type (int, bytearray)", pos );
				dcArgPointer(gpCall, p);
			}
			break;

			case DC_SIGCHAR_STRING: // strings are considered to be immutable objects
			{
				PyObject* bo = NULL;
				const char* p;
				size_t s;
				if ( PyUnicode_Check(po) )
				{
					if(n_str_aux >= NUM_AUX_STRS)
						return PyErr_Format( PyExc_RuntimeError, "too many arguments (implementation limit of %d new UTF-8 string references reached) - abort", n_str_aux );

#if defined(PYUNICODE_CACHES_UTF8)
					p = PyUnicode_AsUTF8(po);
#else
					// w/o PyUnicode_AsUTF8(), which caches the UTF-8 representation, itself, create new ref we'll dec below
					if((bo = PyUnicode_AsEncodedString(po, "utf-8", "strict")))  // !new ref!
						p = PyBytes_AS_STRING(bo); // Borrowed pointer
#endif
				} else if ( DcPyString_Check(po) )
					p = DcPyString_AsString(po);
				else if ( PyByteArray_Check(po) )
					p = (DCpointer) PyByteArray_AsString(po); // adds an extra '\0', but that's ok //@@@ not sure if allowed to modify
				else
					return PyErr_Format( PyExc_RuntimeError, "arg %d - expecting a str", pos );

				// p points in any case to a buffer that shouldn't be modified, so pass a copy to dyncall (cleaned up after call)
				s = strlen(p)+1;
				str_aux[n_str_aux] = malloc(s);
				strncpy(str_aux[n_str_aux], p, s);
				Py_XDECREF(bo);
				dcArgPointer(gpCall, (DCpointer)str_aux[n_str_aux++]);
			}
			break;

			default:
				return PyErr_Format( PyExc_RuntimeError, "unknown signature character '%c'", ch);
		}
	}

	if (pos != ts)
		return PyErr_Format( PyExc_RuntimeError, "too many arguments");

	if (ch == '\0')
		return PyErr_Format( PyExc_RuntimeError, "return value missing in signature");


	ch = *++sig_ptr;
	switch(ch)
	{
		// every line creates a new reference passed back to python
		case DC_SIGCHAR_VOID:                                dcCallVoid    (gpCall, pfunc); Py_RETURN_NONE;                        // !new ref!
		case DC_SIGCHAR_BOOL:                             if(dcCallBool    (gpCall, pfunc)){Py_RETURN_TRUE;}else{Py_RETURN_FALSE;} // !new ref!
		case DC_SIGCHAR_CHAR:      return Py_BuildValue("b", dcCallChar    (gpCall, pfunc));                                       // !new ref!
		case DC_SIGCHAR_UCHAR:     return Py_BuildValue("B", dcCallChar    (gpCall, pfunc));                                       // !new ref!
		case DC_SIGCHAR_SHORT:     return Py_BuildValue("h", dcCallShort   (gpCall, pfunc));                                       // !new ref!
		case DC_SIGCHAR_USHORT:    return Py_BuildValue("H", dcCallShort   (gpCall, pfunc));                                       // !new ref!
		case DC_SIGCHAR_INT:       return Py_BuildValue("i", dcCallInt     (gpCall, pfunc));                                       // !new ref!
		case DC_SIGCHAR_UINT:      return Py_BuildValue("I", dcCallInt     (gpCall, pfunc));                                       // !new ref!
		case DC_SIGCHAR_LONG:      return Py_BuildValue("l", dcCallLong    (gpCall, pfunc));                                       // !new ref!
		case DC_SIGCHAR_ULONG:     return Py_BuildValue("k", dcCallLong    (gpCall, pfunc));                                       // !new ref!
		case DC_SIGCHAR_LONGLONG:  return Py_BuildValue("L", dcCallLongLong(gpCall, pfunc));                                       // !new ref!
		case DC_SIGCHAR_ULONGLONG: return Py_BuildValue("K", dcCallLongLong(gpCall, pfunc));                                       // !new ref!
		case DC_SIGCHAR_FLOAT:     return Py_BuildValue("f", dcCallFloat   (gpCall, pfunc));                                       // !new ref!
		case DC_SIGCHAR_DOUBLE:    return Py_BuildValue("d", dcCallDouble  (gpCall, pfunc));                                       // !new ref!
		case DC_SIGCHAR_STRING:    return Py_BuildValue("s", dcCallPointer (gpCall, pfunc));                                       // !new ref!
		case DC_SIGCHAR_POINTER:   return Py_BuildValue("n", dcCallPointer (gpCall, pfunc));                                       // !new ref!
		default:                   return PyErr_Format(PyExc_RuntimeError, "invalid return type signature");
	}

#if !defined(PYUNICODE_CACHES_UTF8)
	Py_XDECREF(sig_obj);
#endif
}


static PyObject*
pydc_call(PyObject* self, PyObject* args)
{
	int i;
	n_str_aux = 0;
	PyObject* o = pydc_call_impl(self, args);
	for(i = 0; i<n_str_aux; ++i)
		free(str_aux[i]);
	return o;
}


// module deinit
static void deinit_pydc(void* x)
{
	if(gpCall) {
		dcFree(gpCall);
		gpCall = NULL;
	}
}


#define PYDC_TO_STR_(x)     #x
#define PYDC_TO_STR(x)      PYDC_TO_STR_(x)
#define PYDC_CONCAT_(x, y)  x ## y
#define PYDC_CONCAT(x, y)   PYDC_CONCAT_(x, y)

#define PYDC_MOD_NAME       pydc
#define PYDC_MOD_NAME_STR   PYDC_TO_STR(PYDC_MOD_NAME)
#define PYDC_MOD_DESC_STR  "dyncall bindings for python"

#if PY_MAJOR_VERSION >= 3
#  define PY_MOD_INIT_FUNC_NAME  PYDC_CONCAT(PyInit_, PYDC_MOD_NAME)
#else
#  define PY_MOD_INIT_FUNC_NAME  PYDC_CONCAT(init, PYDC_MOD_NAME)
#endif


PyMODINIT_FUNC
PY_MOD_INIT_FUNC_NAME(void)
{
	static PyMethodDef pydcMethods[] = {
		{"load",     pydc_load,     METH_VARARGS, "load library"    },
		{"find",     pydc_find,     METH_VARARGS, "find symbols"    },
		{"free",     pydc_free,     METH_VARARGS, "free library"    },
		{"get_path", pydc_get_path, METH_VARARGS, "get library path"},
		{"call",     pydc_call,     METH_VARARGS, "call function"   },
		{NULL,NULL,0,NULL}
	};

	PyObject* m;
#if PY_MAJOR_VERSION >= 3
	static struct PyModuleDef moddef = { PyModuleDef_HEAD_INIT, PYDC_MOD_NAME_STR, PYDC_MOD_DESC_STR, -1, pydcMethods, NULL, NULL, NULL, deinit_pydc };
	m = PyModule_Create(&moddef);
#else
	m = Py_InitModule3(PYDC_MOD_NAME_STR, pydcMethods, PYDC_MOD_DESC_STR);
	// NOTE: there is no way to pass a pointer to deinit_pydc - see PEP 3121 for details
#endif

	if(m)
		gpCall = dcNewCallVM(4096); //@@@ one shared callvm for the entire module, this is not reentrant

#if PY_MAJOR_VERSION >= 3
	return m;
#endif
}

