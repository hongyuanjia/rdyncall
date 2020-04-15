from distutils.core import setup, Extension

pydcext = Extension('pydcext',
  sources   = ['pydcext.c']
, libraries = ['dyncall_s','dynload_s']
)

setup(
  name             = 'pydc'
, version          = '1.1.3'
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
, py_modules       = ['pydc']
, description      = 'dynamic call bindings for python'
, long_description = '''
dynamic call library allows to call arbitrary C library functions
with a single call code (written in assembly)
'''
)

