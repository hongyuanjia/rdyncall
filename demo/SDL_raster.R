# Package: rdyncall
# File: demo/SDL_raster.R
# Description: SDL3/OpenGL Mandelbrot raster demo with dynamic base R comparison.

library(rdyncall)
source(system.file("demo-support", "sdl3.R", package = "rdyncall", mustWork = TRUE), local = TRUE)

# Convert private `--sdl-raster-*` worker arguments into environment variables.
# The parent process uses this to start child workers from the same source file.
apply_demo_cli_overrides <- function() {
    args <- commandArgs(trailingOnly = TRUE)
    args <- args[startsWith(args, "--sdl-raster-")]
    if (!length(args)) {
        return(invisible(FALSE))
    }

    keys <- sub("^--sdl-raster-", "", args)
    values <- sub("^[^=]*=", "", keys)
    keys <- sub("=.*$", "", keys)
    keys <- gsub("-", "_", keys, fixed = TRUE)
    env_names <- paste0("SDL_RASTER_DEMO_", toupper(keys))
    env_names[env_names == "SDL_RASTER_DEMO_SDL3_LIB"] <- "SDL3_LIB"
    env_names[env_names == "SDL_RASTER_DEMO_OPENGL_LIB"] <- "OPENGL_LIB"
    do.call(Sys.setenv, as.list(stats::setNames(values, env_names)))
    invisible(TRUE)
}

apply_demo_cli_overrides()

# Bind SDL3 window/event/OpenGL-context functions used by this demo.
sdl3_libs <- find_sdl3()

sdl <- new.env(parent = globalenv())
sdl_info <- tryCatch(
    dynbind(
        sdl3_libs,
        paste(
            "SDL_Init(I)B",
            "SDL_Quit()v",
            "SDL_CreateWindow(ZiiL)p",
            "SDL_DestroyWindow(p)v",
            "SDL_GetError()Z",
            "SDL_GL_SetAttribute(ii)B",
            "SDL_GL_CreateContext(p)p",
            "SDL_GL_DestroyContext(p)v",
            "SDL_GL_SetSwapInterval(i)B",
            "SDL_GL_SwapWindow(p)B",
            "SDL_SetWindowPosition(pii)B",
            "SDL_SetWindowTitle(pZ)B",
            "SDL_PollEvent(p)B",
            "SDL_Delay(I)v",
            sep = ";"
        ),
        envir = sdl
    ),
    error = function(e) {
        stop(
            conditionMessage(e),
            " Install SDL3, set SDL3_LIB, or set SDL3_DEMO_AUTO_DOWNLOAD=true or RDYNCALL_DEMO_AUTO_DOWNLOAD=true.",
            call. = FALSE
        )
    }
)
rm(sdl3_libs)

if (length(sdl_info$unresolved.symbols)) {
    stop("unresolved SDL3 symbols: ", paste(sdl_info$unresolved.symbols, collapse = ", "), call. = FALSE)
}
rm(sdl_info)

# Bind legacy fixed-function OpenGL calls used to draw one textured quad.
gl_libs <- c(
    Sys.getenv("OPENGL_LIB", unset = ""),
    "/System/Library/Frameworks/OpenGL.framework/OpenGL",
    "OPENGL32", "OpenGL", "GL", "GL.so.1"
)
gl_libs <- gl_libs[nzchar(gl_libs)]

gl <- new.env(parent = globalenv())
gl_info <- tryCatch(
    dynbind(
        gl_libs,
        paste(
            "glBegin(I)v",
            "glBindTexture(II)v",
            "glClear(I)v",
            "glDeleteTextures(i*I)v",
            "glDisable(I)v",
            "glEnable(I)v",
            "glEnd()v",
            "glGenTextures(i*I)v",
            "glLoadIdentity()v",
            "glMatrixMode(I)v",
            "glOrtho(dddddd)v",
            "glPixelStorei(Ii)v",
            "glTexCoord2f(ff)v",
            "glTexImage2D(IiiiiiII*v)v",
            "glTexParameteri(IIi)v",
            "glVertex2f(ff)v",
            "glViewport(iiii)v",
            sep = ";"
        ),
        callmode = "stdcall",
        envir = gl
    ),
    error = function(e) {
        stop(
            conditionMessage(e),
            " Install OpenGL or set OPENGL_LIB to the shared library path.",
            call. = FALSE
        )
    }
)
rm(gl_libs)

if (length(gl_info$unresolved.symbols)) {
    stop("unresolved OpenGL symbols: ", paste(gl_info$unresolved.symbols, collapse = ", "), call. = FALSE)
}
rm(gl_info)

# SDL subsystem bit: initialize video/windowing support.
SDL_INIT_VIDEO <- 0x00000020L
# SDL event type: user requested the window to close.
SDL_EVENT_QUIT <- 0x100L
# SDL window flag: create an OpenGL-capable window.
SDL_WINDOW_OPENGL <- 0x0000000000000002

# SDL_GL attribute: red channel bit depth.
SDL_GL_RED_SIZE <- 0L
# SDL_GL attribute: green channel bit depth.
SDL_GL_GREEN_SIZE <- 1L
# SDL_GL attribute: blue channel bit depth.
SDL_GL_BLUE_SIZE <- 2L
# SDL_GL attribute: alpha channel bit depth.
SDL_GL_ALPHA_SIZE <- 3L
# SDL_GL attribute: request a double-buffered OpenGL context.
SDL_GL_DOUBLEBUFFER <- 5L
# SDL_GL attribute: requested OpenGL context major version.
SDL_GL_CONTEXT_MAJOR_VERSION <- 17L
# SDL_GL attribute: requested OpenGL context minor version.
SDL_GL_CONTEXT_MINOR_VERSION <- 18L

# OpenGL mask: clear the color buffer.
GL_COLOR_BUFFER_BIT <- 0x00004000L
# OpenGL matrix mode: model-view transform stack.
GL_MODELVIEW <- 0x1700L
# OpenGL matrix mode: projection transform stack.
GL_PROJECTION <- 0x1701L
# OpenGL primitive type: draw four vertices as a quadrilateral.
GL_QUADS <- 0x0007L
# OpenGL texture filter: nearest-neighbor sampling.
GL_NEAREST <- 0x2600L
# OpenGL pixel format: red, green, blue, alpha byte order.
GL_RGBA <- 0x1908L
# OpenGL target: two-dimensional texture object.
GL_TEXTURE_2D <- 0x0DE1L
# OpenGL texture parameter: magnification filter.
GL_TEXTURE_MAG_FILTER <- 0x2800L
# OpenGL texture parameter: minification filter.
GL_TEXTURE_MIN_FILTER <- 0x2801L
# OpenGL texture parameter: horizontal wrap mode.
GL_TEXTURE_WRAP_S <- 0x2802L
# OpenGL texture parameter: vertical wrap mode.
GL_TEXTURE_WRAP_T <- 0x2803L
# OpenGL pixel-store parameter: byte alignment for unpacking rows.
GL_UNPACK_ALIGNMENT <- 0x0CF5L
# OpenGL wrap mode: clamp texture coordinates to the texture edge.
GL_CLAMP_TO_EDGE <- 0x812FL
# OpenGL pixel component type: unsigned byte.
GL_UNSIGNED_BYTE <- 0x1401L

# Number of repeated draws used by the static timing mode.
demo_iterations <- function() {
    iterations <- as.integer(Sys.getenv("SDL_RASTER_DEMO_ITER", "100"))
    if (is.na(iterations) || iterations < 1L) {
        iterations <- 100L
    }
    iterations
}

# Total seconds for dynamic worker windows to stay open.
demo_duration <- function() {
    duration <- as.numeric(Sys.getenv("SDL_RASTER_DEMO_SECONDS", "20"))
    if (!is.finite(duration) || duration <= 0) {
        duration <- 20
    }
    duration
}

# Select parent, base-only, SDL-only, or static timing mode.
demo_mode <- function() {
    mode <- tolower(Sys.getenv("SDL_RASTER_DEMO_MODE", "both"))
    if (!mode %in% c("both", "base", "sdl", "static")) {
        mode <- "both"
    }
    mode
}

# Probe mode validates bindings and data preparation without opening windows.
is_probe_only <- function() {
    tolower(Sys.getenv("SDL_RASTER_DEMO_PROBE_ONLY", "false")) %in% c("1", "true", "yes")
}

# Return the demo source file that should be used to spawn child workers.
current_demo_file <- function() {
    file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
    if (length(file_arg)) {
        return(normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = FALSE))
    }

    for (frame in rev(sys.frames())) {
        if (!is.null(frame$ofile)) {
            return(normalizePath(frame$ofile, mustWork = FALSE))
        }
    }

    source_file <- file.path("demo", "SDL_raster.R")
    if (file.exists(source_file)) {
        return(normalizePath(source_file, mustWork = FALSE))
    }

    installed <- system.file("demo", "SDL_raster.R", package = "rdyncall")
    if (nzchar(installed)) {
        return(installed)
    }

    normalizePath(source_file, mustWork = FALSE)
}

# Measure elapsed wall time for a small expression.
time_value <- function(expr) {
    system.time(expr)[["elapsed"]]
}

# Define the small Mandelbrot viewport used by this demo.
issue_mandelbrot_parameters <- function() {
    xlims <- c(-0.74877, -0.74872)
    ylims <- c(0.065053, 0.065103)
    width <- 640L
    height <- 480L
    nb_iter <- as.integer(min(round(500 + log10(4 / abs(diff(xlims)))^5), 1E4))

    list(
        xlims = xlims,
        ylims = ylims,
        width = width,
        height = height,
        nb_iter = nb_iter
    )
}

# Build the diverging color palette used by both base R and OpenGL paths.
issue_palette <- function() {
    rdylbu <- c(
        "#A50026", "#D73027", "#F46D43", "#FDAE61", "#FEE090", "#FFFFBF",
        "#E0F3F8", "#ABD9E9", "#74ADD1", "#4575B4", "#313695"
    )
    palette <- grDevices::colorRampPalette(rev(rdylbu))(1000L)
    c(palette, rev(palette), "black")
}

# Rescale a numeric vector to the closed interval [0, 1].
scale01 <- function(x) {
    rng <- range(x)
    (x - rng[[1L]]) / (rng[[2L]] - rng[[1L]])
}

# Histogram-equalize continuous values so the fractal detail is more visible.
equalize_values <- function(values, rng = c(0, 0.95), levels = 10000L) {
    levels <- as.integer(levels)
    breaks <- seq(rng[[1L]], rng[[2L]], length.out = levels + 1L)
    cdf <- cumsum(tabulate(findInterval(values, vec = breaks)))
    cdf_min <- min(cdf[cdf > 0L])
    mapped <- ((cdf - cdf_min) / (length(values) - cdf_min) * diff(rng)) + rng[[1L]]
    bins <- round((values - rng[[1L]]) / diff(rng) * (levels - 1L)) + 1L
    mapped[bins]
}

# Convert raw escape counts into normalized color indices.
equalize_mandelbrot <- function(counts, nb_iter, rng = c(0, 0.95), levels = 10000L) {
    dims <- dim(counts)
    values <- as.vector(counts)
    in_set <- values == nb_iter
    outside <- scale01(values[!in_set]) * rng[[2L]]
    if (diff(range(outside)) != 0) {
        outside <- equalize_values(outside, rng = rng, levels = levels)
        outside <- scale01(outside) * rng[[2L]]
    }
    values[!in_set] <- outside
    values[in_set] <- 1
    dim(values) <- dims
    values
}

# Compute Mandelbrot escape counts for each pixel in the viewport.
generate_mandelbrot_counts <- function(params) {
    width <- params$width
    height <- params$height
    nb_iter <- params$nb_iter
    x <- params$xlims[[1L]] + seq.int(0L, width - 1L) * diff(params$xlims) / width
    y <- params$ylims[[1L]] + seq.int(0L, height - 1L) * diff(params$ylims) / height
    c_real <- rep(x, times = height)
    c_imag <- rep(y, each = width)
    z_real <- numeric(length(c_real))
    z_imag <- numeric(length(c_real))
    counts <- integer(length(c_real))
    active <- seq_along(c_real)

    for (iter in seq_len(nb_iter)) {
        # Iterate only points that have not escaped yet.
        current <- active
        zr <- z_real[current]
        zi <- z_imag[current]
        zr_new <- zr * zr - zi * zi + c_real[current]
        zi_new <- 2 * zr * zi + c_imag[current]
        z_real[current] <- zr_new
        z_imag[current] <- zi_new

        # Points with |z|^2 >= 4 have escaped the Mandelbrot set.
        escaped <- zr_new * zr_new + zi_new * zi_new >= 4
        if (any(escaped)) {
            escaped_index <- current[escaped]
            counts[escaped_index] <- iter
            active <- current[!escaped]
            if (!length(active)) {
                break
            }
        }
    }

    counts[counts == 0L] <- nb_iter
    matrix(counts, nrow = width, ncol = height)
}

# Generate the shared raster asset used by both comparison workers.
make_issue_mandelbrot <- function() {
    params <- issue_mandelbrot_parameters()
    counts <- NULL
    generation_time <- time_value({
        counts <- generate_mandelbrot_counts(params)
    })
    m <- equalize_mandelbrot(counts, params$nb_iter, rng = c(0, 0.95), levels = 10000L)^(1 / 8)

    list(
        x_res = params$width,
        y_res = params$height,
        m = m,
        palette = issue_palette(),
        generation_time = generation_time
    )
}

# Load a precomputed asset for worker children or generate one in the parent.
demo_asset <- function() {
    asset_file <- Sys.getenv("SDL_RASTER_DEMO_ASSET", unset = "")
    if (nzchar(asset_file) && file.exists(asset_file)) {
        return(readRDS(asset_file))
    }

    make_issue_mandelbrot()
}

# Convert normalized matrix values to R color strings.
issue_colors <- function(m, palette) {
    idx <- findInterval(m, seq(0, 1, length.out = length(palette)))
    colors <- palette[idx]
    dim(colors) <- dim(m)
    colors
}

# Convert normalized matrix values to an RGBA byte buffer for OpenGL.
issue_rgba_buffer <- function(m, palette, width, height) {
    idx <- findInterval(m, seq(0, 1, length.out = length(palette)))
    colors <- palette[idx]
    # m is width x height, so its column-major vector already has x varying
    # fastest for each image row, which is the order OpenGL expects here.
    rgba <- grDevices::col2rgb(colors, alpha = TRUE)
    as.raw(as.vector(rgba))
}

# Format an FPS label for an on-canvas overlay.
fps_label <- function(label, fps, frames, elapsed) {
    sprintf("%s: %.1f FPS | frame %d | %.1fs", label, fps, frames, elapsed)
}

# Build overlay text for the dynamic base R worker.
dynamic_overlay <- function(label, fps, frames, elapsed, setup_time = NA_real_) {
    out <- fps_label(label, fps, frames, elapsed)
    if (!is.na(setup_time)) {
        out <- c(out, sprintf("setup: %.3f sec", setup_time))
    }
    out
}

# Read optional target FPS. Missing or nonpositive values mean unlimited.
target_frame_rate <- function() {
    value <- Sys.getenv("SDL_RASTER_DEMO_FPS", "")
    if (!nzchar(value)) {
        return(Inf)
    }

    fps <- suppressWarnings(as.numeric(value))
    if (!is.finite(fps) || fps <= 0) {
        return(Inf)
    }
    fps
}

# Convert a target FPS value to user-facing text.
target_frame_rate_label <- function(fps) {
    if (is.finite(fps)) {
        return(paste0(as.integer(fps), " FPS"))
    }
    "unlimited FPS"
}

# Build the live SDL window title.
sdl_dynamic_window_title <- function(fps, target_fps, frames, setup_time) {
    if (is.finite(target_fps)) {
        fps_text <- sprintf("%.1f/%d FPS", fps, as.integer(target_fps))
    } else {
        fps_text <- sprintf("%.1f FPS", fps)
    }

    sprintf("SDL3/OpenGL dynamic Mandelbrot raster | %s | frame %d | setup %.3fs",
        fps_text, frames, setup_time)
}

# Return numeric wall-clock time in seconds.
wall_time <- function() {
    as.numeric(Sys.time())
}

# Read the synchronized start time used by child workers.
demo_start_time <- function() {
    start_at <- suppressWarnings(as.numeric(Sys.getenv("SDL_RASTER_DEMO_START_AT", "")))
    if (!is.finite(start_at)) {
        return(wall_time())
    }
    start_at
}

# Delay a worker until the shared start timestamp.
wait_until_wall_time <- function(start_at) {
    wait <- start_at - wall_time()
    if (is.finite(wait) && wait > 0) {
        Sys.sleep(wait)
    }
    invisible(TRUE)
}

# Compute the integer-pixel wraparound offset for the moving raster.
animation_offset <- function(elapsed, width, height) {
    c(x = as.integer(elapsed * 64) %% width, y = as.integer(elapsed * 39) %% height)
}

# Circularly shift the base R matrix so it matches the SDL texture motion.
shift_mandelbrot <- function(m, offset) {
    dx <- offset[["x"]] %% nrow(m)
    dy <- offset[["y"]] %% ncol(m)
    rows <- ((seq_len(nrow(m)) - dx - 1L) %% nrow(m)) + 1L
    cols <- ((seq_len(ncol(m)) - dy - 1L) %% ncol(m)) + 1L
    m[rows, cols]
}

# Draw one base R raster frame and optional overlay labels.
draw_base_image <- function(m, palette, asp, labels = character()) {
    graphics::image(m, col = palette, asp = asp, axes = FALSE, useRaster = TRUE)
    try(draw_overlay_labels(labels), silent = TRUE)
    try(grDevices::dev.flush(), silent = TRUE)
    invisible(TRUE)
}

# Pick the base R graphics-device DPI used to match the SDL window size.
graphics_device_dpi <- function() {
    default <- if (identical(Sys.info()[["sysname"]], "Darwin")) 110 else 96
    dpi <- suppressWarnings(as.numeric(Sys.getenv("SDL_RASTER_DEMO_BASE_DPI", as.character(default))))
    if (!is.finite(dpi) || dpi <= 0) {
        dpi <- 96
    }
    dpi
}

# Convert desired pixel dimensions to R graphics-device inches.
graphics_device_inches <- function(width, height) {
    dpi <- graphics_device_dpi()
    c(width = width / dpi, height = height / dpi, dpi = dpi)
}

# Open a base R graphics device sized to match the SDL raster window.
open_base_graphics_device <- function(width, height) {
    size <- graphics_device_inches(width, height)
    device_width <- size[["width"]]
    device_height <- size[["height"]]
    dpi <- size[["dpi"]]

    if (isTRUE(capabilities("aqua"))) {
        opened <- tryCatch({
            args <- list(
                title = "base R image() Mandelbrot raster",
                width = device_width,
                height = device_height
            )
            if ("dpi" %in% names(formals(grDevices::quartz))) {
                args$dpi <- dpi
            }
            do.call(grDevices::quartz, args)
            TRUE
        }, error = function(e) FALSE)
        if (opened) {
            return(TRUE)
        }
    }

    if (isTRUE(capabilities("X11"))) {
        opened <- tryCatch({
            grDevices::x11(
                width = device_width,
                height = device_height,
                xpos = 40L,
                ypos = 80L,
                title = "base R image() Mandelbrot raster"
            )
            TRUE
        }, error = function(e) FALSE)
        if (opened) {
            return(TRUE)
        }
    }

    tryCatch({
        grDevices::dev.new(width = device_width, height = device_height)
        TRUE
    }, error = function(e) FALSE)
}

# Test whether an R graphics device id is still open.
device_exists <- function(device) {
    devices <- grDevices::dev.list()
    !is.null(devices) && device %in% unname(devices)
}

# Restore graphics parameters and close the base R timing display when needed.
close_base_display <- function(state) {
    if (is.null(state$device) || !device_exists(state$device)) {
        return(invisible(FALSE))
    }

    old_device <- grDevices::dev.cur()
    if (device_exists(old_device) && old_device != state$device) {
        on.exit(grDevices::dev.set(old_device), add = TRUE)
    }

    grDevices::dev.set(state$device)
    if (!is.null(state$par)) {
        try(graphics::par(state$par), silent = TRUE)
    }
    if (isTRUE(state$opened)) {
        grDevices::dev.off()
    }

    invisible(TRUE)
}

# Redraw the static base R timing display with summary labels.
update_base_display <- function(state, m, palette, asp, labels) {
    if (is.null(state$device) || !device_exists(state$device)) {
        return(invisible(FALSE))
    }

    old_device <- grDevices::dev.cur()
    if (device_exists(old_device) && old_device != state$device) {
        on.exit(grDevices::dev.set(old_device), add = TRUE)
    }

    grDevices::dev.set(state$device)
    draw_base_image(m, palette, asp, labels)
    invisible(TRUE)
}

# Measure repeated base R image() drawing in the static comparison mode.
time_base_image <- function(m, palette, asp, iterations, width, height) {
    if (grDevices::dev.cur() == 1L && !interactive()) {
        return(list(elapsed = NA_real_, device = NULL, opened = FALSE, par = NULL))
    }

    opened <- FALSE
    if (grDevices::dev.cur() == 1L) {
        opened <- open_base_graphics_device(width, height)
    }
    if (!opened && grDevices::dev.cur() == 1L) {
        cat("base R image() timing skipped: no graphics device could be opened\n")
        return(list(elapsed = NA_real_, device = NULL, opened = FALSE, par = NULL))
    }

    old_par <- graphics::par(no.readonly = TRUE)
    graphics::par(mar = c(0, 0, 0, 0))

    elapsed <- time_value({
        for (i in seq_len(iterations)) {
            draw_base_image(m, palette, asp)
        }
    })

    draw_base_image(m, palette, asp, timing_label("base R image()", elapsed, iterations))
    list(elapsed = elapsed, device = grDevices::dev.cur(), opened = opened, par = old_par)
}

# Print one timing measurement, allowing skipped graphics devices.
print_timing <- function(label, value) {
    if (is.na(value)) {
        cat("  ", label, ": skipped\n", sep = "")
    } else {
        cat("  ", label, ": ", sprintf("%.3f", value), " sec\n", sep = "")
    }
}

# Format one static-mode timing label for the base R overlay.
timing_label <- function(label, value, iterations) {
    if (is.na(value)) {
        return(paste0(label, ": skipped"))
    }
    sprintf("%s: %.3f sec / %d draws (%.1f draws/sec)",
        label, value, iterations, iterations / value)
}

# Format the OpenGL/base-R speedup when both timings are available.
speedup_label <- function(base_time, gl_time) {
    if (is.na(base_time) || is.na(gl_time) || gl_time <= 0) {
        return(character())
    }
    sprintf("SDL/OpenGL speedup: %.1fx", base_time / gl_time)
}

# Build the static-mode overlay labels for the base R window.
comparison_labels <- function(base_time, gl_time, iterations) {
    c(
        timing_label("base R image()", base_time, iterations),
        timing_label("SDL3/OpenGL", gl_time, iterations),
        speedup_label(base_time, gl_time)
    )
}

# Build the static-mode SDL window title.
comparison_window_title <- function(base_time, gl_time, iterations) {
    if (is.na(base_time) || is.na(gl_time) || gl_time <= 0) {
        return("rdyncall SDL3/OpenGL Mandelbrot raster")
    }

    sprintf("rdyncall SDL3/OpenGL %.3fs/%d draws | base R %.3fs | %.1fx faster",
        gl_time, iterations, base_time, base_time / gl_time)
}

# Draw a dark title band over the base R raster.
draw_overlay_labels <- function(labels) {
    labels <- labels[nzchar(labels)]
    if (!length(labels)) {
        return(invisible(FALSE))
    }

    usr <- graphics::par("usr")
    x_span <- diff(usr[1:2])
    y_span <- diff(usr[3:4])
    line_height <- y_span * 0.045
    pad_y <- y_span * 0.012
    center_x <- usr[[1L]] + x_span / 2
    top <- usr[[4L]] - pad_y
    bottom <- top - line_height * length(labels) - pad_y * 1.5

    graphics::rect(usr[[1L]], bottom, usr[[2L]], usr[[4L]],
        col = grDevices::adjustcolor("black", alpha.f = 0.70), border = NA)
    for (i in seq_along(labels)) {
        graphics::text(center_x, top - line_height * (i - 0.5),
            labels[[i]], adj = c(0.5, 0.5), col = "white",
            cex = if (i == 1L) 0.95 else 0.80,
            font = if (i == 1L) 2L else 1L)
    }

    invisible(TRUE)
}

# Set one SDL OpenGL context attribute and fail early if SDL rejects it.
set_gl_attribute <- function(attr, value) {
    if (!isTRUE(sdl$SDL_GL_SetAttribute(as.integer(attr), as.integer(value)))) {
        stop("SDL_GL_SetAttribute failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
}

# Move the SDL window to the right of the base R comparison window when possible.
place_sdl_window <- function(window, width) {
    ok <- sdl$SDL_SetWindowPosition(window, as.integer(width + 80L), 80L)
    if (!isTRUE(ok)) {
        cat("SDL_SetWindowPosition skipped: ", sdl$SDL_GetError(), "\n", sep = "")
    }
    invisible(ok)
}

# Create an OpenGL texture and configure a pixel-coordinate projection.
prepare_gl_texture <- function(width, height) {
    gl$glViewport(0L, 0L, width, height)
    gl$glMatrixMode(GL_PROJECTION)
    gl$glLoadIdentity()
    gl$glOrtho(0, width, height, 0, -1, 1)
    gl$glMatrixMode(GL_MODELVIEW)
    gl$glLoadIdentity()

    # Allocate one texture id and configure nearest sampling for exact pixels.
    tex_id <- integer(1L)
    gl$glGenTextures(1L, tex_id)
    if (tex_id[[1L]] == 0L) {
        stop("glGenTextures failed", call. = FALSE)
    }
    gl$glBindTexture(GL_TEXTURE_2D, tex_id)
    gl$glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    gl$glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    gl$glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
    gl$glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
    gl$glPixelStorei(GL_UNPACK_ALIGNMENT, 1L)
    tex_id
}

# Upload an RGBA byte buffer into an OpenGL texture.
upload_gl_texture <- function(texture, buffer, width, height) {
    gl$glBindTexture(GL_TEXTURE_2D, texture)
    gl$glTexImage2D(
        GL_TEXTURE_2D, 0L, GL_RGBA,
        width, height, 0L, GL_RGBA, GL_UNSIGNED_BYTE, buffer
    )
    invisible(TRUE)
}

# Upload and draw a static raster frame.
render_gl_raster <- function(window, texture, buffer, width, height) {
    upload_gl_texture(texture, buffer, width, height)
    draw_gl_texture(window, texture, width, height, c(x = 0L, y = 0L))
}

# Emit one textured quad at a given screen position.
draw_gl_texture_quad <- function(x, y, width, height) {
    x1 <- x + width
    y1 <- y + height

    gl$glTexCoord2f(0, 1)
    gl$glVertex2f(x, y)
    gl$glTexCoord2f(1, 1)
    gl$glVertex2f(x1, y)
    gl$glTexCoord2f(1, 0)
    gl$glVertex2f(x1, y1)
    gl$glTexCoord2f(0, 0)
    gl$glVertex2f(x, y1)
    invisible(TRUE)
}

# Draw the same uploaded texture as four tiles to make wraparound motion seamless.
draw_gl_texture <- function(window, texture, width, height, offset) {
    x <- offset[["x"]] %% width
    y <- offset[["y"]] %% height

    # Keep the raster colors fixed and move the already-uploaded texture as a
    # tiled image. This avoids per-frame resampling/recoloring flicker.
    gl$glBindTexture(GL_TEXTURE_2D, texture)
    gl$glClear(GL_COLOR_BUFFER_BIT)
    gl$glEnable(GL_TEXTURE_2D)
    gl$glBegin(GL_QUADS)
    for (x0 in c(x - width, x)) {
        for (y0 in c(y - height, y)) {
            draw_gl_texture_quad(x0, y0, width, height)
        }
    }
    gl$glEnd()
    gl$glDisable(GL_TEXTURE_2D)
    if (!isTRUE(sdl$SDL_GL_SwapWindow(window))) {
        stop("SDL_GL_SwapWindow failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    invisible(TRUE)
}

# Child worker that animates the same raster with base R graphics.
run_base_raster_worker <- function(asset, duration) {
    width <- asset$x_res
    height <- asset$y_res
    asp <- height / width

    if (!open_base_graphics_device(width, height)) {
        stop("base R image() worker could not open a graphics device", call. = FALSE)
    }
    old_par <- graphics::par(no.readonly = TRUE)
    on.exit({
        try(graphics::par(old_par), silent = TRUE)
        if (grDevices::dev.cur() != 1L) {
            grDevices::dev.off()
        }
    }, add = TRUE)
    graphics::par(mar = c(0, 0, 0, 0))

    start_at <- demo_start_time()
    wait_until_wall_time(start_at)

    last_report <- wall_time()
    report_frames <- 0L
    frames <- 0L
    fps <- 0
    repeat {
        # Use the shared wall-clock start time so base R and SDL show the same
        # phase of the moving raster.
        now <- wall_time()
        elapsed <- now - start_at
        if (elapsed >= duration) {
            return(invisible(TRUE))
        }

        frames <- frames + 1L
        report_frames <- report_frames + 1L
        offset <- animation_offset(elapsed, width, height)
        frame_m <- shift_mandelbrot(asset$m, offset)
        if (now - last_report >= 0.5) {
            fps <- report_frames / (now - last_report)
            report_frames <- 0L
            last_report <- now
        }

        draw_base_image(frame_m, asset$palette, asp,
            dynamic_overlay("base R image()", fps, frames, elapsed, asset$generation_time))
    }
}

# Child worker that animates the same raster with SDL/OpenGL.
run_sdl_raster_worker <- function(asset, duration) {
    width <- asset$x_res
    height <- asset$y_res

    buffer <- NULL
    buffer_prepare_time <- time_value({
        buffer <- issue_rgba_buffer(asset$m, asset$palette, width, height)
    })

    if (!isTRUE(sdl$SDL_Init(SDL_INIT_VIDEO))) {
        stop("SDL_Init failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    on.exit(sdl$SDL_Quit(), add = TRUE)

    set_gl_attribute(SDL_GL_RED_SIZE, 8L)
    set_gl_attribute(SDL_GL_GREEN_SIZE, 8L)
    set_gl_attribute(SDL_GL_BLUE_SIZE, 8L)
    set_gl_attribute(SDL_GL_ALPHA_SIZE, 8L)
    set_gl_attribute(SDL_GL_DOUBLEBUFFER, 1L)
    set_gl_attribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2L)
    set_gl_attribute(SDL_GL_CONTEXT_MINOR_VERSION, 1L)

    window <- sdl$SDL_CreateWindow("SDL3/OpenGL dynamic Mandelbrot raster", width, height, SDL_WINDOW_OPENGL)
    if (is.null(window) || is.nullptr(window)) {
        stop("SDL_CreateWindow failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    on.exit(sdl$SDL_DestroyWindow(window), add = TRUE)
    place_sdl_window(window, width)

    context <- sdl$SDL_GL_CreateContext(window)
    if (is.null(context) || is.nullptr(context)) {
        stop("SDL_GL_CreateContext failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    on.exit(sdl$SDL_GL_DestroyContext(context), add = TRUE)
    sdl$SDL_GL_SetSwapInterval(1L)

    texture <- prepare_gl_texture(width, height)
    on.exit(gl$glDeleteTextures(1L, texture), add = TRUE)
    # Upload once; every animation frame only moves texture geometry.
    upload_time <- time_value(upload_gl_texture(texture, buffer, width, height))
    setup_time <- buffer_prepare_time + upload_time

    target_fps <- target_frame_rate()
    start_at <- demo_start_time()
    wait_until_wall_time(start_at)

    frame_interval <- if (is.finite(target_fps)) 1 / target_fps else 0
    event <- raw(128L)
    last_report <- wall_time()
    report_frames <- 0L
    frames <- 0L
    fps <- 0
    repeat {
        # Poll SDL events, draw one shifted texture frame, then optionally sleep
        # if the user requested a fixed FPS.
        frame_started <- wall_time()
        while (isTRUE(sdl$SDL_PollEvent(event))) {
            if (unpack(event, 0L, "I") == SDL_EVENT_QUIT) {
                return(invisible(TRUE))
            }
        }

        elapsed <- frame_started - start_at
        if (elapsed >= duration) {
            return(invisible(TRUE))
        }

        frames <- frames + 1L
        report_frames <- report_frames + 1L
        draw_gl_texture(window, texture, width, height, animation_offset(elapsed, width, height))

        sleep_for <- frame_interval - (wall_time() - frame_started)
        if (is.finite(target_fps) && sleep_for > 0) {
            Sys.sleep(sleep_for)
        }

        frame_ended <- wall_time()
        if (frame_ended - last_report >= 0.5) {
            fps <- report_frames / (frame_ended - last_report)
            report_frames <- 0L
            last_report <- frame_ended
            sdl$SDL_SetWindowTitle(window,
                sdl_dynamic_window_title(fps, target_fps, frames, setup_time))
        }
    }
}

# Parent mode: precompute one asset and launch synchronized base R and SDL workers.
run_dynamic_workers <- function() {
    script <- current_demo_file()
    rscript <- file.path(R.home("bin"), "Rscript")
    duration_value <- demo_duration()
    duration <- as.character(duration_value)
    target_fps <- target_frame_rate()
    fps <- as.character(target_fps)
    start_at <- sprintf("%.6f", wall_time() + 1.5)
    asset_file <- tempfile("rdyncall-sdl-raster-", fileext = ".rds")
    saveRDS(make_issue_mandelbrot(), asset_file)

    # Pass worker settings as explicit script arguments so child processes run
    # this source file instead of an older installed demo copy.
    common_args <- c(
        script,
        paste0("--sdl-raster-seconds=", duration),
        paste0("--sdl-raster-fps=", fps),
        paste0("--sdl-raster-start-at=", start_at),
        paste0("--sdl-raster-base-dpi=", graphics_device_dpi()),
        paste0("--sdl-raster-asset=", asset_file)
    )
    if (nzchar(Sys.getenv("SDL3_LIB", ""))) {
        common_args <- c(common_args, paste0("--sdl-raster-sdl3-lib=", Sys.getenv("SDL3_LIB")))
    }
    if (nzchar(Sys.getenv("OPENGL_LIB", ""))) {
        common_args <- c(common_args, paste0("--sdl-raster-opengl-lib=", Sys.getenv("OPENGL_LIB")))
    }

    system2(rscript, c(common_args, "--sdl-raster-mode=base"), wait = FALSE)
    system2(rscript, c(common_args, "--sdl-raster-mode=sdl"), wait = FALSE)
    cat("Started side-by-side dynamic workers for ", duration, " seconds",
        " at ", target_frame_rate_label(target_fps), ".\n", sep = "")
    cat("Move the two windows side by side for recording.\n")
    Sys.sleep(duration_value + 2)
    invisible(TRUE)
}

# Run the selected demo mode.
run_sdl_raster_demo <- function() {
    mode <- demo_mode()
    if (!is_probe_only() && identical(mode, "both")) {
        return(run_dynamic_workers())
    }

    asset <- demo_asset()
    width <- asset$x_res
    height <- asset$y_res
    m <- asset$m
    palette <- asset$palette
    asp <- height / width
    iterations <- demo_iterations()

    buffer <- issue_rgba_buffer(m, palette, width, height)
    stopifnot(length(buffer) == width * height * 4L)

    rgba_prepare_time <- time_value({
        for (i in seq_len(iterations)) {
            issue_rgba_buffer(m, palette, width, height)
        }
    })

    if (is_probe_only()) {
        # Probe mode stops before opening base R or SDL windows.
        invisible(issue_colors(m, palette))
        cat("SDL3/OpenGL raster probe ok: symbols resolved and issue Mandelbrot generated.\n")
        print_timing("Mandelbrot generation setup", asset$generation_time)
        cat("illustrative preparation timing over ", iterations, " iterations:\n", sep = "")
        print_timing("Mandelbrot RGBA buffer", rgba_prepare_time)
        return(invisible(TRUE))
    }

    if (identical(mode, "base")) {
        return(run_base_raster_worker(asset, demo_duration()))
    }
    if (identical(mode, "sdl")) {
        return(run_sdl_raster_worker(asset, demo_duration()))
    }

    base_display <- time_base_image(m, palette, asp, iterations, width, height)
    on.exit(close_base_display(base_display), add = TRUE)
    base_image_time <- base_display$elapsed

    if (!isTRUE(sdl$SDL_Init(SDL_INIT_VIDEO))) {
        stop("SDL_Init failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    on.exit(sdl$SDL_Quit(), add = TRUE)

    set_gl_attribute(SDL_GL_RED_SIZE, 8L)
    set_gl_attribute(SDL_GL_GREEN_SIZE, 8L)
    set_gl_attribute(SDL_GL_BLUE_SIZE, 8L)
    set_gl_attribute(SDL_GL_ALPHA_SIZE, 8L)
    set_gl_attribute(SDL_GL_DOUBLEBUFFER, 1L)
    set_gl_attribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2L)
    set_gl_attribute(SDL_GL_CONTEXT_MINOR_VERSION, 1L)

    window <- sdl$SDL_CreateWindow("rdyncall SDL3/OpenGL Mandelbrot raster", width, height, SDL_WINDOW_OPENGL)
    if (is.null(window) || is.nullptr(window)) {
        stop("SDL_CreateWindow failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    on.exit(sdl$SDL_DestroyWindow(window), add = TRUE)
    place_sdl_window(window, width)

    context <- sdl$SDL_GL_CreateContext(window)
    if (is.null(context) || is.nullptr(context)) {
        stop("SDL_GL_CreateContext failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    on.exit(sdl$SDL_GL_DestroyContext(context), add = TRUE)
    sdl$SDL_GL_SetSwapInterval(0L)

    texture <- prepare_gl_texture(width, height)
    on.exit(gl$glDeleteTextures(1L, texture), add = TRUE)

    gl_display_time <- time_value({
        for (i in seq_len(iterations)) {
            render_gl_raster(window, texture, buffer, width, height)
        }
    })

    labels <- comparison_labels(base_image_time, gl_display_time, iterations)
    update_base_display(base_display, m, palette, asp, labels)
    sdl$SDL_SetWindowTitle(window, comparison_window_title(base_image_time, gl_display_time, iterations))

    cat("illustrative demo timing over ", iterations, " iterations:\n", sep = "")
    print_timing("Mandelbrot generation setup", asset$generation_time)
    print_timing("base R image()", base_image_time)
    print_timing("Mandelbrot RGBA buffer", rgba_prepare_time)
    print_timing("SDL3/OpenGL glTexImage2D + quad + swap", gl_display_time)

    event <- raw(128L)
    started <- proc.time()[["elapsed"]]
    duration <- demo_duration()
    repeat {
        while (isTRUE(sdl$SDL_PollEvent(event))) {
            if (unpack(event, 0L, "I") == SDL_EVENT_QUIT) {
                return(invisible(TRUE))
            }
        }
        render_gl_raster(window, texture, buffer, width, height)
        if (proc.time()[["elapsed"]] - started >= duration) {
            return(invisible(TRUE))
        }
        sdl$SDL_Delay(16L)
    }
}

run_sdl_raster_demo()
