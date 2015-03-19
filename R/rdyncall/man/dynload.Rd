\name{dynload}
\alias{dynload}
\alias{.dynload}
\alias{.dynunload}
\alias{.dynsym}
\title{Loading of shared libraries and resolving of symbols (Alternative Framework)}
\description{Alternative framework for loading of shared libraries and resolving of symbols.
The framework offers \emph{automatic unload management} of shared libraries and
provides a direct interface to the dynamic linker of the OS.
}
\usage{
.dynload(libname, auto.unload=TRUE)
.dynsym(libhandle, symname, protect.lib=TRUE)
.dynunload(libhandle)
}
\arguments{
  \item{libname}{character string giving the pathname to a shared library in OS-specific notation.}
  \item{libhandle}{external pointer representing a handle to an opened library.}
  \item{symname}{character string specifying a symbolic name to be resolved.}
  \item{auto.unload}{logical, if \code{TRUE} a finalizer will be registered that will automatically unload the library.}
  \item{protect.lib}{logical, if \code{TRUE} resolved external pointers protect library handles from finalization.}
}
\value{
\code{.dynload} returns an external pointer \code{libhandle} on success. Otherwise NULL is returned, if the library is not found or the linkage failed.

\code{.dynsym} returns an external pointer \code{address} on success. Otherwise NULL is returned, if the address was invalid or the symbol has not been found.

\code{.dynunload} always returns \code{NULL}.    
}
\details{
\code{.dynload} loads a shared library into the current R process using the OS-specific dynamic linker interface. 
The \code{libname} is passed \emph{as-is} directly to the dynamic linker and thus is given in OS-specific notation - see below for details. 
On success, a handle to the library represented as an external pointer R objects is returned, otherwise \code{NULL}. 
If \code{auto.unload} is \code{TRUE}, a finalizer function is registered that will unload the library on garbage collection via \code{.dynunload}.

\code{.dynsym} looks up symbol names in loaded libraries and resolves them to memory addresses returned as external pointer R objects.
Otherwise \code{NULL} is returned. 
If \code{protect.lib} is \code{TRUE}, the library handle is \emph{protected} by resolved address external pointers from unloading.

\code{.dynunload} explicitly unreferences the loaded library specified by \code{libhandle}.

Setting both \code{auto.unload} and \code{protect.lib} to \code{TRUE}, libraries remain loaded as long as resolved symbols are in use, and they get automatic unloaded 
when no resolved symbols remain.

Dynamic linkers usually hold an internal link count, such that a library can be opened multiple times via \code{.dynload} 
- with a balanced number of calls to \code{.dynunload} that decreases the link count to unload the library again.

Similar functionality is available via \code{\link[base]{dyn.load}} and \code{getNativeSymbolInfo}, 
except that path names are filtered and no automatic unloading of libraries is supported.
}

\section{Shared library}{

Shared libraries are single files that contain compiled code, data and meta-information.
The code and data can be loaded and mapped to a process at run-time once.
Operating system platforms have slightly different schemes for naming, 
searching and linking options.

\tabular{lll}{
\strong{Platform}                      \tab \strong{Binary format}   \tab \strong{File Extension} \cr
Linux, BSD derivates and Sun Solaris   \tab ELF format               \tab \code{so}          \cr
Darwin / Apple Mac OS X                \tab Mach-O format            \tab \code{dylib}       \cr
Microsoft Windows                      \tab PE format                \tab \code{dll}         \cr
}

}

\section{Library search on Posix platforms (Linux,BSD,Sun Solaris)}{  

The following text is taken from the Linux \code{dlopen} manual page:

These search rules will only be applied to path names that do not contain an embedded '/'. 
\itemize{    
\item If the \code{LD_LIBRARY_PATH} environment variable is defined to contain a colon-separated list of
directories, then these are searched.

\item The cache file \code{/etc/ld.so.cache} is checked to see whether it contains an entry for filename.

\item The directories \code{/lib} and \code{/usr/lib} are searched (in that order).
}  
If the library has dependencies on other shared libraries, then these are also automatically 
loaded by the dynamic linker using the same rules.  
}
\section{Library search on Darwin (Mac OS X) platforms}{

The following text is taken from the Mac OS X dlopen manual page:

\code{dlopen()} searches for a compatible Mach-O file in the directories specified by a set of environment
variables and the process's current working directory.  When set, the environment variables must contain 
a colon-separated list of directory paths, which can be absolute or relative to the current working
directory. The environment variables are $LD_LIBRARY_PATH, $DYLD_LIBRARY_PATH, and $DYLD_FALLBACK_LIBRARY_PATH. 
The first two variables have no default value. The default value of $DYLD_FALLBACK_LIBRARY_PATH
is $HOME/lib;/usr/local/lib;/usr/lib.  \code{dlopen()} searches the directories specified in
the environment variables in the order they are listed.

When path doesn't contain a slash character (i.e. it is just a leaf name), \code{dlopen()} searches the following 
until it finds a compatible Mach-O file: $LD_LIBRARY_PATH, $DYLD_LIBRARY_PATH,
current working directory, $DYLD_FALLBACK_LIBRARY_PATH.

When path contains a slash (i.e. a full path or a partial path) \code{dlopen()} searches the following the
following until it finds a compatible Mach-O file: $DYLD_LIBRARY_PATH (with leaf name from path ), current
working directory (for partial paths), $DYLD_FALLBACK_LIBRARY_PATH (with leaf name from path ).
}
\section{Library search on Microsoft Windows platforms}{

The following text is taken from the Window SDK Documentation:

If no file name extension is specified [...], the default library extension 
\code{.dll} is appended. However, the file name string can include a trailing point character (.) to 
indicate that the [shared library] module name has no extension. When no path is specified, the function searches 
for loaded modules whose base name matches the base name of the module to be loaded. 
If the name matches, the load succeeds. Otherwise, the function searches for the file in the 
following sequence:

\itemize{

\item The directory from which the application loaded. 
\item The current directory. 
\item The system directory. Use the GetSystemDirectory Win32 API function to get the path of this directory.
\item The 16-bit system directory. There is no function that obtains the path of this directory, but it is searched. Windows Me/98/95:  This directory does not exist.
\item The Windows directory. Use the GetWindowsDirectory Win32 API function to get the path of this directory. 
\item The directories that are listed in the PATH environment variable. 
}

Windows Server 2003, Windows XP SP1:  The default value of \preformatted{HKLM\\System\\CurrentControlSet\\Control\\Session Manager\\SafeDllSearchMode} is 1 (current directory is searched after the system and Windows directories).

Windows XP:  If \preformatted{HKLM\\System\\CurrentControlSet\\Control\\Session Manager\\SafeDllSearchMode} is 1, the current directory is searched after the system and Windows directories, but before the directories in the PATH environment variable. The default value is 0 (current directory is searched before the system and Windows directories).


The first directory searched is the one directory containing the image file used to create the calling process. Doing this allows private dynamic-link library (DLL) files associated with a process to be found without adding the process's installed directory to the PATH environment variable.

The search path can be altered using the \code{SetDllDirectory} function. This solution is recommended instead of using \code{SetCurrentDirectory} or hard-coding the full path to the DLL.

If a path is specified and there is a redirection file for the application, the function searches for the module in the application's directory. If the module exists in the application's directory, the LoadLibrary function ignores the specified path and loads the module from the application's directory. If the module does not exist in the application's directory, LoadLibrary loads the module from the specified directory. For more information, see Dynamic Link Library Redirection from the Windows SDK Documentation.
}
\section{Portability}{
The implementation is based on the \emph{dynload} library (part of the DynCall project) which has been ported
to all major R platforms (ELF (Linux,BSD,Solaris), Mach-O (Mac OS X) and Portable Executable (Win32/64)). 
}
\seealso{
  This facility is used by \code{\link{dynfind}} and \code{\link{dynbind}}.
  Similar functionality is available from \code{\link[base]{dyn.load}} and \code{\link[base]{getNativeSymbolInfo}}.
}
\keyword{programming}
\keyword{interface}
