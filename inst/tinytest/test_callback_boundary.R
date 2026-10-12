# Compile in a temporary directory so installed package sources stay read-only.
local({
    source <- system.file(
        "tinytest",
        "callback_boundary.c",
        package = "rdyncall",
        mustWork = TRUE
    )
    directory <- tempfile("rdyncall-callback-boundary-")
    dir.create(directory)
    file.copy(source, directory)
    previous <- setwd(directory)
    on.exit(setwd(previous), add = TRUE)
    output <- system2(
        file.path(R.home("bin"), "R"),
        c("CMD", "SHLIB", "callback_boundary.c"),
        stdout = TRUE,
        stderr = TRUE
    )
    stopifnot(is.null(attr(output, "status")))
    library <- dynload(
        file.path(directory, paste0("callback_boundary", .Platform$dynlib.ext)),
        auto.unload = FALSE
    )
    on.exit(dynunload(library), add = TRUE)
    invoke <- dynsym(library, "m0_callback_boundary")
    previous_options <- options(warn = 2)
    on.exit(options(previous_options), add = TRUE)
    # Verify foreign continuation, status, zero return, and disabled reuse.
    callback__check_boundary <- function(fun, reason) {
        callback <- ccallback(")i", fun)
        sentinel <- 0L
        expect_equal(dyncall(invoke, "pp)i", callback, sentinel), 0L)
        expect_equal(sentinel, 123L)
        status <- callback_status(callback)
        expect_true(status$disabled)
        expect_equal(status$error_invocations, 1)
        expect_equal(status$disable_reason, reason)
        expect_equal(dyncall(invoke, "pp)i", callback, sentinel), 0L)
        expect_equal(callback_status(callback)$disabled_invocations, 1)
    }
    callback__check_boundary(function() stop("boundary error"), "r_error")
    callback__check_boundary(function() warning("boundary warning"), "r_error")
    callback__check_boundary(function() new.env(), "boundary_error")
    callback__check_boundary(
        function() {
            stop(structure(
                list(message = "boundary interrupt", call = NULL),
                class = c("interrupt", "condition")
            ))
        },
        "r_interrupt"
    )
    # Nested callbacks retain separate protection frames and native sentinels.
    inner <- ccallback(")i", function() stop("nested error"))
    outer <- ccallback(")i", function() {
        marker <- 0L
        result <- dyncall(invoke, "pp)i", inner, marker)
        stopifnot(result == 0L, marker == 123L)
        7L
    })
    marker <- 0L
    expect_equal(dyncall(invoke, "pp)i", outer, marker), 7L)
    expect_equal(marker, 123L)
    expect_true(callback_status(inner)$disabled)
    expect_equal(callback_status(outer)$successful_invocations, 1)
    # Different argument/return descriptors must remain correct after callback disable.
    cstruct("BoundaryInput{i}x;")
    cstruct("BoundaryPair{dd}x y;")
    pair_invoke <- dynsym(library, "m0_pair_boundary")
    input <- cdata(BoundaryInput)
    input$x <- 7L
    pair_callback <- ccallback(
        "<BoundaryInput>)<BoundaryPair>",
        function(input) stop("pair error")
    )
    for (i in seq_len(2L)) {
        pair <- dyncall(
            pair_invoke,
            "p<BoundaryInput>)<BoundaryPair>",
            pair_callback,
            input
        )
        expect_equal(as.integer(pair), rep(0L, length(pair)))
    }
    expect_equal(callback_status(pair_callback)$error_invocations, 1)
    expect_equal(callback_status(pair_callback)$disabled_invocations, 1)
    # Preserve LP64 long arguments beyond the R integer range as doubles.
    long_callback <- ccallback("j)d", function(value) value)
    expect_equal(
        dyncall(
            long_callback,
            "j)d",
            if (.Platform$OS.type == "windows") 2147483647 else 4294967297
        ),
        if (.Platform$OS.type == "windows") 2147483647 else 4294967297
    )
})
