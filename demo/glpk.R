# Package: rdyncall
# File: demo/glpk.R
# Description: Solve a small linear program through the GLPK C API.

library(rdyncall)

# Bind the GLPK routines used by this small linear-programming example.
glpk <- new.env(parent = globalenv())
binding <- tryCatch(
    dynbind(c("glpk", "glpk40", "glpk_4_65"), paste(
        "glp_create_prob()p",
        "glp_delete_prob(p)v",
        "glp_set_prob_name(pZ)v",
        "glp_set_obj_dir(pi)v",
        "glp_add_rows(pi)i",
        "glp_set_row_name(piZ)v",
        "glp_set_row_bnds(piidd)v",
        "glp_add_cols(pi)i",
        "glp_set_col_name(piZ)v",
        "glp_set_col_bnds(piidd)v",
        "glp_set_obj_coef(pid)v",
        "glp_load_matrix(pi*i*i*d)v",
        "glp_simplex(pp)i",
        "glp_get_obj_val(p)d",
        "glp_get_col_prim(pi)d",
        sep = ";"
    ), envir = glpk),
    error = function(e) {
        stop("unable to load the GLPK shared library: ", conditionMessage(e), call. = FALSE)
    }
)
stopifnot(!length(binding$unresolved.symbols))

# GLPK row/column bound type: lower bound only.
GLP_LO <- 2L
# GLPK objective direction: maximize the objective.
GLP_MAX <- 2L
# GLPK row/column bound type: upper bound only.
GLP_UP <- 3L

# Build and solve:
#   maximize 10*x1 + 6*x2 + 4*x3
# subject to three upper-bounded linear constraints and x >= 0.
run_glpk_demo <- function() {
    # Create the opaque `glp_prob*` problem object and release it on exit.
    lp <- glpk$glp_create_prob()
    on.exit(glpk$glp_delete_prob(lp), add = TRUE)

    # Set objective direction and add three constraint rows.
    glpk$glp_set_prob_name(lp, "sample")
    glpk$glp_set_obj_dir(lp, GLP_MAX)

    glpk$glp_add_rows(lp, 3L)
    glpk$glp_set_row_name(lp, 1L, "p")
    glpk$glp_set_row_bnds(lp, 1L, GLP_UP, 0, 100)
    glpk$glp_set_row_name(lp, 2L, "q")
    glpk$glp_set_row_bnds(lp, 2L, GLP_UP, 0, 600)
    glpk$glp_set_row_name(lp, 3L, "r")
    glpk$glp_set_row_bnds(lp, 3L, GLP_UP, 0, 300)

    # Add decision variables, their nonnegative lower bounds, and objective
    # coefficients.
    glpk$glp_add_cols(lp, 3L)
    glpk$glp_set_col_name(lp, 1L, "x1")
    glpk$glp_set_col_bnds(lp, 1L, GLP_LO, 0, 0)
    glpk$glp_set_obj_coef(lp, 1L, 10)
    glpk$glp_set_col_name(lp, 2L, "x2")
    glpk$glp_set_col_bnds(lp, 2L, GLP_LO, 0, 0)
    glpk$glp_set_obj_coef(lp, 2L, 6)
    glpk$glp_set_col_name(lp, 3L, "x3")
    glpk$glp_set_col_bnds(lp, 3L, GLP_LO, 0, 0)
    glpk$glp_set_obj_coef(lp, 3L, 4)

    # GLPK sparse matrices are 1-based. Element 0 is an unused sentinel so the
    # vectors can be passed directly to `glp_load_matrix()`.
    ia <- c(0L, 1L, 1L, 1L, 2L, 3L, 2L, 3L, 3L, 3L)
    ja <- c(0L, 1L, 2L, 3L, 1L, 1L, 2L, 2L, 1L, 3L)
    ar <- c(0, 1, 1, 1, 10, 2, 4, 2, 5, 6)

    # Load the constraint matrix and solve with GLPK's simplex method.
    glpk$glp_load_matrix(lp, 9L, ia, ja, ar)
    glpk$glp_simplex(lp, NULL)

    # Read the objective value and primal column values back from GLPK.
    result <- c(
        z = glpk$glp_get_obj_val(lp),
        x1 = glpk$glp_get_col_prim(lp, 1L),
        x2 = glpk$glp_get_col_prim(lp, 2L),
        x3 = glpk$glp_get_col_prim(lp, 3L)
    )
    print(result)
    expected <- c(z = 733.333333333333, x1 = 33.3333333333333,
        x2 = 66.6666666666667, x3 = 0)
    stopifnot(isTRUE(all.equal(result, expected, tolerance = 1e-8)))
}

run_glpk_demo()
