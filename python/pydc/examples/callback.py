# callback of python function to qsort(3) some numbers - this is just a example
# using an existing libc function that uses a callback; it's not practical for
# real world use as it comes with a huge overhead:
# - sorting requires many calls of the comparison function
# - each such callback back into python comes with a lot of overhead
# - on top of that, for this example, 2 memcpy(3)s are needed to access the
#   data to compare, further adding to the overhead

from pydc import *
import sys
import platform
import random
import struct

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



fp_qsort  = find(libc,"qsort")  # void qsort(void *base, size_t nmemb, size_t size, int (*compar)(const void *, const void *));
fp_memcpy = find(libc,"memcpy") # void * memcpy(void *dst, const void *src, size_t len);



n = 8
nums = bytearray(struct.pack("i"*n, *[random.randrange (-10, 50) for i in range (n)]))
es = int(len(nums)/n)  # element size


def compar(a, b):
    ba = bytearray(es)
    call(fp_memcpy,"ppi)p", ba, a, es)
    a = struct.unpack("i", ba)[0]
    call(fp_memcpy,"ppi)p", ba, b, es)
    b = struct.unpack("i", ba)[0]
    return a - b

cb = new_callback("pp)i", compar)

# --------

print('%d '*n % struct.unpack("i"*n, nums))

print('... qsort ...')
call(fp_qsort,"piip)v", nums, n, es, cb)

print('%d '*n % struct.unpack("i"*n, nums))


free_callback(cb)

