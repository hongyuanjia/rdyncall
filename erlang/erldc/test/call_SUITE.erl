%%  Copyright (c) 2014 Erik Mackdanz <erikmack@gmail.com>

%%  Permission to use, copy, modify, and distribute this software for any
%%  purpose with or without fee is hereby granted, provided that the above
%%  copyright notice and this permission notice appear in all copies.

%%  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
%%  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
%%  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
%%  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
%%  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
%%  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
%%  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.          

-module(call_SUITE).
-compile(export_all).

-define(VMSZ, 1024).

all() ->
    [
     ret_double_arg_double,
     arg_double_bad_vm,
     arg_double_bad_vm_2,
     arg_double_bad_vm_3,
     arg_double_bad_arg,
     call_double_bad_vm,
     call_double_bad_sym,

     ret_float_arg_float,

     ret_int,
     arg_int,

     ret_char_arg_char,
     ret_bool_arg_bool,
     ret_bool_arg_bool_2,
     bad_bool_arg,
     ret_short_arg_short,
     ret_long_arg_long,
     ret_longlong_arg_longlong,

     ret_ptr_arg_int__ret_void_arg_ptr,
     ret_string_arg_string
    ].

%% Tests on sqrt

ret_double_arg_double(_) ->
    {ok,Libm} = dyncall:load_library("libm"),
    {ok,Sqrt} = dyncall:find_symbol(Libm, "sqrt"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    ok = dyncall:arg_double(CallVm,49.0),
    {ok,7.0} = dyncall:call_double(CallVm,Sqrt).
    
arg_double_bad_vm(_) ->
    {error,invalid_vm} = dyncall:arg_double(1000,49.0).
    
arg_double_bad_vm_2(_) ->
    {error,invalid_vm} = dyncall:arg_double("Not an int",49.0).
    
arg_double_bad_vm_3(_) ->
    {error,invalid_vm} = dyncall:arg_double(-4,49.0).
    
arg_double_bad_arg(_) ->
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    {error,invalid_arg} = dyncall:arg_double(CallVm,"Not a double").
    
call_double_bad_vm(_) ->
    {ok,Libm} = dyncall:load_library("libm"),
    {ok,Sqrt} = dyncall:find_symbol(Libm, "sqrt"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    ok = dyncall:arg_double(CallVm,49.0),
    {error,invalid_vm} = dyncall:call_double(12,Sqrt). %% assuming 12 is bad after preceding tests

call_double_bad_sym(_) ->
    {ok,Libm} = dyncall:load_library("libm"),
    {ok,_Sqrt} = dyncall:find_symbol(Libm, "sqrt"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    ok = dyncall:arg_double(CallVm,49.0),
    {error,invalid_arg} = dyncall:call_double(CallVm,12). %% assuming 12 is bad after preceding tests


%% Tests on sqrtf

ret_float_arg_float(_) ->
    {ok,Libm} = dyncall:load_library("libm"),
    {ok,Sqrt} = dyncall:find_symbol(Libm, "sqrtf"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    ok = dyncall:arg_float(CallVm,49.0),
    {ok,7.0} = dyncall:call_float(CallVm,Sqrt).

%% Tests on ilogb
ret_int(_) ->
    {ok,Libm} = dyncall:load_library("libm"),
    {ok,Exp} = dyncall:find_symbol(Libm, "ilogb"),
    {ok,CallVm} = dyncall:new_call_vm(4096),
    ok = dyncall:arg_double(CallVm,1024.0),
    {ok,10} = dyncall:call_int(CallVm,Exp).
    
%% Tests on ldexp
arg_int(_) ->
    {ok,Libm} = dyncall:load_library("libm"),
    {ok,Exp} = dyncall:find_symbol(Libm, "ldexp"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    ok = dyncall:arg_double(CallVm,3.0),
    ok = dyncall:arg_int(CallVm,2),
    {ok,12.0} = dyncall:call_double(CallVm,Exp).
    
%% Tests on get_next_char
ret_char_arg_char(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "get_next_char"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    ok = dyncall:arg_char(CallVm,$e),
    {ok,$f} = dyncall:call_char(CallVm,Sym).    

%% Tests on is_false
ret_bool_arg_bool(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "is_false"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    ok = dyncall:arg_bool(CallVm,true),
    {ok,false} = dyncall:call_bool(CallVm,Sym).    

ret_bool_arg_bool_2(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "is_false"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    ok = dyncall:arg_bool(CallVm,false),
    {ok,true} = dyncall:call_bool(CallVm,Sym).    

bad_bool_arg(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,_Sym} = dyncall:find_symbol(Libm, "is_false"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    {error,invalid_arg} = dyncall:arg_bool(CallVm,foobar).

%% Tests on times_three
ret_short_arg_short(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "times_three"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    ok = dyncall:arg_short(CallVm,7),
    {ok,21} = dyncall:call_short(CallVm,Sym).    

%% Tests on add_nineteen
ret_long_arg_long(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "add_nineteen"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    ok = dyncall:arg_long(CallVm,12),
    {ok,31} = dyncall:call_long(CallVm,Sym).    

%% Tests on subtract_four
ret_longlong_arg_longlong(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "subtract_four"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    ok = dyncall:arg_longlong(CallVm,15),
    {ok,11} = dyncall:call_longlong(CallVm,Sym).    

%% Tests on coolmalloc/coolfree
ret_ptr_arg_int__ret_void_arg_ptr(_) ->
    {ok,Lib} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Lib, "coolmalloc"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    ok = dyncall:arg_int(CallVm,100),
    {ok,Ptr} = dyncall:call_ptr(CallVm,Sym),

    %% Comes out as <<>> (opaque)
    %% io:format("Pointer in erl is ~p~n",[Ptr]),

    {ok,Sym2} = dyncall:find_symbol(Lib, "coolsetstr"),
    {ok,CallVm2} = dyncall:new_call_vm(?VMSZ),
    ok = dyncall:arg_ptr(CallVm2,Ptr),
    ok = dyncall:arg_string(CallVm2,"Barbaz"),
    ok = dyncall:call_void(CallVm2,Sym2),

    {ok,Sym3} = dyncall:find_symbol(Lib, "coolfree"),
    {ok,CallVm3} = dyncall:new_call_vm(?VMSZ),
    ok = dyncall:arg_ptr(CallVm3,Ptr),
    ok = dyncall:call_void(CallVm3,Sym3).    
    
%% Tests on interested_reply
ret_string_arg_string(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "interested_reply"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    ok = dyncall:arg_string(CallVm,"Georg"),
    {ok,"Really, Georg?  My name is Erik."} = dyncall:call_string(CallVm,Sym).    


