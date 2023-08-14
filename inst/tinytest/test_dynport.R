env <- new.env()
expect_equal(
    class(bind <- dynbind(
        c("msvcrt", "c", "c.so.6"), "qsort(piip)v;",
        pattern = "qsort", replace = "c_qsort", envir = env
    )),
    "dynbind.report"
)
expect_true(exists("c_qsort", env, inherits = FALSE))

# package
expect_error(dynport_parse_package("a-", 2),     "ASCII")
expect_error(dynport_parse_package("a\n  b", 2), "single string")
expect_error(dynport_parse_package("a", 2),      "two character")
expect_error(dynport_parse_package(".a", 2),     "a letter")
expect_equal(dynport_parse_package("", 2),       NULL)
expect_equal(dynport_parse_package("SDL2", 2),   "SDL2")

# version
expect_error(dynport_parse_version("-", 2),      "specification")
expect_error(dynport_parse_version("1\n2", 2),   "single string")
expect_equal(dynport_parse_version(c(""), 2),    NULL)
expect_equal(dynport_parse_version(c("2.1"), 2), numeric_version(2.1))

# library
expect_error(dynport_parse_library("com\n |.o", 2),  "file name")
expect_equal(dynport_parse_library(c("a.o\n b"), 2), c("a.o", "b"))

# enum
expect_null(dynport_parse_enum("  ", 2, "Enum"))
expect_error(dynport_parse_enum("a = 1", 2, "Enum"), "spec")
expect_error(dynport_parse_enum("a = 1 b = 2", 2, "Enum/test"), "member spec")
expect_error(dynport_parse_enum("  a = 1.2", 2, "Enum/test"), "member value")
expect_equal(
    dynport_parse_enum("a = 1\nb = 2", 2, "Enum/test"),
    list(test = c(a = 1L, b = 2L))
)

# struct
expect_null(dynport_parse_struct("  \n ", 2))
expect_null(dynport_parse_struct("", 2))
expect_error(dynport_parse_struct("test\n}", 2),     "\\{")
expect_error(dynport_parse_struct("test{\n}}", 2),   "\\}")
expect_error(dynport_parse_struct("a = 1", 2),       "\\{")
expect_error(dynport_parse_struct("s\n{1", 2),       "\\}")
expect_error(dynport_parse_struct("{}", 2),          "name")
expect_error(dynport_parse_struct("test{ab}", 2),    "type name")
expect_error(dynport_parse_struct("test{ii}a", 2),   "number")
expect_error(dynport_parse_struct("test{i} a b", 2), "number")
expect_equal(
    dynport_parse_struct("test{ii} a b", 2),
    list(test = typeinfo(
        name = "test", type = "struct", size = 8L, align = 4L, basetype = NA,
        fields = data.frame(name = c("a", "b"), type = c("i", "i"), offset = c(0L, 4L)),
        signature = NA
    ))
)

# union
expect_null(dynport_parse_union("  \n ", 2))
expect_null(dynport_parse_union("", 2))
expect_error(dynport_parse_union("test\n}", 2),     "\\{")
expect_error(dynport_parse_union("test{\n}}", 2),   "\\}")
expect_error(dynport_parse_union("a = 1", 2),       "\\{")
expect_error(dynport_parse_union("s\n{1", 2),       "\\}")
expect_error(dynport_parse_union("{}", 2),          "name")
expect_error(dynport_parse_union("test{ab}", 2),    "type name")
expect_error(dynport_parse_union("test{ii}a", 2),   "number")
expect_error(dynport_parse_union("test{i} a b", 2), "number")
expect_equal(
    dynport_parse_union("test{ii} a b", 2),
    list(test = typeinfo(
        name = "test", type = "union", size = 4L, align = 4L, basetype = NA,
        fields = data.frame(name = c("a", "b"), type = c("i", "i"), offset = c(0L, 0L)),
        signature = NA
    ))
)

# function
expect_null(dynport_parse_function("  \n ", 2))
expect_null(dynport_parse_function("", 2))
expect_error(dynport_parse_function("test\n)", 2), "\\{")
expect_error(dynport_parse_function("test(\n))", 2), "\\}")
expect_error(dynport_parse_function("a = 1", 2), "spec")
expect_error(dynport_parse_function("s\n(1", 2), "\\)")
expect_error(dynport_parse_function("()", 2), "name")
expect_error(dynport_parse_function("test(ab)", 2), "return")
expect_error(dynport_parse_function("test(ii)a", 2), "type name")
expect_error(dynport_parse_function("test(i) i a b", 2), "number")
expect_error(dynport_parse_function("test(ii)i a a", 2), "name")
expect_equal(
    dynport_parse_function("test(ii)i a b", 2),
    list(test = list(
        name = "test", argument = list(sig = "ii", name = c("a", "b")), return = "i"
    ))
)
