#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

cmd <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", cmd, value = TRUE)
this_file <- if (length(file_arg)) sub("^--file=", "", file_arg[[1L]]) else "tools/record-raylib-demo.R"
repo <- normalizePath(file.path(dirname(this_file), ".."), mustWork = FALSE)
if (!file.exists(file.path(repo, "DESCRIPTION"))) {
    repo <- normalizePath(getwd(), mustWork = TRUE)
}

if (!requireNamespace("asciicast", quietly = TRUE)) {
    stop(
        "tools/record-raylib-demo.R requires the optional asciicast package. ",
        "Install it with pak::pak(\"r-lib/asciicast\") or remotes::install_github(\"r-lib/asciicast\").",
        call. = FALSE
    )
}

cast_file <- if (length(args) >= 1L) args[[1L]] else file.path(repo, "man", "figures", "raylib-3d-demo.cast")
svg_file <- if (length(args) >= 2L) args[[2L]] else sub("[.][^.]*$", ".svg", cast_file)
script_file <- file.path(repo, "tools", "asciicast", "raylib-3d.R")

dir.create(dirname(cast_file), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(svg_file), recursive = TRUE, showWarnings = FALSE)

fast <- tolower(Sys.getenv("RDYNCALL_RECORD_FAST", "false")) %in% c("1", "true", "yes", "on")

old_wd <- setwd(repo)
on.exit(setwd(old_wd), add = TRUE)

cast <- asciicast::record(
    script_file,
    typing_speed = if (fast) 0.005 else 0.04,
    speed = if (fast) 4 else 1,
    show_output = FALSE
)

asciicast::write_json(cast, cast_file)
asciicast::write_svg(cast, svg_file, window = TRUE)

cat("Recorded ", cast_file, "\n", sep = "")
cat("Rendered ", svg_file, "\n", sep = "")
