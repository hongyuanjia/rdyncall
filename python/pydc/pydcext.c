/******************************************************************************
 **
 **       pydc - python dyncall package
 **
 **       python extension package in C
 **       Copyright 2007 Daniel Adler.
 **
 **       December 04, 2007
 **
 *****************************************************************************/

#include <Python.h>
#include "dynload.h"
#include <limits.h>

/* PyCObject destructor callback for libhandle */

void free_library(void* libhandle) 
{
  if (libhandle != 0)
    dlFreeLibrary(libhandle);
}

/* load function */

static PyObject*
pydc_load(PyObject* self, PyObject* args)
{
  const char* libpath;
  void* libhandle;

  if ( !PyArg_ParseTuple(args,"s", &libpath) ) return PyErr_Format(PyExc_RuntimeError, "libpath argument (string) missing");

  libhandle = dlLoadLibrary(libpath);

  if (!libhandle) return PyErr_Format(PyExc_RuntimeError, "dlLoadLibrary('%s') failed", libpath);

  return PyCObject_FromVoidPtr(libhandle, &free_library);
}

/* find function */

static PyObject*
pydc_find(PyObject* self, PyObject* args)
{
  PyObject* pcobj;
  const char* symbol;
  void* libhandle;
  void* funcptr;

  if ( !PyArg_ParseTuple(args,"Os", &pcobj, &symbol) ) return PyErr_Format(PyExc_RuntimeError, "argument mismatch");
  
  libhandle = PyCObject_AsVoidPtr(pcobj);
  
  if (!libhandle) return PyErr_Format(PyExc_RuntimeError, "libhandle is null");

  funcptr = dlFindSymbol(libhandle, symbol);
  if (!funcptr) 
    return PyErr_Format(PyExc_RuntimeError, "symbol '%s' not found", symbol);

  return PyCObject_FromVoidPtr(funcptr, NULL);
}

/* free function */

static PyObject*
pydc_free(PyObject* self, PyObject* args)
{
  PyObject* pcobj;
  void* libhandle;

  if ( !PyArg_ParseTuple(args,"o", &pcobj) ) return PyErr_Format(PyExc_RuntimeError, "argument mismatch");
  
  libhandle = PyCObject_AsVoidPtr(pcobj);
  
  if (!libhandle) return PyErr_Format(PyExc_RuntimeError, "libhandle is NULL");

  dlFreeLibrary(libhandle);
  PyCObject_SetVoidPtr(pcobj,0);
  Py_RETURN_NONE;
}

#include "dyncall.h"
#include "dyncall_signature.h"

DCCallVM* gpCall;

/* call function */

static PyObject*
pydc_call(PyObject* self, PyObject* in_args)
{
  PyObject*   pcobj_funcptr;
  const char* signature;
  PyObject*   args;
  int         l;
  const char* ptr;
  char        ch;
  int         pos;
  void*       pfunc;
  
  if ( !PyArg_ParseTuple(in_args,"OsO", &pcobj_funcptr, &signature, &args) ) return PyErr_Format(PyExc_RuntimeError, "argument mismatch");
  pfunc = PyCObject_AsVoidPtr(pcobj_funcptr);  
  if ( !pfunc ) return PyErr_Format( PyExc_RuntimeError, "function pointer is NULL" );
  l = PyTuple_Size(args);

  ptr = signature;
  pos = 0; 

  dcReset(gpCall);
  
  while ( (ch = *ptr) != '\0' && ch != ')' ) 
  {
    PyObject* po;

    int index = pos+1;

    if (pos > l) return PyErr_Format( PyExc_RuntimeError, "expecting more arguments" );

    po = PyTuple_GetItem(args,pos);

    switch(ch) 
    {
      case DC_SIGCHAR_BOOL:
      {
        DCbool b;
        if ( !PyBool_Check(po) ) return PyErr_Format( PyExc_RuntimeError, "argument mismatch at pos %d - expecting a bool", index ); 
        b = (Py_True == po) ? DC_TRUE : DC_FALSE;
        dcArgBool(gpCall, b);
      }
      break;
      case DC_SIGCHAR_CHAR:
      {
        DCchar c;
        if ( PyString_Check(po) )
        {
          // Py_ssize_t l;
          size_t l;
          char* s;
          l = PyString_GET_SIZE(po);
          if (l != 1) return PyErr_Format( PyExc_RuntimeError, "argument mismatch at pos %d - expecting a string with length of 1 (a char string)", index );          
          s = PyString_AsString(po);          
          c = (DCchar) s[0];
        }
        else if ( PyInt_Check(po) ) 
        {
          long l;
          l = PyInt_AsLong(po);
          if ( (l > CHAR_MAX) || (l < CHAR_MIN)) return PyErr_Format( PyExc_RuntimeError, "value out of range at argument %d - expecting a char code", index );
          c = (DCchar) l;
        }
        else return PyErr_Format( PyExc_RuntimeError, "argument mismatch at pos %d - expecting a char", index );        
        dcArgChar(gpCall, c);
      }
      break;
      case DC_SIGCHAR_SHORT:
      {
        DCshort s;
        long v;
        if ( !PyInt_Check(po) )
          return PyErr_Format( PyExc_RuntimeError, "argument mismatch at pos %d - expecting a short int", index ); 
        v = PyInt_AS_LONG(po);
        if ( (v < SHRT_MIN) || (v > SHRT_MAX) ) 
          return PyErr_Format( PyExc_RuntimeError, "value out of range at argument %d - expecting a short value", index );
        s = (DCshort) v;
        dcArgShort(gpCall, s);
      } 
      break;
      case DC_SIGCHAR_INT:
      {
        long v;
        if ( !PyInt_Check(po) ) return PyErr_Format( PyExc_RuntimeError, "argument mismatch at pos %d - expecting an int", index ); 
        v = PyInt_AS_LONG(po);
        dcArgInt(gpCall, (DCint) v );
      }
      break;
      case DC_SIGCHAR_LONG:
      {
        long v;
        if ( !PyInt_Check(po) ) return PyErr_Format( PyExc_RuntimeError, "argument mismatch at pos %d - expecting an int", index ); 
        v = PyInt_AsLong(po);
        
      }
      break;
      case DC_SIGCHAR_LONGLONG:
      {
        PY_LONG_LONG pl;
        DClonglong dl;
        if ( !PyLong_Check(po) ) return PyErr_Format( PyExc_RuntimeError, "argument mismatch at pos %d - expecting a long long", index );
        pl = PyLong_AsLongLong(po);
        dl = (DClonglong) pl;
        dcArgLongLong(gpCall, dl );
      }
      break;
      case DC_SIGCHAR_FLOAT:
      {
        DCfloat f;
        if (!PyFloat_Check(po)) return PyErr_Format( PyExc_RuntimeError, "argument mismatch at pos %d - expeecting a float", index );
        f = (float) PyFloat_AsDouble(po);
        dcArgFloat(gpCall, f);
      }
      break;
      case DC_SIGCHAR_DOUBLE:
      {
        double d;
        if (!PyFloat_Check(po)) return PyErr_Format( PyExc_RuntimeError, "argument mismatch at pos %d - expeecting a float", index );
        d = PyFloat_AsDouble(po);
        dcArgDouble(gpCall, d);      
      }
      break;
      case DC_SIGCHAR_POINTER:
      {
        DCpointer ptr;
        if ( PyString_Check(po) ) {
          ptr = (DCpointer) PyString_AsString(po);
        } else if ( PyLong_Check(po) ) {
          ptr = (DCpointer) ( (DCint) PyLong_AsLongLong(po) );
        } else {
          return PyErr_Format( PyExc_RuntimeError, "argument mismatch at pos %d - expecting a promoting pointer-type (int,string)", index );
        }
        dcArgPointer(gpCall, ptr );
      }
      break;
      case DC_SIGCHAR_STRING:
      {
        char* p;
        if (!PyString_Check(po) ) return PyErr_Format( PyExc_RuntimeError, "argument mismatch at pos %d - expecting a string", index );
        p = PyString_AsString(po);
        dcArgPointer(gpCall, (DCpointer) p );
      }
      break;
      default: return PyErr_Format( PyExc_RuntimeError, "unknown signature character '%c'", ch);
    }

    ++pos; ++ptr;

  }

  if (pos != l) return PyErr_Format( PyExc_RuntimeError, "too many arguments");

  if (ch == '\0') return PyErr_Format( PyExc_RuntimeError, "return value missing in signature");

  ch = *++ptr;

  switch(ch) 
  {
    case DC_SIGCHAR_VOID:                                                   dcCallVoid    (gpCall, pfunc); Py_RETURN_NONE;
    case DC_SIGCHAR_BOOL:     return Py_BuildValue("i",                     dcCallBool    (gpCall, pfunc));
    case DC_SIGCHAR_INT:      return Py_BuildValue("i",                     dcCallInt     (gpCall, pfunc)); 
    case DC_SIGCHAR_LONGLONG: return Py_BuildValue("L", (unsigned long long)dcCallLongLong(gpCall, pfunc));
    case DC_SIGCHAR_FLOAT:    return Py_BuildValue("f",                     dcCallFloat   (gpCall, pfunc)); 
    case DC_SIGCHAR_DOUBLE:   return Py_BuildValue("d",                     dcCallDouble  (gpCall, pfunc)); 
    case DC_SIGCHAR_STRING:   return Py_BuildValue("s",                     dcCallPointer (gpCall, pfunc)); 
    case DC_SIGCHAR_POINTER:  return Py_BuildValue("p",                     dcCallPointer (gpCall, pfunc)); 
    default:                  return PyErr_Format( PyExc_RuntimeError, "invalid return type signature");
  }
}


static PyMethodDef pydcMethods[] = {
  {"load", pydc_load, METH_VARARGS, "load library"},
  {"find", pydc_find, METH_VARARGS, "find symbols"},
  {"free", pydc_free, METH_VARARGS, "free library"},
  {"call", pydc_call, METH_VARARGS, "call function"},
  {NULL,NULL,0,NULL}
};

PyMODINIT_FUNC
initpydcext(void)
{
  PyObject* m;
  m = Py_InitModule("pydcext", pydcMethods);
  if (m == NULL)
    return;
  gpCall = dcNewCallVM(4096);
}


