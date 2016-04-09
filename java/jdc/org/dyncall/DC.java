package org.dyncall;

public class DC
{
  static
  {
    System.loadLibrary("jdc");
  }
	
  public static final int
	// calling conventions
	  C_DEFAULT            =   0
	, C_ELLIPSIS           = 100
	, C_ELLIPSIS_VARARGS   = 101
	, C_X86_CDECL          =   1
	, C_X86_WIN32_STD      =   2
	, C_X86_WIN32_FAST_MS  =   3
	, C_X86_WIN32_FAST_GNU =   4
	, C_X86_WIN32_THIS_MS  =   5
	, C_X86_WIN32_THIS_GNU =   6
	, C_X64_WIN64          =   7
	, C_X64_SYSV           =   8
	, C_PPC32_DARWIN       =   9
	, C_PPC32_OSX          =   9 //C_PPC32_DARWIN /* alias */
	, C_ARM_ARM_EABI       =  10
	, C_ARM_THUMB_EABI     =  11
	, C_ARM_ARMHF          =  30
	, C_MIPS32_EABI        =  12
	, C_MIPS32_PSPSDK      =  12 //C_MIPS32_EABI /* alias - deprecated. */
	, C_PPC32_SYSV         =  13
	, C_PPC32_LINUX        =  13 //C_PPC32_SYSV /* alias */
	, C_ARM_ARM            =  14
	, C_ARM_THUMB          =  15
	, C_MIPS32_O32         =  16
	, C_MIPS64_N32         =  17
	, C_MIPS64_N64         =  18
	, C_X86_PLAN9          =  19
	, C_SPARC32            =  20
	, C_SPARC64            =  21
	, C_ARM64              =  22
	, C_PPC64              =  23
	, C_PPC64_LINUX        =  23 //C_PPC64 /* alias */
	, SYS_DEFAULT          = 200
	, SYS_X86_INT80H_LINUX = 201
	, SYS_X86_INT80H_BSD   = 202
	, SYS_PPC32            = 210
	, SYS_PPC64            = 211
	// error codes
	, ERROR_NONE             =  0
	, ERROR_UNSUPPORTED_MODE = -1
  ;

  public static native long newCallVM(int size);
  public static native void freeCallVM(long vmhandle);

  public static native long loadLibrary(String libname);
  public static native void freeLibrary(long libhandle);
  public static native long find(long libhandle, String symbol);
  //public static native int    symsCount(long libhandle);
  //public static native String symsName (long libhandle, int index);

  public static native void reset(long vmhandle);
  public static native void mode(long vmhandle, int mode);

  // Note that the function names mimic the C api, as C functions are called,
  // meaning argChar takes a java byte (not char, as latter is 16 bit), argLongLong
  // takes a java long (which is 64bit), etc..
  public static native void argBool    (long vmhandle, boolean b);
  public static native void argChar    (long vmhandle, byte b);
  public static native void argShort   (long vmhandle, short s);
  public static native void argInt     (long vmhandle, int i);
  public static native void argLong    (long vmhandle, long l);
  public static native void argLongLong(long vmhandle, long l);
  public static native void argFloat   (long vmhandle, float f);
  public static native void argDouble  (long vmhandle, double d);
  public static native void argPointer (long vmhandle, long l);
  public static native void argPointer (long vmhandle, Object o);
  public static native void argString  (long vmhandle, String s);

  public static native void    callVoid    (long vmhandle, long funcpointer);
  public static native boolean callBool    (long vmhandle, long funcpointer);
  public static native byte    callChar    (long vmhandle, long funcpointer);
  public static native short   callShort   (long vmhandle, long funcpointer);
  public static native int     callInt     (long vmhandle, long funcpointer);
  public static native long    callLong    (long vmhandle, long funcpointer);
  public static native long    callLongLong(long vmhandle, long funcpointer);
  public static native float   callFloat   (long vmhandle, long funcpointer);
  public static native double  callDouble  (long vmhandle, long funcpointer);
  public static native long    callPointer (long vmhandle, long funcpointer);
  public static native String  callString  (long vmhandle, long funcpointer);

  public static native int getError(long vmhandle);
};

