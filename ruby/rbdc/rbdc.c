/*

 rbdc.c
 Copyright (c) 2007-2018 Daniel Adler <dadler@uni-goettingen.de>,
                         Tassilo Philipp <tphilipp@potion-studios.com>

 Permission to use, copy, modify, and distribute this software for any
 purpose with or without fee is hereby granted, provided that the above
 copyright notice and this permission notice appear in all copies.

 THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

 Ruby/dyncall extension implementation.

*/


#include <ruby.h>
#include "dyncall/dyncall/dyncall.h"
#include "dyncall/dyncallback/dyncall_callback.h"
#include "dyncall/dynload/dynload.h"
#include "dyncall/dyncall/dyncall_signature.h"

/* Our ruby module and its classes. */
static VALUE rb_dcModule;
static VALUE rb_dcExtLib;


typedef struct {
	void*     lib;
	void*     syms;
	DCCallVM* cvm;
} rb_dcLibHandle;


/* Allocator for handle and mark-and-sweep GC handlers. */
static void GCMark_ExtLib(rb_dcLibHandle* h)
{
}

static void GCSweep_ExtLib(rb_dcLibHandle* h)
{
	if(h->lib  != NULL) dlFreeLibrary(h->lib);
	if(h->syms != NULL) dlSymsCleanup(h->syms);

	dcFree(h->cvm);
	free(h);
}

static VALUE AllocExtLib(VALUE cl)
{
	rb_dcLibHandle* h = malloc(sizeof(rb_dcLibHandle));
	h->lib  = NULL;
	h->syms = NULL;
	h->cvm  = dcNewCallVM(4096/*@@@*/);
	return Data_Wrap_Struct(cl, GCMark_ExtLib, GCSweep_ExtLib, h);
}


/* Helpers */
static void ExtLib_SecCheckLib(rb_dcLibHandle* h)
{
	if(h->lib == NULL)
		rb_raise(rb_eRuntimeError, "no library loaded - use ExtLib#load");
}

static void ExtLib_SecCheckSyms(rb_dcLibHandle* h)
{
	if(h->syms == NULL)
		rb_raise(rb_eRuntimeError, "no symbol table initialized - use ExtLib#symsInit");
}



/* Methods for lib access */
static VALUE ExtLib_Load(VALUE self, VALUE path)
{
	void* newLib;
	rb_dcLibHandle* h;

	if(TYPE(path) != T_STRING)
		rb_raise(rb_eRuntimeError, "argument must be of type 'String'");/*@@@ respond to to_s*/

	Data_Get_Struct(self, rb_dcLibHandle, h);
	newLib = dlLoadLibrary(RSTRING_PTR(path));
	if(newLib) {
		dlFreeLibrary(h->lib);
		h->lib = newLib;

		return self;
	}

	return Qnil;
}

static VALUE ExtLib_ExistsQ(VALUE self, VALUE sym)
{
	rb_dcLibHandle* h;

	Data_Get_Struct(self, rb_dcLibHandle, h);
	ExtLib_SecCheckLib(h);

	return dlFindSymbol(h->lib, rb_id2name(SYM2ID(sym))) ? Qtrue : Qfalse;
}


/* Methods for syms parsing */
static VALUE ExtLib_SymsInit(VALUE self, VALUE path)
{
	void* newSyms;
	rb_dcLibHandle* h;

	if(TYPE(path) != T_STRING)
		rb_raise(rb_eRuntimeError, "argument must be of type 'String'");/*@@@ respond to to_s*/

	Data_Get_Struct(self, rb_dcLibHandle, h);
	newSyms = dlSymsInit(RSTRING_PTR(path));

	if(newSyms) {
		dlSymsCleanup(h->syms);
		h->syms = newSyms;

		return self;
	}

	return Qnil;
}


static VALUE ExtLib_SymsCount(VALUE self)
{
	rb_dcLibHandle* h;

	Data_Get_Struct(self, rb_dcLibHandle, h);
	ExtLib_SecCheckSyms(h);

	return LONG2NUM(dlSymsCount(h->syms));
}


static VALUE ExtLib_SymsEach(int argc, VALUE* argv, VALUE self)
{
	rb_dcLibHandle* h;
	size_t i, c;

	if(!rb_block_given_p())
		rb_raise(rb_eRuntimeError, "no block given");

	Data_Get_Struct(self, rb_dcLibHandle, h);
	ExtLib_SecCheckSyms(h);

	c = dlSymsCount(h->syms);
	for(i=0; i<c; ++i)
		rb_yield(ID2SYM(rb_intern(dlSymsName(h->syms, i))));

	return self;
}

/* expose dlSymsName @@@ */


/* Methods interfacing with dyncall */
static VALUE ExtLib_Call(int argc, VALUE* argv, VALUE self)
{
	/* argv[0] - symbol to call  *
	 * argv[1] - signature       *
	 * argv[2] - first parameter *
	 * argv[x] - parameter x-2   */

	rb_dcLibHandle* h;
	DCpointer       fptr;
	int             i, t, b;
	VALUE           r;
	DCCallVM*       cvm;
	const char*     sig;


	/* Security checks. */
	if(argc < 2)
		rb_raise(rb_eRuntimeError, "wrong number of arguments for function call");

	if(TYPE(argv[0]) != T_SYMBOL)
		rb_raise(rb_eRuntimeError, "syntax error - argument 0 must be of type 'Symbol'");

	if(TYPE(argv[1]) != T_STRING)
		rb_raise(rb_eRuntimeError, "syntax error - argument 1 must be of type 'String'");

	Data_Get_Struct(self, rb_dcLibHandle, h);
	cvm = h->cvm;

	if(argc != RSTRING_LEN(argv[1]))	/* Don't count the return value in the signature @@@ write something more secure */
		rb_raise(rb_eRuntimeError, "number of provided arguments doesn't match signature");

	ExtLib_SecCheckLib(h);


	/* Flush old arguments. */
	dcReset(cvm);


	/* Get a pointer to the function and start pushing. */
	fptr = (DCpointer)dlFindSymbol(h->lib, rb_id2name(SYM2ID(argv[0])));
	sig = RSTRING_PTR(argv[1]);

	for(i=2; i<argc; ++i) {
		t = TYPE(argv[i]);

		//@@@ add support for calling convention mode(s)

		switch(sig[i-2]) {
			case DC_SIGCHAR_BOOL:
				b = 1;
				switch(t) {
					case T_TRUE:   dcArgBool(cvm, DC_TRUE);                break;  /* TrueClass.  */
					case T_FALSE:                                                  /* FalseClass. */
					case T_NIL:    dcArgBool(cvm, DC_FALSE);               break;  /* NilClass.   */
					case T_FIXNUM: dcArgBool(cvm, FIX2LONG(argv[i]) != 0); break;  /* Fixnum.     */
					default:       b = 0;                                  break;
				}
				break;

			case DC_SIGCHAR_CHAR:
			case DC_SIGCHAR_UCHAR:     if(b = (t == T_FIXNUM)) dcArgChar    (cvm, (DCchar)    FIX2LONG(argv[i]));      break;
			case DC_SIGCHAR_SHORT:
			case DC_SIGCHAR_USHORT:    if(b = (t == T_FIXNUM)) dcArgShort   (cvm, (DCshort)   FIX2LONG(argv[i]));      break;
			case DC_SIGCHAR_INT:
			case DC_SIGCHAR_UINT:      if(b = (t == T_FIXNUM)) dcArgInt     (cvm, (DCint)     FIX2LONG(argv[i]));      break;
			case DC_SIGCHAR_LONG:
			case DC_SIGCHAR_ULONG:     if(b = (t == T_FIXNUM)) dcArgLong    (cvm, (DClong)    FIX2LONG(argv[i]));      break;
			case DC_SIGCHAR_LONGLONG:
			case DC_SIGCHAR_ULONGLONG: if(b = (t == T_FIXNUM)) dcArgLongLong(cvm, (DClonglong)FIX2LONG(argv[i]));      break;
			case DC_SIGCHAR_FLOAT:     if(b = (t == T_FLOAT))  dcArgFloat   (cvm, (DCfloat)   RFLOAT_VALUE(argv[i]));  break;
			case DC_SIGCHAR_DOUBLE:    if(b = (t == T_FLOAT))  dcArgDouble  (cvm, (DCdouble)  RFLOAT_VALUE(argv[i]));  break;

			case DC_SIGCHAR_POINTER:
			case DC_SIGCHAR_STRING:
				b = 1;	
				switch(t) {
					case T_STRING: dcArgPointer(cvm, RSTRING_PTR(argv[i])); break;  /* String. */
					default:       b = 0;                                   break;
				}
				break;

			default:
				b = 0;
				break;
		}


		if(!b)
			rb_raise(rb_eRuntimeError, "syntax error in signature or type mismatch at argument %d", i-2);
	}


	/* Get the return type and call the function. */
	switch(sig[i-1]) {
		case DC_SIGCHAR_VOID:      r = Qnil;        dcCallVoid    (cvm, fptr);                  break;
		case DC_SIGCHAR_BOOL:      r =              dcCallBool    (cvm, fptr) ? Qtrue : Qfalse; break;
		case DC_SIGCHAR_CHAR:
		case DC_SIGCHAR_UCHAR:     r = CHR2FIX(     dcCallChar    (cvm, fptr));                 break;
		case DC_SIGCHAR_SHORT:
		case DC_SIGCHAR_USHORT:    r = INT2FIX(     dcCallShort   (cvm, fptr));                 break;
		case DC_SIGCHAR_INT:
		case DC_SIGCHAR_UINT:      r = INT2FIX(     dcCallInt     (cvm, fptr));                 break;
		case DC_SIGCHAR_LONG:
		case DC_SIGCHAR_ULONG:     r = INT2FIX(     dcCallLong    (cvm, fptr));                 break;
		case DC_SIGCHAR_LONGLONG:
		case DC_SIGCHAR_ULONGLONG: r = INT2FIX(     dcCallLongLong(cvm, fptr));                 break;
		case DC_SIGCHAR_FLOAT:     r = rb_float_new(dcCallFloat   (cvm, fptr));                 break;
		case DC_SIGCHAR_DOUBLE:    r = rb_float_new(dcCallDouble  (cvm, fptr));                 break;
		case DC_SIGCHAR_STRING:    r = rb_str_new2( dcCallPointer (cvm, fptr));                 break;
		case DC_SIGCHAR_POINTER:
		default:
			rb_raise(rb_eRuntimeError, "unsupported return type or syntax error in signature");
	}

	return r;
}


/* Main initialization. */
void Init_rbdc()
{
	rb_dcModule = rb_define_module("Dyncall");

	/* Handle to the external dynamic library. */
	rb_dcExtLib = rb_define_class_under(rb_dcModule, "ExtLib", rb_cObject);

	/* Class allocators. */
	rb_define_alloc_func(rb_dcExtLib, AllocExtLib);

	/* Methods. */
	rb_define_method(rb_dcExtLib, "load",       &ExtLib_Load,      1);
	rb_define_method(rb_dcExtLib, "exists?",    &ExtLib_ExistsQ,   1);
	rb_define_method(rb_dcExtLib, "syms_init",  &ExtLib_SymsInit,  1);
	rb_define_method(rb_dcExtLib, "syms_count", &ExtLib_SymsCount, 0);
	rb_define_method(rb_dcExtLib, "syms_each",  &ExtLib_SymsEach, -1);
	rb_define_method(rb_dcExtLib, "call",       &ExtLib_Call,     -1);
}

