# TODO:
#  - how to handle C files? such as intutils.cpp and ldynguess.c
TOP=..
SRCS="typesignature.lua array.lua dynload.lua dyncall.lua dynport.lua path.lua"
luadoc -d "${TOP}/doc" ${SRCS}
