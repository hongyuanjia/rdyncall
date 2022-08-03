.PHONY: test.so

test.so:
	(for i in char 'unsigned char' short 'unsigned short' int 'unsigned int' long 'unsigned long' 'long long' 'unsigned long long' float double 'const char*'; do \
		echo "$$i `echo $$i | sed -E 's/\*/ p/;s/(^| )([a-z])[^ ]*/\2/g'`_plus_one($$i v) { return v+1; }"; \
	done; \
	echo 'void cp_head_incr(char* v) { v[0]+=1; }') | ${CC} -`[ \`uname\` = Darwin ] && echo dynamiclib || echo shared` -x c - -o $@
	@echo Done! Now you can run types_test.py

