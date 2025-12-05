library(rdyncall)
dynport(SDL)
dynport(EGL)
dynbind("X11", "XOpenDisplay(Z)p;")

init <- function() {
SDL_Init(SDL_INIT_VIDEO)
srf <- SDL_SetVideoMode(640,480,32,SDL_SWSURFACE)
dpy <- XOpenDisplay(NULL)
egl <- eglGetDisplay(dpy)
if (is.nullptr(egl)) {
  error("failed: eglGetDisplay")
}
status <- eglInitialize(egl,NULL,NULL)
if (!status) {
  error("failed: eglInitialize")
}
numConfigOuts <- integer(1)
g_configAttribs <- as.integer(c(
	EGL_RED_SIZE, 5,
	EGL_GREEN_SIZE, 6,
	EGL_BLUE_SIZE, 5,
	EGL_DEPTH_SIZE, 16,
	EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
	EGL_RENDERABLE_TYPE, EGL_OPENGL_ES_BIT,
	EGL_BIND_TO_TEXTURE_RGBA, EGL_TRUE,
	EGL_NONE
))

g_eglConfig <- raw(4)

s <- eglChooseConfig(egl, g_configAttribs, g_eglConfig, 1, numConfigOuts)
if (s != EGL_TRUE || numConfigOuts == 0) {
  error("failed: eglChooseConfig")
}


}

init()



