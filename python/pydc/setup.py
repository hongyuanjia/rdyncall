from distutils.core import setup, Extension

dctop = '../../..'

pydcext = Extension('pydcext',
  sources = ['pydcext.c']
#,include_dirs=[ "/".join([dctop,'dyncall']), "/".join([dctop,'dynload']) ]
#,library_dirs=[ "/".join([dctop,'dyncall']), "/".join([dctop,'dynload']) ]
,libraries=['dyncall_s','dynload_s']
)

setup(
  name='pydc'
, version='0.1'
, author = 'Daniel Adler'
, author_email = 'dadler@uni-goettingen.de'
, maintainer = 'Daniel Adler'
, maintainer_email = 'dadler@uni-goettingen.de'
, url = 'http://dyncall.org'
, description = 'dynamic call bindings for python'
, long_description = '''
dynamic call library allows to call arbitrary library functions
with a single call code (written in assembly)
'''
, download_url = 'http://dyncall.org/download'
, classifiers=[]
#, packages=['pydc']
#, package_dir['dir']
, ext_modules = [pydcext]
, py_modules = ['pydc']
)

