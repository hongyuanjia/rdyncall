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

-module(callf_SUITE).
-compile(export_all).
-define(VMSZ, 1024).

all() ->
    [
     argf_one,
     argf_excessive_format,
     argf_excessive_args,
     argf_struct,
     callf_one,
     callf_bool,
     callf_void,
     callf_char,
     callf_uchar,
     callf_short,
     callf_ushort,
     callf_int,
     callf_uint,
     callf_long,
     callf_ulong,
     callf_longlong,
     callf_ulonglong,
     callf_float,
     callf_double,
     callf_pointer,
     callf_struct
    ].

argf_one(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "several_args"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    ok = dyncall:argf(CallVm,"jcZf)Z",[-125,$[,"foo",6.2]),
    {ok,"Your args were -125, [, foo, 6.2"} = dyncall:call_string(CallVm,Sym).    

argf_excessive_format(_) ->
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    {error,invalid_format} = dyncall:argf(CallVm,"jjjjjjjjcZf)Z",[-125,91,"foo",6.2]).

argf_excessive_args(_) ->
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    {error,invalid_format} = dyncall:argf(CallVm,"jcZf)Z",[-125,91,"foo",6.2,7,7,7,7,7,7]).

argf_struct(_) ->
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    {error,not_implemented} = dyncall:argf(CallVm,"jTZf)Z",[-125,91,"foo",6.2]).

callf_one(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "several_args"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    {ok,"Your args were -125, [, foo, 6.2"} = 
        dyncall:callf(CallVm,Sym,"jcZf)Z",[-125,91,"foo",6.2]).    

callf_bool(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "is_false"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    {ok,true} = 
        dyncall:callf(CallVm,Sym,"B)B",[false]).    

callf_void(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "noop"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    ok = dyncall:callf(CallVm,Sym,")v",[]).

callf_struct(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "several_args"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    {error,not_implemented} = 
        dyncall:callf(CallVm,Sym,"jcZf)T",[-125,91,"foo",6.2]).    

callf_char(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "get_next_char"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    {ok,120} = 
        dyncall:callf(CallVm,Sym,"c)c",[119]).    

callf_uchar(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "get_next_char_u"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    {ok,222} = 
        dyncall:callf(CallVm,Sym,"C)C",[221]).    

callf_short(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "times_three"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    {ok,-12} = 
        dyncall:callf(CallVm,Sym,"s)s",[-4]).    

callf_ushort(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "times_three_u"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    {ok,12} = 
        dyncall:callf(CallVm,Sym,"S)S",[4]).    

callf_int(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "is_false"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    {ok,1} = 
        dyncall:callf(CallVm,Sym,"i)i",[0]).    

callf_uint(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "dual_increment_u"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    {ok,6} = 
        dyncall:callf(CallVm,Sym,"I)I",[4]).    

callf_long(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "add_nineteen"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    {ok,19} = 
        dyncall:callf(CallVm,Sym,"j)j",[0]).    

callf_ulong(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "add_nineteen_u"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    {ok,23} = 
        dyncall:callf(CallVm,Sym,"J)J",[4]).    

callf_longlong(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "subtract_four"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    {ok,-1} = 
        dyncall:callf(CallVm,Sym,"l)l",[3]).    

callf_ulonglong(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "subtract_four_u"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    {ok,5} = 
        dyncall:callf(CallVm,Sym,"L)L",[9]).

callf_float(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "calculate_pi"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    {ok,3.0} = 
        dyncall:callf(CallVm,Sym,"f)f",[1.0]).

callf_double(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "times_pi"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    {ok,6.2} = 
        dyncall:callf(CallVm,Sym,"d)d",[2.0]).

callf_pointer(_) ->
    {ok,Libm} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Libm, "coolmalloc"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    {ok,MyMemory} = 
        dyncall:callf(CallVm,Sym,"j)p",[42]),
    ok = dyncall:reset(CallVm),
    {ok,Sym2} = dyncall:find_symbol(Libm, "coolidentity"),
    %% Surprisingly, this works.  The _resource handle
    %% returned to erlang from callf compares equal in
    %% erlang to the _resource handle passed as an arg.
    {ok,MyMemory} = 
        dyncall:callf(CallVm,Sym2,"p)p",[MyMemory]).






