import pydc
import sys
import platform
import copy
import types



def theader(title):
  print("\n"+title)
  print('%8s %20s %16s %-20s %11s %-16s -> %16s %-16s %12s %-16s  # %s' % ('DC_SIG', 'C_RET_T', 'C_FSYM', 'C_PARAMLIST', 'PY_ARG_T', 'IN_ARGS', 'RET_VAL', 'PY_RET_T', 'OUT_ARGS', 'OUT_ARGS_T', 'NOTES'))


def t(lib, dcsig, c_rtype, c_fsym, c_paramlist, extra_msg, **kwargs):
  args      = kwargs['i'] if 'i' in kwargs else ()
  post_args = kwargs['p'] if 'p' in kwargs else copy.deepcopy(args)  # expected args after call (as some can be modified in-place)
  exp_ret   = kwargs['r'] if 'r' in kwargs else None                 # expected return value
  err_sgr = ''
  # before call
  inarg_types = '('+','.join(map(lambda x: type(x).__name__, args))+')'
  inargs_str = ','.join(map(str, args))
  # call
  try:
    fp = pydc.find(lib, c_fsym)
    r = pydc.call(fp, dcsig, *args)
    rt = type(r).__name__
    if(r != exp_ret or args != post_args):
        if((type(exp_ret) is types.LambdaType) and exp_ret(r) == False):
            err_sgr = '\033[41m'
  except:
    r = '[EXCEPTION]'
    rt = '!'
    if(exp_ret != Exception):
        err_sgr = '\033[41m'
    e = str(sys.exc_info()[1])
    extra_msg += ' "'+(e if len(e)<32 else e[0:32]+'...')+'"'
  # after call
  outarg_types = '('+','.join(map(lambda x: type(x).__name__, args))+')'
  outargs = ','.join(map(str, args))
  print('%s%8s %20s %16s %-20s %11s \033[33m%-16s\033[39m -> \033[32m%16.16s\033[39m %-16s %12s \033[32m%-16s\033[0m  # %s' % (err_sgr, dcsig, c_rtype, c_fsym, c_paramlist, inarg_types, inargs_str, str(r), '('+rt+')', outarg_types, outargs, extra_msg))

  return r



# some libc tests ------------------

try:
  if len(sys.argv) > 1:
    libc = pydc.load(sys.argv[1])
  elif sys.platform == "win32":
    libc = pydc.load("msvcrt")
  elif sys.platform == "darwin":
    libc = pydc.load("/usr/lib/libc.dylib")
  elif "bsd" in sys.platform:
    libc = pydc.load("/usr/lib/libc.so")
    #libc = pydc.load("/lib/libc.so.7")
  elif platform.architecture()[0] == "64bit":
    libc = pydc.load("/lib64/libc.so.6")
  else:
    libc = pydc.load("/lib/libc.so")
  
  theader('CLIB TESTS:')
  
  # void()
  t(libc, ")v", "void", "sranddev", "(void)", '')
  
  # int()
  t(libc, ")i", "int", "rand", "(void)", '')
  
  # void(unsigned int)
  t(libc, "I)v", "void", "srand", "(int)", '', i=(123,))
  
  # int() (and one different helper call for test)
  x = \
  t(libc,  ")i",  "int",  "rand", "(void)", 'with seed <------,', r=lambda i: type(i) is int)
  t(libc, "I)v", "void", "srand", "(int)",  'set same seed    |', i=(123,))
  t(libc,  ")i",  "int",  "rand", "(void)", 'should be same result...', r=x)
  t(libc,  ")i",  "int",  "rand", "(void)", '...and now different result', r=lambda i: type(i) is int and i!=x)
  
  # int(int)
  t(libc, "i)i", "int", "abs", "(int)", '       10   =>   10', i=(   10,), r=10)
  t(libc, "i)i", "int", "abs", "(int)", '        0   =>    0', i=(    0,), r=0)
  t(libc, "i)i", "int", "abs", "(int)", '      -9209 => 9209', i=(-9209,), r=9209)
  
  # long(long)
  t(libc, "j)j", "long", "labs", "(long)", '         48 =>         48', i=(         48,), r=48)
  t(libc, "j)j", "long", "labs", "(long)", '          0 =>          0', i=(          0,), r=0)
  t(libc, "j)j", "long", "labs", "(long)", '-4271477497 => 4271477497', i=(-4271477497,), r=4271477497)
  
  # long long(long long)
  t(libc, "l)l", "long long", "labs", "(long long)", ' 6334810198 => 6334810198', i=( 6334810198,), r=6334810198)
  t(libc, "l)l", "long long", "labs", "(long long)", '          1 =>          1', i=(          1,), r=1)
  t(libc, "l)l", "long long", "labs", "(long long)", '          0 =>          0', i=(          0,), r=0)
  t(libc, "l)l", "long long", "labs", "(long long)", '         -1 =>          1', i=(         -1,), r=1)
  t(libc, "l)l", "long long", "labs", "(long long)", '-7358758407 => 7358758407', i=(-7358758407,), r=7358758407)
  
  pydc.free(libc)
except:
  print("\033[33mskipping clib tests because: "+str(sys.exc_info()[1])+"\033[0m\nnote: c-lib to use can be specified as command line param")


# tests with own .so for testing all conversions ------------------

l = pydc.load(sys.path[0]+"/test.so")

# "long" typed test value use for Python 2
long_i = 11234
long_h = 0xdeadc0de
if sys.version_info < (3, 0):
  long_i = long(11234)
  long_h = long(0xdeadc0de)

# test all possible arg types and their conversions to and from python, with
# specific focus/tests in areas where python 2 and 3 differ
theader('ARG & RET TYPE CONVERSION TESTS:')
t(l, "B)B", "int",                  "i_plus_one", "(int)",                '      False =>  True (using int func in C)', i=(False,), r=True)

t(l, "c)c", "char",                 "c_plus_one", "(char)",               '   "a" (97) =>    98',                      i=(   'a',), r=98)
t(l, "C)C", "unsigned char",       "uc_plus_one", "(unsigned char)",      '   "a" (97) =>    98',                      i=(   'a',), r=98)
t(l, "c)c", "char",                 "c_plus_one", "(char)",               '         -2 =>    -1',                      i=(    -2,), r=-1)
t(l, "C)C", "unsigned char",       "uc_plus_one", "(unsigned char)",      '         10 =>    11',                      i=(    10,), r=11)

t(l, "s)s", "short",                "s_plus_one", "(short)",              '         10 =>    11',                      i=(    10,), r=11)
t(l, "S)S", "unsigned short",      "us_plus_one", "(unsigned short)",     '         10 =>    11',                      i=(    10,), r=11)

t(l, "i)i", "int",                  "i_plus_one", "(int)",                '         10 =>    11',                      i=(    10,), r=11)
t(l, "I)I", "unsigned int",        "ui_plus_one", "(unsigned int)",       '         10 =>    11',                      i=(    10,), r=11)

t(l, "j)j", "long",                 "l_plus_one", "(long)",               '         10 =>    11',                      i=(    10,), r=11)
t(l, "J)J", "unsigned long",       "ul_plus_one", "(unsigned long)",      '         10 =>    11',                      i=(    10,), r=11)

t(l, "l)l", "long long",           "ll_plus_one", "(long long)",          '         10 =>    11',                      i=(    10,), r=11)
t(l, "L)L", "unsigned long long", "ull_plus_one", "(unsigned long long)", '         10 =>    11',                      i=(    10,), r=11)
t(l, "l)l", "long long",           "ll_plus_one", "(long long)",          '      11234 => 11235',                      i=(long_i,), r=11235)
t(l, "L)L", "unsigned long long", "ull_plus_one", "(unsigned long long)", '      11234 => 11235',                      i=(long_i,), r=11235)

t(l, "f)f", "float",                "f_plus_one", "(float)",              '      -1.23 => -0.23... (w/ fp imprecision)', i=( -1.23,), r=-0.23000001907348633)
t(l, "d)d", "double",               "d_plus_one", "(double)",             '       5.67 =>  6.67',                        i=(  5.67,), r= 6.67)

t(l, "Z)Z", "const char*",        "ccp_plus_one", "(const char*)",        '"lose char" => "ose char"',       i=(     'lose char',), r= 'ose char') # string object
t(l, "Z)Z", "const char*",        "ccp_plus_one", "(const char*)",        '"X_unicode" => "_unicode"',       i=(    u'X_unicode',), r=u'_unicode') # string object (unicode in Python 2)
t(l, "Z)Z", "const char*",        "ccp_plus_one", "(const char*)",        '"1lessbyte" => "lessbyte"',       i=(    b'1lessbyte',), r= 'lessbyte') # bytes object
t(l, "Z)Z", "const char*",        "ccp_plus_one", "(const char*)",        '       "xY" =>    "Y"',           i=(bytearray(b'xY'),), r=        'Y') # bytearray object

t(l, "p)Z", "const char*",        "ccp_plus_one", "(const char*)",        '       "xY" =>    "Y"',           i=(bytearray(b'xY'),), r='Y') # bytearray object
t(l, "p)p", "const char*",        "ccp_plus_one", "(const char*)",        '       "xY" => p+1 (~ odd addr)', i=(bytearray(b'xY'),), r='??') # bytearray object
t(l, "p)p", "const char*",        "ccp_plus_one", "(const char*)",        ' 0xdeadc0de => 0xdeadc0de+1=3735929055',    i=(long_h,), r=3735929055) # handle (integer interpreted as ptr)
t(l, "p)p", "const char*",        "ccp_plus_one", "(const char*)",        ' 0xdeadc0de => 0xdeadc0de+1=3735929055',    i=(long_h,), r=3735929055) # handle (integer interpreted as ptr, long in Python 2)
t(l, "p)p", "const char*",        "ccp_plus_one", "(const char*)",        '       NULL => NULL+1=1',                   i=(  None,), r=1) # NULL, adding one will result in 0x1

# functions that change buffers
theader('TESTS OF IMMUTABLE AND MUTABLE PYTHON BUFFERS:')
t(l, "Z)v", "const char*",        "cp_head_incr", "(const char*)",        '   "string" => None / arg => "string"  (not modified)"', i=(        'string',)) # string object
t(l, "Z)v", "const char*",        "cp_head_incr", "(const char*)",        '  "UnIcOdE" => None / arg => "UnIcOdE" (not modified)"', i=(      u'UnIcOdE',)) # string object (unicode in Python 2)
t(l, "Z)v", "const char*",        "cp_head_incr", "(const char*)",        '   "BCssk#" => None / arg => "BCssk#"  (not modified)"', i=(       b'BCssk#',)) # bytes object
t(l, "Z)v", "const char*",        "cp_head_incr", "(const char*)",        '       "xY" => None / arg => "xY"      (not modified)"', i=(bytearray(b'xY'),)) # bytearray object
t(l, "p)v", "const char*",        "cp_head_incr", "(const char*)",        '       "xY" => None / arg => "yY"       (!MODIFIED!)"',  i=(bytearray(b'xY'),), p=(bytearray(b'yY'),)) # bytearray object

# tested checked value conversions
theader('ARG & RET TYPE CONVERSION TESTS FOR RANGE CHECKED TYPES:')
t(l, "c)c", "char",                 "c_plus_one", "(char)",               '        "~" =>    127',            i=( '~',), r=127)
t(l, "c)c", "char",                 "c_plus_one", "(char)",               '        "~" =>    127',            i=( '~',), r=127)
t(l, "c)c", "char",                 "c_plus_one", "(char)",               '         "" => input exc:',        i=(  '',), r=Exception)
t(l, "c)c", "char",                 "c_plus_one", "(char)",               '         "" => input exc:',        i=(  '',), r=Exception)
t(l, "C)C", "unsigned char",       "uc_plus_one", "(unsigned char)",      '       "ab" => input exc:',        i=('ab',), r=Exception)
t(l, "C)C", "unsigned char",       "uc_plus_one", "(unsigned char)",      '       "ab" => input exc:',        i=('ab',), r=Exception)
                                                                                                                    
t(l, "c)c", "char",                 "c_plus_one", "(char)",               '       -128 =>   -127',            i=(-128,), r=-127)
t(l, "c)c", "char",                 "c_plus_one", "(char)",               '        127 =>   -128 (wrapped)',  i=( 127,), r=-128)
t(l, "c)c", "char",                 "c_plus_one", "(char)",               '       -129 => input exc:',        i=(-129,), r=Exception)
t(l, "c)c", "char",                 "c_plus_one", "(char)",               '        128 => input exc:',        i=( 128,), r=Exception)
                                                                                                                     
t(l, "C)C", "unsigned char",       "uc_plus_one", "(unsigned char)",      '          0 =>      1',            i=(   0,), r=1)
t(l, "C)C", "unsigned char",       "uc_plus_one", "(unsigned char)",      '        255 =>      0 (wrapped)',  i=( 255,), r=0)
t(l, "C)C", "unsigned char",       "uc_plus_one", "(unsigned char)",      '         -1 => input exc:',        i=(  -1,), r=Exception)
t(l, "C)C", "unsigned char",       "uc_plus_one", "(unsigned char)",      '        256 => input exc:',        i=( 256,), r=Exception)
                                                                                                                     
t(l, "s)s", "short",                "s_plus_one", "(short)",              '     -32768 => -32767',          i=(-32768,), r=-32767)
t(l, "s)s", "short",                "s_plus_one", "(short)",              '      32767 => -32768 (wrapped)',i=( 32767,), r=-32768)
t(l, "s)s", "short",                "s_plus_one", "(short)",              '     -32769 => input exc:',      i=(-32769,), r=Exception)
t(l, "s)s", "short",                "s_plus_one", "(short)",              '      32768 => input exc:',      i=( 32768,), r=Exception)
                                                                                                                     
t(l, "S)S", "unsigned short",      "us_plus_one", "(unsigned short)",     '          0 =>     1',            i=(    0,), r=1)
t(l, "S)S", "unsigned short",      "us_plus_one", "(unsigned short)",     '      65535 =>     0 (wrapped)',  i=(65535,), r=0)
t(l, "S)S", "unsigned short",      "us_plus_one", "(unsigned short)",     '         -1 => input exc:',       i=(   -1,), r=Exception)
t(l, "S)S", "unsigned short",      "us_plus_one", "(unsigned short)",     '      65536 => input exc:',       i=(65536,), r=Exception)
                                                                                                                    
t(l, "p)Z", "const char*",        "ccp_plus_one", "(const char*)",        '"w/pointer" => input exc:',i=( 'w/pointer',), r=Exception) # string object, not passable as 'p'ointer
t(l, "p)Z", "const char*",        "ccp_plus_one", "(const char*)",        '"X_unicode" => input exc:',i=(u'X_unicode',), r=Exception) # string object (unicode in Python 2), not passable as 'p'ointer
t(l, "p)Z", "const char*",        "ccp_plus_one", "(const char*)",        '"1less/ptr" => input exc:',i=(b'1less/ptr',), r=Exception) # bytes object, not passable as 'p'ointer
t(l, "p)p", "const char*",        "ccp_plus_one", "(const char*)",        '        "x" => input exc:',i=(         'x',), r=Exception) # string object, not passable as 'p'ointer

