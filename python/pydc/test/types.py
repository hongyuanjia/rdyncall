import pydc
import sys
import platform




def theader(title):
  print(title)
  print('%8s %20s %16s %-20s %12s %-12s -> %16s %-16s    # %s' % ('DC_SIG', 'C_RET_T', 'C_FSYM', 'C_PARAMLIST', 'PYTHON_ARG_T', 'IN_ARGS', 'RET_VAL', 'PYTHON_RET_T', 'NOTES'))


def t(lib, dcsig, c_rtype, c_fsym, c_paramlist, extra_msg, *args):
  try:
    fp = pydc.find(lib, c_fsym)
    r = pydc.call(fp, dcsig, *args)
    rt = type(r).__name__
  except:
    r = '[EXCEPTION]'
    rt = '!'
    extra_msg += ' "'+str(sys.exc_info()[1])+'"'

  inarg_types = '('+','.join(map(lambda x: type(x).__name__, args))+')'
  inargs = ','.join(map(str, args))
  print('%8s %20s %16s %-20s %12s %-12s -> %16.16s %-16s    # %s' % (dcsig, c_rtype, c_fsym, c_paramlist, inarg_types, inargs, str(r), '('+rt+')', extra_msg))



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
t(l, "f)f", "float",                "f_plus_one", "(float)",              '      -1.23 => -0.23',                       -1.23)
t(l, "d)d", "double",               "d_plus_one", "(double)",             '       5.67 =>  6.67',                        5.67)
t(l, "Z)Z", "const char*",         "cc_plus_one", "(const char*)",        '"lose char" => "ose char"',            'lose char')
t(l, "p)Z", "const char*",         "cc_plus_one", "(const char*)",        '"w/pointer" => "/pointer"',            'w/pointer')
t(l, "p)p", "const char*",         "cc_plus_one", "(const char*)",        '        "x" => p+1 (retval is prob odd addr)', 'x')
t(l, "p)p", "const char*",         "cc_plus_one", "(const char*)",        ' 0xdeadc0de => 0xdeadc0de+1=3735929055',0xdeadc0de)

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


#     int
#     rand(void);
#rand()
#define DC_SIGCHAR_VOID         'v' ra
#define DC_SIGCHAR_BOOL         'B'
#define DC_SIGCHAR_CHAR         'c'    2 versions
#define DC_SIGCHAR_UCHAR        'C'
#define DC_SIGCHAR_SHORT        's'
#define DC_SIGCHAR_USHORT       'S'
#define DC_SIGCHAR_INT          'i' r
#define DC_SIGCHAR_UINT         'I'  a
#define DC_SIGCHAR_LONG         'j' ra
#define DC_SIGCHAR_ULONG        'J'
#define DC_SIGCHAR_LONGLONG     'l' ra
#define DC_SIGCHAR_ULONGLONG    'L'
#define DC_SIGCHAR_FLOAT        'f'
#define DC_SIGCHAR_DOUBLE       'd'
#define DC_SIGCHAR_POINTER      'p'
#define DC_SIGCHAR_STRING       'Z'
#define DC_SIGCHAR_STRUCT       'T'
#define DC_SIGCHAR_ENDARG       ')' /* also works for end struct */



#  SIG | FROM PYTHON 2                      | FROM PYTHON 3 @@@                  | C/C++                           | TO PYTHON 2                        | TO PYTHON 3 @@@
#  ----+------------------------------------+------------------------------------+---------------------------------+------------------------------------+-----------------------------------
#  'v' |                                    |                                    | void                            | ?NoneType (returned for "xxx)v")    | NoneType (returned for "xxx)v")
#  'B' | ?PyBool                             | ?PyBool                             | bool                            | ?PyBool                             | ?PyBool
#  'c' | ?PyInt (range checked)              | ?PyLong (range checked)             | char                            | ?PyInt                              | ?PyLong
#  'C' | ?PyInt (range checked)              | ?PyLong (range checked)             | unsigned char                   | ?PyInt                              | ?PyLong
#  's' | ?PyInt (range checked)              | ?PyLong (range checked)             | short                           | ?PyInt                              | ?PyLong
#  'S' | ?PyInt (range checked)              | ?PyLong (range checked)             | unsigned short                  | ?PyInt                              | ?PyLong
#  'i' | ?PyInt                              | ?PyLong                             | int                             | ?PyInt                              | ?PyLong
#  'I' | ?PyInt                              | ?PyLong                             | unsigned int                    | ?PyInt                              | ?PyLong
#  'j' | ?PyLong                             | ?PyLong                             | long                            | ?PyLong                             | ?PyLong
#  'J' | ?PyLong                             | ?PyLong                             | unsigned long                   | ?PyLong                             | ?PyLong
#  'l' | ?PyLongLong                         | ?PyLongLong                         | long long                       | ?PyLongLong                         | ?PyLongLong
#  'L' | ?PyLongLong                         | ?PyLongLong                         | unsigned long long              | ?PyLongLong                         | ?PyLongLong
#  'f' | ?PyFloat (cast to single precision) | ?PyFloat (cast to single precision) | float                           | ?PyFloat (cast to double precision) | ?PyFloat (cast to double precision)
#  'd' | ?PyFloat                            | ?PyFloat                            | double                          | ?PyFloat                            | ?PyFloat
#  'p' | ?PyUnicode/PyString/PyLong          | ?PyUnicode/PyBytes/PyLong           | void*                           | ?Py_ssize_t                         | ?Py_ssize_t
#  'Z' | ?PyUnicode/PyString                 | ?PyUnicode/PyBytes                  | const char* (UTF-8 for unicode) | ?PyString                           | ?PyUnicode

