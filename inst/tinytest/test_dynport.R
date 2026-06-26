expect_dynport_portfile_error <- function(lines, pattern) {
    portfile <- tempfile(fileext = ".dynport")
    writeLines(lines, portfile)
    expect_error(rdyncall:::dynport_read(portfile), pattern)
}

write_dynport <- function(lines) {
    portfile <- tempfile(fileext = ".dynport")
    writeLines(lines, portfile)
    portfile
}

unload_test_package <- function(package) {
    search_name <- paste0("package:", package)
    if (search_name %in% search()) {
        detach(search_name, character.only = TRUE)
    }
    if (package %in% loadedNamespaces()) {
        unloadNamespace(package)
    }
}

libc_names <- c("msvcrt", "c", "c.so.6")

env <- new.env()
expect_equal(
    class(bind <- dynbind(
        libc_names, "qsort(piip)v;",
        pattern = "qsort", replace = "c_qsort", envir = env
    )),
    "dynbind.report"
)
expect_true(exists("c_qsort", env, inherits = FALSE))

missing_repo <- tempfile("rdyncall-missing-dynport-repo")
expect_true(dir.create(missing_repo))
expect_error(dynport(rdyncall_missing_dynport, repo = missing_repo), "not found")

# package
expect_dynport_portfile_error("Package: a-", "ASCII")
expect_dynport_portfile_error(c("Package: a", "  b"), "single string")
expect_dynport_portfile_error("Package: a", "two character")
expect_dynport_portfile_error("Package: .a", "letter")

# version
expect_dynport_portfile_error("Version: -", "specification")
expect_dynport_portfile_error(c("Version: 1", "  2"), "single string")

# library
expect_dynport_portfile_error(c("Library: com", " |.o"), "file name")

# constant
expect_dynport_portfile_error("Constant: a", "constant specification")
expect_dynport_portfile_error("Constant: a-b = 1", "constant name")
expect_dynport_portfile_error("Constant: a = b", "constant value")

# enum
expect_dynport_portfile_error("Enum: a = 1", "Invalid specification")
expect_dynport_portfile_error("Enum/test: a = 1 b = 2", "member specification")
expect_dynport_portfile_error("Enum/test: a = 1.2", "member value")

# struct
expect_dynport_portfile_error(c("Struct: test", " }"), "\\{")
expect_dynport_portfile_error(c("Struct: test{", " }}"), "\\}")
expect_dynport_portfile_error("Struct: a = 1", "\\{")
expect_dynport_portfile_error(c("Struct: s", " {1"), "\\}")
expect_dynport_portfile_error("Struct: {}", "name")
expect_dynport_portfile_error("Struct: test{ab}", "type name")
expect_dynport_portfile_error("Struct: test{ii}a", "number")
expect_dynport_portfile_error("Struct: test{i} a b", "number")
expect_dynport_portfile_error("Struct: test{d} a:1", "integer")
expect_dynport_portfile_error("Struct: test{I} a:33", "exceeds")
expect_dynport_portfile_error("Struct: test{I} a:0", "zero-width")
expect_dynport_portfile_error("Struct: test{C} c @pack(3)", "power-of-two")
expect_dynport_portfile_error("Struct: test{C} c @packed @pack(1)", "duplicate")
expect_dynport_portfile_error("Struct: test{C} c @bytepack", "unknown")
expect_dynport_portfile_error("Struct: test{<Bad} x", "<Bad")

packed_struct <- rdyncall:::dynport_parse_struct("PackedDyn{Cd} c d @packed;")
expect_equal(packed_struct$PackedDyn$size, 9L)
expect_equal(packed_struct$PackedDyn$align, 1L)
expect_equal(packed_struct$PackedDyn$fields$offset, c(0L, 1L))

# union
expect_dynport_portfile_error(c("Union: test", " }"), "\\{")
expect_dynport_portfile_error(c("Union: test{", " }}"), "\\}")
expect_dynport_portfile_error("Union: a = 1", "\\{")
expect_dynport_portfile_error(c("Union: s", " {1"), "\\}")
expect_dynport_portfile_error("Union: {}", "name")
expect_dynport_portfile_error("Union: test{ab}", "type name")
expect_dynport_portfile_error("Union: test{ii}a", "number")
expect_dynport_portfile_error("Union: test{i} a b", "number")
expect_dynport_portfile_error("Union: test{d} a:1", "integer")
expect_dynport_portfile_error("Union: test{C} c @align(3)", "power-of-two")

aligned_union <- rdyncall:::dynport_parse_union("AlignedDynUnion{Ci} c i @align(8);")
expect_equal(aligned_union$AlignedDynUnion$size, 8L)
expect_equal(aligned_union$AlignedDynUnion$align, 8L)

parsed_bits <- rdyncall:::dynport_parse_struct("Flags{IIII} a:1 b:3 :4 c:8;")
expect_equal(parsed_bits$Flags$size, 4L)
expect_equal(parsed_bits$Flags$fields$name, c("a", "b", "", "c"))
expect_equal(parsed_bits$Flags$fields$bit_width, c(1L, 3L, 4L, 8L))

# function
expect_dynport_portfile_error(c("Function: test", " )"), "Invalid specification")
expect_dynport_portfile_error(c("Function: test(", " ))"), "Extra")
expect_dynport_portfile_error("Function: a = 1", "spec")
expect_dynport_portfile_error(c("Function: s", " (1"), "\\)")
expect_dynport_portfile_error("Function: ()", "name")
expect_dynport_portfile_error("Function: test(ab)", "return")
expect_dynport_portfile_error("Function: test(ii)a", "type name")
expect_dynport_portfile_error("Function: test(C[2])v arg", "C\\[2\\].*argument")
expect_dynport_portfile_error("Function: test(i) i a b", "number")
expect_dynport_portfile_error("Function: test(ii)i a a", "name")
expect_dynport_portfile_error("Function: test(i.i)v x y", "Variadic marker")

inline_variadic <- rdyncall:::dynport_parse_function("printf(Z.)i fmt ...;")
expect_true(inline_variadic$printf$variadic)
expect_equal(inline_variadic$printf$argument$sig, "Z")
expect_equal(inline_variadic$printf$argument$name, "fmt")

metadata_variadic <- rdyncall:::dynport_read(write_dynport(c(
    "Package: VarMeta",
    "Function:",
    "    printf(Z)i fmt;",
    "Variadic:",
    "    printf"
)))
expect_true(metadata_variadic$Function$printf$variadic)

signature_variadic <- rdyncall:::dynport_read(write_dynport(c(
    "Package: VarSig",
    "Variadic:",
    "    snprintf(*cJZ)i text maxlen fmt;"
)))
expect_true(signature_variadic$Function$snprintf$variadic)
expect_equal(signature_variadic$Function$snprintf$argument$name, c("text", "maxlen", "fmt"))

expect_dynport_portfile_error(c(
    "Package: VarMissing",
    "Variadic:",
    "    printf"
), "not defined")

parsed_port <- rdyncall:::dynport_read(write_dynport(c(
    "Package: ParsePort",
    "Version: 1.0.0",
    "Constant:",
    "    PARSE_INT=32",
    "    PARSE_WIDE=2147483648",
    "    PARSE_STR=\"hello\"",
    "Variadic:",
    "    parse_printf(Z)i fmt;"
)))
expect_equal(parsed_port$Constant$PARSE_INT, 32L)
expect_equal(parsed_port$Constant$PARSE_WIDE, 2147483648)
expect_equal(parsed_port$Constant$PARSE_STR, "hello")
expect_true(parsed_port$Function$parse_printf$variadic)

empty_port <- tempfile(fileext = ".dynport")
expect_true(file.create(empty_port))
expect_error(dynport(rdyncall_empty_dynport, portfile = empty_port), "Empty")

opaque <- rdyncall:::dynport_parse_struct("Opaque{};")
expect_equal(opaque$Opaque$size, 0L)
expect_equal(opaque$Opaque$align, 1L)
expect_equal(nrow(opaque$Opaque$fields), 0L)

sdl3_portfile <- system.file("dynports", "SDL3.dynport", package = "rdyncall", mustWork = TRUE)
sdl3 <- rdyncall:::dynport_read(sdl3_portfile)
expect_equal(as.character(sdl3$Package), "SDL3")
expect_equal(sdl3$Constant$SDL_INIT_VIDEO, 32L)
expect_true("SDL_GetPlatform" %in% names(sdl3$Function))
expect_true(sdl3$Function$SDL_Log$variadic)
expect_true("SDL_FRect" %in% names(sdl3$Struct))
expect_equal(
    length(rdyncall:::dynport_wrapper_formals(
        rdyncall:::dynport_function_arg_names(sdl3$Function$SDL_GetNumAllocations)
    )),
    0L
)

local({
    portfile <- write_dynport(c(
        "Package: TinyPort",
        "Version: 1.0.0",
        "Constant:",
        "    TINY_CONST=42",
        "    TINY_STR=\"tiny\"",
        "Enum/TinyEnum:",
        "    TINY_ONE=1",
        "Struct:",
        "    TinyOpaque{};"
    ))
    lib <- tempfile("rdyncall-dynport-lib")
    package <- "dyn.TinyPort"
    unload_test_package(package)
    on.exit(unload_test_package(package), add = TRUE)

    pkg <- dynport(tiny, portfile = portfile, lib = lib, quiet = TRUE)
    expect_equal(pkg, package)
    expect_true(dir.exists(file.path(lib, package)))
    expect_true(package %in% loadedNamespaces())
    expect_equal(getExportedValue(package, "TINY_CONST"), 42L)
    expect_equal(getExportedValue(package, "TINY_STR"), "tiny")
    expect_equal(getExportedValue(package, "TINY_ONE"), 1L)
    expect_true("package:dyn.TinyPort" %in% search())
})

local({
    portfile <- write_dynport(c(
        "Package: ClearPort",
        "Version: 1.0.0",
        "Enum/ClearEnum:",
        "    CLEAR_ONE=1"
    ))
    lib <- tempfile("rdyncall-dynport-lib")
    package <- "dyn.ClearPort"
    ordinary <- file.path(lib, "ordinary")
    expect_true(dir.create(ordinary, recursive = TRUE))
    writeLines(c(
        "Package: ordinary",
        "Version: 1.0.0",
        "Title: Ordinary",
        "Description: Ordinary package.",
        "License: MIT"
    ), file.path(ordinary, "DESCRIPTION"))
    unload_test_package(package)
    on.exit(unload_test_package(package), add = TRUE)

    expect_silent(dynport(clear, portfile = portfile, lib = lib, quiet = TRUE))
    expect_true(package %in% loadedNamespaces())
    removed <- dynport_clear_lib(lib)
    expect_true(package %in% basename(removed))
    expect_false(package %in% loadedNamespaces())
    expect_false(dir.exists(file.path(lib, package)))
    expect_true(dir.exists(ordinary))
})

local({
    portfile <- write_dynport(c(
        "Package: PrefixPort",
        "Version: 1.0.0",
        "Enum/PrefixEnum:",
        "    PREFIX_ONE=1"
    ))
    lib <- tempfile("rdyncall-dynport-lib")
    old <- options(rdyncall.dynport.package.prefix = "zz.")
    on.exit(options(old), add = TRUE)

    path <- dynport_install_package(prefix, portfile = portfile, lib = lib, quiet = TRUE)
    expect_true(dir.exists(file.path(lib, "zz.PrefixPort")))
    expect_equal(attr(path, "package"), "zz.PrefixPort")

    path <- dynport_install_package(prefix, portfile = portfile, package = "ShortPort", lib = lib, quiet = TRUE)
    expect_true(dir.exists(file.path(lib, "ShortPort")))
    expect_equal(attr(path, "package"), "ShortPort")
})

local({
    portfile <- write_dynport(c(
        "Package: ConflictPort",
        "Version: 1.0.0",
        "Enum/ConflictEnum:",
        "    CONFLICT_ONE=1"
    ))
    lib <- tempfile("rdyncall-dynport-lib")
    fake <- file.path(lib, "dyn.ConflictPort")
    expect_true(dir.create(fake, recursive = TRUE))
    writeLines(c(
        "Package: dyn.ConflictPort",
        "Version: 1.0.0",
        "Title: Fake",
        "Description: Fake package.",
        "License: MIT"
    ), file.path(fake, "DESCRIPTION"))
    expect_error(
        dynport_install_package(conflict, portfile = portfile, lib = lib, quiet = TRUE),
        "not generated"
    )
})

local({
    portfile <- write_dynport(c(
        "Package: RebuildPort",
        "Version: 1.0.0",
        "Enum/RebuildEnum:",
        "    REBUILD_ONE=1"
    ))
    lib <- tempfile("rdyncall-dynport-lib")
    expect_silent(dynport_install_package(rebuild, portfile = portfile, lib = lib, quiet = TRUE))
    writeLines(c(
        "Package: RebuildPort",
        "Version: 1.0.0",
        "Enum/RebuildEnum:",
        "    REBUILD_ONE=2"
    ), portfile)
    expect_error(
        dynport_install_package(rebuild, portfile = portfile, lib = lib, quiet = TRUE),
        "rebuild = TRUE"
    )
    expect_silent(dynport_install_package(rebuild, portfile = portfile, lib = lib, rebuild = TRUE, quiet = TRUE))
})

local({
    if (!is.null(dynfind(libc_names))) {
        portfile <- write_dynport(c(
            "Package: CString",
            "Version: 1.0.0",
            "Library:",
            "    msvcrt",
            "    c",
            "    c.so.6",
            "Function:",
            "    strlen(Z)L str;"
        ))
        lib <- tempfile("rdyncall-dynport-lib")
        package <- "dyn.CString"
        unload_test_package(package)
        on.exit(unload_test_package(package), add = TRUE)

        expect_silent(dynport(cstring, portfile = portfile, lib = lib, quiet = TRUE))
        strlen <- getExportedValue(package, "strlen")
        expect_equal(formalArgs(strlen), "str")
        expect_equal(strlen("abc"), 3)
    }
})

local({
    libc <- dynfind(libc_names)
    if (!is.null(libc) && !is.null(dynsym(libc, "snprintf"))) {
        portfile <- write_dynport(c(
            "Package: CSnprintf",
            "Version: 1.0.0",
            "Library:",
            "    msvcrt",
            "    c",
            "    c.so.6",
            "Function:",
            "    snprintf(*cJZ)i text maxlen fmt;",
            "Variadic:",
            "    snprintf"
        ))
        lib <- tempfile("rdyncall-dynport-lib")
        package <- "dyn.CSnprintf"
        unload_test_package(package)
        on.exit(unload_test_package(package), add = TRUE)

        port <- rdyncall:::dynport_read(portfile)
        src <- rdyncall:::dynport_create_package_source(port, portfile, "csnprintf", package, "md5")
        on.exit(unlink(src, recursive = TRUE, force = TRUE), add = TRUE)
        rd <- file.path(src, "man", "snprintf.Rd")
        expect_true(file.exists(rd))
        rd_text <- readLines(rd)
        expect_true(any(grepl("\\\\title\\{snprintf\\}", rd_text)))
        expect_true(any(grepl("\\\\item\\{text\\}", rd_text)))
        expect_true(any(grepl("\\\\item\\{\\.varargs\\}", rd_text)))
        expect_silent(tools::parse_Rd(rd))

        expect_silent(dynport(csnprintf, portfile = portfile, lib = lib, quiet = TRUE))
        snprintf <- getExportedValue(package, "snprintf")
        expect_equal(formalArgs(snprintf), c("text", "maxlen", "fmt", "...", ".varargs"))

        buf <- raw(32L)
        n <- snprintf(buf, length(buf), "%d", 42L, .varargs = "i")
        expect_equal(n, 2L)
        expect_equal(rawToChar(buf[seq_len(n)]), "42")
    }
})

local({
    rlib <- dynfind("R")
    if (!is.null(rlib) && !is.null(dynsym(rlib, "rdyncall_missing_dynport_symbol"))) {
        stop("Unexpected test fixture symbol exists in R library.", call. = FALSE)
    }
    if (!is.null(rlib)) {
        portfile <- write_dynport(c(
            "Package: MissingSymbol",
            "Version: 1.0.0",
            "Library:",
            "    R",
            "Function:",
            "    rdyncall_missing_dynport_symbol()v;"
        ))
        lib <- tempfile("rdyncall-dynport-lib")
        package <- "dyn.MissingSymbol"
        unload_test_package(package)
        on.exit(unload_test_package(package), add = TRUE)

        expect_silent(dynport(missing_symbol, portfile = portfile, lib = lib, quiet = TRUE))
        expect_error(
            getExportedValue(package, "rdyncall_missing_dynport_symbol")(),
            "Unresolved DynPort symbol 'rdyncall_missing_dynport_symbol'"
        )
    }
})

local({
    rlib <- dynfind("R")
    if (!is.null(rlib) && !is.null(dynsym(rlib, "Rprintf"))) {
        portfile <- write_dynport(c(
            "Package: RVariadic",
            "Version: 1.0.0",
            "Library:",
            "    R",
            "Variadic:",
            "    Rprintf(Z)v format;"
        ))
        lib <- tempfile("rdyncall-dynport-lib")
        package <- "dyn.RVariadic"
        unload_test_package(package)
        on.exit(unload_test_package(package), add = TRUE)

        expect_silent(dynport(rvariadic, portfile = portfile, lib = lib, quiet = TRUE))
        output <- capture.output(
            result <- getExportedValue(package, "Rprintf")("dynport %d", 2L, .varargs = "i")
        )
        expect_null(result)
        expect_true(any(grepl("dynport 2", output, fixed = TRUE)))
    }
})
