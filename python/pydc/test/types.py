import pydc
import sys
import platform




def theader(title):
  print("\n"+title)
  print('%8s %20s %16s %-20s %11s %-16s -> %16s %-16s %12s %-16s  # %s' % ('DC_SIG', 'C_RET_T', 'C_FSYM', 'C_PARAMLIST', 'PY_ARG_T', 'IN_ARGS', 'RET_VAL', 'PY_RET_T', 'OUT_ARGS', 'OUT_ARGS_T', 'NOTES'))


def t(lib, dcsig, c_rtype, c_fsym, c_paramlist, extra_msg, *args):
  # before call
  inarg_types = '('+','.join(map(lambda x: type(x).__name__, args))+')'
  inargs = ','.join(map(str, args))
  # call
  try:
    fp = pydc.find(lib, c_fsym)
    r = pydc.call(fp, dcsig, *args)
    rt = type(r).__name__
  except:
    r = '[EXCEPTION]'
    rt = '!'
    e = str(sys.exc_info()[1])
    extra_msg += ' "'+(e if len(e)<32 else e[0:32]+'...')+'"'
  # after call
  outarg_types = '('+','.join(map(lambda x: type(x).__name__, args))+')'
  outargs = ','.join(map(str, args))
  print('%8s %20s %16s %-20s %11s \033[33m%-16s\033[0m -> \033[32m%16.16s\033[0m %-16s %12s \033[32m%-16s\033[0m  # %s' % (dcsig, c_rtype, c_fsym, c_paramlist, inarg_types, inargs, str(r), '('+rt+')', outarg_types, outargs, extra_msg))



# some libc tests ------------------

try:
  if sys.platform == "win32":
    libc = pydc.load("msvcrt")
  elif sys.platform == "darwin":
    libc = pydc.load("/usr/lib/libc.dylib")
  elif "bsd" in sys.platform:
    libc = pydc.load("/usr/lib/libc.so")
    #libc = pydc.load("/lib/libc.so.7")
  elif platform.architecture()[0] == "64bit":
    libc = pydc.load("/lib64/libc.so.6")
  else:
    libc = pydc.load("/lib/libc.so.6")
  
  theader('CLIB TESTS:')
  
  # void()
  t(libc, ")v", "void", "sranddev", "(void)", '')
  
  # int()
  t(libc, ")i", "int", "rand", "(void)", '')
  
  # void(unsigned int)
  t(libc, "I)v", "void", "srand", "(int)", '', 123)
  
  # int() (and one different helper call for test)
  t(libc,  ")i",  "int",  "rand", "(void)", 'with seed <------,')
  t(libc, "I)v", "void", "srand", "(int)",  'set same seed    |', 123)
  t(libc,  ")i",  "int",  "rand", "(void)", 'should be same result...')
  t(libc,  ")i",  "int",  "rand", "(void)", '...and now different result')
  
  # int(int)
  t(libc, "i)i", "int", "abs", "(int)", '       10   =>   10',    10)
  t(libc, "i)i", "int", "abs", "(int)", '        0   =>    0',     0)
  t(libc, "i)i", "int", "abs", "(int)", '      -9209 => 9209', -9209)
  
  # long(long)
  t(libc, "j)j", "long", "labs", "(long)", '         48 =>         48',          48)
  t(libc, "j)j", "long", "labs", "(long)", '          0 =>          0',           0)
  t(libc, "j)j", "long", "labs", "(long)", '-4271477497 => 4271477497', -4271477497)
  
  # long long(long long)
  t(libc, "l)l", "long long", "labs", "(long long)", ' 6334810198 => 6334810198',  6334810198)
  t(libc, "l)l", "long long", "labs", "(long long)", '          1 =>          1',           1)
  t(libc, "l)l", "long long", "labs", "(long long)", '          0 =>          0',           0)
  t(libc, "l)l", "long long", "labs", "(long long)", '         -1 =>          1',          -1)
  t(libc, "l)l", "long long", "labs", "(long long)", '-7358758407 => 7358758407', -7358758407)
  
  pydc.free(libc)
except:
  print("skipping clib tests because: "+str(sys.exc_info()[1]))


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
t(l, "B)B", "int",                  "i_plus_one", "(int)",                '      False =>  True (using int func in C)', False)

t(l, "c)c", "char",                 "c_plus_one", "(char)",               '   "a" (97) =>    98',                         'a')
t(l, "C)C", "unsigned char",       "uc_plus_one", "(unsigned char)",      '   "a" (97) =>    98',                         'a')
t(l, "c)c", "char",                 "c_plus_one", "(char)",               '         -2 =>    -1',                          -2)
t(l, "C)C", "unsigned char",       "uc_plus_one", "(unsigned char)",      '         10 =>    11',                          10)

t(l, "s)s", "short",                "s_plus_one", "(short)",              '         10 =>    11',                          10)
t(l, "S)S", "unsigned short",      "us_plus_one", "(unsigned short)",     '         10 =>    11',                          10)

t(l, "i)i", "int",                  "i_plus_one", "(int)",                '         10 =>    11',                          10)
t(l, "I)I", "unsigned int",        "ui_plus_one", "(unsigned int)",       '         10 =>    11',                          10)

t(l, "j)j", "long",                 "l_plus_one", "(long)",               '         10 =>    11',                          10)
t(l, "J)J", "unsigned long",       "ul_plus_one", "(unsigned long)",      '         10 =>    11',                          10)

t(l, "l)l", "long long",           "ll_plus_one", "(long long)",          '         10 =>    11',                          10)
t(l, "L)L", "unsigned long long", "ull_plus_one", "(unsigned long long)", '         10 =>    11',                          10)
t(l, "l)l", "long long",           "ll_plus_one", "(long long)",          '      11234 => 11235',                      long_i)
t(l, "L)L", "unsigned long long", "ull_plus_one", "(unsigned long long)", '      11234 => 11235',                      long_i)

t(l, "f)f", "float",                "f_plus_one", "(float)",              '      -1.23 => -0.23',                       -1.23)
t(l, "d)d", "double",               "d_plus_one", "(double)",             '       5.67 =>  6.67',                        5.67)

t(l, "Z)Z", "const char*",        "ccp_plus_one", "(const char*)",        '"lose char" => "ose char"',            'lose char') # string object
t(l, "Z)Z", "const char*",        "ccp_plus_one", "(const char*)",        '"X_unicode" => "_unicode"',           u'X_unicode') # string object (unicode in Python 2)
t(l, "Z)Z", "const char*",        "ccp_plus_one", "(const char*)",        '"1lessbyte" => "lessbyte"',           b'1lessbyte') # bytes object
t(l, "Z)Z", "const char*",        "ccp_plus_one", "(const char*)",        '       "xY" =>    "Y"',           bytearray(b'xY')) # bytearray object

t(l, "p)Z", "const char*",        "ccp_plus_one", "(const char*)",        '       "xY" =>    "Y"',           bytearray(b'xY')) # bytearray object
t(l, "p)p", "const char*",        "ccp_plus_one", "(const char*)",        '       "xY" => p+1 (~ odd addr)', bytearray(b'xY')) # bytearray object
t(l, "p)p", "const char*",        "ccp_plus_one", "(const char*)",        ' 0xdeadc0de => 0xdeadc0de+1=3735929055',    long_h) # handle (integer interpreted as ptr)
t(l, "p)p", "const char*",        "ccp_plus_one", "(const char*)",        ' 0xdeadc0de => 0xdeadc0de+1=3735929055',    long_h) # handle (integer interpreted as ptr, long in Python 2)

# functions that change buffers
theader('TESTS OF IMMUTABLE AND MUTABLE PYTHON BUFFERS:')
t(l, "Z)v", "const char*",        "cp_head_incr", "(const char*)",        '   "string" => None / arg => "string"  (not modified)"',         'string') # string object
t(l, "Z)v", "const char*",        "cp_head_incr", "(const char*)",        '  "UnIcOdE" => None / arg => "UnIcOdE" (not modified)"',       u'UnIcOdE') # string object (unicode in Python 2)
t(l, "Z)v", "const char*",        "cp_head_incr", "(const char*)",        '   "BCssk#" => None / arg => "BCssk#"  (not modified)"',        b'BCssk#') # bytes object
t(l, "Z)v", "const char*",        "cp_head_incr", "(const char*)",        '       "xY" => None / arg => "xY"      (not modified)"', bytearray(b'xY')) # bytearray object
t(l, "p)v", "const char*",        "cp_head_incr", "(const char*)",        '       "xY" => None / arg => "yY"       (!MODIFIED!)"',  bytearray(b'xY')) # bytearray object

# tested checked value conversions
theader('ARG & RET TYPE CONVERSION TESTS FOR RANGE CHECKED TYPES:')
t(l, "c)c", "char",                 "c_plus_one", "(char)",               '        "~" =>    127',             '~')
t(l, "c)c", "char",                 "c_plus_one", "(char)",               '        "~" =>    127',             '~')
t(l, "c)c", "char",                 "c_plus_one", "(char)",               '         "" => input exc:',          '')
t(l, "c)c", "char",                 "c_plus_one", "(char)",               '         "" => input exc:',          '')
t(l, "C)C", "unsigned char",       "uc_plus_one", "(unsigned char)",      '       "ab" => input exc:',        'ab')
t(l, "C)C", "unsigned char",       "uc_plus_one", "(unsigned char)",      '       "ab" => input exc:',        'ab')

t(l, "c)c", "char",                 "c_plus_one", "(char)",               '       -128 =>   -127',            -128)
t(l, "c)c", "char",                 "c_plus_one", "(char)",               '        127 =>   -128 (wrapped)',   127)
t(l, "c)c", "char",                 "c_plus_one", "(char)",               '       -129 => input exc:',        -129)
t(l, "c)c", "char",                 "c_plus_one", "(char)",               '        128 => input exc:',         128)
                                                                                                                    
t(l, "C)C", "unsigned char",       "uc_plus_one", "(unsigned char)",      '          0 =>      1',               0)
t(l, "C)C", "unsigned char",       "uc_plus_one", "(unsigned char)",      '        255 =>      0 (wrapped)',   255)
t(l, "C)C", "unsigned char",       "uc_plus_one", "(unsigned char)",      '         -1 => input exc:',          -1)
t(l, "C)C", "unsigned char",       "uc_plus_one", "(unsigned char)",      '        256 => input exc:',         256)
                                                                                                                    
t(l, "s)s", "short",                "s_plus_one", "(short)",              '     -32768 => -32767',          -32768)
t(l, "s)s", "short",                "s_plus_one", "(short)",              '      32767 => -32768 (wrapped)', 32767)
t(l, "s)s", "short",                "s_plus_one", "(short)",              '     -32769 => input exc:',      -32769)
t(l, "s)s", "short",                "s_plus_one", "(short)",              '      32768 => input exc:',       32768)
                                                                                                                    
t(l, "S)S", "unsigned short",      "us_plus_one", "(unsigned short)",     '          0 =>     1',                0)
t(l, "S)S", "unsigned short",      "us_plus_one", "(unsigned short)",     '      65535 =>     0 (wrapped)',  65535)
t(l, "S)S", "unsigned short",      "us_plus_one", "(unsigned short)",     '         -1 => input exc:',          -1)
t(l, "S)S", "unsigned short",      "us_plus_one", "(unsigned short)",     '      65536 => input exc:',       65536)

t(l, "p)Z", "const char*",        "ccp_plus_one", "(const char*)",        '"w/pointer" => input exc:', 'w/pointer') # string object, not passable as 'p'ointer
t(l, "p)Z", "const char*",        "ccp_plus_one", "(const char*)",        '"X_unicode" => input exc:',u'X_unicode') # string object (unicode in Python 2), not passable as 'p'ointer
t(l, "p)Z", "const char*",        "ccp_plus_one", "(const char*)",        '"1less/ptr" => input exc:',b'1less/ptr') # bytes object, not passable as 'p'ointer
t(l, "p)p", "const char*",        "ccp_plus_one", "(const char*)",        '        "x" => input exc:',         'x') # string object, not passable as 'p'ointer

