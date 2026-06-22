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
                offset = c(0L, 2L, 4L, 6L),
                array_len = c(1L, 1L, 1L, 1L)
            ),
            signature = NA
        ), class = "typeinfo"
    )
)
expect_equal(env$RectWithSpace$fields$name, c("x", "y", "w", "h"))
expect_equal(env$NumberWithSpace$fields$name, c("i", "d"))

expect_null(cstruct("EmptyStruct{};", env))
expect_equal(env$EmptyStruct$size, 0L)
expect_equal(nrow(env$EmptyStruct$fields), 0L)

parsed_struct <- rdyncall:::dynport_parse_struct("Rect{ssSS} x y w h;")
expect_equal(parsed_struct$Rect$fields, env$RectWithSpace$fields)

parsed_union <- rdyncall:::dynport_parse_union("Number{id} i d;")
expect_equal(parsed_union$Number$fields, env$NumberWithSpace$fields)

expect_null(cstruct("FixedArray{C[4]id[2]}bytes tag values;", env))
expect_equal(
    env$FixedArray$fields,
    data.frame(
        name = c("bytes", "tag", "values"),
        type = I(c("C", "i", "d")),
        offset = c(0L, 4L, 8L),
        array_len = c(4L, 1L, 2L)
    )
)
expect_equal(env$FixedArray$size, 24L)
expect_equal(env$FixedArray$align, 8L)

expect_null(cunion("FixedArrayUnion|i[2]d} ints value ;", env))
expect_equal(env$FixedArrayUnion$size, 8L)
expect_equal(env$FixedArrayUnion$align, 8L)
expect_equal(env$FixedArrayUnion$fields$array_len, c(2L, 1L))

expect_null(cunion("FixedArrayUnionPadding|C[3]s} bytes short ;", env))
expect_equal(env$FixedArrayUnionPadding$size, 4L)
expect_equal(env$FixedArrayUnionPadding$align, 2L)

parsed_array_struct <- rdyncall:::dynport_parse_struct("DynFixedArray{C[4]i} bytes tag;")
expect_equal(parsed_array_struct$DynFixedArray$fields$type, I(c("C", "i")))
expect_equal(parsed_array_struct$DynFixedArray$fields$offset, c(0L, 4L))
expect_equal(parsed_array_struct$DynFixedArray$fields$array_len, c(4L, 1L))

cstruct("FixedArrayAccess{C[4]i}bytes tag;")
fixed_array_access <- cdata(FixedArrayAccess)
fixed_array_access$bytes <- 1:4
fixed_array_access$tag <- 42L
expect_equal(fixed_array_access$bytes, 1:4)
expect_equal(fixed_array_access$tag, 42L)
expect_error(fixed_array_access$bytes <- 1:3, "fixed array field length")

expect_null(cstruct("PackedCharDouble{Cd} c d @packed;", env))
expect_equal(env$PackedCharDouble$size, 9L)
expect_equal(env$PackedCharDouble$align, 1L)
expect_equal(env$PackedCharDouble$fields$offset, c(0L, 1L))

expect_null(cstruct("Pack4CharDouble{Cd} c d @pack(4);", env))
expect_equal(env$Pack4CharDouble$size, 12L)
expect_equal(env$Pack4CharDouble$align, 4L)
expect_equal(env$Pack4CharDouble$fields$offset, c(0L, 4L))

expect_null(cstruct("AlignedChar{C} c @align(8);", env))
expect_equal(env$AlignedChar$size, 8L)
expect_equal(env$AlignedChar$align, 8L)
expect_equal(env$AlignedChar$fields$offset, 0L)

expect_null(cstruct("PackedAlignedCharDouble{Cd} c d @packed @align(8);", env))
expect_equal(env$PackedAlignedCharDouble$size, 16L)
expect_equal(env$PackedAlignedCharDouble$align, 8L)
expect_equal(env$PackedAlignedCharDouble$fields$offset, c(0L, 1L))

expect_null(cstruct("PackedFixedArray{C[3]d} bytes value @packed;", env))
expect_equal(env$PackedFixedArray$size, 11L)
expect_equal(env$PackedFixedArray$align, 1L)
expect_equal(env$PackedFixedArray$fields$offset, c(0L, 3L))
expect_equal(env$PackedFixedArray$fields$array_len, c(3L, 1L))

expect_null(cunion("PackedUnion|Cd} c d @packed;", env))
expect_equal(env$PackedUnion$size, 8L)
expect_equal(env$PackedUnion$align, 1L)
expect_equal(env$PackedUnion$fields$offset, c(0L, 0L))

expect_null(cunion("AlignedUnion|Ci} c i @align(8);", env))
expect_equal(env$AlignedUnion$size, 8L)
expect_equal(env$AlignedUnion$align, 8L)
expect_equal(env$AlignedUnion$fields$offset, c(0L, 0L))

parsed_packed <- rdyncall:::dynport_parse_struct("PackedCharDouble{Cd} c d @packed;")
expect_equal(parsed_packed$PackedCharDouble$size, env$PackedCharDouble$size)
expect_equal(parsed_packed$PackedCharDouble$align, env$PackedCharDouble$align)
expect_equal(parsed_packed$PackedCharDouble$fields, env$PackedCharDouble$fields)

expect_error(cstruct("BadPacked{C} c @pack(3);", env), "power-of-two")
expect_error(cstruct("BadPacked{C} c @packed @pack(1);", env), "duplicate")
expect_error(cstruct("BadPacked{C} c @bytepack;", env), "unknown")
