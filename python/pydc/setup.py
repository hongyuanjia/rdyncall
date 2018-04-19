from distutils.core import setup, Extension

pydcext = Extension('pydcext',
  sources = ['pydcext.c']
,libraries=['dyncall_s','dynload_s']
)

setup(
  name             = 'pydc'
, version          = '1.0'
, author           = 'Daniel Adler'
, author_email     = 'dadler@dyncall.org'
, maintainer       = 'Daniel Adler'
, maintainer_email = 'dadler@dyncall.org'
, url              = 'http://www.dyncall.org'
, description      = 'dynamic call bindings for python'
, long_description = '''
dynamic call library allows to call arbitrary C library functions
with a single call code (written in assembly)
'''
, download_url = 'http://www.dyncall.org/download'
, classifiers=[]
#, packages=['pydc']
#, package_dir['dir']
, ext_modules = [pydcext]
, py_modules = ['pydc']
)

