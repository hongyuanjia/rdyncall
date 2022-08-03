from distutils.core import setup, Extension

pydcext = Extension('pydc',
  sources   = ['pydc.c']
, libraries = ['dyncall_s','dyncallback_s','dynload_s']
)

setup(
  name             = 'pydc'
, version          = '1.2.6'
, author           = 'Daniel Adler, Tassilo Philipp'
, author_email     = 'dadler@dyncall.org, tphilip@dyncall.org'
, maintainer       = 'Daniel Adler, Tassilo Philipp'
, maintainer_email = 'dadler@dyncall.org, tphilip@dyncall.org'
, url              = 'https://www.dyncall.org'
, download_url     = 'https://www.dyncall.org/download'
, classifiers      = []
#, packages         = ['pydc']
#, package_dir      = ['dir']
, ext_modules      = [pydcext]
, description      = 'dynamic call bindings for python'
, long_description = '''
library allowing to call arbitrary C library functions dynamically,
based on a single call kernel (so no interface generation used/required);
also has callback support and helper functions to load shared objects and
lookup symbols by name (including from running process itself)
'''
, package_data     = {'': ['pydc.pyi']}
, packages         = ['']
)

