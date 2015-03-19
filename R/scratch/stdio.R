# Dynport: stdio
# Description: Standard I/O C library
# Dynport-Maintainer: dadler@uni-goettingen.de
# -----------------------------------------------------------------------------

.sysname <- Sys.info()[["sysname"]]
if (.sysname == "Windows") {
  .libNameC <- "msvcrt"
} else {
  .libNameC <- "c"
}

dynbind(.libNameC,"
fopen(ZZ)p;
fread(piip)i;
fwrite(piip)i;
fseek(pli)i;
fclose(p)i;
memcpy(ppi)p;
memset(pii)p;
")

SEEK_SET = 0
SEEK_CUR = 1
SEEK_END = 2
