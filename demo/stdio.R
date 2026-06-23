# Package: rdyncall
# File: demo/stdio.R
# Description: Read and write R raw vectors through C stdio.

library(rdyncall)

libc <- new.env(parent = globalenv())
binding <- dynbind(c("msvcrt", "c", "c.so.6"), paste(
    "fopen(ZZ)p",
    "fwrite(pJJp)J",
    "fread(pJJp)J",
    "fclose(p)i",
    sep = ";"
), envir = libc)
stopifnot(!length(binding$unresolved.symbols))

path <- tempfile("rdyncall-stdio-")
on.exit(unlink(path), add = TRUE)

missing <- libc$fopen(path, "rb")
print(is.nullptr(missing))
stopifnot(is.nullptr(missing))

write_buffer <- as.raw(0:255)
file <- libc$fopen(path, "wb")
stopifnot(!is.nullptr(file))
written <- libc$fwrite(write_buffer, 1L, length(write_buffer), file)
libc$fclose(file)
stopifnot(written == length(write_buffer))

read_buffer <- raw(length(write_buffer))
file <- libc$fopen(path, "rb")
stopifnot(!is.nullptr(file))
read <- libc$fread(read_buffer, 1L, length(read_buffer), file)
libc$fclose(file)

print(read_buffer)
stopifnot(read == length(read_buffer))
stopifnot(identical(read_buffer, write_buffer))
