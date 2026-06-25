f <- function(x, y) x + y
expect_error(ccallback(NA_character_, identity), "'signature'")
expect_error(ccallback(c("i)i", "i)i"), identity), "'signature'")
expect_error(ccallback(1, identity), "'signature'")
expect_error(ccallback("A)v", identity), "reserved")
expect_error(ccallback("i)i", 1), "is.function")
expect_error(ccallback("i)i", identity, envir = list()), "is.environment")

expect_true(is.externalptr(cb <- ccallback("ii)i", function(x, y) x + y)))
status <- callback_status(cb)
expect_equal(class(status), "callback_status")
expect_equal(
    names(status),
    c(
        "active", "disabled", "signature", "invocations",
        "successful_invocations", "error_invocations",
        "disabled_invocations", "disable_reason", "last_error"
    )
)
expect_true(callback_is_active(cb))
expect_true(status$active)
expect_false(status$disabled)
expect_equal(status$signature, "ii)i")
expect_equal(status$invocations, 0)
expect_equal(status$successful_invocations, 0)
expect_equal(status$error_invocations, 0)
expect_equal(status$disabled_invocations, 0)
expect_null(status$disable_reason)
expect_null(status$last_error)
expect_null(callback_last_error(cb))
status_print <- capture.output(expect_identical(print(status), status))
expect_true(any(grepl("rdyncall callback: active", status_print, fixed = TRUE)))

expect_equal(dyncall(cb, "ii)i", 20, 3), 23)
status <- callback_status(cb)
expect_true(status$active)
expect_equal(status$invocations, 1)
expect_equal(status$successful_invocations, 1)
expect_equal(status$error_invocations, 0)
expect_equal(status$disabled_invocations, 0)

runs <- 0L
err_cb <- ccallback("i)i", function(x) {
    runs <<- runs + 1L
    if (x < 0L) stop("negative callback input", call. = FALSE)
    x
})
expect_equal(dyncall(err_cb, "i)i", 10L), 10L)
expect_warning(invisible(dyncall(err_cb, "i)i", -1L)), "Callback disabled")
expect_false(callback_is_active(err_cb))
expect_equal(runs, 2L)
last_error <- callback_last_error(err_cb)
expect_true(is.list(last_error))
expect_equal(last_error$message, "negative callback input")
expect_true("simpleError" %in% last_error$class)
expect_equal(last_error$reason, "r_error")
last_error$message <- "mutated outside"
expect_equal(callback_last_error(err_cb)$message, "negative callback input")
status <- callback_status(err_cb)
expect_false(status$active)
expect_true(status$disabled)
expect_equal(status$invocations, 2)
expect_equal(status$successful_invocations, 1)
expect_equal(status$error_invocations, 1)
expect_equal(status$disabled_invocations, 0)
expect_equal(status$disable_reason, "r_error")
expect_equal(status$last_error$message, "negative callback input")
status$last_error$message <- "mutated through status"
expect_equal(callback_status(err_cb)$last_error$message, "negative callback input")

invisible(dyncall(err_cb, "i)i", 10L))
status <- callback_status(err_cb)
expect_equal(runs, 2L)
expect_equal(status$invocations, 3)
expect_equal(status$successful_invocations, 1)
expect_equal(status$error_invocations, 1)
expect_equal(status$disabled_invocations, 1)

string_cb <- ccallback(")Z", function() "abc")
expect_warning(invisible(dyncall(string_cb, ")Z")), "string return values")
string_status <- callback_status(string_cb)
expect_false(callback_is_active(string_cb))
expect_false(string_status$active)
expect_true(string_status$disabled)
expect_equal(string_status$invocations, 1)
expect_equal(string_status$successful_invocations, 0)
expect_equal(string_status$error_invocations, 1)
expect_equal(string_status$disabled_invocations, 0)
expect_equal(string_status$disable_reason, "unsupported_return")
expect_equal(
    string_status$last_error$message,
    "callback string return values are not implemented"
)
expect_equal(callback_last_error(string_cb)$class, "rdyncall_callback_error")
expect_equal(callback_last_error(string_cb)$reason, "unsupported_return")

plain_ptr <- as.externalptr(1)
null_ptr <- unpack(raw(.Machine$sizeof.pointer), 0, "p")
expect_true(is.nullptr(null_ptr))
for (bad_callback in list(plain_ptr, null_ptr, NULL)) {
    expect_error(callback_status(bad_callback), "not an rdyncall callback")
    expect_error(callback_is_active(bad_callback), "not an rdyncall callback")
    expect_error(callback_last_error(bad_callback), "not an rdyncall callback")
}

libc <- dynfind(c("msvcrt", "c", "c.so.6"))
if (!is.null(libc)) {
    expect_error(callback_status(libc), "not an rdyncall callback")
    expect_error(callback_is_active(libc), "not an rdyncall callback")
    expect_error(callback_last_error(libc), "not an rdyncall callback")
}
