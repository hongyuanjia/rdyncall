
# -----------------------------------------------------------------------------
# dynport configuration
.installdir <- "c:\\dynports"
# -----------------------------------------------------------------------------

# installation:
.libname <- "SDL"
.sysname <- Sys.info()[["sysname"]]
if (.sysname == "Windows") {
  
  dynports.ui.init <- function()
  {
    winMenuAdd("Dynports")
    winMenuAdd("Dynports/Install dynport(s) ...") 
  }
  
  
  dynport.sdl.is.installed <- function() {
    x <- .dynload(.libname)
    if (is.null(x)) return(FALSE) 
    return(TRUE)
  }
  
  dynport.sdl.install <- function() {
    
    sysname <- Sys.info()[["sysname"]]
    
    .prebuilt <- c(
        Windows.zip="http://www.libsdl.org/release/SDL-1.2.13-win32.zip",
        Linux.rpm.x86="http://www.libsdl.org/release/SDL-1.2.13-1.i386.rpm",
        Linux.rpm.x86_64="http://www.libsdl.org/release/SDL-1.2.13-1.x86_64.rpm",
        MacOSX="http://www.libsdl.org/release/SDL-1.2.13.dmg"
    )
    
    if (sysname == "Windows") {
      
      # install.windows.zip to .dyncall.bindir
      
      package <- "SDL"
      version <- "1.2.13"
      arch    <- "win32"
      rooturl <- "http://www.libsdl.org/release/"
      zipname <- "SDL-1.2.13-win32.zip"
      tempdir   <- tempdir()
      zipfile  <- file.path( tempdir, zipname )
      url     <- paste( rooturl , zipname, sep="/" )
      method  <- "internal" 
      download.file(url, zipfile, method)
      zip.unpack( zipfile, tempdir )
      dllname <- "SDL.dll"
      dllfile <- file.path( tempdir, dllname )
      file.copy(dllfile, .installdir)
      
    } else if (sysname == "Linux") {
      
      
      
    } else if (sysname == "Darwin") {
      
      
      
    }
    
  }
  

  