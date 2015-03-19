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

-module(misc_SUITE).
-compile(export_all).
-include("../include/dyncall.hrl").

-define(VMSZ, 1024).

all() ->
    [ 
      set_mode,
      set_bad_mode,
      reset_after_call,
      reset_before_call
    ].

set_mode(_) ->
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    dyncall:mode(CallVm,?DC_CALL_C_DEFAULT),
    {ok,?DC_ERROR_NONE} = dyncall:get_error(CallVm).

set_bad_mode(_) ->
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    dyncall:mode(CallVm,?DC_CALL_C_X86_WIN32_FAST_MS),
    {ok,?DC_ERROR_UNSUPPORTED_MODE} = dyncall:get_error(CallVm).

reset_after_call(_) ->
    {ok,Lib} = dyncall:load_library("erldc_testtargets"),
    {ok,Sym} = dyncall:find_symbol(Lib, "add_one"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    ok = dyncall:arg_int(CallVm,100),
    {ok,101} = dyncall:call_int(CallVm,Sym),
    
    ok = dyncall:reset(CallVm),
    
    {ok,Sym2} = dyncall:find_symbol(Lib, "add_seven"),
    {ok,107} = dyncall:call_int(CallVm,Sym2).
    
reset_before_call(_) ->
    {ok,Lib} = dyncall:load_library("erldc_testtargets"),
    {ok,_Sym} = dyncall:find_symbol(Lib, "add_one"),
    {ok,CallVm} = dyncall:new_call_vm(?VMSZ),
    ok = dyncall:arg_int(CallVm,100),

    ok = dyncall:reset(CallVm),

    {ok,Sym2} = dyncall:find_symbol(Lib, "add_seven"),
    ok = dyncall:arg_int(CallVm,200),
    {ok,207} = dyncall:call_int(CallVm,Sym2).
    

