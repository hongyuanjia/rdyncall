DC_TOP		= ../../../dyncall
CC		= gcc
LUA_INCDIR	= ../lua-5.1.3/src
LUA_LIBDIR	= ../lua-5.1.3/src
CFLAGS	= -I$(LUA_INCDIR) -I$(DC_TOP)/include
LIBS = -L$(LUA_LIBDIR) -llua -L$(DC_TOP)/lib -ldynload_s -ldyncall_s

all: test luadc

test: main.o
	$(LINK.c) $^ $(LIBS) $(OUTPUT_OPTION)

LINK.DLL	= gcc --shared

luadc.dll: luadc.o
	$(LINK.DLL) $^ $(LIBS) $(OUTPUT_OPTION)

