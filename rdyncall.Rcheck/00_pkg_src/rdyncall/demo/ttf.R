# Package: rdyncall
# File: demo/ttf.R
# Description: TrueType Font loading and drawing via SDL and SDL_ttf.

dynport(SDL_ttf)

fbSurf <- NULL
textSurf <- NULL

numTexts <- 10

init <- function()
{
  status <- TTF_Init()

  if (status != 0) {
    stop(paste("TTF_Init failed: ", TTF_GetError(), sep=""))
  }

  # tryPaths <- c("/Library/Fonts","/usr/X11R7","/usr/X11R6")
  # tryFonts <- c("Sathu.ttf", "Vera.ttf")

  font <- TTF_OpenFont("/usr/X11R7/lib/X11/fonts/TTF/Vera.ttf",48)
  # Library/Fonts/Sathu.ttf",48)
  if (is.nullptr(font)) {
    stop(paste("TTF_OpenFont failed: ", TTF_GetError(), sep=""))
  }

  color <- cdata(SDL_Color)
  color$r <- color$g <- color$b <- 255
  textSurf <<- TTF_RenderText_Solid(font, "Hello World.")

  SDL_Init(SDL_INIT_VIDEO)
  fbSurf <<- SDL_SetVideoMode(256,256,32,SDL_DOUBLEBUF)

  displace <<- rnorm(numTexts*2)
}

main <- function()
{

  rect <- cdata(SDL_Rect)

  rect$x <- 0
  rect$y <- 0
  rect$w <- textSurf$w
  rect$h <- textSurf$h

  rect2 <- rect

  evt <- cdata(SDL_Event)

  quit <- FALSE

  distance <- 0

  while(!quit) {

    SDL_FillRect(fbSurf, as.ctype( as.externalptr(NULL), "SDL_Rect" ), 0xFFFFFFL)
    rect
    i <- 1
    while(i < numTexts*2) {
      rect2$x <- rect$x + distance * displace[i]
      rect2$y <- rect$y + distance * displace[i+1]
      i <- i + 2
      SDL_BlitSurface(textSurf, as.ctype(as.externalptr(NULL),"SDL_Rect"),fbSurf,rect2)
    }
    SDL_Flip(fbSurf)

    distance <- distance + 1

    while ( SDL_PollEvent(evt) ) {
      if ( evt$type == SDL_QUIT )
        quit <- TRUE
      else if (evt$type == SDL_MOUSEBUTTONDOWN ) {
        rect$x <- evt$button$x
        rect$y <- evt$button$y
        distance <- 0
      }
    }

  }

}

run <- function()
{
  init()
  main()
}


