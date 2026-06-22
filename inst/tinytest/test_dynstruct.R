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

parsed_struct <- rdyncall:::dynport_parse_struct("Rect{ssSS} x y w h;")
expect_equal(parsed_struct$Rect$fields, env$RectWithSpace$fields)

parsed_union <- rdyncall:::dynport_parse_union("Number{id} i d;")
expect_equal(parsed_union$Number$fields, env$NumberWithSpace$fields)

local({
    cstruct("Flags{IIII}a:1 b:3 :4 c:8;")
    expect_equal(Flags$size, 4L)
    expect_equal(Flags$align, 4)
    expect_equal(Flags$fields$name, c("a", "b", "", "c"))
    expect_equal(Flags$fields$offset, c(0L, 0L, 0L, 1L))
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
