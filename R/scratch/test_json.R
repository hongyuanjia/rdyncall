library(rjson)

parseJSON <- function(path)
{
  parser <- newJSONParser()
  f <- file(path)
  open(f)
  while(TRUE) 
  {
    aLine <- readLines(f, 1)
    if (length(aLine) == 0) break    
    parser$addData( aLine )
  }
  close(f)
  parser$getObject()
}
# TEST:
testfile <- "/lab/eclipse/dyncall/rdyncall/inst/dynports/GL.json"
x <- parseJSON(testfile)
# print(glinfo)
