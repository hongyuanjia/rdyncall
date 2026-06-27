#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
cast_file <- if (length(args) >= 1L) args[[1L]] else "man/figures/sdl3-demo.cast"
svg_file <- if (length(args) >= 2L) args[[2L]] else "man/figures/sdl3-demo.svg"
fast <- tolower(Sys.getenv("RDYNCALL_RECORD_FAST", "false")) %in% c("1", "true", "yes", "on")

cast <- asciicast::record(
    "tools/asciicast/sdl3-minimal.R",
    typing_speed = if (fast) 0.005 else 0.04,
    speed = if (fast) 4 else 1,
    show_output = FALSE
)

asciicast::write_json(cast, cast_file)
asciicast::write_svg(cast, svg_file, window = TRUE)
