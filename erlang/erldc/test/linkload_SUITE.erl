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

-module(linkload_SUITE).
-compile(export_all).

-define(VMSZ, 1024).

all() ->
    [create_vm,
     create_vm_badsz,
     load_lib,
     no_such_lib,
     bad_lib,
     bad_sym,
     bad_sym_2,
     load_sym
    ].

create_vm(_) ->
    {ok,Vm} = dyncall:new_call_vm(?VMSZ),
    true = is_binary(Vm).

create_vm_badsz(_) ->
    {error,bad_vm_size} = dyncall:new_call_vm("Hello badarg").

load_lib(_) ->
    {ok,Lib} = dyncall:load_library("libm"),
    true = is_binary(Lib).
    
no_such_lib(_) ->
    {error,lib_not_found} = dyncall:load_library("foobarbaz").

bad_lib(_) ->
    {error,invalid_lib} = dyncall:load_library(12).

bad_sym(_) ->
    {ok,Lib} = dyncall:load_library("libm"),
    {error,symbol_not_found} = dyncall:find_symbol(Lib,"bogussymbol").
    
bad_sym_2(_) ->
    {ok,Lib} = dyncall:load_library("libm"),
    {error,invalid_symbol} = dyncall:find_symbol(Lib,9).
    
load_sym(_) ->
    {ok,Lib} = dyncall:load_library("libm"),
    {ok,_Partner} = dyncall:find_symbol(Lib,"sqrt").
    
    
	
