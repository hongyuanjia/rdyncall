# Package: rdyncall
# File: demo/intro.R
# Description: Texture-mapped scroll-text, playing music 'Hybrid Song' composed in jan. -96 by Quazar of Sanxion 

s     <- NULL
texId <- NULL
music <- NULL

checkGL <- function()
{
  glerror <- glGetError()
  if (glerror != 0)
  {
    cat("GL Error", glerror, "\n")
  }
  return(glerror == 0)
}

init <- function()
{
  require(rdyncall)
  dynport(SDL)
  SDL_Init(SDL_INIT_VIDEO+SDL_INIT_AUDIO)
  dynport(GL)
  dynport(SDL_image)
  s <<- SDL_SetVideoMode(640,480,32,SDL_OPENGL+SDL_DOUBLEBUF)
  stopifnot( IMG_Init(IMG_INIT_PNG) == IMG_INIT_PNG )
  texId <<- loadTexture("chromefont.png")
  # texId <<- loadTexture("nuskool_krome_64x64.png")
  dynport(SDL_mixer)
  # stopifnot( Mix_Init(MIX_INIT_MOD) == MIX_INIT_MOD )
  Mix_OpenAudio(MIX_DEFAULT_FREQUENCY, MIX_DEFAULT_FORMAT, 2, 4096)
  music <<- Mix_LoadMUS(rsrc("external.xm"))
}
  
rsrc <- function(name) system.file(paste("demo-files",name,sep=.Platform$file.sep), package="rdyncall")

loadTexture <- function(name)
{
  checkGL()
  glEnable(GL_TEXTURE_2D)
  x <- rsrc(name)
  img <- IMG_Load(x)
#  glPixelStorei(GL_UNPACK_ALIGNMENT,4)
  texid <- integer(1)
  glGenTextures(1, texid)
  glBindTexture(GL_TEXTURE_2D, texid)
  SDL_LockSurface(img)
  maxS <- integer(1)
  glGetIntegerv(GL_MAX_TEXTURE_SIZE, maxS)
  stopifnot( (img$w <= maxS) && (img$h <= maxS) )
  glTexImage2D(GL_TEXTURE_2D, 0, 4, img$w, img$h, 0, GL_BGRA, GL_UNSIGNED_BYTE, img$pixels)
  SDL_UnlockSurface(img)
  SDL_FreeSurface(img) 
#  gluBuild2DMipmaps(GL_TEXTURE_2D, 4, img$w, img$h)
  return(texid)
}

drawScroller <- function(codes,time)
{
  glBindTexture(GL_TEXTURE_2D, texId)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)
  glEnable(GL_BLEND)
  glBlendFunc( GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE)

  glMatrixMode(GL_MODELVIEW)
  glLoadIdentity()  
  glMatrixMode(GL_PROJECTION)
  glLoadIdentity()

  x <- 1-time*0.5
  y <- 0
  w <- 0.3+0.1*sin(6.24*time)
  h <- 0.2
  for (i in 1:length(codes)) {
    t  <- codes[i] 
    s0 <- (t%%8)/8
    t0 <- as.integer(t/8)/8
    s1 <- s0+1/8
    t1 <- t0+1/8

    # s0 <- 0
    # s1 <- 1
    # t0 <- 0
    # t1 <- 1
    
    glBegin(GL_QUADS)
    glTexCoord2f(s0,t1) ; glVertex3f(x  ,y  ,0)
    glTexCoord2f(s1,t1) ; glVertex3f(x+w,y  ,0)
    glTexCoord2f(s1,t0) ; glVertex3f(x+w,y+h,0)
    glTexCoord2f(s0,t0) ; glVertex3f(x  ,y+h,0)
    glEnd()
    x <- x + w
  } 
}
  
codes <- utf8ToInt("DO YOU SOMETIMES WANT FOR YOUR OLD HOME COMPUTER?! - I DO") - 32

mainloop <- function()
{
  Mix_PlayMusic(music, 1)
  quit <- FALSE
  blink <- 0
  tbase <- SDL_GetTicks()
  evt <- cdata(SDL_Event)
  while(!quit)
  {
    tnow <- SDL_GetTicks()
    tdemo <- ( tnow - tbase ) / 1000
    glClearColor(0,0,blink,0)
    glClear(GL_COLOR_BUFFER_BIT+GL_DEPTH_BUFFER_BIT)
    blink <- blink + 0.01
    drawScroller(codes,tdemo)
    SDL_GL_SwapBuffers()
    while( SDL_PollEvent(evt) != 0 )
    {
      type <- evt$type
      if ( 
           type == SDL_QUIT 
      || ( type == SDL_KEYDOWN && evt$key$keysym$sym == SDLK_ESCAPE )
      ) {
        quit <- TRUE
      }
    }
    SDL_Delay(20)
  }
}

cleanup <- function()
{
  Mix_CloseAudio()
#  Mix_Quit()
  IMG_Quit()
  SDL_Quit()
}

run <- function()
{
  init()
  mainloop()
  cleanup()
}

run()

