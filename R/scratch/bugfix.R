

x <- rdyncall:::makeNamespace("bla")
sys.source("/lab/eclipse/dyncall/rdyncall/scratch/script.R", envir=x)

quote({
parseStructInfos("
SDL_keysym{CiiS}scancode sym mod unicode ;
SDL_KeyboardEvent{CCC<SDL_keysym>}type which state keysym ;
", envir=x)
})

f <- function()
{
  parent.frame()
}

g <- function(envir=parent.frame())
{
  envir
}

f <- function(envir=parent.frame())
{
  
}
