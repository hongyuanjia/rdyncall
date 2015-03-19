package org.dyncall;

public class DC
{
  static 
  {
    System.loadLibrary("jdc");
  }
	
  public static final int
    DEFAULT_C 	      = 0
  , X86_WIN32_FAST    = 1
  , X86_WIN32_STD     = 2
  , X86_WIN32_THIS_MS = 3
  ;

  public static native long newCallVM(int type, int size);  
  public static native long load(String libname);
  public static native long addpath(String dirpath);
  public static native long rempath(String dirpath);
  public static native long find(long libhandle, String symbol);

  public static native void reset     (long vmhandle);
  public static native void argBool   (long vmhandle, boolean b);
  public static native void argChar   (long vmhandle, char c);
  public static native void argByte   (long vmhandle, byte b);
  public static native void argShort  (long vmhandle, short s);
  public static native void argInt    (long vmhandle, int i);
  public static native void argLong   (long vmhandle, long l);
  public static native void argFloat  (long vmhandle, float f);
  public static native void argDouble (long vmhandle, double d);
  public static native void argPointer(long vmhandle, long l);
  public static native void argPointer(long vmhandle, Object o);
  public static native void argString (long vmhandle, String s);
  
  public static native void    callVoid    (long vmhandle, long funcpointer);
  public static native boolean callBoolean (long vmhandle, long funcpointer);
  public static native char    callChar    (long vmhandle, long funcpointer);
  public static native byte    callByte    (long vmhandle, long funcpointer);
  public static native short   callShort   (long vmhandle, long funcpointer);
  public static native int     callInt     (long vmhandle, long funcpointer);
  public static native long    callLong    (long vmhandle, long funcpointer);
  public static native float   callFloat   (long vmhandle, long funcpointer);
  public static native double  callDouble  (long vmhandle, long funcpointer);
  public static native long    callPointer (long vmhandle, long funcpointer);
};

