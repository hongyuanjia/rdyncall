# Package: rdyncall 
# File: demo/callbacks.R
# Description: Creating a callback and call it via .dyncall

# The function to wrap:
f <- function(x,y) x+y

# Create the callback:
cb <- new.callback("ii)i", f)

# Call the callback
r <- .dyncall(cb, "ii)i", 20, 3)
r == 23

# Recursive callback example:

f <- function(x,y,f,i) 
{
  if (i > 1) .dyncall(f, "iipi)i", x,y,f,i-1)
  x+y
}

cb <- new.callback("iipi)i", f)

r <- .dyncall(cb, "iipi)i", 1,1,cb,100 )
r == 2

