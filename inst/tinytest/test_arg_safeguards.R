build_argument_safeguards_fixture <- function() {
    src <- system.file("tinytest", "argument_safeguards.c", package = "rdyncall", mustWork = TRUE)
    src <- normalizePath(src, winslash = "/", mustWork = TRUE)
    outdir <- tempfile("rdyncall-argument-safeguards-")
    dir.create(outdir)
    outdir <- normalizePath(outdir, winslash = "/", mustWork = TRUE)
    lib <- file.path(outdir, paste0("argument_safeguards", .Platform$dynlib.ext))
    out <- system2(file.path(R.home("bin"), "R"),
        c("CMD", "SHLIB", "-o", lib, src),
        stdout = TRUE, stderr = TRUE
    )
    if (!is.null(attr(out, "status"))) {
        stop(paste(c("failed to build argument safeguard test fixture", out), collapse = "\n"), call. = FALSE)
    }
    dynload(lib)
}

arg_fixture <- build_argument_safeguards_fixture()
arg_sym <- function(name) dynsym(arg_fixture, name)

ptr_is_null <- arg_sym("rdyncall_arg_ptr_is_null")
ptr_is_nonnull <- arg_sym("rdyncall_arg_ptr_is_nonnull")
int_ptr_value <- arg_sym("rdyncall_arg_int_ptr_value")
double_ptr_nonnull <- arg_sym("rdyncall_arg_double_ptr_nonnull")
float_ptr_nonnull <- arg_sym("rdyncall_arg_float_ptr_nonnull")
char_ptr_nonnull <- arg_sym("rdyncall_arg_char_ptr_nonnull")
short_ptr_nonnull <- arg_sym("rdyncall_arg_short_ptr_nonnull")
ptrptr_nonnull <- arg_sym("rdyncall_arg_ptrptr_nonnull")

expect_equal(dyncall(ptr_is_null, "*s)i", NULL), 1L)
expect_equal(dyncall(short_ptr_nonnull, "*s)i", as.externalptr(raw(2))), 1L)
expect_error(dyncall(short_ptr_nonnull, "*s)i", integer(1)), "external pointer")

expect_equal(dyncall(int_ptr_value, "*i)i", 42L), 42L)
expect_equal(dyncall(int_ptr_value, "*i)i", as.externalptr(42L)), 42L)
expect_error(dyncall(int_ptr_value, "*i)i", numeric(1)), "integer")

expect_equal(dyncall(double_ptr_nonnull, "*d)i", 1.25), 1L)
expect_error(dyncall(double_ptr_nonnull, "*d)i", 1L), "numeric")

floats <- as.floatraw(1.5)
expect_equal(dyncall(float_ptr_nonnull, "*f)i", floats), 1L)
expect_equal(dyncall(float_ptr_nonnull, "*f)i", as.externalptr(floats)), 1L)
expect_error(dyncall(float_ptr_nonnull, "*f)i", raw(4)), "floatraw")

expect_equal(dyncall(ptr_is_nonnull, "*v)i", raw(1)), 1L)
expect_error(dyncall(ptr_is_nonnull, "*v)i", raw()), "length greater zero")
expect_equal(dyncall(char_ptr_nonnull, "*c)i", raw(1)), 1L)
expect_error(dyncall(char_ptr_nonnull, "**c)i", raw(1)), "external pointer")
expect_equal(dyncall(ptrptr_nonnull, "**c)i", as.externalptr(raw(.Machine$sizeof.pointer))), 1L)

cstruct("ArgBox{i} value;")
arg_box <- cdata(ArgBox)
expect_equal(dyncall(ptr_is_nonnull, "*<ArgBox>)i", arg_box), 1L)
expect_error(dyncall(ptr_is_nonnull, "*<ArgBox>)i", raw(ArgBox$size)), "struct metadata")

buf <- raw(8)
expect_error(pack(buf, -1L, "i", 1L), "offset")
expect_error(pack(buf, NA_integer_, "i", 1L), "offset")
expect_error(pack(buf, 8L, "i", 1L), "out-of-bounds")
expect_error(pack(buf, 0L, "i", integer()), "length greater zero")
expect_error(pack(buf, 0L, "", 1L), "sigchar")

expect_error(unpack(buf, -1L, "i"), "offset")
expect_error(unpack(buf, 8L, "i"), "out-of-bounds")
expect_error(unpack(buf, 0L, ""), "sigchar")

expect_error(as.externalptr(raw()), "length greater zero")
expect_error(offset_ptr(raw(4), -1L), "offset")
expect_error(offset_ptr(raw(4), NA_integer_), "offset")
expect_error(offset_ptr(raw(4), 5L), "out-of-bounds")
expect_true(is.externalptr(offset_ptr(raw(4), 4L)))
