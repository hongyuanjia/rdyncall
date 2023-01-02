
# Package: rdyncall 
# File: demo/playtune.R
# Description: play a nice oldsch00l tune.
# Uses: SDL/audio, SDL_mixer

rsrc <- function(name) system.file(paste("demo-files",name,sep=.Platform$file.sep), package="rdyncall")
music <- NULL
init <- function()
{
  require(rdyncall)
  dynport(SDL)
  SDL_Init(SDL_INIT_AUDIO)
  dynport(SDL_mixer)
  Mix_OpenAudio(MIX_DEFAULT_FREQUENCY, MIX_DEFAULT_FORMAT, 2, 4096)
  music <<- Mix_LoadMUS(rsrc("external.xm"))
}
cleanup <- function()
{
  stopTune()
  Mix_FreeMusic(music)
  Mix_CloseAudio()
  SDL_Quit()
}

playTune <- function() {
  Mix_PlayMusic(music, 1) 
  cat("playing music... [to stop, call 'stopTune()']\n")
}
pauseTune <- function() Mix_PauseMusic()
stopTune <- function() Mix_HaltMusic()  

init()
playTune()

