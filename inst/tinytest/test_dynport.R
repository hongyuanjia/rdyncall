expect_dynport_portfile_error <- function(lines, pattern) {
    portfile <- tempfile(fileext = ".dynport")
    writeLines(lines, portfile)
    expect_error(dynport(rdyncall_invalid_dynport, portfile = portfile), pattern)
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
expect_dynport_portfile_error("Package:", "unexpected")
expect_dynport_portfile_error("Package: SDL2", "object 'Package'")

# version
expect_dynport_portfile_error("Version: -", "specification")
expect_dynport_portfile_error(c("Version: 1", "  2"), "single string")
expect_dynport_portfile_error("Version:", "unexpected")
expect_dynport_portfile_error("Version: 2.1", "object 'Version'")

# library
expect_dynport_portfile_error(c("Library: com", " |.o"), "file name")
expect_dynport_portfile_error(c("Library: a.o", " b"), "object 'Library'")

# enum
expect_dynport_portfile_error("Enum:  ", "Both")
expect_dynport_portfile_error("Enum: a = 1", "Both")
expect_dynport_portfile_error("Enum/test: a = 1 b = 2", "member specification")
expect_dynport_portfile_error("Enum/test: a = 1.2", "member value")
expect_dynport_portfile_error(c("Enum/test: a = 1", " b = 2"), "object 'Enum'")

# struct
expect_dynport_portfile_error(c("Struct:", "  "), "unexpected")
expect_dynport_portfile_error("Struct:", "unexpected")
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
expect_dynport_portfile_error("Struct: test{ii} a b", "unexpected")

# union
expect_dynport_portfile_error(c("Union:", "  "), "unexpected")
expect_dynport_portfile_error("Union:", "unexpected")
expect_dynport_portfile_error(c("Union: test", " }"), "\\{")
expect_dynport_portfile_error(c("Union: test{", " }}"), "\\}")
expect_dynport_portfile_error("Union: a = 1", "\\{")
expect_dynport_portfile_error(c("Union: s", " {1"), "\\}")
expect_dynport_portfile_error("Union: {}", "name")
expect_dynport_portfile_error("Union: test{ab}", "type name")
expect_dynport_portfile_error("Union: test{ii}a", "number")
expect_dynport_portfile_error("Union: test{i} a b", "number")
expect_dynport_portfile_error("Union: test{d} a:1", "integer")
expect_dynport_portfile_error("Union: test{ii} a b", "unexpected")

parsed_bits <- rdyncall:::dynport_parse_struct("Flags{IIII} a:1 b:3 :4 c:8;")
expect_equal(parsed_bits$Flags$size, 4L)
expect_equal(parsed_bits$Flags$fields$name, c("a", "b", "", "c"))
expect_equal(parsed_bits$Flags$fields$bit_width, c(1L, 3L, 4L, 8L))

# function
expect_dynport_portfile_error(c("Function:", "  "), "unexpected")
expect_dynport_portfile_error("Function:", "unexpected")
expect_dynport_portfile_error(c("Function: test", " )"), "Invalid specification")
expect_dynport_portfile_error(c("Function: test(", " ))"), "Extra")
expect_dynport_portfile_error("Function: a = 1", "spec")
expect_dynport_portfile_error(c("Function: s", " (1"), "\\)")
expect_dynport_portfile_error("Function: ()", "name")
expect_dynport_portfile_error("Function: test(ab)", "return")
expect_dynport_portfile_error("Function: test(ii)a", "type name")
expect_dynport_portfile_error("Function: test(i) i a b", "number")
expect_dynport_portfile_error("Function: test(ii)i a a", "name")
expect_dynport_portfile_error("Function: test(ii)i a b", "unexpected")

empty_port <- tempfile(fileext = ".dynport")
expect_true(file.create(empty_port))
empty_envname <- "dynport:rdyncall_empty_dynport"
if (empty_envname %in% search()) {
    detach(empty_envname, character.only = TRUE)
}
expect_silent(dynport(rdyncall_empty_dynport, portfile = empty_port))
expect_true(empty_envname %in% search())
detach(empty_envname, character.only = TRUE)
expect_false(empty_envname %in% search())
