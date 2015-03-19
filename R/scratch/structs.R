# struct tests:


# test embedded structures and inline assignments

parseStructInfos("
SDL_Rect{ssSS}x y w h ;
Test{II<SDL_Rect>II}a b rect c d;
")
x <- new.struct("Test")
print(x)

r <- new.struct("SDL_Rect")
r$x <- 1
r$y <- 2
r$w <- 3
r$h <- 4
x$rect <- r

# 

parseStructInfos("
SDL_ActiveEvent{CCC}type gain state ;
SDL_keysym{CiiS}scancode sym mod unicode ;
SDL_KeyboardEvent{CCC<SDL_keysym>}type which state keysym ;
SDL_MouseMotionEvent{CCCSSss}type which state x y xrel yrel ;
SDL_MouseButtonEvent{CCCCSS}type which button state x y ;
")

g

new <- function()
{
  x <- list()
  class(x) <- "test"
  return(x)
}

"$<-.test" <- function(x, index, value)
{
  cat("$<-\n")
  cat("nargs:", nargs(), "\n" )
  x[index] <- value
  return(x)
}

"$.test" <- function(x, index)
{
  cat("$\n")
  x[index]
}

x <- new()
x$a <- 23

x$a$b <- 23




str(x)

x$rect

registerStructInfos("
SDL_Rect{ssSS}x y w h ;
SDL_Surface{I*<SDL_PixelFormat>iiS*vi*<private_hwdata><SDL_Rect>II*<SDL_BlitMap>Ii}flags format w h pitch pixels offset hwdata clip_rect unused1 locked map format_version refcount ;
")


x <- new.struct("SDL_Rect")
x$x <- 10
x$y <- 10
x$w <- 100
x$h <- 100
str(x)

# ----------------------------------------------------------------------------
# tests


registerStructInfos("SDL_SysWMmsg{};
        SDL_SysWMEvent{C*<SDL_SysWMmsg>}type msg ;  
        ")

registerStructInfos(sdlStructs)
parseStructInfos("SDL_UserEvent{Ci*v*v}type code data1 data2 ;SDL_QuitEvent{C}type ;")
sigs <- "SDL_UserEvent{Ci*v*v}type code data1 data2 ;SDL_QuitEvent{C}type ;"

for (i in seq(along=sigs)) 
{
  if ( length(sigs[[i]]) < 2 ) next
  name     <- sigs[[i]][[1]]
  # eat white spaces
  name     <- gsub("[ \n\t]*","",name)      
  tail     <- unlist( strsplit(sigs[[i]][[2]], "\\}") )
  sig      <- tail[[1]]
  fields   <- unlist( strsplit( tail[[2]], "[ \n\t]+" ) )
  infos[[name]] <- list(sig, fields)
  infos[[name]] <- makeStructInfo(sig, fields)
}
return(infos)
}




registerStructInfos("SDL_version{CCC}major minor patch ;
        _SDL_TimerID{};
        SDL_SysWMmsg{};
        SDL_SysWMEvent{C*<SDL_SysWMmsg>}type msg ;  
        SDL_UserEvent{Ci*v*v}type code data1 data2 ;
        SDL_QuitEvent{C}type ;
        SDL_ExposeEvent{C}type ;
        SDL_ResizeEvent{Cii}type w h ;
        SDL_JoyButtonEvent{CCCC}type which button state ;
        SDL_JoyHatEvent{CCCC}type which hat value ;
        SDL_JoyBallEvent{CCCss}type which ball xrel yrel ;
        SDL_JoyAxisEvent{CCCs}type which axis value ;
        SDL_MouseButtonEvent{CCCCSS}type which button state x y ;
        SDL_MouseMotionEvent{CCCSSss}type which state x y xrel yrel ;
        SDL_keysym{CiiS}scancode sym mod unicode ;
        SDL_KeyboardEvent{CCC<SDL_keysym>}type which state keysym ;
        SDL_ActiveEvent{CCC}type gain state ;
        SDL_Rect{ssSS}x y w h ;
        SDL_Surface{I*<SDL_PixelFormat>iiS*vi*<private_hwdata><SDL_Rect>II*<SDL_BlitMap>Ii}flags format w h pitch pixels offset hwdata clip_rect unused1 locked map format_version refcount ;
        ")



sigs <- "SDL_ActiveEvent{CCC}type gain state ;SDL_AudioCVT{iSSd*Ciiidi}needed src_format dst_format rate_incr buf len len_cvt len_mult len_ratio filters filter_index ;"
sigs <- "SDL_AudioCVT{iSSd*Ciiidi}needed src_format dst_format rate_incr buf len len_cvt len_mult len_ratio filters filter_index ;"
parseStructInfos(sigs)
dsadsigs <- sdlStructs
sdlStructs <- "
    SDL_version{CCC}major minor patch ;
    _SDL_TimerID{};
    SDL_SysWMmsg{};
    SDL_SysWMEvent{C*<SDL_SysWMmsg>}type msg ;  
    SDL_UserEvent{Ci*v*v}type code data1 data2 ;
    SDL_QuitEvent{C}type ;
    SDL_ExposeEvent{C}type ;
    SDL_ResizeEvent{Cii}type w h ;
    SDL_JoyButtonEvent{CCCC}type which button state ;
    SDL_JoyHatEvent{CCCC}type which hat value ;
    SDL_JoyBallEvent{CCCss}type which ball xrel yrel ;
    SDL_JoyAxisEvent{CCCs}type which axis value ;
    SDL_MouseButtonEvent{CCCCSS}type which button state x y ;
    SDL_MouseMotionEvent{CCCSSss}type which state x y xrel yrel ;
    SDL_keysym{CiiS}scancode sym mod unicode ;
    SDL_KeyboardEvent{CCC<SDL_keysym>}type which state keysym ;
    SDL_ActiveEvent{CCC}type gain state ;
    _SDL_Joystick{};
    SDL_Rect{ssSS}x y w h ;
    WMcursor{};
    SDL_Cursor{<SDL_Rect>ss*C*C*<WMcursor>}area hot_x hot_y data mask save wm_cursor ;
    SDL_Overlay{Iiii*S**<private_yuvhwfuncs>*<private_yuvhwdata>II}format w h planes pitches pixels hwfuncs hwdata hw_overlay UnusedBits ;
    private_yuvhwdata{};
    private_yuvhwfuncs{};
    SDL_VideoInfo{IIIIIIIIIIIII*<SDL_PixelFormat>ii}hw_available wm_available UnusedBits1 UnusedBits2 blit_hw blit_hw_CC blit_hw_A blit_sw blit_sw_CC blit_sw_A blit_fill UnusedBits3 video_mem vfmt current_w current_h ;
    SDL_BlitMap{};
    private_hwdata{};
    SDL_Color{CCCC}r g b unused ;
    SDL_Palette{i*<SDL_Color>}ncolors colors ;
    SDL_PixelFormat{*<SDL_Palette>CCCCCCCCCCIIIIIC}palette BitsPerPixel BytesPerPixel Rloss Gloss Bloss Aloss Rshift Gshift Bshift Ashift Rmask Gmask Bmask Amask colorkey alpha ;
    SDL_CD{iiiii}id status numtracks cur_track cur_frame track ;
    SDL_CDtrack{CCSII}id type unused length offset ;
    SDL_AudioCVT{iSSd*Ciiidi}needed src_format dst_format rate_incr buf len len_cvt len_mult len_ratio filters filter_index ;
    SDL_AudioSpec{iSCCSSI*p*v}freq format channels silence samples padding size callback userdata ;
    "



old <- "SDL_version{CCC}major minor patch ;
    _SDL_TimerID{};
    SDL_SysWMEvent{C*<SDL_SysWMmsg>}type msg ;  
    SDL_SysWMmsg{};
    SDL_UserEvent{Ci*v*v}type code data1 data2 ;
    SDL_QuitEvent{C}type ;
    SDL_ExposeEvent{C}type ;
    SDL_ResizeEvent{Cii}type w h ;
    SDL_JoyButtonEvent{CCCC}type which button state ;
    SDL_JoyHatEvent{CCCC}type which hat value ;
    SDL_JoyBallEvent{CCCss}type which ball xrel yrel ;
    SDL_JoyAxisEvent{CCCs}type which axis value ;
    SDL_MouseButtonEvent{CCCCSS}type which button state x y ;
    SDL_MouseMotionEvent{CCCSSss}type which state x y xrel yrel ;
    SDL_KeyboardEvent{CCC<SDL_keysym>}type which state keysym ;
    SDL_ActiveEvent{CCC}type gain state ;
    _SDL_Joystick{};
    SDL_Cursor{<SDL_Rect>ss*C*C*<WMcursor>}area hot_x hot_y data mask save wm_cursor ;
    WMcursor{};
    SDL_Overlay{Iiii*S**<private_yuvhwfuncs>*<private_yuvhwdata>II}format w h planes pitches pixels hwfuncs hwdata hw_overlay UnusedBits ;
    private_yuvhwdata{};
    private_yuvhwfuncs{};
    SDL_VideoInfo{IIIIIIIIIIIII*<SDL_PixelFormat>ii}hw_available wm_available UnusedBits1 UnusedBits2 blit_hw blit_hw_CC blit_hw_A blit_sw blit_sw_CC blit_sw_A blit_fill UnusedBits3 video_mem vfmt current_w current_h ;
    SDL_Surface{I*<SDL_PixelFormat>iiS*vi*<private_hwdata><SDL_Rect>II*<SDL_BlitMap>Ii}flags format w h pitch pixels offset hwdata clip_rect unused1 locked map format_version refcount ;
    SDL_BlitMap{};
    private_hwdata{};
    SDL_PixelFormat{*<SDL_Palette>CCCCCCCCCCIIIIIC}palette BitsPerPixel BytesPerPixel Rloss Gloss Bloss Aloss Rshift Gshift Bshift Ashift Rmask Gmask Bmask Amask colorkey alpha ;
    SDL_Palette{i*<SDL_Color>}ncolors colors ;
    SDL_Color{CCCC}r g b unused ;
    SDL_Rect{ssSS}x y w h ;
    SDL_keysym{CiiS}scancode sym mod unicode ;
    SDL_CD{iiiii}id status numtracks cur_track cur_frame track ;
    SDL_CDtrack{CCSII}id type unused length offset ;
    SDL_AudioCVT{iSSd*Ciiidi}needed src_format dst_format rate_incr buf len len_cvt len_mult len_ratio filters filter_index ;
    SDL_AudioSpec{iSCCSSI*p*v}freq format channels silence samples padding size callback userdata ;
    SDL_RWops{*p*p*p*pI<$_7>}seek read write close type hidden ;
    SDL_Thread{};
    SDL_cond{};
    SDL_semaphore{};
    SDL_mutex{};
    _SDL_iconv_t{};
    lldiv_t{ll}quot rem ;
    ldiv_t{jj}quot rem ;
    div_t{ii}quot rem ;
    _iobuf{*ci*ciiii*c}_ptr _cnt _base _flag _file _charbuf _bufsiz _tmpfname ;
    $_8{i*v<$_9>}append h buffer ;
    $_10{i*<_iobuf>}autoclose fp ;
    $_11{*C*C*C}base here stop ;
    $_12{*v}data1 ;
    $_9{*vii}data size left ;
    "


.types <- list()

setStruct <- function(name, ...)
{
  x <- list(...)
  class(x) <- c("struct","type")
  .types[[name]] <<- x
}

setUnion <- function(name, ...)
{
  x <- list(...)
  class(x) <- c("union","type")
  .types[[name]] <<- x
}

getType <- function(name)
{
  .types[[name]]
}


setStruct("SDL_keysym", scancode="C", sym="i", mod="i", unicode="S" )
setStruct("SDL_KeyboardEvent", type="C", which="C", state="C", keysym="{SDL_keysym}")

parseTypeSignature("SDL_Event|C<SDL_ActiveEvent><SDL_KeyboardEvent><SDL_MouseMotionEvent><SDL_MouseButtonEvent><SDL_JoyAxisEvent><SDL_JoyBallEvent><SDL_JoyHatEvent><SDL_JoyButtonEvent><SDL_ResizeEvent><SDL_ExposeEvent><SDL_QuitEvent><SDL_UserEvent><SDL_SysWMEvent>|type active key motion button jaxis jball jhat jbutton resize expose quit user syswm ;")

setUnion("SDL_Event", 
    type="uchar", 
    action="SDL_ActiveEvent", 
    key="SDL_KeyboardEvent", 
    motion="SDL_MouseMotionEvent", 
    button="SDL_MouseButtonEvent", 
    jaxis="SDL_JoyAxisEvent", 
    jball="SDL_JoyBallEvent", 
    jbutton="SDL_JoyButtonEvent", 
    resize="SDL_ResizeEvent", 
    expose="SDL_ExposeEvent", 
    quit="SDL_QuitEvent", 
    user="SDL_UserEvent", 
    syswm="SDL_SysWMEvent")

.sizeof <- c(
    B=.Machine$sizeof.long,
    c=1L,
    C=1L,
    s=2L,
    S=2L,
    i=.Machine$sizeof.long,
    I=.Machine$sizeof.long,
    j=.Machine$sizeof.long,
    J=.Machine$sizeof.long,
    l=.Machine$sizeof.longlong,
    L=.Machine$sizeof.longlong,
    f=4L,
    d=8L,
    "*"=.Machine$sizeof.pointer,
    p=.Machine$sizeof.pointer,
    x=.Machine$sizeof.pointer,
    Z=.Machine$sizeof.pointer,
    v=0L    
)

align <- function(start, type)
{
  start %% sizeof(x)
}

sizeof <- function(x) 
{
  first <- substr(x,1,1)
  if (first == "<") {
    if ( substr(x, nchar(x), nchar(x) ) != ">" ) stop("invalid signature")
    typeName <- substr(x,2,nchar(x)-2)
    sizeof(getType(typeName))
  } else {
    .sizeof[[substr(x, 1,1)]]
  }
}

sizeof.struct <- function(x)
{
  total <- 0L
  for(i in x)
  {
    size  <- sizeof(i)
    total <- total + total %% size + size
  }
  return(total)
}


sizeof(struct("iii"))
sizeof(union("iii"))

