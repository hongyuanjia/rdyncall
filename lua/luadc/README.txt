lua bindings for dyncall
========================

1. loading the lua C extension

   require "package"
   f = package.loadlib("luadc","luadc_open")
   f()

2. using the C extension

   libhandle = dc.load("libname")
   f = dc.find(libhandle,"symbol")  

3. change calling convention mode

   dc.mode(mode)

   mode is dc.C_DEFAULT, dc.C_X86_WIN32_STD, dc.C_X86_WIN32_FAST, ...

4. make a call

   dc.call(f, signature, args... )

