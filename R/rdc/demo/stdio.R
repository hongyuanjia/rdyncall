if (.Platform$OS.type == "windows") { 
  .libC <- "/windows/system32/msvcrt"
} else if ( Sys.info()[["sysname"]] == "Darwin" ) { 
  .libC <- "/usr/lib/libc.dylib"
} else {
  .libC <- "/lib/libc.so.6"
}

.libC <- rdcLoad(.libC)
.fopen <- rdcFind(.libC, "fopen")
.fwrite <- rdcFind(.libC, "fwrite")
.fread <- rdcFind(.libC, "fread")
.fclose <- rdcFind(.libC, "fclose")
.fprintf <- rdcFind(.libC, "fprintf")

fopen <- function(name, mode) 
  rdcCall(.fopen, "SS)p",name,mode)
fread <- function(buf, size, count, fp) 
  rdcCall(.fread,"piip)i", buf, size, count, fp)
fwrite <- function(buf, size, count, fp) 
  rdcCall(.fwrite, "piip)i", buf, size, count, fp)
fclose <- function(fp) 
  rdcCall(.fclose, "p)i", fp)



do.write <- function(filename, x)
{
  fh <- fopen(filename, "wb")
  error <- FALSE
  offset <- 0L
  size <- rdcSizeOf("double")
  count <- length(x)
  while( count > 0 && !error )
  {
    nwritten <- fwrite( rdcDataPtr(x,offset), size, count, fh )
    if (nwritten < 0)
    {
      error <- TRUE
    }
    else
    {
      count <- count - nwritten
      offset <- offset + nwritten * size
    }
  }
  fclose(fh)
  if (error)
    stop("fwrite error")
}

do.read <- function(filename, x)
{
  fh <- fopen(filename, "rb")
  error <- FALSE
  offset <- 0L
  size <- rdcSizeOf("double")
  count <- length(x)
  while (size > 0 && !error )
  {
    nread <- fread( rdcDataPtr(x,offset), size, count, fh )
    if (nread < 0)
    {
      error <- TRUE
    }
    else
    {
      size <- size - nread
      offset <- offset + nread * size
    }
  }
  fclose(fh)
  if (error)
    stop("fread error")
}

filename <- tempfile()
x <- rnorm(1000)
do.write(filename, x)
y <- numeric(1000)
do.read(filename,y)
identical(x,y)

