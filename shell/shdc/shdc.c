/*
 Package: dyncall
 File: bindings/shell.c
 Description: printf(1) style function call mechanism
 License:
 Copyright (c) 2007-2015 Daniel Adler <dadler@uni-goettingen.de>, 
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

*/

#include "../../dyncall/dyncall/dyncall.h"
#include "../../dyncall/dynload/dynload.h"
#include "../../dyncall/dyncall/dyncall_signature.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h> /* needed on some platforms to make atof work _at_runtime_ */

#define SHDC_VERSION "1.0"


void usage(const char* s)
{
	printf(
		"Usage: %s -l SO\n"
		"       %s -c SO SYM SIG [ARGS]\n"
		"       %s -v\n"
		"  where SO is the name of the shared object.\n"
		"\n"
		"  -l lists all symbol names in the shared object\n"
		"  -c calls function in the shared object, where SYM is the symbol name,\n"
		"     SIG the symbol's type signature, and ARGS the arguments.\n"
		"  -v displays the binding's version\n",
		s, s, s
	);
}


int main(int argc, char* argv[])
{
	const char* libPath;
	const char* symName;
	const DCsigchar* sig;
	const DCsigchar* i;
	void* sym;
	DCCallVM* vm;
	DLLib* dlLib;
	DLSyms* dlSyms;
	int c, l;

	if(argc == 2  && strcmp(argv[1], "-v") == 0) {
		printf(SHDC_VERSION"\n");
		return 0;
	}

	/* Parse arguments and check validity. */
	/* Need at least shared object name and action, and symbol name and signature string for call. */
	if(argc < 2) {
		usage(argv[0]);
		return 1;
	}

	c = strcmp(argv[1], "-c");
	l = strcmp(argv[1], "-l");
	if((c != 0 && l != 0) || (c == 0 && argc < 4)) {
		usage(argv[0]);
		return 1;
	}

	/* if lib path is empty string, use NULL as reference to own process/exe */
	libPath = argv[2][0] == '\0' ? NULL : argv[2];

	/* List symbols, if 'ls', else it must be 'call', so proceed to call. */
	if(l == 0) {
		dlSyms = dlSymsInit(libPath);
		if(!dlSyms) {
			printf("Can't load \"%s\".\n", libPath?libPath:"<NULL>");
			usage(argv[0]);
			return 1;
		}

		/* hacky: reuse c and l */
		for(c=dlSymsCount(dlSyms), l=0; l<c; ++l)
			printf("%s\n", dlSymsName(dlSyms, l));

		dlSymsCleanup(dlSyms);
	}
	else {
		/* Check if number of arguments matches sigstring spec. */
		/*if(n != argc-4)@@@*/	/* 0 is prog, 1 is flag, 2 is lib, 3 is symbol name, 4 is sig */
    
		/* Load library and get a pointer to the symbol to call. */
		dlLib = dlLoadLibrary(libPath);
		if(!dlLib) {
			printf("Can't load \"%s\".\n", libPath?libPath:"<NULL>");
			usage(argv[0]);
			return 1;
		}
    
		symName = argv[3];
		sig = i = argv[4];
    
		sym = dlFindSymbol(dlLib, symName);
		if(!sym) {
			/* this might be a syscall attempt, check if "symbol" is numeric */
			int n;
			if(sscanf(symName, "%d", &n) == 0) {
				printf("Can't find symbol \"%s\".\n", symName);
				dlFreeLibrary(dlLib);
				usage(argv[0]);
				return 1;
			}
			sym = (void*)(size_t)n;
		}
    
    
		vm = dcNewCallVM(4096/*@@@*/);/*@@@ error checking */
		dcReset(vm);
    
		while(*i != '\0' && *i != DC_SIGCHAR_ENDARG) {
			switch(*i) {
				case DC_SIGCHAR_CC_PREFIX:
					if(*(i+1) != '\0')
					{
						DCint mode = dcGetModeFromCCSigChar(*++i);
						if(mode != DC_ERROR_UNSUPPORTED_MODE)
							dcMode(vm, mode);
					}
					sig += 2;
					break;
    
				case DC_SIGCHAR_BOOL:      dcArgBool    (vm, (DCbool)           atoi    (argv[5+i-sig]        )); break;
				case DC_SIGCHAR_CHAR:      dcArgChar    (vm, (DCchar)           atoi    (argv[5+i-sig]        )); break;
				case DC_SIGCHAR_UCHAR:     dcArgChar    (vm, (DCchar)(DCuchar)  atoi    (argv[5+i-sig]        )); break;
				case DC_SIGCHAR_SHORT:     dcArgShort   (vm, (DCshort)          atoi    (argv[5+i-sig]        )); break;
				case DC_SIGCHAR_USHORT:    dcArgShort   (vm, (DCshort)(DCushort)atoi    (argv[5+i-sig]        )); break;
				case DC_SIGCHAR_INT:       dcArgInt     (vm, (DCint)            strtol  (argv[5+i-sig],NULL,10)); break;
				case DC_SIGCHAR_UINT:      dcArgInt     (vm, (DCint)(DCuint)    strtoul (argv[5+i-sig],NULL,10)); break;
				case DC_SIGCHAR_LONG:      dcArgLong    (vm, (DClong)           strtol  (argv[5+i-sig],NULL,10)); break;
				case DC_SIGCHAR_ULONG:     dcArgLong    (vm, (DCulong)          strtoul (argv[5+i-sig],NULL,10)); break;
				case DC_SIGCHAR_LONGLONG:  dcArgLongLong(vm, (DClonglong)       strtoll (argv[5+i-sig],NULL,10)); break;
				case DC_SIGCHAR_ULONGLONG: dcArgLongLong(vm, (DCulonglong)      strtoull(argv[5+i-sig],NULL,10)); break;
				case DC_SIGCHAR_FLOAT:     dcArgFloat   (vm, (DCfloat)          atof    (argv[5+i-sig]        )); break;
				case DC_SIGCHAR_DOUBLE:    dcArgDouble  (vm, (DCdouble)         atof    (argv[5+i-sig]        )); break;
				case DC_SIGCHAR_POINTER:   dcArgPointer (vm, (DCpointer)                 argv[5+i-sig]         ); break;
				case DC_SIGCHAR_STRING:    dcArgPointer (vm, (DCpointer)                 argv[5+i-sig]         ); break;
			}
			++i;
		}
    
		if(*i == DC_SIGCHAR_ENDARG)
			++i;
    
		switch(*i) {
			case '\0':
			case DC_SIGCHAR_VOID:                       dcCallVoid    (vm,sym) ; break;
			case DC_SIGCHAR_BOOL:      printf("%d\n",   dcCallBool    (vm,sym)); break;
			case DC_SIGCHAR_CHAR:      printf("%d\n",   dcCallChar    (vm,sym)); break;
			case DC_SIGCHAR_UCHAR:     printf("%d\n",   dcCallChar    (vm,sym)); break;
			case DC_SIGCHAR_SHORT:     printf("%d\n",   dcCallShort   (vm,sym)); break;
			case DC_SIGCHAR_USHORT:    printf("%d\n",   dcCallShort   (vm,sym)); break;
			case DC_SIGCHAR_INT:       printf("%d\n",   dcCallInt     (vm,sym)); break;
			case DC_SIGCHAR_UINT:      printf("%d\n",   dcCallInt     (vm,sym)); break;
			case DC_SIGCHAR_LONG:      printf("%ld\n",  dcCallLong    (vm,sym)); break;
			case DC_SIGCHAR_ULONG:     printf("%ld\n",  dcCallLong    (vm,sym)); break;
			case DC_SIGCHAR_LONGLONG:  printf("%lld\n", dcCallLongLong(vm,sym)); break;
			case DC_SIGCHAR_ULONGLONG: printf("%lld\n", dcCallLongLong(vm,sym)); break;
			case DC_SIGCHAR_FLOAT:     printf("%g\n",   dcCallFloat   (vm,sym)); break;
			case DC_SIGCHAR_DOUBLE:    printf("%g\n",   dcCallDouble  (vm,sym)); break;
			case DC_SIGCHAR_POINTER:   printf("%p\n",   dcCallPointer (vm,sym)); break;
			case DC_SIGCHAR_STRING:    printf("%s",     dcCallPointer (vm,sym)); break;
		}
    
		dlFreeLibrary(dlLib);
		dcFree(vm);
	}

	return 0;
}

