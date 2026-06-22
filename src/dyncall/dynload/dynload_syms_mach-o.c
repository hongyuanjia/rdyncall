/*

 Package: dyncall
 Library: dynload
 File: dynload/dynload_syms_mach-o.c
 Description:
 License:

   Copyright (c) 2007-2015 Olivier Chafik <olivier.chafik@gmail.com>,
                 2017-2021 refactored completely for stability, API
                           consistency and portability by Tassilo Philipp.

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



/*

 dynamic symbol resolver for Mach-O

*/

#include "dynload.h"
#include "dynload_alloc.h"
#include "../dyncall/dyncall_macros.h"

#include <mach-o/dyld.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>
#include <dlfcn.h>
#include <stdint.h>
#include <string.h>

#ifndef LC_REEXPORT_DYLIB
#define LC_REEXPORT_DYLIB 0x8000001f
#endif
#ifndef LC_DYLD_INFO
#define LC_DYLD_INFO 0x22
#endif
#ifndef LC_DYLD_INFO_ONLY
#define LC_DYLD_INFO_ONLY 0x80000022
#endif
#ifndef LC_DYLD_EXPORTS_TRIE
#define LC_DYLD_EXPORTS_TRIE 0x80000033
#endif

#if defined(DC__Arch_AMD64) || defined(DC__Arch_PPC64) || defined(DC__Arch_ARM64)
#define MACH_HEADER_TYPE mach_header_64
#define MACH_HEADER_MAGIC_NR MH_MAGIC_64
#define SEGMEND_COMMAND_ID LC_SEGMENT_64
#define SEGMENT_COMMAND segment_command_64
#define NLIST_TYPE nlist_64
#else
#define MACH_HEADER_TYPE mach_header
#define MACH_HEADER_MAGIC_NR MH_MAGIC
#define SEGMEND_COMMAND_ID LC_SEGMENT
#define SEGMENT_COMMAND segment_command
#define NLIST_TYPE nlist
#endif

#define DL_EXPORT_TRIE_MAX_DEPTH 128
#define DL_REEXPORT_MAX_DEPTH 16


typedef struct DLStringList_
{
	char**   values;
	uint32_t count;
	uint32_t capacity;
} DLStringList;


struct DLSyms_
{
	DLLib*                   pLib;
	const char*              pStringTable;
	const struct NLIST_TYPE* pSymbolTable;
	char**                   pSymbolNames;
	uint32_t                 symbolCount;
	uintptr_t                symOffset;
};


static void dlStringListInit(DLStringList* pList)
{
	pList->values = NULL;
	pList->count = 0;
	pList->capacity = 0;
}


static void dlStringListRelease(DLStringList* pList)
{
	uint32_t i;
	if(pList->values) {
		for(i = 0; i < pList->count; ++i)
			dlFreeMem(pList->values[i]);
		dlFreeMem(pList->values);
	}
	dlStringListInit(pList);
}


static const char* dlNormalizeDarwinSymbolName(const char* name, int stripPrefix)
{
	if(stripPrefix && name && name[0] == '_' && name[1] != '\0')
		return name + 1;
	return name;
}


static int dlStringListContains(const DLStringList* pList, const char* value)
{
	uint32_t i;
	for(i = 0; i < pList->count; ++i) {
		if(strcmp(pList->values[i], value) == 0)
			return 1;
	}
	return 0;
}


static char* dlStrDup(const char* value)
{
	size_t len = strlen(value);
	char* copy = (char*)dlAllocMem(len + 1);
	if(!copy)
		return NULL;
	memcpy(copy, value, len + 1);
	return copy;
}


static int dlStringListGrow(DLStringList* pList)
{
	uint32_t newCapacity = pList->capacity ? pList->capacity * 2 : 64;
	char** values;

	if(newCapacity <= pList->capacity)
		return 0;

	values = (char**)dlAllocMem(sizeof(char*) * newCapacity);
	if(!values)
		return 0;

	if(pList->values) {
		memcpy(values, pList->values, sizeof(char*) * pList->count);
		dlFreeMem(pList->values);
	}

	pList->values = values;
	pList->capacity = newCapacity;
	return 1;
}


static int dlStringListAppendUnique(DLStringList* pList, const char* value, int stripDarwinPrefix)
{
	char* copy;

	value = dlNormalizeDarwinSymbolName(value, stripDarwinPrefix);
	if(!value || value[0] == '\0')
		return 1;

	if(dlStringListContains(pList, value))
		return 1;

	if(pList->count == pList->capacity && !dlStringListGrow(pList))
		return 0;

	copy = dlStrDup(value);
	if(!copy)
		return 0;

	pList->values[pList->count++] = copy;
	return 1;
}


static int dlStringListAppendUniqueBounded(DLStringList* pList, const char* value, const char* end, int stripDarwinPrefix)
{
	const char* p = value;
	char* copy;
	int ok;

	while(p < end && *p != '\0')
		++p;
	if(p == end)
		return 0;

	copy = (char*)dlAllocMem((size_t)(p - value) + 1);
	if(!copy)
		return 0;

	memcpy(copy, value, (size_t)(p - value));
	copy[p - value] = '\0';
	ok = dlStringListAppendUnique(pList, copy, stripDarwinPrefix);
	dlFreeMem(copy);
	return ok;
}


static int dlReadULEB128(const unsigned char** pp, const unsigned char* end, uintptr_t* out)
{
	const unsigned char* p = *pp;
	uintptr_t result = 0;
	unsigned int bit = 0;

	for(;;) {
		unsigned char byte;
		if(p >= end || bit >= sizeof(uintptr_t) * 8)
			return 0;
		byte = *p++;
		result |= ((uintptr_t)(byte & 0x7f)) << bit;
		if((byte & 0x80) == 0) {
			*pp = p;
			*out = result;
			return 1;
		}
		bit += 7;
	}
}


static int dlWalkExportTrie(DLStringList* pNames, const unsigned char* trieStart, const unsigned char* trieEnd, const unsigned char* node, const char* prefix, int depth)
{
	const unsigned char* p;
	const unsigned char* terminalEnd;
	uintptr_t terminalSize;
	uintptr_t childOffset;
	uint32_t i;
	unsigned char childCount;
	size_t prefixLen;

	if(depth > DL_EXPORT_TRIE_MAX_DEPTH || node < trieStart || node >= trieEnd)
		return 0;

	p = node;
	if(!dlReadULEB128(&p, trieEnd, &terminalSize))
		return 0;
	if((uintptr_t)(trieEnd - p) < terminalSize)
		return 0;

	terminalEnd = p + terminalSize;
	if(terminalSize != 0) {
		uintptr_t flags;
		const unsigned char* terminal = p;
		if(!dlReadULEB128(&terminal, terminalEnd, &flags))
			return 0;
		(void)flags;
		if(!dlStringListAppendUnique(pNames, prefix, 1))
			return 0;
	}

	p = terminalEnd;
	if(p >= trieEnd)
		return 0;

	childCount = *p++;
	prefixLen = strlen(prefix);

	for(i = 0; i < childCount; ++i) {
		const unsigned char* edge = p;
		size_t edgeLen;
		char* childName;

		while(p < trieEnd && *p != '\0')
			++p;
		if(p >= trieEnd)
			return 0;

		edgeLen = (size_t)(p - edge);
		++p;
		if(!dlReadULEB128(&p, trieEnd, &childOffset))
			return 0;
		if(childOffset >= (uintptr_t)(trieEnd - trieStart))
			return 0;
		if(prefixLen > ((size_t)-1) - edgeLen - 1)
			return 0;

		childName = (char*)dlAllocMem(prefixLen + edgeLen + 1);
		if(!childName)
			return 0;
		memcpy(childName, prefix, prefixLen);
		memcpy(childName + prefixLen, edge, edgeLen);
		childName[prefixLen + edgeLen] = '\0';

		if(!dlWalkExportTrie(pNames, trieStart, trieEnd, trieStart + childOffset, childName, depth + 1)) {
			dlFreeMem(childName);
			return 0;
		}
		dlFreeMem(childName);
	}

	return 1;
}


static int dlCollectExportTrieSymbols(DLStringList* pNames, const char* linkeditBase, uint32_t exportOff, uint32_t exportSize)
{
	const unsigned char* trieStart;
	const unsigned char* trieEnd;

	if(!linkeditBase || exportOff == 0 || exportSize == 0)
		return 0;

	trieStart = (const unsigned char*)(linkeditBase + exportOff);
	trieEnd = trieStart + exportSize;
	return dlWalkExportTrie(pNames, trieStart, trieEnd, trieStart, "", 0);
}


static DLSyms* dlSymsAlloc(DLLib* pLib)
{
	DLSyms* pSyms = (DLSyms*)dlAllocMem(sizeof(DLSyms));
	if(pSyms)
		memset(pSyms, 0, sizeof(DLSyms));
	if(pSyms)
		pSyms->pLib = pLib;
	return pSyms;
}


static DLSyms* dlSymsFromNameList(DLLib* pLib, DLStringList* pNames)
{
	DLSyms* pSyms = dlSymsAlloc(pLib);
	if(!pSyms)
		return NULL;

	pSyms->symbolCount = pNames->count;
	pSyms->pSymbolNames = pNames->values;
	pNames->values = NULL;
	pNames->count = 0;
	pNames->capacity = 0;
	return pSyms;
}


static const char* dlLastPathComponent(const char* path)
{
	const char* slash = path ? strrchr(path, '/') : NULL;
	return slash ? slash + 1 : path;
}


static int dlSystemAliasName(const char* libPath, char* out, size_t outSize)
{
	const char* leaf = dlLastPathComponent(libPath);
	size_t len;

	if(!leaf || strncmp(libPath, "/usr/lib/", 9) != 0)
		return 0;
	if(strncmp(leaf, "lib", 3) != 0)
		return 0;

	len = strlen(leaf);
	if(len <= 9 || strcmp(leaf + len - 6, ".dylib") != 0)
		return 0;

	len -= 6; /* strip .dylib */
	if(len <= 3 || outSize <= len - 3)
		return 0;

	memcpy(out, leaf + 3, len - 3);
	out[len - 3] = '\0';
	return 1;
}


static int dlIsMatchingSystemAliasReexport(const char* libPath, const char* reexportPath)
{
	const char prefix[] = "libsystem_";
	const char suffix[] = ".dylib";
	char alias[128];
	const char* leaf;
	size_t aliasLen;
	size_t expectedLen;

	if(!dlSystemAliasName(libPath, alias, sizeof(alias)))
		return 0;
	if(!reexportPath || strncmp(reexportPath, "/usr/lib/system/", 16) != 0)
		return 0;

	leaf = dlLastPathComponent(reexportPath);
	if(!leaf)
		return 0;

	aliasLen = strlen(alias);
	expectedLen = strlen(prefix) + aliasLen + strlen(suffix);
	return strlen(leaf) == expectedLen &&
		strncmp(leaf, prefix, strlen(prefix)) == 0 &&
		strncmp(leaf + strlen(prefix), alias, aliasLen) == 0 &&
		strcmp(leaf + strlen(prefix) + aliasLen, suffix) == 0;
}


static int dlShouldExpandReexport(const char* libPath, const char* reexportPath)
{
	return dlIsMatchingSystemAliasReexport(libPath, reexportPath);
}


static int dlSymsCopyNames(DLStringList* pNames, DLSyms* pSyms)
{
	uint32_t i;
	for(i = 0; i < pSyms->symbolCount; ++i) {
		const char* name = dlSymsName(pSyms, (int)i);
		if(name && !dlStringListAppendUnique(pNames, name, 0))
			return 0;
	}
	return 1;
}


static DLSyms* dlSymsInitWithVisited(const char* libPath, DLStringList* pVisited, int depth)
{
	DLLib* pLib;
	DLSyms* pSyms = NULL;
	uint32_t i, n;
	const struct MACH_HEADER_TYPE* pHeader = NULL;

	if(!libPath || depth > DL_REEXPORT_MAX_DEPTH)
		return NULL;
	if(dlStringListContains(pVisited, libPath))
		return NULL;
	if(!dlStringListAppendUnique(pVisited, libPath, 0))
		return NULL;

	pLib = dlLoadLibrary(libPath);
	if(!pLib)
		return NULL;

	/* Loop over all dynamically linked images to find ours. */
	for(i = 0, n = _dyld_image_count(); i < n; ++i)
	{
		const char* name = _dyld_get_image_name(i);

		if(name)
		{
			/* Don't rely on name comparison alone, as libPath might be relative, symlink, differently */
			/* cased, use weird osx path placeholders, etc., but compare inode number with the one of the mapped dyld image. */

			/* reload already loaded lib to get handle to compare with, should be lightweight and only increase ref count */
			DLLib* pLib_ = dlLoadLibrary(name);
			if(pLib_)
			{
				/* free / refcount-- */
				dlFreeLibrary(pLib_);

				if(pLib == pLib_)
				{
					pHeader = (const struct MACH_HEADER_TYPE*) _dyld_get_image_header(i);
/*@@@ slide = _dyld_get_image_vmaddr_slide(i);*/
					break; /* found header */
				}
			}
		}
	}

	if(pHeader && (pHeader->magic == MACH_HEADER_MAGIC_NR) && (pHeader->filetype == MH_DYLIB)/*@@@ ignore for now, seems to work without it on El Capitan && !(pHeader->flags & MH_SPLIT_SEGS)*/)
	{
		const char* pBase = (const char*)pHeader;
		const char* linkeditBase = NULL;
		uintptr_t slide = 0, symOffset = 0;
		uint32_t exportOff = 0, exportSize = 0;
		const struct symtab_command* symtab_cmd = NULL;
		DLStringList reexports;
		const struct load_command* cmd = (const struct load_command*)(pBase + sizeof(struct MACH_HEADER_TYPE));

		dlStringListInit(&reexports);

		for(i = 0, n = pHeader->ncmds; i < n; ++i, cmd = (const struct load_command*)((const char*)cmd + cmd->cmdsize))
		{
			if(cmd->cmd == SEGMEND_COMMAND_ID)
			{
				const struct SEGMENT_COMMAND* seg = (struct SEGMENT_COMMAND*)cmd;
				/*@@@ unsure why I used this instead of checking __TEXT: if((seg->fileoff == 0) && (seg->filesize != 0))*/
				if(strcmp(seg->segname, "__TEXT") == 0)
					slide = (uintptr_t)pHeader - seg->vmaddr; /* effective offset of segment from header */
			}
		}

		cmd = (const struct load_command*)(pBase + sizeof(struct MACH_HEADER_TYPE));
		for(i = 0, n = pHeader->ncmds; i < n; ++i, cmd = (const struct load_command*)((const char*)cmd + cmd->cmdsize))
		{
			if(cmd->cmd == SEGMEND_COMMAND_ID)
			{
				const struct SEGMENT_COMMAND* seg = (struct SEGMENT_COMMAND*)cmd;

				/* If we have __LINKEDIT segment (= raw data for dynamic linkers), use that one to find symbol data. */
				if(strcmp(seg->segname, "__LINKEDIT") == 0) {
					/* Recompute pBase relative to where __LINKEDIT segment is in memory. */
					linkeditBase = (const char*)(seg->vmaddr - seg->fileoff) + slide;

					/*@@@ we might want to also check maxprot and initprot here:
						VM_PROT_READ    ((vm_prot_t) 0x01)
						VM_PROT_WRITE   ((vm_prot_t) 0x02)
						VM_PROT_EXECUTE ((vm_prot_t) 0x04)*/

					symOffset = slide; /* this is also offset of symbols */
				}
			}
			else if(cmd->cmd == LC_DYLD_EXPORTS_TRIE)
			{
				const struct linkedit_data_command* ecmd = (const struct linkedit_data_command*)cmd;
				if(cmd->cmdsize == sizeof(struct linkedit_data_command)) {
					exportOff = ecmd->dataoff;
					exportSize = ecmd->datasize;
				}
			}
			else if((cmd->cmd == LC_DYLD_INFO || cmd->cmd == LC_DYLD_INFO_ONLY) && exportSize == 0)
			{
				const struct dyld_info_command* dcmd = (const struct dyld_info_command*)cmd;
				if(cmd->cmdsize == sizeof(struct dyld_info_command)) {
					exportOff = dcmd->export_off;
					exportSize = dcmd->export_size;
				}
			}
			else if(cmd->cmd == LC_REEXPORT_DYLIB)
			{
				const struct dylib_command* dcmd = (const struct dylib_command*)cmd;
				if(cmd->cmdsize >= sizeof(struct dylib_command) && dcmd->dylib.name.offset < cmd->cmdsize) {
					const char* begin = (const char*)dcmd + dcmd->dylib.name.offset;
					const char* end = (const char*)cmd + cmd->cmdsize;
					if(!dlStringListAppendUniqueBounded(&reexports, begin, end, 0)) {
						dlStringListRelease(&reexports);
						dlFreeLibrary(pLib);
						return NULL;
					}
				}
			}
			else if(cmd->cmd == LC_SYMTAB && !symtab_cmd/* only init once - just safety check */)
			{
				const struct symtab_command* scmd = (const struct symtab_command*)cmd;

				/* cmd->cmdsize must be size of struct, otherwise something is off; abort */
				if(cmd->cmdsize != sizeof(struct symtab_command))
					break;

				symtab_cmd = scmd;
			}
		}

		if(linkeditBase && exportOff && exportSize) {
			DLStringList names;
			dlStringListInit(&names);
			if(dlCollectExportTrieSymbols(&names, linkeditBase, exportOff, exportSize)) {
				for(i = 0; i < reexports.count; ++i) {
					DLSyms* pReexportSyms;
					if(!dlShouldExpandReexport(libPath, reexports.values[i]))
						continue;
					pReexportSyms = dlSymsInitWithVisited(reexports.values[i], pVisited, depth + 1);
					if(pReexportSyms) {
						int copied = dlSymsCopyNames(&names, pReexportSyms);
						dlSymsCleanup(pReexportSyms);
						if(!copied) {
							dlStringListRelease(&names);
							dlStringListRelease(&reexports);
							dlFreeLibrary(pLib);
							return NULL;
						}
					}
				}
				if(names.count > 0) {
					pSyms = dlSymsFromNameList(pLib, &names);
					dlStringListRelease(&names);
					dlStringListRelease(&reexports);
					if(pSyms)
						return pSyms;
					dlFreeLibrary(pLib);
					return NULL;
				}
			}
			dlStringListRelease(&names);
		}

		if(symtab_cmd && linkeditBase) {
			pSyms = dlSymsAlloc(pLib);
			if(pSyms) {
				pSyms->symbolCount  = symtab_cmd->nsyms;
				pSyms->pStringTable = linkeditBase + symtab_cmd->stroff;
				pSyms->pSymbolTable = (struct NLIST_TYPE*)(linkeditBase + symtab_cmd->symoff);
				pSyms->symOffset    = symOffset;
			}
		}

		dlStringListRelease(&reexports);
	}

	/* Got symbol table? */
	if(pSyms) {
		return pSyms;
	}

	/* Couldn't init syms, so free lib and return error. */
	dlFreeLibrary(pLib);
	return NULL;
}


DLSyms* dlSymsInit(const char* libPath)
{
	DLSyms* pSyms;
	DLStringList visited;

	dlStringListInit(&visited);
	pSyms = dlSymsInitWithVisited(libPath, &visited, 0);
	dlStringListRelease(&visited);
	return pSyms;
}


void dlSymsCleanup(DLSyms* pSyms)
{
	if(pSyms) {
		if(pSyms->pSymbolNames) {
			uint32_t i;
			for(i = 0; i < pSyms->symbolCount; ++i)
				dlFreeMem(pSyms->pSymbolNames[i]);
			dlFreeMem(pSyms->pSymbolNames);
		}
		dlFreeLibrary(pSyms->pLib);
		dlFreeMem(pSyms);
	}
}

int dlSymsCount(DLSyms* pSyms)
{
	return pSyms ? pSyms->symbolCount : 0;
}


const char* dlSymsName(DLSyms* pSyms, int index)
{
	const struct NLIST_TYPE* nl;
	unsigned char t;

	if(!pSyms || index < 0 || (uint32_t)index >= pSyms->symbolCount)
		return NULL;

	if(pSyms->pSymbolNames)
		return pSyms->pSymbolNames[index];

	nl = pSyms->pSymbolTable + index;
	t = nl->n_type & N_TYPE;

	/* Return name by lookup through it's address. This guarantees to be consistent with dlsym and dladdr */
	/* calls as used in dlFindAddress and dlSymsNameFromValue - the "#if 0"-ed code below returns the */
	/* name directly, but assumes wrongly that everything is prefixed with an underscore on Darwin. */

	/* only handle symbols that are in a section and aren't symbolic debug entries */
	if((t == N_SECT) && (nl->n_type & N_STAB) == 0)
		return dlSymsNameFromValue(pSyms, (void*)(nl->n_value + pSyms->symOffset));

	return NULL; /* @@@ handle N_INDR, etc.? */

#if 0
	/* Mach-O manual: Symbols with an index into the string table of zero */
	/* (n_un.n_strx == 0) are defined to have a null ("") name. */
	if(nl->n_un.n_strx == 0)
		return NULL; /*@@@ have return pointer to some static "" string? */

	/* Skip undefined symbols. @@@ should we? */
	if(t == N_UNDF || t == N_PBUD) /* @@@ check if N_PBUD is defined, it's not in the NeXT manual, but on Darwin 8.0.1 */
		return NULL;

	/*TODO skip more symbols based on nl->n_desc and nl->n_type ? */

	/* Return name - handles lookup of indirect names. */
	return &pSyms->pStringTable[(t == N_INDR ? nl->n_value : nl->n_un.n_strx)
#if defined(DC__OS_Darwin)
		+ 1 /* Skip '_'-prefix */
#endif
	];
#endif
}


const char* dlSymsNameFromValue(DLSyms* pSyms, void* value)
{
	Dl_info info;
	if (!dladdr(value, &info) || (value != info.dli_saddr))
		return NULL;

	return info.dli_sname;
}
