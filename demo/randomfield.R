# Package: rdyncall
# File: demo/randomfield.R
# Description: Scientific Computations using OpenGL: Rendering 512x512 random field by blending 5000 point sprites (dynport demo)

dynport(SDL)
dynport(GL)

# ----------------------------------------------------------------------------
# Parameters:

# framebuffer size
fb.size <- 512

# texture size
tex.size <- 512


# ----------------------------------------------------------------------------
# texture setup

genTex.circle <- function(n)
{
  m   <- matrix(data=FALSE,nr=n,nc=n)
  r   <- n/2
  for(i in 1:n)
  {
    for(j in 1:n)
    {
      m[[i,j]] <- ifelse((i-r)^2+(j-r)^2 > r^2,0L,255L)
    }
  }
  return(m)
}

genTex.bnorm <- function(n)
{
  x <- seq(-3,3,len=n)
  y <- dnorm(x)
  return( outer(y,y) )
}

# ----------------------------------------------------------------------------
# draw circle using OpenGL Vertex Arrays

drawTexCirclesVertexArray <- function(x,y,r)
{
  n <- max( length(x), length(y), length(r) )
  x1 <- x-r
  x2 <- x+r
  y1 <- y-r
  y2 <- y+r

  vertexArray <- as.vector(rbind(x1,y1,x2, y1, x2, y2, x1, y2))
  texCoordArray <- rep( as.double(c(0,0,1,0,1,1,0,1)), n )

  glEnableClientState(GL_VERTEX_ARRAY)
  glEnableClientState(GL_TEXTURE_COORD_ARRAY)
  glVertexPointer(2,GL_DOUBLE,0,vertexArray)
  glTexCoordPointer(2,GL_DOUBLE,0,texCoordArray)

  glDrawArrays(GL_QUADS, 0, n*4)

  glDisableClientState(GL_VERTEX_ARRAY)
  glDisableClientState(GL_TEXTURE_COORD_ARRAY)
}

#drawPointSprite <- function()
#{
#  glEnable(GL_POINT_SPRITE)
#  glTexEnvi(GL_POINT_SPRITE,GL_COORD_REPLACE,GL_TRUE)
#  glPointParameter(GL_POINT_SPRITE_COORD_ORIGIN, GL_LOWER_LEFT)
#  glPointSize
#}

# ----------------------------------------------------------------------------
# initialize SDL, OpenGL

max.tex.size <- integer(1)
max.tex.units <- integer(1)
tex.ids <- integer(1)
init <- function()
{
  # initialize SDL

  SDL_Init(SDL_INIT_VIDEO)
  surface  <<- SDL_SetVideoMode(fb.size,fb.size,32,SDL_OPENGL+SDL_DOUBLEBUF)

  # initialize OpenGL

  glGetIntegerv(GL_MAX_TEXTURE_SIZE, max.tex.size)
  glGetIntegerv(GL_MAX_TEXTURE_UNITS, max.tex.units)

  glClearColor(0,0,0,0)
  glColor4f(0.1,0.1,0.1,0)

  # img <- genTex.circle(tex.size)
  # texdata <- as.raw(img)

  img <- genTex.bnorm(tex.size)
  m <- max(img)
  texdata <- as.raw( ( img/m ) * 255 )


  glGenTextures( length(tex.ids),tex.ids)
  glBindTexture(GL_TEXTURE_2D, tex.ids[[1]])
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1)
  glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, tex.size, tex.size, 0, GL_ALPHA, GL_UNSIGNED_BYTE, texdata)
  # glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, tex.size, tex.size, 0, GL_ALPHA, GL_DOUBLE, as.vector(img))

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S,GL_CLAMP_TO_BORDER)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T,GL_CLAMP_TO_BORDER)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)

  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE)
  glEnable(GL_TEXTURE_2D)

  # blending setup

  glBlendFunc(GL_SRC_ALPHA, GL_ONE)
  glEnable(GL_BLEND)
}

cleanup <- function()
{
  glDeleteTextures( length(tex.ids), tex.ids)
  SDL_Quit()
}

pixels  <- NULL

main <- function()
{
  cat("Click on window to import current random field and plot in R.\nClose window to quit mainloop.\n")
  N         <- 5000
  colorunit <- 0.02
  glColor3d( colorunit,colorunit,colorunit )
  tbase <- SDL_GetTicks()
  frames <- 0

  x <- runif(N,-1.1,1.1)
  y <- runif(N,-1.1,1.1)
  r <- runif(N,0.1,0.2)
  event <- cdata("SDL_Event")

  # disable interactive plot device.
  oldpars <- par(ask=FALSE,mfrow=c(1,1))

  quit <- FALSE
  while(!quit)
  {
    glClear(GL_COLOR_BUFFER_BIT)
    drawTexCirclesVertexArray(x,y,r)
    x <- runif(N,-1.1,1.1)
    y <- runif(N,-1.1,1.1)
    r <- runif(N,0.1,0.2)
    glFinish()
    SDL_GL_SwapBuffers()
    tnow <- SDL_GetTicks()
    if ((tnow - tbase) > 1000)
    {
      tbase <- tnow
      SDL_WM_SetCaption(paste("FPS:", frames),NULL)
      frames <- 0
    }
    while( SDL_PollEvent(event) != 0 )
    {
      type <- event$type
      if (type == SDL_MOUSEBUTTONDOWN) {
        cat("Read pixels via OpenGL into an R integer matrix..")
        pixels <<- readpixels()
        cat("done.\nPlot image results with R plotting device. This may take a while - please be patient..")
        image(pixels)
        cat("done.\nContinue..\n")
      } else if (type == SDL_QUIT) {
        cat("Read pixels via OpenGL into an R integer matrix 'pixels'..")
        pixels <<- readpixels()
        cat("done.\nRe-run by 'run()'\n")
        quit <- TRUE
      }
    }
    frames <- frames + 1
  }
  par(oldpars)
}

readpixels <- function()
{
  array <- matrix(NA_integer_,fb.size,fb.size)
  glPixelStorei(GL_PACK_ALIGNMENT,1)
  glReadPixels(0,0,fb.size,fb.size, GL_LUMINANCE, GL_INT, array)
  return(array)
}

run <- function()
{
  init()
  main()
}

run()
