# Package: rdyncall 
# File: demo/expat.R
# Description: Parsing XML using expat and callbacks 

dynport(expat)

parser <- XML_ParserCreate(NULL)

onXMLStartTag <- function(user,tag,attr)
{
  # as.character( as.cstrptrarray(attr) )
  cat("Start tag:", tag, "\n")  
}

onXMLEndTag <- function(user,tag)
{
  cat("End tag:",tag, "\n")  
}

cb.onstart <- ccallback("pZp)v", onXMLStartTag )
cb.onstop  <- ccallback("pZ)v",  onXMLEndTag )

XML_SetElementHandler( parser, cb.onstart, cb.onstop ) 

text <- "
<hello>
  <world>
  </world>
</hello>
"

XML_Parse( parser, text, nchar(text), 1)

