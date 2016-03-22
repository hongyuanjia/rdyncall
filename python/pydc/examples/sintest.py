import math
import os
import pydc
import sys
import platform

if sys.platform == "win32":
  libm = pydc.load("msvcrt")
elif sys.platform == "darwin":
  libm = pydc.load("/usr/lib/libm.dylib")
elif "bsd" in sys.platform:
  libm = pydc.load("/usr/lib/libm.so")
elif platform.architecture()[0] == "64bit":
  libm = pydc.load("/lib64/libm.so.6")
else:
  libm = pydc.load("/lib/libm.so.6")

fpsin = pydc.find(libm,"sin")



def f1(n):
  for x in xrange(n):
    math.sin(x)
#  filter( math.sin, range(0,n) )

def libmsin(x): pass

def f2(n):
  for x in xrange(n):
    pydc.call(fpsin,"d)d",float(x))
#    libmsin(i)

#  filter( libmsin , range(0,n) )


print "start_native"+str(os.times())
f1(10000000)
print "start_dc"+str(os.times())
f2(10000000)
print "end"+str(os.times())

