# Package: rdyncall 
# File: demo/blink.R
# Description: Simple SDL,OpenGL demonstration - a blinking screen

require(rdyncall)
dynport(SDL)
dynport(gl3)

blink <- 0
surface <- NULL

init <- function()
{
  SDL_Init(SDL_INIT_VIDEO)
  SDL_GL_SetAttribute( SDL_GL_SWAP_CONTROL, 1 )
  surface <<- SDL_SetVideoMode(640,480,32,SDL_OPENGL+SDL_DOUBLEBUF)
  blink <<- 0
}


update <- function()
{
  glClearColor(0,0,blink,0)
  glClear(GL_COLOR_BUFFER_BIT)
  SDL_GL_SwapBuffers()
  blink <<- ( blink + 0.01 ) %% 1
}

input <- function()
{
  return(TRUE)
}

checkGL <- function()
{
  glerror <- glGetError()
  if (glerror != 0)
  {
    cat("GL Error", glerror, "\n")
  }
  return(glerror == 0)
}

mainloop <- function()
{
  sdlevent <- new.struct("SDL_Event")
  quit <- FALSE
  while(!quit)
  {
    update()
    while( SDL_PollEvent(sdlevent) )
    {
      if (sdlevent$type == SDL_QUIT ) {
        quit <- TRUE
      } else if (sdlevent$type == SDL_MOUSEBUTTONDOWN) {
        cat("button ", sdlevent$button$button ,"\n")
      }
    }
    if ( !checkGL() ) quit <- TRUE
    # SDL_Delay(30)
  }
}

quit <- function()
{
  SDL_Quit()
}

run <- function()
{  
  init()
  mainloop()
  quit()
}

run()
