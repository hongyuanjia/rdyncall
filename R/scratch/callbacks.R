

dynbind("user32","RegisterClassEx(p)p;")


C.struct <- function(signature) {
	map <- strsplit(signature,'[; \t\n]+')[[1]]
	if (map[1] == "")
	  map <- map[-1]
	n <- length(map)
	types   <- map[seq(1,n,by=2)]
	ids     <- map[seq(2,n,by=2)]
	sizes   <- C.sizes[types]
	offsets <- c(0,cumsum(sizes))
	ids     <- c(ids,".sizeof")
	types   <- c(types,"")
	sizes   <- c(sizes,"")
	data.frame(
		id=ids,
		type=types,
		size=sizes,
		offset=offsets,
		row.names=1
	)
}

WNDCLASSEX <- "
UINT cbSize;
UINT style;
WNDPROC lpfnWndProc;
int cbClsExtra;
int cbWndExtra;
HINSTANCE hInstance;
HICON hIcon;
HCURSOR hCursor;
HBRUSH hbrBackground;
LPCTSTR lpszMenuName;
LPCTSTR lpszClassName;
HICON hIconSm;
"

WNDCLASSEX <- C.struct("
UINT cbSize;
UINT style;
WNDPROC lpfnWndProc;
int cbClsExtra;
int cbWndExtra;
HINSTANCE hInstance;
HICON hIcon;
HCURSOR hCursor;
HBRUSH hbrBackground;
LPCTSTR lpszMenuName;
LPCTSTR lpszClassName;
HICON hIconSm;
") 

library(rdyncall)

allocC <- function(info)
{
  x <- malloc(sizeof(info))
  attr(x, "cstruct") <- info
  class(x) <- "cstruct"
  return(x)
}

packC <- function( address, offset, type, value )
{
  
}


"$.Cstruct<-" <- function (cstruct, name, value)
{
  info <- attr(x, "cstruct")
  element <- info[name,]
  packC( cstruct, element$offset, sigchar(element$type), value )
  return(value)
}

winclass <- allocC(WNDCLASS) 
winclass$cbSize <- sizeofC(WNDCLASS) 
RegisterClassEx(winclass)
