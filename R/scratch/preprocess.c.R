# TODO: Add comment
# 
# Author: dadler
###############################################################################



x <- "
#define AUDIO_S16 AUDIO_S16LSB
#define AUDIO_S16LSB 0x8010
#define AUDIO_S16MSB 0x9010
"




cpreprocessor <- function(text)
{
  grep(text)
}

