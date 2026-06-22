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


build_aggregate_by_value_fixture <- function() {
    src <- system.file("tinytest", "aggregate_by_value.c", package = "rdyncall", mustWork = TRUE)
    src <- normalizePath(src, winslash = "/", mustWork = TRUE)
    outdir <- tempfile("rdyncall-aggr-fixture-")
    dir.create(outdir)
    outdir <- normalizePath(outdir, winslash = "/", mustWork = TRUE)
    lib <- file.path(outdir, paste0("aggregate_by_value", .Platform$dynlib.ext))
    out <- system2(file.path(R.home("bin"), "R"),
        c("CMD", "SHLIB", "-o", lib, src),
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

make_nested_vec2 <- dynsym(aggregate_fixture, "rdyncall_test_make_nested_vec2")
nested_ret <- dyncall(make_nested_vec2, "ff)<NestedVec2>", 7.5, 8.25)
expect_struct_raw(nested_ret, "NestedVec2")
expect_equal(unpack(nested_ret, nested_base + field_offset(Vec2, "x"), "f"), 7.5)
expect_equal(unpack(nested_ret, nested_base + field_offset(Vec2, "y"), "f"), 8.25)

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

# Aggregate errors remain explicit.
wrong_color <- color
attr(wrong_color, "struct") <- "Vec2"
expect_error(dyncall(color_sum, "<Color>)i", wrong_color), "incompatible aggregate types")
expect_error(dyncall(color_sum, "<Missing>)i", color), "unknown aggregate type")
expect_error(ccallback("<Color>)i", function(x) 0L), "aggregate|signature|Unknown|unsupported")
