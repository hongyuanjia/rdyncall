from pydc import *
from sys  import platform

if platform == "win32":
  libc = load("msvcrt")
elif platform == "darwin":
  libc = load("/usr/lib/libc.dylib")
else:
  libc = load("/lib/libc.so.6")

fp_atoi = find(libc,"atoi")
fp_atof = find(libc,"atof")

def atoi(s): return call(fp_atoi,"p)i",s)
def atod(s): return call(fp_atof,"p)d",s)

print atoi( "3".join(["12","45"]) )
print atod( "3".join(["12","45"]) )

