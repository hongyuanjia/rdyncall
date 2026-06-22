expect_equal(
    rdyncall:::typeinfo("p"),
    structure(
        list(
            name = "p", type = "base", size = NA, align = NA, basetype = NA,
            fields = NA, signature = NA
        ),
        class = "typeinfo"
    )
)

expect_true(rdyncall:::is.typeinfo(rdyncall:::typeinfo("d")))
expect_equal(
    rdyncall:::get_typeinfo("p"),
    structure(
        list(
            name = "p", type = "base", size = .Machine$sizeof.pointer,
            align = .Machine$sizeof.pointer, basetype = NA, fields = NA,
            signature = "p"
        ),
        class = "typeinfo"
    )
)
expect_error(rdyncall:::get_typeinfo(1))

expect_equal(rdyncall:::align(4, 8), 8L)

env <- new.env()
expect_null(cstruct("Rect{ssSS}x y w h ;", env))
expect_null(cstruct("RectWithSpace{ssSS} x y w h ;", env))
expect_null(cunion("NumberWithSpace|id} i d ;", env))
expect_equal(
    env$Rect,
    structure(
        list(name = "Rect", type = "struct", size = .Machine$sizeof.pointer,
            align = 2, basetype = NA,
            fields = data.frame(
                name = c("x", "y", "w", "h"),
                type = I(c("s", "s", "S", "S")),
                offset = c(0L, 2L, 4L, 6L)
            ),
            signature = NA
        ), class = "typeinfo"
    )
)
expect_equal(env$RectWithSpace$fields$name, c("x", "y", "w", "h"))
expect_equal(env$NumberWithSpace$fields$name, c("i", "d"))

parsed_struct <- rdyncall:::dynport_parse_struct("Rect{ssSS} x y w h;")
expect_equal(parsed_struct$Rect$fields, env$RectWithSpace$fields)

parsed_union <- rdyncall:::dynport_parse_union("Number{id} i d;")
expect_equal(parsed_union$Number$fields, env$NumberWithSpace$fields)
