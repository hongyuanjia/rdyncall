\name{rdyncall-demos}
\alias{rdyncall-demos}
\title{rdyncall demos: Platform installation notes for required libraries}
\description{
The demos of the \pkg{rdyncall} package (see \code{demo(package="rdyncall")})
use shared libraries such as SDL, OpenGL and Expat via \code{\link{dynport}}s -
a dynamic binding approach which requires, that prebuilt binary shared library
files are already installed.

Depending on the host system, some libraries are officially a part of the
OS or Distribution, some others need to be installed to get the demos running.

As of the current version of this package, the installation of additional
shared C libraries need to be done manually. It follows an overview of 
the required libraries and installation notes for various operating-systems and distributions.
}
\section{Overview of Libraries}{
The following Libraries are used as 'run-time' pre-compiled binaries
for the particular target OS and Hardware platform.
Some notes on installation of additional run-time libraries
required for some rdyncall demos:

\tabular{lll}{
\strong{Lib}     \tab \strong{Description} \tab \strong{URL} \cr
\code{expat}     \tab XML Parser \tab \url{http://www.libexpat.org} \cr
\code{GL}        \tab Open Graphics Library \tab \url{http://opengl.org}, \url{http://www.mesa3d.org} \cr
\code{GLU}       \tab OpenGL Utility Library \tab see links above\cr
\code{glew}      \tab OpenGL Extension Wrangler Library \tab \url{http://glew.sourceforge.net/} \cr
\code{SDL}       \tab Multimedia Framework \tab \url{http://libsdl.org/} \cr
\code{SDL_mixer} \tab Music Format playing \tab \url{http://www.libsdl.org/projects/SDL_mixer/} \cr
\code{SDL_image} \tab Image Format loading \tab \url{http://www.libsdl.org/projects/SDL_image/}  \cr
\code{SDL_ttf}   \tab True Type Font rendering \tab \url{http://www.libsdl.org/projects/SDL_ttf/} \cr
\code{SDL_net}   \tab Network I/O \tab \url{http://www.libsdl.org/projects/SDL_net/} \cr 
}

In short: Place the shared libraries ( \code{*.DLL}, \code{*.so} or \code{*.dylib}) in a \emph{standard location} or
modify LD_LIBRARY_PATH(unix) or PATH(windows) so that \code{\link{dynfind}} can find the libraries. 

On Mac OS X framework folders are supported as well.
Place the \code{*.framework} folder at \code{/Library/Frameworks}.

Detailed platform-specific installation instructions follow up. 
}
\section{Windows Installation Notes}{
Download the \code{*.zip} files, unpack them and place the \code{*.DLL} files to a place within \code{PATH}.

32-Bit versions:

\tabular{ll}{
\strong{Lib}     \tab \strong{Download Link} \cr
\code{expat}     \tab \url{http://expat.sourceforge.net} (TODO:test installer) \cr
\code{GL}        \tab pre-installed \cr
\code{GLU}       \tab pre-installed \cr
\code{glew}      \tab \url{http://sourceforge.net/projects/glew/files/glew/1.7.0/glew-1.7.0-win32.zip/download} \cr
\code{SDL}       \tab \url{http://www.libsdl.org/release/SDL-1.2.14-win32.zip} \cr
\code{SDL_image} \tab \url{http://www.libsdl.org/projects/SDL_image/release/SDL_image-1.2.10-win32.zip} \cr
\code{SDL_mixer} \tab \url{http://www.libsdl.org/projects/SDL_mixer/release/SDL_mixer-1.2.11-win32.zip} \cr
\code{SDL_ttf}   \tab \url{http://www.libsdl.org/projects/SDL_ttf/release/SDL_ttf-2.0.10-win32.zip} \cr
\code{SDL_net}   \tab \url{http://www.libsdl.org/projects/SDL_net/release/SDL_net-1.2.7-win32.zip} \cr
}

64-Bit version:

\tabular{ll}{
\strong{Lib}     \tab \strong{Downdload Link} \cr
\code{expat}     \tab no prebuilt found (TODO: build) \cr
\code{GL}        \tab pre-installed \cr
\code{GLU}       \tab pre-installed \cr
\code{glew}      \tab \url{http://sourceforge.net/projects/glew/files/glew/1.7.0/glew-1.7.0-win64.zip/download} \cr
\code{SDL}       \tab \url{http://mamedev.org/tools/20100102/sdl-1.2.14-r5428-w64.zip} \cr
\code{SDL_image} \tab pre-built n/a \cr
\code{SDL_mixer} \tab pre-built n/a \cr
\code{SDL_ttf}   \tab pre-built n/a \cr
\code{SDL_net}   \tab pre-built n/a \cr
}

The prebuilt version of SDL from \url{http://www.drangon.org/mingw} did not work (exiting with OpenGL errors).
If you know of other resources for prebuilt 64-bit packages for SDL and expat, please report.
}
\section{Mac OS X Installation Notes}{
Download the \code{*.dmg} files, mount them (by double-click) and copy \code{*.framework} folders to \code{/Library/Frameworks}.
\tabular{ll}{
\strong{Lib}     \tab \strong{Download link} \cr
\code{expat}     \tab pre-installed \cr
\code{GL}        \tab pre-installed \cr
\code{GLU}       \tab pre-installed \cr
\code{glew}      \tab \code{port install glew} \cr
\code{SDL}       \tab \url{http://www.libsdl.org/release/SDL-1.2.14.dmg} \cr
\code{SDL_image} \tab \url{http://www.libsdl.org/projects/SDL_image/release/SDL_image-1.2.10.dmg} \cr
\code{SDL_mixer} \tab \url{http://www.libsdl.org/projects/SDL_mixer/release/SDL_mixer-1.2.11.dmg} \cr
\code{SDL_ttf}   \tab \url{http://www.libsdl.org/projects/SDL_ttf/release/SDL_ttf-2.0.10.dmg} \cr
\code{SDL_net}   \tab \url{http://www.libsdl.org/projects/SDL_net/release/SDL_net-1.2.7.dmg} \cr
}
}
\section{Linux/Debian Installation Notes}{
 
Debian Package installation via aptitude

\preformatted{aptitude install <pkg-names>..}

\tabular{ll}{
\strong{Lib}     \tab \strong{Debian Package name(s)} \cr
\code{expat}     \tab \code{libexpat1} (version 1.5.2 - already installed?)\cr 
\code{GL}        \tab \code{libgl1-mesa-glx} and \code{libgl1-mesa-dri} \cr
\code{GLU}       \tab \code{libglu1-mesa} \cr
\code{glew}      \tab \code{libglew1.5} \cr
\code{SDL}       \tab \code{libsdl1.2debian} and \code{libsdl1.2debian-<SOUNDSYS>} \cr
\code{SDL_image} \tab \code{libsdl-image1.2} \cr
\code{SDL_mixer} \tab \code{libsdl-mixer1.2} \cr
\code{SDL_ttf}   \tab \code{libsdl-ttf2.0} \cr
\code{SDL_net}   \tab \code{libsdl-net1.2} \cr
}
Depending on your sound system, \code{<SOUNDSYS>} should be explaced with one of the following: alsa, all, esd, arts, oss, nas or pulseaudio.
Tested with Debian 5 and 6 (lenny and squeeze).
}
\section{Linux/Fedora Installation Notes}{
\preformatted{pkcon install <pkgname>..}
\tabular{ll}{
\strong{Lib}     \tab \strong{RPM Package name} \cr  
\code{expat}     \tab \code{expat}              \cr
\code{GL}        \tab \code{mesa-libGL}         \cr
\code{GLU}       \tab \code{mesa-libGLU}        \cr
\code{glew}      \tab \code{glew}               \cr
\code{SDL}       \tab \code{SDL}                \cr  
\code{SDL_image} \tab \code{SDL_image}      \cr
\code{SDL_mixer} \tab \code{SDL_mixer}      \cr
\code{SDL_ttf}   \tab \code{SDL_ttf}        \cr
\code{SDL_net}   \tab \code{SDL_net}        \cr
}
Tested with Fedora 13 and 14 on x86 and x86_64.
}
\section{Linux/openSUSE Installation Notes}{
\preformatted{zypper in <pkgname>..}
\tabular{ll}{
\strong{Lib}     \tab \strong{Package Name} \cr
\code{SDL}       \tab \code{libSDL}         \cr 
\code{SDL_image} \tab \code{libSDL_image}   \cr
\code{SDL_mixer} \tab \code{libSDL_mixer}   \cr
\code{SDL_net}   \tab \code{libSDL_net}     \cr
\code{SDL_ttf}   \tab \code{libSDL_ttf}     \cr 
\code{glew}      \tab \code{libGLEW1_6}     \cr
}
openSUSE installation notes have not been confirmed.
}
\section{NetBSD Installation Notes}{

Installation via pkgsrc:

\preformatted{pkg_add <pkgname>..}

\tabular{ll}{
\strong{Lib}     \tab \strong{pkgsrc name} \cr
\code{expat}     \tab \code{expat} \cr
\code{GL}        \tab \code{Mesa} \cr
\code{GLU}       \tab \code{glu} \cr
\code{glew}      \tab \code{glew} \cr
\code{SDL}       \tab \code{SDL} \cr
\code{SDL_image} \tab \code{SDL_image} \cr
\code{SDL_mixer} \tab \code{SDL_mixer} \cr
\code{SDL_ttf}   \tab \code{SDL_ttf} \cr
\code{SDL_net}   \tab \code{SDL_net} \cr
}
}
\section{OpenBSD Installation Notes}{
Using packages:

\preformatted{pkg_add <pkgname>..}

\tabular{ll}{
\strong{Lib} \tab \strong{port name} \cr
\code{expat} \tab \code{expat} \cr
\code{SDL} \tab \code{SDL} \cr
\code{SDL_image} \tab \code{sdl-image} \cr
\code{SDL_mixer} \tab \code{sdl-mixer} \cr
\code{SDL_ttf} \tab not available \cr
\code{SDL_net} \tab \code{sdl-net} \cr
}

The SDL dynport failed on OpenBSD 4.8 - so no multimedia demos here - using the R 2.7 from the ports tree.
This must have been something to do with pthread discrepancies between SDL and R.
}
\section{FreeBSD Installation Notes}{
Using packages:

\preformatted{pkg_add -r <pkgname>..}

\tabular{ll}{
\strong{Lib}     \tab \strong{pkgname} \cr
\code{expat}     \tab \code{expat2} \cr
\code{GL}        \tab \code{xorg} \cr
\code{glew}      \tab \code{glew} \cr
\code{SDL}       \tab \code{sdl} \cr
\code{SDL_image} \tab \code{sdl_image} \cr
\code{SDL_mixer} \tab \code{sdl_mixer} \cr
\code{SDL_ttf}   \tab \code{sdl_ttf} \cr
\code{SDL_net}   \tab \code{sdl_net} \cr
}

}
\section{Solaris Installation Notes}{

OpenCSW offers prebuilt binaries for Solaris.
The installation of OpenCSW packages is done via \code{pkgutil}.

\preformatted{pkgutil -i <pkgname>..}

See \url{http://www.opencsw.org} for details on the OpenCSW project.

\tabular{ll}{
\strong{Lib} \tab \strong{pkgname} \cr
\code{expat}     \tab \code{expat} \cr
\code{GL}        \tab \code{mesalibs} \cr
\code{GLU}       \tab \code{mesalibs} \cr
\code{glew}      \tab \code{glew} \cr
\code{SDL} \tab \code{libsdl1_2_0} \cr
\code{SDL_image} \tab \code{sdlimage} \cr
\code{SDL_mixer} \tab \code{sdlmixer} \cr
\code{SDL_net}   \tab \code{sdlnet} \cr
\code{SDL_ttf}   \tab \code{sdlttf} \cr
}

}
