#' Title: rdyncall raylib 3D cube
#' Rows: 36
#' Cols: 88
#' End_wait: 20
#' Timeout: 30

library(rdyncall)
source(file.path("inst", "demo-support", "raylib.R"), local = TRUE)

cstruct("Color{CCCC}r g b a;")
cstruct("Vector3{fff}x y z;")
cstruct("Camera3D{ffffffffffi}position_x position_y position_z target_x target_y target_z up_x up_y up_z fovy projection;")

color <- function(r, g, b, a = 255L) {
    x <- cdata(Color)
    x$r <- as.integer(r)
    x$g <- as.integer(g)
    x$b <- as.integer(b)
    x$a <- as.integer(a)
    x
}

vector3 <- function(x, y, z) {
    v <- cdata(Vector3)
    v$x <- as.numeric(x)
    v$y <- as.numeric(y)
    v$z <- as.numeric(z)
    v
}

camera3d <- function(position, target, up, fovy = 45, projection = 0L) {
    c <- cdata(Camera3D)
    c$position_x <- position$x
    c$position_y <- position$y
    c$position_z <- position$z
    c$target_x <- target$x
    c$target_y <- target$y
    c$target_z <- target$z
    c$up_x <- up$x
    c$up_y <- up$y
    c$up_z <- up$z
    c$fovy <- as.numeric(fovy)
    c$projection <- as.integer(projection)
    c
}

seconds <- as.numeric(Sys.getenv("RDYNCALL_RECORD_RAYLIB_SECONDS", "2"))
if (!is.finite(seconds) || seconds <= 0) {
    seconds <- 2
}

ray <- new.env(parent = globalenv())
info <- dynbind(
    find_raylib(),
    paste(
        "InitWindow(iiZ)v",
        "CloseWindow()v",
        "WindowShouldClose()B",
        "BeginDrawing()v",
        "EndDrawing()v",
        "ClearBackground(<Color>)v",
        "BeginMode3D(<Camera3D>)v",
        "EndMode3D()v",
        "DrawCube(<Vector3>fff<Color>)v",
        "DrawCubeWires(<Vector3>fff<Color>)v",
        "DrawGrid(if)v",
        "DrawText(Ziii<Color>)v",
        "SetTargetFPS(i)v",
        "GetTime()d",
        sep = ";"
    ),
    envir = ray
)
if (length(info$unresolved.symbols)) {
    stop("unresolved raylib symbols: ", paste(info$unresolved.symbols, collapse = ", "), call. = FALSE)
}

ray$InitWindow(800L, 450L, "rdyncall raylib 3D cube")
on.exit(ray$CloseWindow(), add = TRUE)
ray$SetTargetFPS(60L)

background <- color(245L, 245L, 245L, 255L)
cube_fill <- color(0L, 121L, 241L, 255L)
cube_wire <- color(20L, 48L, 80L, 255L)
text <- color(40L, 45L, 53L, 255L)
muted <- color(110L, 116L, 128L, 255L)

cube <- vector3(0, 1, 0)
target <- vector3(0, 0.8, 0)
up <- vector3(0, 1, 0)
started <- ray$GetTime()

while (!isTRUE(ray$WindowShouldClose()) && ray$GetTime() - started < seconds) {
    elapsed <- ray$GetTime() - started
    camera <- camera3d(
        vector3(4 * cos(elapsed), 3, 4 * sin(elapsed)),
        target,
        up,
        45,
        0L
    )

    ray$BeginDrawing()
    ray$ClearBackground(background)
    ray$BeginMode3D(camera)
    ray$DrawGrid(12L, 1)
    ray$DrawCube(cube, 1.6, 1.6, 1.6, cube_fill)
    ray$DrawCubeWires(cube, 1.6, 1.6, 1.6, cube_wire)
    ray$EndMode3D()
    ray$DrawText("Hello from rdyncall + raylib!", 24L, 24L, 22L, text)
    ray$DrawText("dynbind() + Camera3D + aggregate by-value calls", 24L, 56L, 16L, muted)
    ray$EndDrawing()
}

cat("raylib 3D cube closed after ", round(ray$GetTime() - started, 2), " seconds.\n", sep = "")
