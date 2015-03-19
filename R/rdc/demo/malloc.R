# File: rdc/demo/malloc.R
# Description: sample demo to get malloc/free functions
 
if( .Platform$OS.type == "windows" ) {
 .windir <- paste(Sys.getenv("windir")[[1]],"\\system32\\",sep="")
 .libC <- paste(.windir,"msvcrt",sep="")
} else {
  sysname <- Sys.info()[["sysname"]]
  if (sysname == "Darwin")
  {
  .libC <- "/usr/lib/libc.dylib"
  } else { 
  .libC <- "/lib/libc.so.6"
  }
}

dyn.load(.libC)

bind <- function(name, signature)
{
 address <- getNativeSymbolInfo(name)$address
 assign(name, function(...) rdcCall(address,signature,...), parent.frame() )
}
 
bind("malloc","i)p")
bind("free","p)v")

