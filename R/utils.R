check_single <- function(x, arg = "x") {
  if (!methods::is(x, "SingleGroupClass"))
    stop(sprintf("`%s` must be a single-group model estimated with mirt::mirt().", arg),
         call. = FALSE)
  invisible(TRUE)
}

check_unidim <- function(x, what = "This function") {
  if (mirt::extract.mirt(x, "nfact") != 1L)
    stop(what, " currently supports unidimensional models only.", call. = FALSE)
  invisible(TRUE)
}

as_tbl <- function(df) {
  rownames(df) <- NULL
  tibble::as_tibble(df)
}

item_names <- function(x) mirt::extract.mirt(x, "itemnames")
