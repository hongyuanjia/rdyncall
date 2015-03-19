require"dynport"
dynport("CocoaEssentials")
NSApplicationLoad ()
dynport("SDL")
SDL_Init(SDL_INIT_VIDEO)
SDL_SetVideoMode(640,480,32,SDL_OPENGL)
dynport("GL")
quit = false
while not quit do
  glClearColor(0,0,1,1)
  glClear(GL.GL_COLOR_BUFFER_BIT)
  SDL_GL_SwapBuffers()
end

