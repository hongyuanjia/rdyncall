TOP		 =..
include $(TOP)/config
INSTALL_PREFIX	?=../../../src
INSTALL_LUA	 =$(INSTALL_PREFIX)
INSTALL_LIB	 =$(INSTALL_PREFIX)
CPPFLAGS	 =-I$(LUA)/include -I$(DYNCALL)/include -I$(BOOST_INCDIR)
CXXFLAGS	 =-fno-exceptions -fno-rtti
DYNTYPE		 =dyntype_boost.o
# LDFLAGS		 =-L$(LUA)/lib -llua -L$(DYNCALL)/lib -ldynload_s -ldyncall_s -ldyncallback_s $(DYNTYPE)
# MAC OS X:
LDFLAGS		 =-bundle -undefined dynamic_lookup
LD		 =gcc
all: intutils.so smartptr.so ldynload.so ldyncall.so cocoautil.dylib
# ldynguess.so
# $(DYNTYPE) smartptr.so ldynguess.so ldyntype.so ldynload.so ldyncall.so ldynstruct.so # TODO: ldyncallback.so
# lsmartptr.so $(DYNTYPE) ldynguess.so ldyntype.so ldynload.so ldyncall.so ldynstruct.so # TODO: ldyncallback.so

%.so: %.o
	$(LD) $(LDFLAGS) -o $@ $^  

ldynload.so: ldynload.o
	$(LD) $(LDFLAGS) -o $@ $^ -L$(DYNCALL)/lib -ldynload_s

ldyncall.so: ldyncall.o
	$(LD) $(LDFLAGS) -o $@ $^ -L$(DYNCALL)/lib -ldyncall_s

cocoa.dylib: cocoa.o
	gcc -dynamiclib -o $@ $^ -framework AppKit

clean:
	rm -f *.so *.o

install:
	cp intutils.so smartptr.so ldynload.so ldyncall.so $(INSTALL_LIB)
	cp dynload.lua dyncall.lua dynport.lua $(INSTALL_LUA)

