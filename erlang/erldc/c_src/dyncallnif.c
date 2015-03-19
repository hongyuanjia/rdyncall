/*
  Copyright (c) 2014 Erik Mackdanz <erikmack@gmail.com>

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
*/

#include "erl_nif.h"
#include "dyncall/dyncall.h"
#include "dyncall/dyncall_signature.h"

#include <string.h>
#include <stdio.h>

/************ Begin NIF initialization *******/

#define MAX_LIBPATH_SZ 128
#define MAX_SYMBOL_NAME_SZ 32
#define MAX_FORMAT_STRING_SZ 100
#define MAX_STRING_ARG_SZ 1024

ErlNifResourceType *g_ptrrestype, *g_vmrestype;

static void noop_dtor(ErlNifEnv* env, void* obj) {
  // When erlang gc's a ptr, no-op since we can't know how to free it.
  // Likewise with symbols, etc.
}
static void vm_dtor(ErlNifEnv* env, void* obj) {
  void** ptr = (void**)obj;
  dcFree(*ptr);
}

static int nifload(ErlNifEnv* env, void** priv_data, ERL_NIF_TERM load_info) {
  
  // Allows us to have a native pointer (to vm, lib, symbol, or user-defined) and
  // pass a safe opaque handle into erlang
  g_ptrrestype = enif_open_resource_type(env,"dyncall","pointer",
                                                        noop_dtor,ERL_NIF_RT_CREATE,
                                                        NULL);

  // Works like g_ptrrestype, but requires a dtor that calls dcFree
  g_vmrestype = enif_open_resource_type(env,"dyncall","vmpointer",
                                                        vm_dtor,ERL_NIF_RT_CREATE,
                                                        NULL);

  return 0;
}

/************ End NIF initialization *******/

#define ATOM_OK "ok"
#define ATOM_ERROR "error"

#define ATOM_LIB_NOT_FOUND "lib_not_found"
#define ATOM_SYMBOL_NOT_FOUND "symbol_not_found"
#define ATOM_BADSZ "bad_vm_size"
#define ATOM_INVALID_VM "invalid_vm"
#define ATOM_INVALID_LIB "invalid_lib"
#define ATOM_INVALID_SYMBOL "invalid_symbol"
#define ATOM_INVALID_FORMAT "invalid_format"
#define ATOM_INVALID_ARG "invalid_arg"
#define ATOM_NOT_IMPLEMENTED "not_implemented"

static ERL_NIF_TERM new_call_vm(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {

  long vmsz = 0;
  if(!enif_get_long(env, argv[0], &vmsz)) {
    return enif_make_tuple2(env,
			      enif_make_atom(env,ATOM_ERROR),
			      enif_make_atom(env,ATOM_BADSZ)
			    );
  }

  DCCallVM* vm = dcNewCallVM( vmsz );

  size_t sz = sizeof(DCCallVM*);
  DCpointer ptr_persistent_vm = enif_alloc_resource(g_vmrestype,sz);
  memcpy(ptr_persistent_vm,&vm,sz);
  ERL_NIF_TERM retterm = enif_make_resource(env,ptr_persistent_vm);
  enif_release_resource(ptr_persistent_vm);

  return enif_make_tuple2(env,
			  enif_make_atom(env,ATOM_OK),
                          retterm
			  );
}
  
#define MAYBE_RET_BAD_STRING_ARG(indexvar,argi,limit,retatom) \
  char indexvar[limit]; \
  indexvar[limit-1] = 0; \
  if(enif_get_string(env, argv[argi], indexvar, limit, ERL_NIF_LATIN1) <= 0) { \
    return enif_make_tuple2(env, \
			    enif_make_atom(env,ATOM_ERROR), \
			    enif_make_atom(env,retatom) \
			    ); \
  }

#define RETURN_ERROR(code) return enif_make_tuple2(env, \
			    enif_make_atom(env,ATOM_ERROR), \
			    enif_make_atom(env,code) \
			    );

static ERL_NIF_TERM load_library(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  MAYBE_RET_BAD_STRING_ARG(path,0,MAX_LIBPATH_SZ,ATOM_INVALID_LIB)

  void* libptr = enif_dlopen(path, NULL, NULL);

  // Error if dlLoadLibrary returned NULL
  if(!libptr) RETURN_ERROR(ATOM_LIB_NOT_FOUND)

  size_t sz = sizeof(void*);
  DCpointer ptr_persistent_lib = enif_alloc_resource(g_ptrrestype,sz);
  memcpy(ptr_persistent_lib,&libptr,sz);
  ERL_NIF_TERM retterm = enif_make_resource(env,ptr_persistent_lib);
  enif_release_resource(ptr_persistent_lib);
  
  return enif_make_tuple2(env,
			  enif_make_atom(env,ATOM_OK),
			  retterm
			  );
}

static ERL_NIF_TERM find_symbol(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  MAYBE_RET_BAD_STRING_ARG(path,1,MAX_SYMBOL_NAME_SZ,ATOM_INVALID_SYMBOL)

  void** libptr;
  if(!enif_get_resource(env, argv[0], g_ptrrestype, (void**)&libptr)) RETURN_ERROR(ATOM_INVALID_LIB)

  void* symptr = enif_dlsym(*libptr,path,NULL,NULL);

  size_t sz = sizeof(void*);
  DCpointer ptr_persistent_symbol = enif_alloc_resource(g_ptrrestype,sz);
  memcpy(ptr_persistent_symbol,&symptr,sz);
  ERL_NIF_TERM retterm = enif_make_resource(env,ptr_persistent_symbol);
  enif_release_resource(ptr_persistent_symbol);

  // Error if enif_dlsym returned NULL
  if(!symptr) RETURN_ERROR(ATOM_SYMBOL_NOT_FOUND)
  
  return enif_make_tuple2(env,
			  enif_make_atom(env,ATOM_OK),
			  retterm
			  );
}

#define BOOL_BUF_SZ 6
#define ATOM_TRUE "true"
#define ATOM_FALSE "false"

static void exec_call(ErlNifEnv* env, void* vm, void* sym, char rettype,ERL_NIF_TERM *retvalue, char** error_atom) {
  if(!sym) {
    *error_atom = ATOM_INVALID_SYMBOL;
    return;
  }

  DCpointer pret;
  DCfloat fret;
  DCdouble dret;
  DCint iret;
  DCbool bret;
  DCshort sret;
  DClong lret;
  DClonglong llret;

  char* tmpstr;
  size_t sz;
  DCpointer ptr_persistent;

  switch(rettype) {
  case DC_SIGCHAR_VOID:
    dcCallVoid(vm,sym);
    return;
  case DC_SIGCHAR_BOOL:
    bret = dcCallBool(vm,sym);
    tmpstr = bret ? ATOM_TRUE : ATOM_FALSE;
    *retvalue = enif_make_atom(env,tmpstr);
    return;
  case DC_SIGCHAR_CHAR:
    iret = dcCallChar(vm,sym);
    *retvalue = enif_make_int(env,(char)iret);
    return;
  case DC_SIGCHAR_UCHAR:
    iret = dcCallChar(vm,sym);
    *retvalue = enif_make_int(env,(unsigned char)iret);
    return;
  case DC_SIGCHAR_SHORT:
    sret = dcCallShort(vm,sym);
    *retvalue = enif_make_int(env,sret);
    return;
  case DC_SIGCHAR_USHORT:
    sret = dcCallShort(vm,sym);
    *retvalue = enif_make_int(env,(unsigned short)sret);
    return;
  case DC_SIGCHAR_INT:
    iret = dcCallInt(vm,sym);
    *retvalue = enif_make_int(env,iret);
    return;
  case DC_SIGCHAR_UINT:
    iret = dcCallInt(vm,sym);
    *retvalue = enif_make_int(env,(unsigned int)iret);
    return;
  case DC_SIGCHAR_LONG:
    lret = dcCallLong(vm,sym);
    *retvalue = enif_make_long(env,lret);
    return;
  case DC_SIGCHAR_ULONG:
    lret = dcCallLong(vm,sym);
    *retvalue = enif_make_long(env,(unsigned long)lret);
    return;
  case DC_SIGCHAR_LONGLONG:
    llret = dcCallLongLong(vm,sym);
    *retvalue = enif_make_int64(env,llret);
    return;
  case DC_SIGCHAR_ULONGLONG:
    llret = dcCallLongLong(vm,sym);
    *retvalue = enif_make_int64(env,(unsigned long long)llret);
    return;
  case DC_SIGCHAR_FLOAT:
    fret = dcCallFloat(vm,sym);
    *retvalue = enif_make_double(env,fret);
    return;
  case DC_SIGCHAR_DOUBLE:
    dret = dcCallDouble(vm,sym);
    *retvalue = enif_make_double(env,dret);
    return;
  case DC_SIGCHAR_POINTER:
    pret = dcCallPointer(vm,sym);
    sz = sizeof(DCpointer);

    ptr_persistent = enif_alloc_resource(g_ptrrestype,sz);
    memcpy(ptr_persistent,&pret,sz);
    *retvalue = enif_make_resource(env,ptr_persistent);
    enif_release_resource(ptr_persistent);
    return;
  case DC_SIGCHAR_STRING:
    pret = dcCallPointer(vm,sym);
    *retvalue = enif_make_string(env,pret,ERL_NIF_LATIN1);
    break;
  case DC_SIGCHAR_STRUCT:
    *error_atom=ATOM_NOT_IMPLEMENTED;
    return;
  default:
    *error_atom=ATOM_INVALID_FORMAT;
    return;
  }
}


static void exec_arg(ErlNifEnv* env,void* vm,char argtype,ERL_NIF_TERM argterm,char** error_atom) {
    char carg;
    long int larg = -1;
    int iarg = -1;
    char sarg[MAX_STRING_ARG_SZ];
    double darg = -1.0;
    char barg[BOOL_BUF_SZ];
    ErlNifSInt64 llarg = -1;
    void** parg;

    switch(argtype) {
    case DC_SIGCHAR_BOOL:
      if(!enif_get_atom(env, argterm, barg, BOOL_BUF_SZ, ERL_NIF_LATIN1)) {
        *error_atom = ATOM_INVALID_ARG;
        return;
      }
      dcArgBool(vm,!strcmp(barg,ATOM_TRUE));
      break;
    case DC_SIGCHAR_CHAR:
      if(!enif_get_int(env, argterm, &iarg)) {
        *error_atom = ATOM_INVALID_ARG;
        return;
      }
      dcArgChar(vm,(char)iarg);
      break;
    case DC_SIGCHAR_UCHAR:
      if(!enif_get_int(env, argterm, &iarg)) {
        *error_atom = ATOM_INVALID_ARG;
        return;
      }
      dcArgInt(vm,(unsigned char)iarg);
      break;
    case DC_SIGCHAR_SHORT:
      if(!enif_get_int(env, argterm, &iarg)) {
        *error_atom = ATOM_INVALID_ARG;
        return;
      }
      dcArgShort(vm,(short)iarg);
      break;
    case DC_SIGCHAR_USHORT:
      if(!enif_get_int(env, argterm, &iarg)) {
        *error_atom = ATOM_INVALID_ARG;
        return;
      }
      dcArgShort(vm,(unsigned short)iarg);
      break;
    case DC_SIGCHAR_INT:
      if(!enif_get_int(env, argterm, &iarg)) {
        *error_atom = ATOM_INVALID_ARG;
        return;
      }
      dcArgInt(vm,iarg);
      break;
    case DC_SIGCHAR_UINT:
      if(!enif_get_int(env, argterm, &iarg)) {
        *error_atom = ATOM_INVALID_ARG;
        return;
      }
      dcArgInt(vm,(unsigned int)iarg);
      break;
    case DC_SIGCHAR_LONG:
      if(!enif_get_long(env, argterm, &larg)) {
        *error_atom = ATOM_INVALID_ARG;
        return;
      }
      dcArgLong(vm,larg);
      break;
    case DC_SIGCHAR_ULONG:
      if(!enif_get_long(env, argterm, &larg)) {
        *error_atom = ATOM_INVALID_ARG;
        return;
      }
      dcArgLong(vm,(unsigned long)larg);
      break;
    case DC_SIGCHAR_LONGLONG:
      if(!enif_get_int64(env, argterm, &llarg)) {
        *error_atom = ATOM_INVALID_ARG;
        return;
      }
      dcArgLongLong(vm,llarg);
      break;
    case DC_SIGCHAR_ULONGLONG:
      if(!enif_get_int64(env, argterm, &llarg)) {
        *error_atom = ATOM_INVALID_ARG;
        return;
      }
      dcArgLongLong(vm,(unsigned long long)llarg);
      break;
    case DC_SIGCHAR_FLOAT:
      if(!enif_get_double(env, argterm, &darg)) {
        *error_atom = ATOM_INVALID_ARG;
        return;
      }
      dcArgFloat(vm,(float)darg);
      break;
    case DC_SIGCHAR_DOUBLE:
      if(!enif_get_double(env, argterm, &darg)) {
        *error_atom = ATOM_INVALID_ARG;
        return;
      }
      dcArgDouble(vm,darg);
      break;
    case DC_SIGCHAR_POINTER:
      if(!enif_get_resource(env, argterm, g_ptrrestype, (void**)&parg)) {
        *error_atom = ATOM_INVALID_ARG;
        return;
      }
      dcArgPointer(vm,*parg);
      break;
    case DC_SIGCHAR_STRING:
      if(!enif_get_string(env, argterm, sarg, MAX_STRING_ARG_SZ, ERL_NIF_LATIN1)) {
        *error_atom = ATOM_INVALID_ARG;
        return;
      }
      dcArgPointer(vm,sarg);
      break;
    case DC_SIGCHAR_STRUCT:
      *error_atom = ATOM_NOT_IMPLEMENTED;
      return;
    default:
      *error_atom = ATOM_INVALID_FORMAT;
      return;
    }
}

#define GET_VM void** vmptr; \
  if(!enif_get_resource(env, argv[0], g_vmrestype, (void**)&vmptr)) RETURN_ERROR(ATOM_INVALID_VM); \
  if(!*vmptr) RETURN_ERROR(ATOM_INVALID_VM);

#define GET_SYM void** symptr; \
  if(!enif_get_resource(env, argv[1], g_ptrrestype, (void**)&symptr)) RETURN_ERROR(ATOM_INVALID_ARG);

#define EXEC_CALL(typechar) ERL_NIF_TERM retvalue; \
  char* error_atom = NULL; \
  exec_call(env,*vmptr,*symptr,typechar,&retvalue,&error_atom);

#define MAKE_CALL_RETURN if(error_atom) RETURN_ERROR(error_atom); \
  return enif_make_tuple2(env, \
			  enif_make_atom(env,ATOM_OK), \
			  retvalue \
			  );

#define EXEC_ARG(typechar) char* error_atom = NULL; \
  exec_arg(env,*vmptr,typechar,argv[1],&error_atom);

#define MAKE_ARG_RETURN if(error_atom) RETURN_ERROR(error_atom); \
  return enif_make_atom(env,ATOM_OK);


static ERL_NIF_TERM arg_double(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;
  EXEC_ARG(DC_SIGCHAR_DOUBLE);
  MAKE_ARG_RETURN;
}

static ERL_NIF_TERM call_double(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;
  GET_SYM;
  EXEC_CALL(DC_SIGCHAR_DOUBLE);
  MAKE_CALL_RETURN;
}

static ERL_NIF_TERM arg_float(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;
  EXEC_ARG(DC_SIGCHAR_FLOAT);
  MAKE_ARG_RETURN;
}

static ERL_NIF_TERM call_float(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;
  GET_SYM;
  EXEC_CALL(DC_SIGCHAR_FLOAT);
  MAKE_CALL_RETURN;
}

static ERL_NIF_TERM arg_int(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;
  EXEC_ARG(DC_SIGCHAR_INT);
  MAKE_ARG_RETURN;
}

static ERL_NIF_TERM call_int(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;
  GET_SYM;
  EXEC_CALL(DC_SIGCHAR_INT);
  MAKE_CALL_RETURN;
}

static ERL_NIF_TERM arg_char(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;
  EXEC_ARG(DC_SIGCHAR_CHAR);
  MAKE_ARG_RETURN;
}

static ERL_NIF_TERM call_char(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;
  GET_SYM;
  EXEC_CALL(DC_SIGCHAR_CHAR);
  MAKE_CALL_RETURN;
}

static ERL_NIF_TERM arg_bool(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;
  EXEC_ARG(DC_SIGCHAR_BOOL);
  MAKE_ARG_RETURN;
}

static ERL_NIF_TERM call_bool(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;
  GET_SYM;
  EXEC_CALL(DC_SIGCHAR_BOOL);
  MAKE_CALL_RETURN;
}

static ERL_NIF_TERM arg_short(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;
  EXEC_ARG(DC_SIGCHAR_SHORT);
  MAKE_ARG_RETURN;
}

static ERL_NIF_TERM call_short(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;
  GET_SYM;
  EXEC_CALL(DC_SIGCHAR_SHORT);
  MAKE_CALL_RETURN;
}

static ERL_NIF_TERM arg_long(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;
  EXEC_ARG(DC_SIGCHAR_LONG);
  MAKE_ARG_RETURN;
}

static ERL_NIF_TERM call_long(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;
  GET_SYM;
  EXEC_CALL(DC_SIGCHAR_LONG);
  MAKE_CALL_RETURN;
}

static ERL_NIF_TERM arg_longlong(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;
  EXEC_ARG(DC_SIGCHAR_LONGLONG);
  MAKE_ARG_RETURN;
}

static ERL_NIF_TERM call_longlong(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;
  GET_SYM;
  EXEC_CALL(DC_SIGCHAR_LONGLONG);
  MAKE_CALL_RETURN;
}

static ERL_NIF_TERM arg_ptr(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;
  EXEC_ARG(DC_SIGCHAR_POINTER);
  MAKE_ARG_RETURN;
}

static ERL_NIF_TERM call_ptr(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;
  GET_SYM;
  EXEC_CALL(DC_SIGCHAR_POINTER);
  MAKE_CALL_RETURN;
}

static ERL_NIF_TERM call_void(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;
  GET_SYM;
  EXEC_CALL(DC_SIGCHAR_VOID);

  if(error_atom) RETURN_ERROR(error_atom);
  return enif_make_atom(env,ATOM_OK);
}

static ERL_NIF_TERM arg_string(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;
  EXEC_ARG(DC_SIGCHAR_STRING);
  MAKE_ARG_RETURN;
}

static ERL_NIF_TERM call_string(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;
  GET_SYM;
  EXEC_CALL(DC_SIGCHAR_STRING);
  MAKE_CALL_RETURN;
}

static ERL_NIF_TERM mode(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;

  int mode = -1;
  if(!enif_get_int(env, argv[1], &mode)) RETURN_ERROR(ATOM_INVALID_ARG)

  dcMode(*vmptr,mode);
  return enif_make_atom(env,ATOM_OK);
}

static ERL_NIF_TERM get_error(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;

  DCint ret = dcGetError(*vmptr);

  return enif_make_tuple2(env,
			  enif_make_atom(env,ATOM_OK),
			  enif_make_int(env,ret)
			  );
}

static ERL_NIF_TERM reset(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;

  dcReset(*vmptr);
  return enif_make_atom(env,ATOM_OK);
}

static void process_formatted_args(ErlNifEnv* env,void* vm,char** format,ERL_NIF_TERM arglist,char** error_atom) {

  ERL_NIF_TERM remaining = arglist;

  char sigchar;
  char* onechar = *format;
  while((sigchar=*onechar)) {
    if(sigchar==DC_SIGCHAR_ENDARG) break;

    // If the format has more items than the arg list,
    // fail and call it a bad format.
    ERL_NIF_TERM first, rest;
    if(!enif_get_list_cell(env, remaining, &first, &rest)) {
      *error_atom = ATOM_INVALID_FORMAT;
      return;
    }
    
    exec_arg(env,vm,sigchar,first,error_atom);

    remaining = rest;
    onechar++;
  }

  // There are more args, but the format was exhausted
  if(!enif_is_empty_list(env,remaining)) {
    *error_atom = ATOM_INVALID_FORMAT;
    return;
  }

  *format = onechar;
}

static ERL_NIF_TERM argf(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;
  MAYBE_RET_BAD_STRING_ARG(format,1,MAX_FORMAT_STRING_SZ,ATOM_INVALID_FORMAT);

  char* formatretyped = format;
  char* error_atom = NULL;
  process_formatted_args(env,*vmptr,&formatretyped, argv[2], &error_atom);

  if(error_atom) {
    RETURN_ERROR(error_atom);
  } else return enif_make_atom(env,ATOM_OK);
}

static ERL_NIF_TERM callf(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[]) {
  GET_VM;

  void** symptr;
  if(!enif_get_resource(env, argv[1], g_ptrrestype, (void**)&symptr)) RETURN_ERROR(ATOM_INVALID_ARG)
  if(!*symptr) RETURN_ERROR(ATOM_INVALID_SYMBOL)

  MAYBE_RET_BAD_STRING_ARG(format,2,MAX_FORMAT_STRING_SZ,ATOM_INVALID_FORMAT);

  char* formatretyped = format;
  char* error_atom = NULL;
  process_formatted_args(env,*vmptr,&formatretyped, argv[3], &error_atom);

  if(error_atom) {
    RETURN_ERROR(error_atom);
  }

  // Get return type char, skip )
  char rettypechar = *(formatretyped+1);

  ERL_NIF_TERM retval;

  exec_call(env,*vmptr,*symptr,rettypechar,&retval,&error_atom);
  
  if(error_atom) {
    RETURN_ERROR(error_atom);
  }

  if(rettypechar == DC_SIGCHAR_VOID) {
    return enif_make_atom(env,ATOM_OK);
  }

  return enif_make_tuple2(env,
                          enif_make_atom(env,ATOM_OK),
                          retval
                          );
}

static ErlNifFunc nif_funcs[] = {
  {"new_call_vm", 1, new_call_vm},
  {"mode", 2, mode},
  {"get_error", 1, get_error},
  {"reset", 1, reset},
  {"load_library", 1, load_library},
  {"find_symbol", 2, find_symbol},
  {"arg_double", 2, arg_double},
  {"call_double", 2, call_double},
  {"arg_float", 2, arg_float},
  {"call_float", 2, call_float},
  {"arg_int", 2, arg_int},
  {"call_int", 2, call_int},
  {"arg_char", 2, arg_char},
  {"call_char", 2, call_char},
  {"arg_bool", 2, arg_bool},
  {"call_bool", 2, call_bool},
  {"arg_short", 2, arg_short},
  {"call_short", 2, call_short},
  {"arg_long", 2, arg_long},
  {"call_long", 2, call_long},
  {"arg_longlong", 2, arg_longlong},
  {"call_longlong", 2, call_longlong},
  {"arg_ptr", 2, arg_ptr},
  {"call_ptr", 2, call_ptr},
  {"call_void", 2, call_void},
  {"arg_string", 2, arg_string},
  {"call_string", 2, call_string},

  {"argf", 3, argf},
  {"callf", 4, callf}
};

ERL_NIF_INIT(dyncall,nif_funcs,&nifload,NULL,NULL,NULL)
