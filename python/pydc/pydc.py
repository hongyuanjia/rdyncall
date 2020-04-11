import pydcext

def load(libpath):
  return pydcext.load(libpath)

def find(libhandle,symbol):
  return pydcext.find(libhandle,symbol)

def free(libhandle):
  pydcext.free(libhandle)

def get_path(libhandle):
  return pydcext.get_path(libhandle)

def call(funcptr,signature,*arguments):
  return pydcext.call(funcptr,signature,arguments)

