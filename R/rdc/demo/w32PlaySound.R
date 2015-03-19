# example: play sound

lib.winmm <- dyn.load("\\windows\\system32\\winmm.dll")
PlaySoundA <- lib.winmm$PlaySoundA
playsound <- function(path) rdcCall(PlaySoundA$address,"pii)v",path,0,0)
sample <- "c:\\windows\\Media\\tada.wav"
playsound(sample)
	