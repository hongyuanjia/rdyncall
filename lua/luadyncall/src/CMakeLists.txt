# use lua
include_directories(${LUA_INCLUDE_DIR})

# Lua Module Names:
set(CMAKE_SHARED_MODULE_PREFIX "")

# DynLoad and DynCall:
include_directories( ${DynCall_SOURCE_DIR}/dyncall ${DynCall_SOURCE_DIR}/dynload ${DynCall_SOURCE_DIR}/dyncallback )

# Fix arch x86_64: force PIC always (even in static libraries)

if("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "x86_64")
add_definitions("-fPIC")
endif()

add_library(smartptr MODULE smartptr.c)
add_library(intutils MODULE intutils.cpp)
add_library(ldynload MODULE ldynload.c)
add_library(ldyncall MODULE ldyncall.c)
add_library(ldynguess MODULE ldynguess.c)
add_library(ldynstruct MODULE ldynstruct.c)
add_library(ldyntype MODULE ldyntype.c)
add_library(larray MODULE larray.c dyntype.c)

target_link_libraries(ldynload dynload_s) 
target_link_libraries(ldyncall dyncall_s) 

install(TARGETS 
  ldynload smartptr
  ldyncall 
  larray 
  intutils 
  ldynguess 
  # ldynstruct ldyntype
  LIBRARY DESTINATION lib/lua
)

install(FILES 
  dynload.lua 
  dyncall.lua 
  dynport.lua path.lua
  array.lua
  # dynstruct.lua
  # dyntype.lua 
  DESTINATION lib/lua
)

if(APPLE)
  set(CMAKE_MODULE_LINKER_FLAGS "-bundle -undefined dynamic_lookup")
  # build cocoautil library on mac os x
  add_library(cocoautil MODULE cocoautil.m)
endif()

