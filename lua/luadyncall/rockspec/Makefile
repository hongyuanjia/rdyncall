NAME		 =luadyncall
VERSION		 =0.1
TOP		 =..
TMPDIR		 =/tmp
DIR		 =$(NAME)-$(VERSION)

.PHONY: all srcpkg srcdir clean 

all: srcpkg

srcpkg: srcdir
	tar -C $(TMPDIR) -czvpf $(TMPDIR)/$(DIR).tar.gz $(DIR)

srcdir:
	mkdir -p $(TMPDIR)/$(DIR)
	cp -R $(TOP) $(TMPDIR)/$(DIR)

clean: 
	rm -Rf $(TMPDIR)/$(DIR) $(TMPDIR)/$(DIR).tar.gz

