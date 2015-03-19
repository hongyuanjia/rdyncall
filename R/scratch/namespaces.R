
makeNamespace <- function(name, version = NULL, lib = NULL) {
	impenv <- new.env(parent = .BaseNamespaceEnv, hash = TRUE)
	attr(impenv, "name") <- paste("imports", name, sep = ":")
	env <- new.env(parent = impenv, hash = TRUE)
	name <- as.character(as.name(name))
	version <- as.character(version)
	info <- new.env(hash = TRUE, parent = baseenv())
	assign(".__NAMESPACE__.", info, envir = env)
	assign("spec", c(name = name, version = version), 
			envir = info)
	setNamespaceInfo(env, "exports", new.env(hash = TRUE, 
					parent = baseenv()))
	setNamespaceInfo(env, "imports", list(base = TRUE))
	setNamespaceInfo(env, "path", file.path(lib, name))
	setNamespaceInfo(env, "dynlibs", NULL)
	setNamespaceInfo(env, "S3methods", matrix(NA_character_, 
					0L, 3L))
	assign(".__S3MethodsTable__.", new.env(hash = TRUE, 
					parent = baseenv()), envir = env)
	.Internal(registerNamespace(name, env))
	env
}

install <- function()
{
  name <- "GL"
  ns   <- makeNamespace(name)
  info <- ns$.__NAMESPACE__.
  # info$DLLs <- dyn.load("")
  with(ns,
    {
      dynbind("GL","glBegin()v;")
      .onUnload <- function()
      {
        .dynunload(.lib)
      }
    }
  )
  # ns$.packageName <- "stdio"
  namespaceExport( ns, ls(ns) )
  # attach(ns, name="dynport:GL")
  attachNamespace(ns)
}
install()


unloadNamespace("stdio")


# retrieve list of shared libraries loaded

library.dynam()
.dynLibs()
# load a specified library

.sys.lib.loc <- c("/opt/local/lib", "/opt/lib", "/usr/local/lib", "/usr/lib")

findLibPath <- function(name, lib.loc=.sys.lib.loc)
{
  for(i in lib.loc) {
	trypath <- file.path(i, paste("lib", name,.Platform$dynlib.ext,sep="") )
	if ( file.exists(trypath) ) return(trypath)
  }
  NULL
}

tests <- c("GL","SDL","expat")

sapply( tests, findLibPath )


