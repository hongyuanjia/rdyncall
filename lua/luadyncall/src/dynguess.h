#ifndef DYNGUESS_H
#define DYNGUESS_H

/* guess architecture (ARCH) */

#if defined __i386__
#define DG_ARCH_x86 1
#define DG_ARCH "x86"
#elif defined __x86_64__
#define DG_ARCH_x64 1
#define DG_ARCH "x64"
#elif defined __ppc__
#define DG_ARCH_ppc32 1
#define DG_ARCH "ppc32"
#elif defined __ppc64__
#define DG_ARCH_ppc64 1
#define DG_ARCH "ppc64"
#elif defined __arm__
#define DG_ARCH_arm 1
#define DG_ARCH "arm"
#elif defined __mips__
#define DG_ARCH_mips 1
#define DG_ARCH "mips"
#endif

/* guess operating system (OS) */

#if defined __APPLE__
#define DG_OS_osx 1
#define DG_OS "osx"
#elif defined __linux__
#define DG_OS_linux 1
#define DG_OS "linux"
#endif

/* guess compiler (CC) */

#if defined __GNUC__
#define DG_CC_gcc 1
#define DG_CC "gcc"
#define DG_CC_VERSION __VERSION__
#endif

#endif /* DYNGUESS_H */

