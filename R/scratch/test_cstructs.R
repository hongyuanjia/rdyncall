sdlLib <- dynload("SDL")
._SDL_SetVideoMode <- sdlLib$SDL_SetVideoMode
._SDL_Init <- sdlLib$SDL_Init
err  <- .dyncall.cdecl(._SDL_Init, "i)i", SDL_INIT_VIDEO)
surf <- .dyncall.cdecl(._SDL_SetVideoMode, "iiii)*<SDL_Surface>", 640,480,32,SDL_DOUBLEBUF+SDL_OPENGL)

