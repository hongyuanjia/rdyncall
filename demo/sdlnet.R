# BUGS: does not work on Mac OS X using R64, needs to use R32.

library(rdyncall)
dynport(SDL)
dynport(GL)
dynport(SDL_net)
library(mapdata)

db <- "worldHires"

PORT <- 1234
MAX_CLIENT_SOCKETS <- 3

tcp     <- NULL
socket  <- NULL
sockets <- NULL
ctcps   <- NULL
csocks  <- NULL
world   <- NULL
glList  <- NULL

init <- function() {

  if ( SDL_Init(SDL_INIT_VIDEO) == -1 ) {
    error("SDL_Init failed")
  }

  if ( SDLNet_Init() == -1 ) {
    error("SDLNet_Init failed")
  }

  ip <- new.struct("IPaddress")

  if ( SDLNet_ResolveHost(ip,NULL,PORT) == -1 ) {
    error("SDLNet_ResolveHost failed")
  }

  tcp <<- SDLNet_TCP_Open(ip)

  socket <<- as.struct(offsetPtr(tcp,0),"SDLNet_GenericSocket_")

  sockets <<- SDLNet_AllocSocketSet(1+MAX_CLIENT_SOCKETS)
  SDLNet_AddSocket(sockets, socket )

  SDL_SetVideoMode(640,480,32,SDL_OPENGL+SDL_DOUBLEBUF)

  ctcps   <<- list()
  csocks  <<- list()
  world   <<- map(db,"switzerland",plot=FALSE)

  glList <<- glGenLists(1)
}


drawMap3d <- function(m) {
  glNewList(glList, GL_COMPILE)
  x       <- m$x
  vb      <- rbind(m$x,m$y)
  glEnableClientState(GL_VERTEX_ARRAY)
  glVertexPointer(2, GL_DOUBLE, 0, vb)
  markers <- which(is.na(x))
  begin   <- 1
  i       <- 1
  while(i <= length(markers)) {
    end     <- markers[i] - 1
    glDrawArrays(GL_LINE_STRIP, begin - 1, (end-1) - (begin-1) + 1)
    begin   <- markers[i] + 1
    i       <- i + 1
  }  
  end     <- length(x)
  glDrawArrays(GL_LINE_STRIP, begin - 1, (end-1) - (begin-1) + 1)
  glDisableClientState(GL_VERTEX_ARRAY)
  glEndList()
}

loop <- function() {
  drawMap3d(world)
  do_loop <- TRUE
  cnt <- 0
  evt <- new.struct("SDL_Event")
  while(do_loop) {
    glClearColor(0.2,0.3,0.1,0)
    glClear(GL_COLOR_BUFFER_BIT)
    r <- world$range
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    glOrtho(r[[1]],r[[2]],r[[3]],r[[4]],-10000, 10000)
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()

    cx <- r[[1]] + ( r[[2]] - r[[1]] ) * 0.5 
    cy <- r[[3]] + ( r[[4]] - r[[3]] ) * 0.5 

    glTranslatef( cx, cy , 0 )
    glRotatef(cnt,0,1,0) ; cnt <- cnt + 1
    glTranslatef( -cx, -cy , 0 )
#( r[[2]]-r[[1]] )*0.5, (r[[4]]-r[[3]]) *0.5,0)
   # glTranslatef(-(r[[2]]-r[[1]])*0.5,-(r[[4]]-r[[3]])*0.5,0)
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glColor4f(1.0,0.8,0.5,0.2)
    delta <- 0
    for(i in 1:10) {
      glLoadIdentity()
      glTranslatef( cx, cy , 0 )
      glRotatef(cnt+delta,0,1,0) ; 
      glTranslatef( -cx, -cy , 0 )
      glCallList(glList)
      delta <- delta + 1.0
    }
    glFinish()
    SDL_GL_SwapBuffers()

    while( SDL_PollEvent(evt) ) {
      if ( evt$type == SDL_QUIT ) {
        do_loop <- FALSE
      }
    }

    numready <- SDLNet_CheckSockets(sockets, 0)
    if (numready > 0) {
      cat("ready\n")
      if (socket$ready) {
        cat("listener\n\n")
        # tcp <- as.struct(tcp,"_TCPsocket")
        ctcp <- SDLNet_TCP_Accept(tcp)
        if (is.null(ctcp)) {
          cat("warning: client is NULL\n")
        } else {
          csock  <- as.struct(offsetPtr(ctcp,0),"SDLNet_GenericSocket_")
          ctcps  <- c(ctcps, ctcp)
          csocks <- c(csocks, csock) 
          if ( SDLNet_AddSocket(sockets, csock) == -1 ) {
            cat("warning: add socket failed\n")
          }
        }
        numready <- numready - 1
      } 
      while(numready) {
        i <- 1
        for(i in 1:length(csocks)) {
          csock <- csocks[[i]]
          if(csock$ready) {
            cat("client ready")
            numready <- numready - 1
            buf <- raw(1000)
            result <- SDLNet_TCP_Recv(ctcps[[i]], buf, length(buf))
            if (result <= 0) {
              cat("ERROR: SDLNet_TCP_Recv result <= 0.\n")
            } else {
              buf[result] <- as.raw(0)
              txt <- ptr2str(offsetPtr(buf,0))
              cat("DATA:'",txt,"'\n")
              
              tryCatch({
                m <- map(db,txt,plot=FALSE)
                world <<- m
                drawMap3d(world)
              },error= function(x) {})
            }
          }
        }
      }
    }
    SDL_Delay(20)
  }
}
init()
loop()

