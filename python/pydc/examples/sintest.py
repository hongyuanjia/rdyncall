import math
import os
import pydc

def f1(n):
  for x in xrange(n):
    math.sin(x)
#  filter( math.sin, range(0,n) )


libc = pydc.load("msvcrt")
fpsin = pydc.find(libc,"sin")

def libcsin(x): pass

def f2(n):
  for x in xrange(n):
    pydc.call(fpsin,"d)d",float(x))
#    libcsin(i)

#  filter( libcsin , range(0,n) )


#b = os.times()
f1(10000000)
#f2(10000000)
e = os.times()

print e




