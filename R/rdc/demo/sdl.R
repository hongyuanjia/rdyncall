library(rdc)
# ----------------------------------------------------------------------------
# Platform specific issues

if (.Platform$OS.type == "windows") { 
	OS <- "windows"
} else if ( Sys.info()[["sysname"]] == "Darwin" ) { 
	OS <- "darwin"
} else {
	OS <- "unix"
}

# ----------------------------------------------------------------------------
# dynbind environment

.cdecl   <- dcNewCallVM(1024)
.stdcall <- dcNewCallVM(1024)
dcMode(.stdcall, rdc:::DC_CALL_C_X86_WIN32_STD )

# ----------------------------------------------------------------------------
# C memory allocation
.callC <- .cdecl
.callSDL <- .cdecl
.callGL <- .cdecl
.callGLU <- .cdecl
.callR   <- .cdecl
if (OS == "windows") {
  .libC <- "/windows/system32/msvcrt"
  .libSDL <- "/dll/sdl"
  .libGL <- "/windows/system32/OPENGL32"
  .libGLU <- "/windows/system32/GLU32"
  .libR <- "R"
  .callGL <- .stdcall
} else if (OS == "darwin") {
  .libCocoa <- "/System/Library/Frameworks/Cocoa.framework/Cocoa"
  dyn.load(.libCocoa)
  .NSApplicationLoad <- getNativeSymbolInfo("NSApplicationLoad")$address
  NSApplicationLoad <- function() rdcCall(.NSApplicationLoad, ")B" )
  # dyn.load("rdc")
  .newPool <- getNativeSymbolInfo("newPool")$address
  .releasePool <- getNativeSymbolInfo("releasePool")$address
  releasePool <- function(x) 
  {
    rdcCall( .releasePool, "p)v", x )
  }
  newPool <- function() 
  {
    x <- rdcCall( .newPool, ")p" )
    reg.finalizer( x, releasePool )
    return(x)
  }
  .pool   <- newPool()
  .libC   <- "/usr/lib/libc.dylib"
  .libSDL <- "/Library/Framworks/SDL.framework/SDL"
  .libGL  <- "/System/Library/Frameworks/OpenGL.framework/Libraries/libGL.dylib"
  .libGLU <- "/System/Library/Frameworks/OpenGL.framework/Libraries/libGLU.dylib"
  .libR   <- Sys.getenv("R_HOME")
  .libR   <- paste(.libR,"/lib/libR.dylib",sep="")
} else { # unix
  .libC <- "/lib/libc.so.6"
  .libSDL <- "/usr/lib/libSDL.so"
  .libGL <- "/usr/lib/libGL.so"
  .libGLU <- "/usr/lib/libGLU.so"
  .libR <- paste(R.home(),"/lib/libR.so",sep="")
}

#dyn.load(.libC)
#.malloc <- getNativeSymbolInfo("malloc")$address
#.free   <- getNativeSymbolInfo("free")$free
#malloc <- function(size) rdcCall(.malloc, "i)p", as.integer(size) )
#free   <- function(ptr) rdcCall(.free, "p)v", ptr)

.importsR <- "
R_chk_calloc(ii)p;
R_chk_realloc(ii)p;
R_chk_free(p)v;
"

rdcBind(.libR,.importsR,.callR)

malloc <- function(size) R_chk_calloc(as.integer(size),1L)
free <- function(ptr) R_chk_free(ptr)


# ----------------------------------------------------------------------------
# SDL library
dyn.load(.libSDL)

.SDL_Init <- getNativeSymbolInfo("SDL_Init")$address
.SDL_Quit <- getNativeSymbolInfo("SDL_Quit")$address
.SDL_SetVideoMode <- getNativeSymbolInfo("SDL_SetVideoMode")$address
.SDL_WM_SetCaption <- getNativeSymbolInfo("SDL_WM_SetCaption")$address
.SDL_GL_SwapBuffers <- getNativeSymbolInfo("SDL_GL_SwapBuffers")$address
.SDL_PollEvent <- getNativeSymbolInfo("SDL_PollEvent")$address
.SDL_GetTicks <- getNativeSymbolInfo("SDL_GetTicks")$address
.SDL_Delay <- getNativeSymbolInfo("SDL_Delay")$address
# init flags:
SDL_INIT_TIMER		= 0x00000001L
SDL_INIT_AUDIO		= 0x00000010L
SDL_INIT_VIDEO		= 0x00000020L
SDL_INIT_CDROM		= 0x00000100L
SDL_INIT_JOYSTICK	= 0x00000200L
SDL_INIT_NOPARACHUTE =	0x00100000L
SDL_INIT_EVENTTHREAD =	0x01000000L
SDL_INIT_EVERYTHING	= 0x0000FFFFL
# SDL_Init(flags):
SDL_Init <- function(flags) rdcCall(.SDL_Init, "i)i", as.integer(flags) )
# SDL_Quit():
SDL_Quit <- function() rdcCall(.SDL_Quit, ")v" )
# video flags:
SDL_SWSURFACE	= 0x00000000L
SDL_HWSURFACE	= 0x00000001L
SDL_ASYNCBLIT	= 0x00000004L
SDL_ANYFORMAT	= 0x10000000L
SDL_HWPALETTE	= 0x20000000L
SDL_DOUBLEBUF	= 0x40000000L
SDL_FULLSCREEN	= 0x80000000
SDL_OPENGL      = 0x00000002L
SDL_OPENGLBLIT	= 0x0000000AL
SDL_RESIZABLE	= 0x00000010L
SDL_NOFRAME	= 0x00000020L
SDL_HWACCEL	= 0x00000100L
SDL_SRCCOLORKEY	= 0x00001000L	
SDL_RLEACCELOK	= 0x00002000L
SDL_RLEACCEL	= 0x00004000L
SDL_SRCALPHA	= 0x00010000L
SDL_PREALLOC	= 0x01000000L
# SDL_SetVideoMode():
SDL_SetVideoMode <- function(width,height,bpp,flags) rdcCall(.SDL_SetVideoMode,"iiii)p",width,height,bpp,flags)
SDL_WM_SetCaption <- function(title, icon) rdcCall(.SDL_WM_SetCaption,"SS)v",as.character(title), as.character(icon))
SDL_PollEvent <- function(eventptr) rdcCall(.SDL_PollEvent,"p)i", eventptr)
SDL_GL_SwapBuffers <- function() rdcCall(.SDL_GL_SwapBuffers,")v")
SDL_GetTicks <- function() rdcCall(.SDL_GetTicks,")i")
SDL_Delay <- function(ms) rdcCall(.SDL_Delay,"i)v",ms)

SDL_NOEVENT = 0
SDL_ACTIVEEVENT = 1
SDL_KEYDOWN = 2
SDL_KEYUP = 3
SDL_MOUSEMOTION = 4 
SDL_MOUSEBUTTONDOWN = 5
SDL_MOUSEBUTTONUP = 6
SDL_JOYAXISMOTION = 7
SDL_JOYBALLMOTION = 8
SDL_JOYHATMOTION = 9
SDL_JOYBUTTONDOWN = 10
SDL_JOYBUTTONUP = 11
SDL_QUIT = 12
SDL_SYSWMEVENT = 13
SDL_EVENT_RESERVEDA = 14
SDL_EVENT_RESERVEDB = 15
SDL_VIDEORESIZE = 16
SDL_VIDEOEXPOSE = 17
SDL_EVENT_RESERVED2 = 18
SDL_EVENT_RESERVED3 = 19
SDL_EVENT_RESERVED4 = 20
SDL_EVENT_RESERVED5 = 21
SDL_EVENT_RESERVED6 = 22
SDL_EVENT_RESERVED7 = 23
SDL_USEREVENT = 24
SDL_NUMEVENTS = 32


SDL_EventType <- function(event) offset(event, 0, "integer", 1)



# ----------------------------------------------------------------------------
# OpenGL bindings
dyn.load(.libGL)

.importsGL <- "
    glGetError()i;
    glClearColor(ffff)v;
    glClear(i)v;
    glMatrixMode(i)v;
    glLoadIdentity()v;
    glBegin(i)v;
    glEnd()v;
    glVertex3d(ddd)v;
    glRotated(dddd)v;
    glGenLists(i)i;
    glNewList(ii)v;
    glEnableClientState(i)v;
    glVertexPointer(iiip)v;
    glColorPointer(iiip)v;
    glDrawElements(iiip)v;
    glDisableClientState(i)v;
    glEndList()v;
    glCallList(i)v;
"

if (OS == "windows") { 
  .callGL  <- .stdcall
  .callGLU <- .stdcall
} else {
  .callGL  <- .cdecl
  .callGLU <- .cdecl
}

# Import OpenGL symbols
rdcBind(.libGL,.importsGL, .callGL)

GL_FALSE                                = 0x0L
GL_TRUE                                 = 0x1L

GL_BYTE                           =      0x1400L
GL_UNSIGNED_BYTE                  =      0x1401L
GL_SHORT                          =      0x1402L
GL_UNSIGNED_SHORT                 =      0x1403L
GL_INT                            =      0x1404L
GL_UNSIGNED_INT                   =      0x1405L
GL_FLOAT                          =      0x1406L
GL_DOUBLE                         =      0x140AL
GL_2_BYTES                        =      0x1407L
GL_3_BYTES                        =      0x1408L
GL_4_BYTES                        =      0x1409L


GL_COMPILE                        =     0x1300L
GL_COMPILE_AND_EXECUTE            =     0x1301L
GL_LIST_BASE                      =     0x0B32L
GL_LIST_INDEX                     =     0x0B33L
GL_LIST_MODE                      =     0x0B30L

GL_VERTEX_ARRAY                    =     0x8074L
 GL_NORMAL_ARRAY                   =      0x8075L
 GL_COLOR_ARRAY                    =      0x8076L
 GL_INDEX_ARRAY                    =      0x8077L
 GL_TEXTURE_COORD_ARRAY            =      0x8078L
 GL_EDGE_FLAG_ARRAY                =      0x8079L
 GL_VERTEX_ARRAY_SIZE              =      0x807AL
 GL_VERTEX_ARRAY_TYPE              =      0x807BL
 GL_VERTEX_ARRAY_STRIDE            =      0x807CL
 GL_NORMAL_ARRAY_TYPE              =      0x807EL
 GL_NORMAL_ARRAY_STRIDE            =      0x807FL
 GL_COLOR_ARRAY_SIZE               =      0x8081L
 GL_COLOR_ARRAY_TYPE               =      0x8082L
 GL_COLOR_ARRAY_STRIDE             =      0x8083L
 GL_INDEX_ARRAY_TYPE               =      0x8085L
 GL_INDEX_ARRAY_STRIDE             =      0x8086L
 GL_TEXTURE_COORD_ARRAY_SIZE       =      0x8088L
 GL_TEXTURE_COORD_ARRAY_TYPE       =      0x8089L
 GL_TEXTURE_COORD_ARRAY_STRIDE     =      0x808AL
 GL_EDGE_FLAG_ARRAY_STRIDE         =      0x808CL
 GL_VERTEX_ARRAY_POINTER           =      0x808EL
 GL_NORMAL_ARRAY_POINTER           =      0x808FL
 GL_COLOR_ARRAY_POINTER            =      0x8090L
 GL_INDEX_ARRAY_POINTER            =      0x8091L
 GL_TEXTURE_COORD_ARRAY_POINTER    =      0x8092L
 GL_EDGE_FLAG_ARRAY_POINTER        =      0x8093L
 GL_V2F                            =      0x2A20L
 GL_V3F                            =      0x2A21L
 GL_C4UB_V2F                       =      0x2A22L
 GL_C4UB_V3F                       =      0x2A23L
 GL_C3F_V3F                        =      0x2A24L
 GL_N3F_V3F                        =      0x2A25L
 GL_C4F_N3F_V3F                     =     0x2A26L
 GL_T2F_V3F                        =      0x2A27L
 GL_T4F_V4F                        =      0x2A28L
 GL_T2F_C4UB_V3F                   =      0x2A29L
 GL_T2F_C3F_V3F                    =      0x2A2AL
 GL_T2F_N3F_V3F                    =      0x2A2BL
 GL_T2F_C4F_N3F_V3F                =      0x2A2CL
 GL_T4F_C4F_N3F_V4F                =      0x2A2DL


GL_COLOR_BUFFER_BIT = 0x00004000L

GL_MODELVIEW = 0x1700L
GL_PROJECTION =  0x1701L
GL_TEXTURE = 0x1702L

GL_POINTS                         = 0x0000L
GL_LINES                          = 0x0001L
GL_LINE_LOOP                      = 0x0002L
GL_LINE_STRIP                     = 0x0003L
GL_TRIANGLES                      = 0x0004L
GL_TRIANGLE_STRIP                 = 0x0005L
GL_TRIANGLE_FAN                   = 0x0006L
GL_QUADS                          = 0x0007L
GL_QUAD_STRIP                     = 0x0008L
GL_POLYGON                        = 0x0009L

# ----------------------------------------------------------------------------
# OpenGL utility library

.importsGLU <- "
  gluLookAt(ddddddddd)v;
  gluPerspective(dddd)v;
"
rdcBind(.libGLU,.importsGLU, .callGLU)

#dyn.load(.libGLU)
#.gluLookAt <- getNativeSymbolInfo("gluLookAt")$address
#.gluPerspective <- getNativeSymbolInfo("gluPerspective")$address
#luLookAt <- function(eyeX,eyeY,eyeZ,centerX,centerY,centerZ,upX,upY,upZ)
#  rdcCall(.gluLookAt,"ddddddddd)v", eyeX,eyeY,eyeZ,centerX,centerY,centerZ,upX,upY,upZ)
#gluPerspective <- function(fovy,aspect,znear,zfar)
#  rdcCall(.gluPerspective,"dddd)v",fovy,aspect,znear,zfar)

# ----------------------------------------------------------------------------
# demo
init <- function()
{
  if (OS == "darwin")
  {
    NSApplicationLoad()
  }
  err <- SDL_Init(SDL_INIT_VIDEO)
  if (err != 0) error("SDL_Init failed")  
  surface <- SDL_SetVideoMode(512,512,32,SDL_DOUBLEBUF+SDL_OPENGL)
}

makeCubeDisplaylist <- function()
{
  vertices <- c(
  -1,-1,-1,
   1,-1,-1,
  -1, 1,-1,
   1, 1,-1,
  -1,-1, 1,
   1,-1, 1,
  -1, 1, 1,
   1, 1, 1
  )
  
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
  glVertexPointer(3, GL_DOUBLE, 0, rdcDataPtr(vertices) )
  
  glEnableClientState(GL_COLOR_ARRAY)  
  glColorPointer(3, GL_UNSIGNED_BYTE, 0, rdcDataPtr(colors) )
  
  displaylistId <- glGenLists(1)
  glNewList( displaylistId, GL_COMPILE )    
  glDrawElements(GL_TRIANGLES, 36L, GL_UNSIGNED_INT, rdcDataPtr(triangleIndices))
  glEndList()
  
  glDisableClientState(GL_VERTEX_ARRAY)
  glDisableClientState(GL_COLOR_ARRAY)
    
  return(displaylistId)
}
#buffers <- integer(2)  
#glGenBuffersARG(length(buffers), rdcDataPtr(buffers))
#glBindBufferARB(GL_ARRAY_BUFFER_ARB, buffers[[1]] )
#glBufferDataARB(GL_ARRAY_BUFFER_ARB, rdcSizeOf(typeof(vertices)) * length(vertices)  , rdcDataPtr(vertices) )


mainloop <- function()
{
  displaylistId <- makeCubeDisplaylist()
  eventobj <- malloc(256)
  blink <- 0
  tbase <- SDL_GetTicks()
  quit <- FALSE
  while(!quit)
  {
    tnow <- SDL_GetTicks()
    tdemo <- ( tnow - tbase ) / 1000
    
    glClearColor(0,0,blink,0)
    glClear(GL_COLOR_BUFFER_BIT)
    
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
    
    #glBegin(GL_TRIANGLES)
    #glVertex3d(-1,-1,-1)
    #glVertex3d( 1,-1,-1)
    #glVertex3d( 1, 1,-1)
    #glVertex3d(-1,-1,-1)
    #glVertex3d( 1, 1,-1)
    #glVertex3d(-1, 1,-1)
    #glEnd()

    SDL_GL_SwapBuffers()  
    
    SDL_WM_SetCaption(paste("time:", tdemo),0)    
    blink <- blink + 0.01
    while (blink > 1) blink <- blink - 1
    while( SDL_PollEvent(eventobj) != 0 )
    {
      eventType <- rdcUnpack1(eventobj, 0L, "c")       
      if (eventType == SDL_QUIT)
        quit <- TRUE
      else if (eventType == SDL_MOUSEBUTTONDOWN)
      {
        button <- rdcUnpack1(eventobj, 1L, "c")
        cat("button down: ",button,"\n") 
      }
    }
    glerr <- glGetError()
    if (glerr != 0)
    {
      cat("GL Error:", glerr)
      quit <- 1
    }
    SDL_Delay(30)
  }
  free(eventobj)
  #glDeleteLists(displaylistId, 1)
}

cleanup <- function()
{
  SDL_Quit()
}

run <- function()
{
  init()
  mainloop()
}
# run()

