#' Title: rdyncall raylib 3D cube
#' Rows: 36
#' Cols: 88
#' End_wait: 20
#' Timeout: 30

library(rdyncall)
source(file.path("inst", "demo-support", "raylib.R"), local = TRUE)

cstruct("Color{CCCC}r g b a;")
cstruct("Vector3{fff}x y z;")
cstruct("Camera3D{ffffffffffi}px py pz tx ty tz ux uy uz fovy projection;")

color <- function(r, g, b, a = 255L) {
    x <- cdata(Color)
    x$r <- r; x$g <- g; x$b <- b; x$a <- a
    x
}

vector3 <- function(x, y, z) {
    v <- cdata(Vector3)
    v$x <- x; v$y <- y; v$z <- z
    v
}

camera <- cdata(Camera3D)
camera$px <- 4; camera$py <- 3; camera$pz <- 4
camera$tx <- 0; camera$ty <- 1; camera$tz <- 0
camera$ux <- 0; camera$uy <- 1; camera$uz <- 0
camera$fovy <- 45; camera$projection <- 0L

ray <- new.env(parent = globalenv())
dynbind(find_raylib(), paste(
    "InitWindow(iiZ)v",
    "CloseWindow()v",
    "BeginDrawing()v",
    "EndDrawing()v",
    "ClearBackground(<Color>)v",
    "BeginMode3D(<Camera3D>)v",
    "EndMode3D()v",
    "DrawCube(<Vector3>fff<Color>)v",
    "DrawCubeWires(<Vector3>fff<Color>)v",
    "DrawGrid(if)v",
    "DrawText(Ziii<Color>)v",
    "WaitTime(d)v",
    sep = ";"
), envir = ray)

ray$InitWindow(800L, 450L, "rdyncall raylib 3D cube")

ray$BeginDrawing()
ray$ClearBackground(color(245L, 245L, 245L))
ray$BeginMode3D(camera)
ray$DrawGrid(12L, 1)
ray$DrawCube(vector3(0, 1, 0), 1.6, 1.6, 1.6, color(0L, 121L, 241L))
ray$DrawCubeWires(vector3(0, 1, 0), 1.6, 1.6, 1.6, color(20L, 48L, 80L))
ray$EndMode3D()
ray$DrawText("Hello from rdyncall + raylib!", 24L, 24L, 22L, color(40L, 45L, 53L))
ray$EndDrawing()

ray$WaitTime(as.numeric(Sys.getenv("RDYNCALL_RECORD_RAYLIB_SECONDS", "2")))
ray$CloseWindow()
