from pydc import *
import sys
import platform

if sys.platform == "win32":
  libc = load("msvcrt")
elif sys.platform == "darwin":
  libc = load("/usr/lib/libc.dylib")
elif "bsd" in sys.platform:
  #libc = load("/usr/lib/libc.so")
  libc = load("/lib/libc.so.7")
elif platform.architecture()[0] == "64bit":
  libc = load("/lib64/libc.so.6")
else:
  libc = load("/lib/libc.so.6")

fp_atoi = find(libc,"atoi")
fp_atof = find(libc,"atof")
fp_printf = find(libc,"printf")



def atoi(s): return call(fp_atoi,"Z)i",s)
def atod(s): return call(fp_atof,"Z)d",s)

print(atoi("3".join(["12","45"])))
print(atod("3".join(["12","45"])))

# w/ some text - tests vararg callconv switch
call(fp_printf,"_eZ_.id)i", "and again: %d %f\n", atoi("31245"), atod("31245"))

