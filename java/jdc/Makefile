# should be .jnilib on os x, .dll on windows, etc. @@@
SO=libjdc.so

build: $(SO)

clean:
	rm org_dyncall_DC.h || true
	rm org/dyncall/DC.class || true
	rm $(SO) || true

$(SO): org_dyncall_DC.h org_dyncall_DC.c
	# @@@ support different compilers @@@ esp. on windows
	$(CC) -shared -fPIC -o $@ org_dyncall_DC.c -ldyncall_s -ldynload_s

org_dyncall_DC.h: org/dyncall/DC.class
	javah -jni org.dyncall.DC

org/dyncall/DC.class:
	cd org/dyncall/ && javac DC.java

.PHONY: build clean
