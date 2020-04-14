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

-define(DC_CALL_C_DEFAULT,              0).
-define(DC_CALL_C_ELLIPSIS,           100).
-define(DC_CALL_C_ELLIPSIS_VARARGS,   101).
-define(DC_CALL_C_X86_CDECL,            1).
-define(DC_CALL_C_X86_WIN32_STD,        2).
-define(DC_CALL_C_X86_WIN32_FAST_MS,    3).
-define(DC_CALL_C_X86_WIN32_FAST_GNU,   4).
-define(DC_CALL_C_X86_WIN32_THIS_MS,    5).
-define(DC_CALL_C_X86_WIN32_THIS_GNU,   6).
-define(DC_CALL_C_X64_WIN64,            7).
-define(DC_CALL_C_X64_SYSV,             8).
-define(DC_CALL_C_PPC32_DARWIN,         9).
-define(DC_CALL_C_PPC32_OSX,           ?DC_CALL_C_PPC32_DARWIN).
-define(DC_CALL_C_ARM_ARM_EABI,        10).
-define(DC_CALL_C_ARM_THUMB_EABI,      11).
-define(DC_CALL_C_ARM_ARMHF,           30).
-define(DC_CALL_C_MIPS32_EABI,         12).
-define(DC_CALL_C_MIPS32_PSPSDK,       ?DC_CALL_C_MIPS32_EABI).
-define(DC_CALL_C_PPC32_SYSV,          13).
-define(DC_CALL_C_PPC32_LINUX,         ?DC_CALL_C_PPC32_SYSV).
-define(DC_CALL_C_ARM_ARM,             14).
-define(DC_CALL_C_ARM_THUMB,           15).
-define(DC_CALL_C_MIPS32_O32,          16).
-define(DC_CALL_C_MIPS64_N32,          17).
-define(DC_CALL_C_MIPS64_N64,          18).
-define(DC_CALL_C_X86_PLAN9,           19).
-define(DC_CALL_C_SPARC32,             20).
-define(DC_CALL_C_SPARC64,             21).
-define(DC_CALL_C_ARM64,               22).
-define(DC_CALL_C_PPC64,               23).
-define(DC_CALL_C_PPC64_LINUX,        ?DC_CALL_C_PPC64).
-define(DC_CALL_SYS_DEFAULT,          200).
-define(DC_CALL_SYS_X86_INT80H_LINUX, 201).
-define(DC_CALL_SYS_X86_INT80H_BSD,   202).
-define(DC_CALL_SYS_X64_SYSCALL_SYSV, 204).
-define(DC_CALL_SYS_PPC32,            210).
-define(DC_CALL_SYS_PPC64,            211).

-define(DC_ERROR_NONE,               0).
-define(DC_ERROR_UNSUPPORTED_MODE,  -1).
