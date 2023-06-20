# Package: rdyncall 
# File: demo/blink.R
# Description: Simple SDL,OpenGL demonstration - a blinking screen

dynport(SDL)
dynport(GL)

blink <- 0
surface <- NULL

init <- function()
{
  SDL_Init(SDL_INIT_VIDEO)
  surface <<- SDL_SetVideoMode(640,480,32,SDL_OPENGL+SDL_DOUBLEBUF)
  blink <<- 0
}


update <- function()
{
  glFinish()
  glClearColor(0,0,blink,0)
  glClear(GL_COLOR_BUFFER_BIT)
  SDL_GL_SwapBuffers()
  glFlush()
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
  sdlevent <- cdata("SDL_Event")
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
