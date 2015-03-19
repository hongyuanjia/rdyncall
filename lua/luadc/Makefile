DC_TOP		= ../../../dyncall
CC		= gcc
LUA_INCDIR	= ../lua-5.1.3/src
LUA_LIBDIR	= ../lua-5.1.3/src
CFLAGS	= -I$(LUA_INCDIR) -I$(DC_TOP)/include
LIBS = -L$(LUA_LIBDIR) $(LUA_LIBDIR)/lua51.dll -L$(DC_TOP)/lib -ldynload_s -ldyncall_s

all: luadc.dll

luadc.dll: luadc.o
	gcc --shared $^ $(LIBS) $(OUTPUT_OPTION)

