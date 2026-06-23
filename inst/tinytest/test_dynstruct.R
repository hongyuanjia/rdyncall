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

tokens <- rdyncall:::scan_signature_tokens("C[2][3]i*<Rect>[2]")
expect_true(tokens$ok)
expect_equal(tokens$type, c("C", "i", "*<Rect>"))
expect_equal(tokens$array_len, c(6L, 1L, 2L))
expect_equal(tokens$start, c(1L, 8L, 9L))
expect_equal(tokens$end, c(7L, 8L, 18L))

empty_tokens <- rdyncall:::scan_signature_tokens("")
expect_true(empty_tokens$ok)
expect_equal(empty_tokens$type, character())

bad_aggregate <- rdyncall:::scan_signature_tokens("<Bad")
expect_false(bad_aggregate$ok)
expect_equal(bad_aggregate$error_reason, "aggregate")
expect_equal(c(bad_aggregate$error_start, bad_aggregate$error_end), c(1L, 5L))

bad_array <- rdyncall:::scan_signature_tokens("C[0]")
expect_false(bad_array$ok)
expect_equal(bad_array$error_reason, "array")
expect_equal(c(bad_array$error_start, bad_array$error_end), c(2L, 4L))

bad_array_leading_zero <- rdyncall:::scan_signature_tokens("C[03]")
expect_false(bad_array_leading_zero$ok)
expect_equal(bad_array_leading_zero$error_reason, "array")
expect_equal(c(bad_array_leading_zero$error_start, bad_array_leading_zero$error_end), c(2L, 5L))

bad_array_close <- rdyncall:::scan_signature_tokens("C[12x]")
expect_false(bad_array_close$ok)
expect_equal(c(bad_array_close$error_start, bad_array_close$error_end), c(2L, 6L))

bad_array_open <- rdyncall:::scan_signature_tokens("C[")
expect_false(bad_array_open$ok)
expect_equal(c(bad_array_open$error_start, bad_array_open$error_end), c(1L, 2L))

parsed_bad_array <- rdyncall:::parse_aggregate_types("struct", "C[0]", on_error = "return")
expect_equal(attr(parsed_bad_array, "reason"), "array")
expect_equal(attr(parsed_bad_array, "pos"), c(2L, 4L))

tail_tokens <- rdyncall:::scan_field_tail("a b:3 :0 @packed @align(8)")
expect_true(tail_tokens$ok)
expect_equal(tail_tokens$field_name, c("a", "b", ""))
expect_equal(tail_tokens$bit_width, c(NA_integer_, 3L, 0L))
expect_equal(tail_tokens$field_start, c(1L, 3L, 7L))
expect_equal(tail_tokens$field_end, c(1L, 5L, 8L))
expect_equal(tail_tokens$directive, c("@packed", "@align(8)"))
expect_equal(tail_tokens$directive_start, c(10L, 18L))
expect_equal(tail_tokens$directive_end, c(16L, 26L))

zero_width_tail <- rdyncall:::scan_field_tail(":0")
expect_true(zero_width_tail$ok)
expect_equal(zero_width_tail$field_name, "")
expect_equal(zero_width_tail$bit_width, 0L)

field_layout <- rdyncall:::parse_aggregate_fields("a b:3 :0 @packed @align(8)")
expect_equal(
    field_layout$fields,
    data.frame(
        name = c("a", "b", ""),
        bit_width = c(NA_integer_, 3L, 0L),
        stringsAsFactors = FALSE
    )
)
expect_equal(field_layout$layout, rdyncall:::aggregate_layout(pack = 1L, align = 8L))

bad_tail_width_empty <- rdyncall:::scan_field_tail("a:")
expect_false(bad_tail_width_empty$ok)
expect_equal(bad_tail_width_empty$error_reason, "bitfield_width")
expect_equal(c(bad_tail_width_empty$error_start, bad_tail_width_empty$error_end), c(1L, 2L))

bad_tail_width_text <- rdyncall:::scan_field_tail("a:b")
expect_false(bad_tail_width_text$ok)
expect_equal(bad_tail_width_text$error_reason, "bitfield_width")
expect_equal(c(bad_tail_width_text$error_start, bad_tail_width_text$error_end), c(1L, 3L))

bad_tail_width_leading_zero <- rdyncall:::scan_field_tail("a:03")
expect_false(bad_tail_width_leading_zero$ok)
expect_equal(bad_tail_width_leading_zero$error_reason, "bitfield_width")
expect_equal(c(bad_tail_width_leading_zero$error_start, bad_tail_width_leading_zero$error_end), c(1L, 4L))

bad_tail_spec <- rdyncall:::scan_field_tail("a:1:2")
expect_false(bad_tail_spec$ok)
expect_equal(bad_tail_spec$error_reason, "bitfield_spec")
expect_equal(c(bad_tail_spec$error_start, bad_tail_spec$error_end), c(1L, 5L))

bad_tail_width_overflow <- rdyncall:::scan_field_tail("a:2147483648")
expect_false(bad_tail_width_overflow$ok)
expect_equal(bad_tail_width_overflow$error_reason, "bitfield_width")

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
                array_len = c(1L, 1L, 1L, 1L),
                bit_offset = rep(NA_integer_, 4L),
                bit_width = rep(NA_integer_, 4L),
                storage_offset = rep(NA_integer_, 4L),
                storage_size = rep(NA_integer_, 4L)
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

expect_null(cstruct("EmptyPacked{} @packed;", env))
expect_equal(env$EmptyPacked$size, 0L)
expect_equal(env$EmptyPacked$align, 1L)

expect_null(cstruct("EmptyAligned{} @align(8);", env))
expect_equal(env$EmptyAligned$size, 0L)
expect_equal(env$EmptyAligned$align, 8L)

expect_error(cstruct("OnlyLayout{C}@packed;", env), "number of field types")

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
        array_len = c(4L, 1L, 2L),
        bit_offset = rep(NA_integer_, 3L),
        bit_width = rep(NA_integer_, 3L),
        storage_offset = rep(NA_integer_, 3L),
        storage_size = rep(NA_integer_, 3L)
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

local({
    cstruct("Flags{IIII}a:1 b:3 :4 c:8;")
    expect_equal(Flags$size, 4L)
    expect_equal(Flags$align, 4)
    expect_equal(Flags$fields$name, c("a", "b", "", "c"))
    expect_equal(Flags$fields$offset, c(0L, 0L, 0L, 1L))
    expect_equal(Flags$fields$array_len, rep(1L, 4L))
    expect_equal(Flags$fields$bit_offset, c(0L, 1L, 4L, 8L))
    expect_equal(Flags$fields$bit_width, c(1L, 3L, 4L, 8L))
    expect_equal(Flags$fields$storage_offset, c(0L, 0L, 0L, 0L))

    flags <- cdata(Flags)
    flags$a <- 1
    flags$b <- 5
    flags$c <- 171
    expect_equal(flags$a, 1)
    expect_equal(flags$b, 5)
    expect_equal(flags$c, 171)
    expect_equal(unclass(flags)[1:2], as.raw(c(0x0b, 0xab)))
})

local({
    cstruct("SignedBits{iI}s:3 u:5;")
    bits <- cdata(SignedBits)
    bits$s <- -1L
    bits$u <- 17
    expect_equal(bits$s, -1L)
    expect_equal(bits$u, 17)
    expect_equal(unclass(bits)[1], as.raw(0x8f))
})

local({
    cstruct("AlignedBits{iiic}a:3 :0 b:5 c;")
    expect_equal(AlignedBits$size, 8L)
    expect_equal(AlignedBits$fields$offset, c(0L, 4L, 4L, 5L))
    expect_equal(AlignedBits$fields$bit_offset, c(0L, NA_integer_, 32L, NA_integer_))

    bits <- cdata(AlignedBits)
    bits$a <- 7
    bits$b <- 31
    bits$c <- 102L
    expect_equal(unpack(bits, 5L, "c"), 102L)
    expect_equal(bits$a, -1L)
    expect_equal(bits$b, -1L)
})

local({
    cstruct("CrossBits{CCIC}x a:7 b:3 y;")
    expect_equal(CrossBits$size, 4L)
    expect_equal(CrossBits$fields$offset, c(0L, 1L, 1L, 3L))

    bits <- cdata(CrossBits)
    bits$x <- 0x55
    bits$a <- 0x7f
    bits$b <- 5
    bits$y <- 0x66
    expect_equal(bits$a, 0x7f)
    expect_equal(bits$b, 5)
    bytes <- unclass(bits)
    attributes(bytes) <- NULL
    expect_equal(bytes, as.raw(c(0x55, 0xff, 0x02, 0x66)))
})

local({
    cstruct("PackedBits{CCC}x a:3 y @packed;")
    expect_equal(PackedBits$size, 3L)
    expect_equal(PackedBits$align, 1L)
    expect_equal(PackedBits$fields$offset, c(0L, 1L, 2L))

    bits <- cdata(PackedBits)
    bits$x <- 0x12
    bits$a <- 7
    bits$y <- 0x34
    expect_equal(bits$a, 7L)
    bytes <- unclass(bits)
    attributes(bytes) <- NULL
    expect_equal(bytes, as.raw(c(0x12, 0x07, 0x34)))
})

local({
    cunion("BitUnion|IC}a:3 b:5;")
    expect_equal(BitUnion$size, 4L)
    expect_equal(BitUnion$align, 4)

    bits <- cdata(BitUnion)
    bits$a <- 5
    expect_equal(bits$a, 5)
    bits$b <- 17L
    expect_equal(bits$b, 17L)
})

expect_error(cstruct("BadFloatBits{d}x:1;"), "integer")
expect_error(cstruct("TooWideBits{I}x:33;"), "exceeds")
expect_error(cstruct("NamedZeroBits{I}x:0;"), "zero-width")
expect_error(cstruct("LeadingZeroBits{I}x:03;"), "invalid bitfield width")
expect_error(cstruct("ArrayBits{I[2]}x:1;"), "fixed array field cannot be a bitfield")
