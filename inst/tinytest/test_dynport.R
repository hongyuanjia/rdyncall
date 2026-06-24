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

env <- new.env()
expect_equal(
    class(bind <- dynbind(
        c("msvcrt", "c", "c.so.6"), "qsort(piip)v;",
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
expect_true("SDL_GetPlatform" %in% names(sdl3$Function))
expect_true("SDL_FRect" %in% names(sdl3$Struct))

local({
    portfile <- write_dynport(c(
        "Package: TinyPort",
        "Version: 1.0.0",
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
    expect_equal(getExportedValue(package, "TINY_ONE"), 1L)
    expect_true("package:dyn.TinyPort" %in% search())
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
    if (!is.null(dynfind(c("msvcrt", "c", "c.so.6")))) {
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
        expect_equal(getExportedValue(package, "strlen")("abc"), 3)
    }
})
