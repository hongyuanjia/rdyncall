# Package: rdyncall 
# File: demo/stdio.R
# Description: Direct I/O of R raw vectors using C stdio functions

dynport(stdio)

# test: fopen returns NULL pointer on error

nonexisting <- "dummyname"
f <- fopen(nonexisting, "r")
is.nullptr(f)

# test: R raw object read/write

tempfile <- "bla"
f <- fopen(tempfile, "wb")
writebuf <- as.raw(0:255)
copy <- writebuf
copy[[1]] <- as.raw(0xFF)
fwrite(writebuf, 1, length(writebuf), f)
fclose(f)

f <- fopen(tempfile, "rb")
readbuf <- raw(256)
copybuf <- readbuf
fread(readbuf, 1, length(readbuf), f)
copybuf[[1]] <- as.raw(0xFF)
fclose(f)

identical(readbuf,writebuf)

