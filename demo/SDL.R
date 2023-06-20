# Package: rdyncall 
# File: demo/SDL.R
# Description: 3D Rotating Cube Demo using SDL,OpenGL and GLU. (dynport demo)

dynport(SDL)
dynport(GL)
dynport(GLU)

# Globals.

surface <- NULL

# Init.

init <- function()
{
  err <- SDL_Init(SDL_INIT_VIDEO)
  if (err != 0) error("SDL_Init failed")  
  surface <<- SDL_SetVideoMode(512,512,32,SDL_DOUBLEBUF+SDL_OPENGL)
}

# GL Display Lists

makeCubeDisplaylist <- function()
{
  vertices <- as.double(c(
  -1,-1,-1,
   1,-1,-1,
  -1, 1,-1,
   1, 1,-1,
  -1,-1, 1,
   1,-1, 1,
  -1, 1, 1,
   1, 1, 1
  ))
  
  colors <- as.raw( col2rgb( rainbow(8) ) )
  
  triangleIndices <- as.integer(c(
    0, 2, 1, 
    2, 3, 1,
    1, 3, 7, 
    1, 7, 5,
    4, 5, 7, 
    4, 7, 6,
    6, 2, 0, 
    6, 0, 4,
    2, 7, 3, 
    2, 6, 7,
    4, 0, 5, 
    0, 1, 5
  ))

  glEnableClientState(GL_VERTEX_ARRAY)
  glVertexPointer(3, GL_DOUBLE, 0, vertices )
  
  glEnableClientState(GL_COLOR_ARRAY)  
  glColorPointer(3, GL_UNSIGNED_BYTE, 0, colors )
  
  displaylistId <- glGenLists(1)
  glNewList( displaylistId, GL_COMPILE )    
  glPushAttrib(GL_ENABLE_BIT)
  glEnable(GL_DEPTH_TEST)
  glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_INT, triangleIndices)
  glPopAttrib()
  glEndList()
  
  glDisableClientState(GL_VERTEX_ARRAY)
  glDisableClientState(GL_COLOR_ARRAY)
 

  return(displaylistId)
}

# Mainloop.

mainloop <- function()
{
  displaylistId <- makeCubeDisplaylist()
  evt <- cdata(SDL_Event)
  blink <- 0
  tbase <- SDL_GetTicks()
  quit <- FALSE
  while(!quit)
  {
    tnow <- SDL_GetTicks()
    tdemo <- ( tnow - tbase ) / 1000
    
    glClearColor(0,0,blink,0)
    glClear(GL_COLOR_BUFFER_BIT+GL_DEPTH_BUFFER_BIT)
    
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    aspect <- 512/512
    gluPerspective(60, aspect, 3, 1000)
    
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()
    gluLookAt(0,0,5,0,0,0,0,1,0)
    glRotated(sin(tdemo)*60.0, 0, 1, 0);
    glRotated(cos(tdemo)*90.0, 1, 0, 0);

    glCallList(displaylistId)       

    glCallList(displaylistId)       
    
    SDL_GL_SwapBuffers()  
    
    SDL_WM_SetCaption(paste("time:", tdemo),NULL)    
    blink <- blink + 0.01
    while (blink > 1) blink <- blink - 1
    while( SDL_PollEvent(evt) != 0 )
    {
      if ( evt$type == SDL_QUIT ) quit <- TRUE
      else if (evt$type == SDL_MOUSEBUTTONDOWN )
      {
        button <- evt$button
        cat("button ",button$button," at ",button$x,",",button$y,"\n") 
      }
    }
    glerr <- glGetError()
    if (glerr != 0)
    {
      cat("GL Error:", gluErrorString(glerr) )
      quit <- 1
    }
    SDL_Delay(30)
  }
  glDeleteLists(displaylistId, 1)
}

cleanup <- function()
{
  SDL_Quit()
}

run <- function()
{
  init()
  mainloop()
  cleanup()
}

run()


