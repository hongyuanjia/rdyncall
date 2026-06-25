f <- function(x, y) x + y
expect_true(is.externalptr(cb <- ccallback("ii)i", f)))
expect_equal(dyncall(cb, "ii)i", 20L, 3L), 23L)

run_rdyncall_subprocess <- function(expr) {
    lib <- dirname(system.file(package = "rdyncall"))
    code <- paste(sprintf(".libPaths(c(%s, .libPaths()))", shQuote(lib)), expr, sep = "\n")
    system2(file.path(R.home("bin"), "Rscript"),
        c("--vanilla", "-e", shQuote(code)),
        stdout = TRUE, stderr = TRUE
    )
}

large_call <- paste(
    "options(rdyncall.callvm.size = 16384L)",
    "library(rdyncall)",
    "n <- 1200L",
    "sig <- paste0(strrep('i', n), ')i')",
    "cb <- ccallback(sig, function(...) as.integer(sum(...)))",
    "ans <- do.call(dyncall, c(list(cb, sig), as.list(rep(1L, n))))",
    "stopifnot(identical(ans, n))",
    sep = "\n"
)
expect_null(attr(run_rdyncall_subprocess(large_call), "status"))

invalid_size <- paste(
    "options(rdyncall.callvm.size = 0L)",
    "library(rdyncall)",
    sep = "\n"
)
out <- suppressWarnings(run_rdyncall_subprocess(invalid_size))
expect_true(!is.null(attr(out, "status")))
expect_true(any(grepl("rdyncall.callvm.size", out, fixed = TRUE)))

legacy_fields <- data.frame(
    type = c("C", "i"),
    offset = c(0L, 4L),
    stringsAsFactors = FALSE
)
expect_equal(
    rdyncall:::dyncall_normalize_aggregate_fields(legacy_fields),
    data.frame(
        type = c("C", "i"),
        offset = c(0L, 4L),
        array_len = c(1L, 1L),
        stringsAsFactors = FALSE
    )
)

array_fields <- data.frame(
    type = I(c("C", "d")),
    offset = c(0L, 8L),
    array_len = c(4L, 2L),
    stringsAsFactors = FALSE
)
expect_equal(
    rdyncall:::dyncall_normalize_aggregate_fields(array_fields),
    data.frame(
        type = c("C", "d"),
        offset = c(0L, 8L),
        array_len = c(4L, 2L),
        stringsAsFactors = FALSE
    )
)

bitfield_fields <- data.frame(
    type = I(c("I", "I", "I", "C")),
    offset = c(0L, 0L, 4L, 5L),
    array_len = rep(1L, 4L),
    bit_offset = c(0L, 1L, NA_integer_, NA_integer_),
    bit_width = c(1L, 3L, 0L, NA_integer_),
    storage_offset = c(0L, 0L, NA_integer_, NA_integer_),
    storage_size = c(4L, 4L, NA_integer_, NA_integer_),
    stringsAsFactors = FALSE
)
expect_equal(
    rdyncall:::dyncall_normalize_aggregate_fields(bitfield_fields),
    data.frame(
        type = c("I", "C"),
        offset = c(0L, 5L),
        array_len = c(1L, 1L),
        stringsAsFactors = FALSE
    )
)

build_aggregate_by_value_fixture <- function() {
    src <- system.file("tinytest", "aggregate_by_value.c", package = "rdyncall", mustWork = TRUE)
    src <- normalizePath(src, winslash = "/", mustWork = TRUE)
    outdir <- tempfile("rdyncall-aggr-fixture-")
    dir.create(outdir)
    outdir <- normalizePath(outdir, winslash = "/", mustWork = TRUE)
    src_copy <- file.path(outdir, basename(src))
    file.copy(src, src_copy)
    lib <- file.path(outdir, paste0("aggregate_by_value", .Platform$dynlib.ext))
    out <- system2(file.path(R.home("bin"), "R"),
        c("CMD", "SHLIB", "-o", lib, src_copy),
        stdout = TRUE, stderr = TRUE
    )
    if (!is.null(attr(out, "status"))) {
        stop(paste(c("failed to build aggregate by-value test fixture", out), collapse = "\n"), call. = FALSE)
    }
    libh <- dynload(lib)
    if (is.null(libh)) stop("failed to load aggregate by-value test fixture", call. = FALSE)
    libh
}

field_offset <- function(info, field) {
    info$fields$offset[match(field, info$fields$name)]
}

expect_struct_raw <- function(x, type) {
    expect_true(is.raw(x))
    expect_true(inherits(x, "struct"))
    expect_equal(attr(x, "struct"), type)
}

register_repeated_struct <- function(name, sigchar, n, envir = parent.frame()) {
    fields <- paste0("v", seq_len(n))
    cstruct(sprintf("%s{%s}%s;", name, strrep(sigchar, n), paste(fields, collapse = " ")), envir = envir)
    get(name, envir = envir)
}

pack_repeated <- function(x, info, sigchar, values) {
    for (i in seq_along(values)) {
        pack(x, field_offset(info, paste0("v", i)), sigchar, values[[i]])
    }
    invisible(x)
}

expect_repeated <- function(x, info, sigchar, values) {
    for (i in seq_along(values)) {
        expect_equal(unpack(x, field_offset(info, paste0("v", i)), sigchar), values[[i]])
    }
}

aggregate_fixture <- build_aggregate_by_value_fixture()

fixture_int <- function(name) {
    dyncall(dynsym(aggregate_fixture, name), ")i")
}

expect_c_layout <- function(info, prefix, offset_fields) {
    expect_equal(info$size, fixture_int(paste0(prefix, "_size")))
    expect_equal(info$align, fixture_int(paste0(prefix, "_align")))
    for (field in offset_fields) {
        expect_equal(field_offset(info, field), fixture_int(paste0(prefix, "_offset_", field)))
    }
}

# Small byte aggregate argument is passed by value.
cstruct("Color{CCCC}r g b a;")
color <- cdata(Color)
pack(color, field_offset(Color, "r"), "C", 1L)
pack(color, field_offset(Color, "g"), "C", 2L)
pack(color, field_offset(Color, "b"), "C", 3L)
pack(color, field_offset(Color, "a"), "C", 4L)
color_sum <- dynsym(aggregate_fixture, "rdyncall_test_color_sum")
expect_equal(dyncall(color_sum, "<Color>)i", color), 4321L)

# Small byte aggregate return is materialized as raw-backed struct.
make_color <- dynsym(aggregate_fixture, "rdyncall_test_make_color")
color_ret <- dyncall(make_color, "CCCC)<Color>", 5L, 6L, 7L, 8L)
expect_struct_raw(color_ret, "Color")
expect_equal(unpack(color_ret, field_offset(Color, "r"), "C"), 5L)
expect_equal(unpack(color_ret, field_offset(Color, "g"), "C"), 6L)
expect_equal(unpack(color_ret, field_offset(Color, "b"), "C"), 7L)
expect_equal(unpack(color_ret, field_offset(Color, "a"), "C"), 8L)

# Float HFA aggregate argument uses the ARM64 floating-point aggregate path.
cstruct("Vec2{ff}x y;")
vec2 <- cdata(Vec2)
pack(vec2, field_offset(Vec2, "x"), "f", 1.25)
pack(vec2, field_offset(Vec2, "y"), "f", 2.5)
vec2_sum <- dynsym(aggregate_fixture, "rdyncall_test_vec2_sum")
expect_equal(dyncall(vec2_sum, "<Vec2>)d", vec2), 3.75)

# Float HFA aggregate return is reassembled from FP return registers.
make_vec2 <- dynsym(aggregate_fixture, "rdyncall_test_make_vec2")
vec2_ret <- dyncall(make_vec2, "ff)<Vec2>", 3.5, 4.25)
expect_struct_raw(vec2_ret, "Vec2")
expect_equal(unpack(vec2_ret, field_offset(Vec2, "x"), "f"), 3.5)
expect_equal(unpack(vec2_ret, field_offset(Vec2, "y"), "f"), 4.25)

# Nested aggregate fields are flattened through registered typeinfo.
cstruct("NestedVec2{<Vec2>}xy;")
nested_vec2 <- cdata(NestedVec2)
nested_base <- field_offset(NestedVec2, "xy")
pack(nested_vec2, nested_base + field_offset(Vec2, "x"), "f", 5.5)
pack(nested_vec2, nested_base + field_offset(Vec2, "y"), "f", 6.25)
nested_sum <- dynsym(aggregate_fixture, "rdyncall_test_nested_vec2_sum")
expect_equal(dyncall(nested_sum, "<NestedVec2>)d", nested_vec2), 11.75)
nested_xy <- nested_vec2$xy
expect_struct_raw(nested_xy, "Vec2")
expect_equal(dyncall(vec2_sum, "<Vec2>)d", nested_xy), 11.75)

make_nested_vec2 <- dynsym(aggregate_fixture, "rdyncall_test_make_nested_vec2")
nested_ret <- dyncall(make_nested_vec2, "ff)<NestedVec2>", 7.5, 8.25)
expect_struct_raw(nested_ret, "NestedVec2")
expect_equal(unpack(nested_ret, nested_base + field_offset(Vec2, "x"), "f"), 7.5)
expect_equal(unpack(nested_ret, nested_base + field_offset(Vec2, "y"), "f"), 8.25)
nested_ret_xy <- nested_ret$xy
expect_struct_raw(nested_ret_xy, "Vec2")
expect_equal(dyncall(vec2_sum, "<Vec2>)d", nested_ret_xy), 15.75)

# Three-double HFA aggregate return stays in FP return registers even though size is over 16 bytes.
cstruct("ThreeDouble{ddd}a b c;")
three_double <- cdata(ThreeDouble)
three_values <- c(a = 1.5, b = 2.5, c = 3.5)
for (field in names(three_values)) pack(three_double, field_offset(ThreeDouble, field), "d", three_values[[field]])
three_sum <- dynsym(aggregate_fixture, "rdyncall_test_three_double_sum")
expect_equal(dyncall(three_sum, "<ThreeDouble>)d", three_double), 7.5)

make_three_double <- dynsym(aggregate_fixture, "rdyncall_test_make_three_double")
three_ret <- dyncall(make_three_double, "ddd)<ThreeDouble>", 4.5, 5.5, 6.5)
expect_struct_raw(three_ret, "ThreeDouble")
expect_equal(unpack(three_ret, field_offset(ThreeDouble, "a"), "d"), 4.5)
expect_equal(unpack(three_ret, field_offset(ThreeDouble, "b"), "d"), 5.5)
expect_equal(unpack(three_ret, field_offset(ThreeDouble, "c"), "d"), 6.5)

# Large aggregate argument and return use indirect by-value storage.
cstruct("MoreThanRegs{ddddd}a b c d e;")
more_than_regs <- cdata(MoreThanRegs)
more_values <- c(a = 1, b = 2, c = 3, d = 4, e = 5)
for (field in names(more_values)) pack(more_than_regs, field_offset(MoreThanRegs, field), "d", more_values[[field]])
more_sum <- dynsym(aggregate_fixture, "rdyncall_test_more_than_regs_sum")
expect_equal(dyncall(more_sum, "<MoreThanRegs>)d", more_than_regs), 15)

make_more_than_regs <- dynsym(aggregate_fixture, "rdyncall_test_make_more_than_regs")
more_ret <- dyncall(make_more_than_regs, "d)<MoreThanRegs>", 10)
expect_struct_raw(more_ret, "MoreThanRegs")
for (field in names(more_values)) {
    expect_equal(unpack(more_ret, field_offset(MoreThanRegs, field), "d"), 10 + more_values[[field]])
}

# Exact-size byte aggregates exercise 1/2/4/8/9/16/17 byte direct and indirect boundaries.
for (n in c(1L, 2L, 4L, 8L, 9L, 16L, 17L)) {
    type <- paste0("Bytes", n)
    info <- register_repeated_struct(type, "C", n)
    values <- as.integer(seq_len(n))
    x <- cdata(info)
    pack_repeated(x, info, "C", values)

    sum_sym <- dynsym(aggregate_fixture, sprintf("rdyncall_test_bytes%d_sum", n))
    expect_equal(dyncall(sum_sym, sprintf("<%s>)i", type), x), sum(values))

    make_sym <- dynsym(aggregate_fixture, sprintf("rdyncall_test_make_bytes%d", n))
    ret <- dyncall(make_sym, sprintf("C)<%s>", type), 10L)
    expect_struct_raw(ret, type)
    expect_repeated(ret, info, "C", as.integer(10L + seq_len(n) - 1L))
}

# Fixed array fields pass the same aggregate descriptor as C arrays.
cstruct("ByteArray4{C[4]}b;")
byte_array4 <- cdata(ByteArray4)
byte_array4$b <- 1:4
byte_array4_sum <- dynsym(aggregate_fixture, "rdyncall_test_bytes4_sum")
expect_equal(dyncall(byte_array4_sum, "<ByteArray4>)i", byte_array4), 10L)
make_byte_array4 <- dynsym(aggregate_fixture, "rdyncall_test_make_bytes4")
byte_array4_ret <- dyncall(make_byte_array4, "C)<ByteArray4>", 20L)
expect_struct_raw(byte_array4_ret, "ByteArray4")
expect_equal(byte_array4_ret$b, 20:23)

# Float and double HFA matrices cover 1-4 register HFA cases plus the 5-element fallback path.
for (case in list(list(prefix = "Float", kind = "float", sig = "f", base = 2),
                  list(prefix = "Double", kind = "double", sig = "d", base = 20))) {
    for (n in 1:5) {
        type <- paste0(case$prefix, n)
        info <- register_repeated_struct(type, case$sig, n)
        values <- case$base + seq_len(n) - 1
        x <- cdata(info)
        pack_repeated(x, info, case$sig, values)

        sum_sym <- dynsym(aggregate_fixture, sprintf("rdyncall_test_%s%d_sum", case$kind, n))
        expect_equal(dyncall(sum_sym, sprintf("<%s>)d", type), x), sum(values))

        make_sym <- dynsym(aggregate_fixture, sprintf("rdyncall_test_make_%s%d", case$kind, n))
        ret <- dyncall(make_sym, sprintf("%s)<%s>", case$sig, type), case$base)
        expect_struct_raw(ret, type)
        expect_repeated(ret, info, case$sig, values)
    }
}

# Fixed float arrays preserve ARM64 homogeneous floating-point aggregate handling.
cstruct("FloatArray3{f[3]}v;")
float_array3 <- cdata(FloatArray3)
float_array3$v <- c(2, 3, 4)
float_array3_sum <- dynsym(aggregate_fixture, "rdyncall_test_float3_sum")
expect_equal(dyncall(float_array3_sum, "<FloatArray3>)d", float_array3), 9)
make_float_array3 <- dynsym(aggregate_fixture, "rdyncall_test_make_float3")
float_array3_ret <- dyncall(make_float_array3, "f)<FloatArray3>", 5)
expect_struct_raw(float_array3_ret, "FloatArray3")
expect_equal(float_array3_ret$v, c(5, 6, 7))

# Mixed non-HFA aggregates make sure field order and padding stay visible to the backend.
cstruct("FloatInt{fi}f i;")
float_int <- cdata(FloatInt)
pack(float_int, field_offset(FloatInt, "f"), "f", 1.5)
pack(float_int, field_offset(FloatInt, "i"), "i", 2L)
float_int_sum <- dynsym(aggregate_fixture, "rdyncall_test_float_int_sum")
expect_equal(dyncall(float_int_sum, "<FloatInt>)d", float_int), 3.5)
make_float_int <- dynsym(aggregate_fixture, "rdyncall_test_make_float_int")
float_int_ret <- dyncall(make_float_int, "fi)<FloatInt>", 4.5, 5L)
expect_struct_raw(float_int_ret, "FloatInt")
expect_equal(unpack(float_int_ret, field_offset(FloatInt, "f"), "f"), 4.5)
expect_equal(unpack(float_int_ret, field_offset(FloatInt, "i"), "i"), 5L)

cstruct("IntFloat{if}i f;")
int_float <- cdata(IntFloat)
pack(int_float, field_offset(IntFloat, "i"), "i", 3L)
pack(int_float, field_offset(IntFloat, "f"), "f", 2.25)
int_float_sum <- dynsym(aggregate_fixture, "rdyncall_test_int_float_sum")
expect_equal(dyncall(int_float_sum, "<IntFloat>)d", int_float), 5.25)
make_int_float <- dynsym(aggregate_fixture, "rdyncall_test_make_int_float")
int_float_ret <- dyncall(make_int_float, "if)<IntFloat>", 6L, 7.25)
expect_struct_raw(int_float_ret, "IntFloat")
expect_equal(unpack(int_float_ret, field_offset(IntFloat, "i"), "i"), 6L)
expect_equal(unpack(int_float_ret, field_offset(IntFloat, "f"), "f"), 7.25)

cstruct("DoubleInt{di}d i;")
double_int <- cdata(DoubleInt)
pack(double_int, field_offset(DoubleInt, "d"), "d", 8.5)
pack(double_int, field_offset(DoubleInt, "i"), "i", 9L)
double_int_sum <- dynsym(aggregate_fixture, "rdyncall_test_double_int_sum")
expect_equal(dyncall(double_int_sum, "<DoubleInt>)d", double_int), 17.5)
make_double_int <- dynsym(aggregate_fixture, "rdyncall_test_make_double_int")
double_int_ret <- dyncall(make_double_int, "di)<DoubleInt>", 10.5, 11L)
expect_struct_raw(double_int_ret, "DoubleInt")
expect_equal(unpack(double_int_ret, field_offset(DoubleInt, "d"), "d"), 10.5)
expect_equal(unpack(double_int_ret, field_offset(DoubleInt, "i"), "i"), 11L)

cstruct("IntDouble{id}i d;")
int_double <- cdata(IntDouble)
pack(int_double, field_offset(IntDouble, "i"), "i", 12L)
pack(int_double, field_offset(IntDouble, "d"), "d", 13.5)
int_double_sum <- dynsym(aggregate_fixture, "rdyncall_test_int_double_sum")
expect_equal(dyncall(int_double_sum, "<IntDouble>)d", int_double), 25.5)
make_int_double <- dynsym(aggregate_fixture, "rdyncall_test_make_int_double")
int_double_ret <- dyncall(make_int_double, "id)<IntDouble>", 14L, 15.5)
expect_struct_raw(int_double_ret, "IntDouble")
expect_equal(unpack(int_double_ret, field_offset(IntDouble, "i"), "i"), 14L)
expect_equal(unpack(int_double_ret, field_offset(IntDouble, "d"), "d"), 15.5)

cstruct("CharDouble{Cd}c d;")
char_double <- cdata(CharDouble)
pack(char_double, field_offset(CharDouble, "c"), "C", 16L)
pack(char_double, field_offset(CharDouble, "d"), "d", 17.5)
char_double_sum <- dynsym(aggregate_fixture, "rdyncall_test_char_double_sum")
expect_equal(dyncall(char_double_sum, "<CharDouble>)d", char_double), 33.5)
make_char_double <- dynsym(aggregate_fixture, "rdyncall_test_make_char_double")
char_double_ret <- dyncall(make_char_double, "Cd)<CharDouble>", 18L, 19.5)
expect_struct_raw(char_double_ret, "CharDouble")
expect_equal(unpack(char_double_ret, field_offset(CharDouble, "c"), "C"), 18L)
expect_equal(unpack(char_double_ret, field_offset(CharDouble, "d"), "d"), 19.5)

# Packed and manually aligned aggregates use the compiler's layout.
cstruct("PackedCharDouble{Cd}c d @packed;")
expect_c_layout(PackedCharDouble, "rdyncall_test_packed_char_double", "d")
packed_char_double <- cdata(PackedCharDouble)
pack(packed_char_double, field_offset(PackedCharDouble, "c"), "C", 4L)
pack(packed_char_double, field_offset(PackedCharDouble, "d"), "d", 5.5)
packed_char_double_sum <- dynsym(aggregate_fixture, "rdyncall_test_packed_char_double_sum")
expect_equal(dyncall(packed_char_double_sum, "<PackedCharDouble>)d", packed_char_double), 9.5)
make_packed_char_double <- dynsym(aggregate_fixture, "rdyncall_test_make_packed_char_double")
packed_char_double_ret <- dyncall(make_packed_char_double, "Cd)<PackedCharDouble>", 6L, 7.5)
expect_struct_raw(packed_char_double_ret, "PackedCharDouble")
expect_equal(unpack(packed_char_double_ret, field_offset(PackedCharDouble, "c"), "C"), 6L)
expect_equal(unpack(packed_char_double_ret, field_offset(PackedCharDouble, "d"), "d"), 7.5)

cstruct("Pack4CharDouble{Cd}c d @pack(4);")
expect_c_layout(Pack4CharDouble, "rdyncall_test_pack4_char_double", "d")
pack4_char_double <- cdata(Pack4CharDouble)
pack(pack4_char_double, field_offset(Pack4CharDouble, "c"), "C", 8L)
pack(pack4_char_double, field_offset(Pack4CharDouble, "d"), "d", 9.5)
pack4_char_double_sum <- dynsym(aggregate_fixture, "rdyncall_test_pack4_char_double_sum")
expect_equal(dyncall(pack4_char_double_sum, "<Pack4CharDouble>)d", pack4_char_double), 17.5)
make_pack4_char_double <- dynsym(aggregate_fixture, "rdyncall_test_make_pack4_char_double")
pack4_char_double_ret <- dyncall(make_pack4_char_double, "Cd)<Pack4CharDouble>", 10L, 11.5)
expect_struct_raw(pack4_char_double_ret, "Pack4CharDouble")
expect_equal(unpack(pack4_char_double_ret, field_offset(Pack4CharDouble, "c"), "C"), 10L)
expect_equal(unpack(pack4_char_double_ret, field_offset(Pack4CharDouble, "d"), "d"), 11.5)

cstruct("AlignedChar{C}c @align(8);")
expect_c_layout(AlignedChar, "rdyncall_test_aligned_char", "c")
aligned_char <- cdata(AlignedChar)
pack(aligned_char, field_offset(AlignedChar, "c"), "C", 12L)
aligned_char_value <- dynsym(aggregate_fixture, "rdyncall_test_aligned_char_value")
expect_equal(dyncall(aligned_char_value, "<AlignedChar>)i", aligned_char), 12L)
make_aligned_char <- dynsym(aggregate_fixture, "rdyncall_test_make_aligned_char")
aligned_char_ret <- dyncall(make_aligned_char, "C)<AlignedChar>", 13L)
expect_struct_raw(aligned_char_ret, "AlignedChar")
expect_equal(unpack(aligned_char_ret, field_offset(AlignedChar, "c"), "C"), 13L)

cstruct("PackedAlignedCharDouble{Cd}c d @packed @align(8);")
expect_c_layout(PackedAlignedCharDouble, "rdyncall_test_packed_aligned_char_double", "d")
packed_aligned_char_double <- cdata(PackedAlignedCharDouble)
pack(packed_aligned_char_double, field_offset(PackedAlignedCharDouble, "c"), "C", 14L)
pack(packed_aligned_char_double, field_offset(PackedAlignedCharDouble, "d"), "d", 15.5)
packed_aligned_char_double_sum <- dynsym(aggregate_fixture, "rdyncall_test_packed_aligned_char_double_sum")
expect_equal(dyncall(packed_aligned_char_double_sum, "<PackedAlignedCharDouble>)d", packed_aligned_char_double), 29.5)
make_packed_aligned_char_double <- dynsym(aggregate_fixture, "rdyncall_test_make_packed_aligned_char_double")
packed_aligned_char_double_ret <- dyncall(make_packed_aligned_char_double, "Cd)<PackedAlignedCharDouble>", 16L, 17.5)
expect_struct_raw(packed_aligned_char_double_ret, "PackedAlignedCharDouble")
expect_equal(unpack(packed_aligned_char_double_ret, field_offset(PackedAlignedCharDouble, "c"), "C"), 16L)
expect_equal(unpack(packed_aligned_char_double_ret, field_offset(PackedAlignedCharDouble, "d"), "d"), 17.5)

# Register exhaustion checks that stack placement still preserves aggregate values.
exhaust_ints_color_sum <- dynsym(aggregate_fixture, "rdyncall_test_exhaust_ints_color_sum")
expect_equal(dyncall(exhaust_ints_color_sum, "iiiiiiii<Color>)i", 1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L, color), 4357L)

exhaust_fp_vec2_sum <- dynsym(aggregate_fixture, "rdyncall_test_exhaust_fp_vec2_sum")
expect_equal(dyncall(exhaust_fp_vec2_sum, "dddddddd<Vec2>)d", 1, 2, 3, 4, 5, 6, 7, 8, vec2), 39.75)

# Union aggregate passes the active storage by value while R uses the public cunion API.
cunion("ValueUnion|ifC}i f c;")
value_union <- cdata(ValueUnion)
pack(value_union, field_offset(ValueUnion, "i"), "i", 123456L)
value_union_int <- dynsym(aggregate_fixture, "rdyncall_test_value_union_int")
expect_equal(dyncall(value_union_int, "<ValueUnion>)i", value_union), 123456L)
make_value_union_int <- dynsym(aggregate_fixture, "rdyncall_test_make_value_union_int")
value_union_ret <- dyncall(make_value_union_int, "i)<ValueUnion>", 654321L)
expect_struct_raw(value_union_ret, "ValueUnion")
expect_equal(unpack(value_union_ret, field_offset(ValueUnion, "i"), "i"), 654321L)

# Pointer-field aggregates make sure pointer-sized fields are copied without truncation.
cstruct("PtrBox{pi}p tag;")
ptr_box <- cdata(PtrBox)
ptr_value <- 100L
pack(ptr_box, field_offset(PtrBox, "p"), "p", ptr_value)
pack(ptr_box, field_offset(PtrBox, "tag"), "i", 23L)
ptr_box_sum <- dynsym(aggregate_fixture, "rdyncall_test_ptr_box_sum")
expect_equal(dyncall(ptr_box_sum, "<PtrBox>)i", ptr_box), 123L)

# Bitfield aggregate storage is passed and returned by value using the
# registered storage-unit layout.
cstruct("Bits{IIII}a:1 b:3 :4 c:8;")
bits <- cdata(Bits)
bits$a <- 1
bits$b <- 5
bits$c <- 171
bits_sum <- dynsym(aggregate_fixture, "rdyncall_test_bits_sum")
expect_equal(dyncall(bits_sum, "<Bits>)i", bits), 17151L)

make_bits <- dynsym(aggregate_fixture, "rdyncall_test_make_bits")
bits_ret <- dyncall(make_bits, "III)<Bits>", 1, 2, 3)
expect_struct_raw(bits_ret, "Bits")
expect_equal(bits_ret$a, 1)
expect_equal(bits_ret$b, 2)
expect_equal(bits_ret$c, 3)

# C can call R callbacks that take and return aggregate values by value.
call_color_callback <- dynsym(aggregate_fixture, "rdyncall_test_call_color_callback")
color_callback <- ccallback("<Color>)i", function(x) {
    x$r + 10L * x$g + 100L * x$b + 1000L * x$a
})
expect_equal(dyncall(call_color_callback, "p<Color>)i", color_callback, color), 4321L)

call_vec2_mix_callback <- dynsym(aggregate_fixture, "rdyncall_test_call_vec2_mix_callback")
vec2_mix_callback <- ccallback("i<Vec2>d)d", function(i, x, y) {
    i + x$x + x$y + y
})
expect_equal(dyncall(call_vec2_mix_callback, "pi<Vec2>d)d", vec2_mix_callback, 10L, vec2, 3.25), 17)

call_make_color_callback <- dynsym(aggregate_fixture, "rdyncall_test_call_make_color_callback")
make_color_callback <- ccallback("CCCC)<Color>", function(r, g, b, a) {
    out <- cdata(Color)
    out$r <- r
    out$g <- g
    out$b <- b
    out$a <- a
    out
})
callback_color <- dyncall(call_make_color_callback, "pCCCC)<Color>", make_color_callback, 9L, 10L, 11L, 12L)
expect_struct_raw(callback_color, "Color")
expect_equal(callback_color$r, 9)
expect_equal(callback_color$g, 10)
expect_equal(callback_color$b, 11)
expect_equal(callback_color$a, 12)

call_make_vec2_callback <- dynsym(aggregate_fixture, "rdyncall_test_call_make_vec2_callback")
make_vec2_callback <- ccallback("ff)<Vec2>", function(x, y) {
    out <- cdata(Vec2)
    out$x <- x + 1
    out$y <- y + 2
    out
})
callback_vec2 <- dyncall(call_make_vec2_callback, "pff)<Vec2>", make_vec2_callback, 1.5, 2.5)
expect_struct_raw(callback_vec2, "Vec2")
expect_equal(callback_vec2$x, 2.5)
expect_equal(callback_vec2$y, 4.5)

call_make_more_callback <- dynsym(aggregate_fixture, "rdyncall_test_call_make_more_than_regs_callback")
make_more_callback <- ccallback("d)<MoreThanRegs>", function(base) {
    out <- cdata(MoreThanRegs)
    for (field in names(more_values)) {
        pack(out, field_offset(MoreThanRegs, field), "d", base + more_values[[field]])
    }
    out
})
callback_more <- dyncall(call_make_more_callback, "pd)<MoreThanRegs>", make_more_callback, 20)
expect_struct_raw(callback_more, "MoreThanRegs")
for (field in names(more_values)) {
    expect_equal(unpack(callback_more, field_offset(MoreThanRegs, field), "d"), 20 + more_values[[field]])
}

# Aggregate errors remain explicit.
wrong_color <- color
attr(wrong_color, "struct") <- "Vec2"
expect_error(dyncall(color_sum, "<Color>)i", wrong_color), "incompatible aggregate types")
expect_error(dyncall(color_sum, "<Missing>)i", color), "unknown aggregate type")
expect_error(ccallback("<Missing>)i", function(x) 0L), "unknown aggregate type")
