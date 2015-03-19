#
# 1. install functions
# 2. install function variables
# 3. install enums
# 4. install defines
#



begin.info <- function()
{  
}

begin.funs <- function()
{
  
}

parse.funs <- function(line)
{
    
}


parse <- function(path)
{
  file <- file(path)
  eof  <- FALSE
  while(!eof)
  {
    line <- readLines(file, 1)
  }
}

parse("rdyncall/scratch/test.dyp")

currentSection <- ""


if ( substr(line, 1, 1) == "!" ) {
  paste("end.", currentSection)
  do.call( paste("end.", currentSection, sep="") )
  type <- substr(line,2)
  handler <- paste("begin.",type,sep="")
  envs <- find(handler)
  if (length(envs) == 1)
    do.call(handler)
  }
}

