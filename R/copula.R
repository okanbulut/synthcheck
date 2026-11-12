# A Gaussian copula: A non-LLM reference generator built from the real data.

#' Respondents drawn from a Gaussian copula of the real data
#'
#' **Experimental.** `synthetic_copula()` makes synthetic respondents with no
#' language model. It keeps each item's answer distribution and the rank
#' correlations between items, and nothing else. It is a reference
#' generator: A language model that does no better than the copula adds
#' nothing beyond the real data's item distributions and correlations
#' (Lukauskas & Šarkauskaitė, 2026; Kumagae & Kaneko, 2026).
#'
#' **How it works.** Each answer is turned into a normal score at the middle
#' of its category, \eqn{z = \Phi^{-1}((F(x^-) + F(x)) / 2)}, where \eqn{F}
#' is the item's empirical distribution in `real`. The correlation matrix of
#' the normal scores (pairwise complete) is made positive definite, new
#' normal vectors are drawn from it, and each value is mapped back to the
#' category whose cumulative share it falls in. The respondents have no
#' missing answers.
#'
#' **Caution.** The copula is fitted to `real`, so it has seen the people it
#' is compared with. It is a strong in-sample reference, not a fair
#' competitor, and it says nothing about a model's value when no real data
#' exist.
#'
#' @param real a data frame of real responses.
#' @param n number of respondents per attempt.
#' @param items optional item table (see [behaviour_features()]) or a
#'   character vector of item columns. `NULL` uses every numeric column of
#'   `real`.
#' @param attempts number of attempts (independent draws).
#' @param seed random seed.
#' @return A list of `attempts` data frames with `n` rows and the item
#'   columns, ready to be one element of `synthetic` in
#'   [authenticity_benchmark()] and the other functions.
#' @references Lukauskas, M., & Šarkauskaitė, V. (2026). Plausible but not
#'   valid: A psychometric audit of LLMs as synthetic survey respondents.
#'   arXiv:2608.14606.
#'
#'   Kumagae, Y., & Kaneko, M. (2026). Silicon samples match the answers but
#'   not the respondents. arXiv:2610.30900.
#' @seealso [authenticity_benchmark()] (`copula = TRUE`)
#' @examples
#' h <- hexaco_items[hexaco_items$trait == "H", ]
#' real <- hexaco_real[hexaco_real$country == "Canada", ]
#' cop <- synthetic_copula(real, n = 300, items = h, attempts = 2)
#' # item means of the copula and of the real data
#' round(rbind(copula = colMeans(cop[[1]][1:5]),
#'             real = colMeans(real[names(cop[[1]])[1:5]], na.rm = TRUE)), 2)
#' @export
synthetic_copula <- function(real, n, items = NULL, attempts = 1, seed = 1) {
  real <- as.data.frame(real)
  cols <- if (is.null(items)) names(real)[vapply(real, is.numeric, logical(1))] else
    if (is.character(items)) items else as.character(as.data.frame(items)$item)
  cols <- intersect(cols, names(real))
  if (length(cols) < 2L) stop("The copula needs at least two item columns of `real`.", call. = FALSE)
  if (!is.numeric(n) || length(n) != 1L || n < 1) stop("`n` must be a positive number.", call. = FALSE)
  fit <- cop_fit(real[cols])
  with_seed(seed, lapply(seq_len(attempts), function(a) cop_draw(fit, as.integer(n))))
}

cop_fit <- function(X) {
  X <- as.matrix(X)
  storage.mode(X) <- "double"
  marg <- lapply(seq_len(ncol(X)), function(j) {
    v <- X[!is.na(X[, j]), j]
    if (!length(v)) stop("Item ", colnames(X)[j], " has no answers.", call. = FALSE)
    k <- sort(unique(v))
    list(k = k, cum = cumsum(tabulate(match(v, k), length(k))) / length(v))
  })
  Z <- vapply(seq_len(ncol(X)), function(j) {
    m <- marg[[j]]
    hi <- m$cum; lo <- c(0, m$cum[-length(m$cum)])
    u <- (lo + hi)[match(X[, j], m$k)] / 2
    stats::qnorm(pmin(pmax(u, 1e-6), 1 - 1e-6))
  }, numeric(nrow(X)))
  R <- suppressWarnings(stats::cor(Z, use = "pairwise.complete.obs"))
  R[is.na(R)] <- 0
  diag(R) <- 1
  e <- eigen(R, symmetric = TRUE)
  R <- e$vectors %*% (pmax(e$values, 1e-6) * t(e$vectors))
  R <- stats::cov2cor(R)
  list(marg = marg, L = chol(R), names = colnames(X))
}

cop_draw <- function(fit, n) {
  p <- length(fit$marg)
  U <- stats::pnorm(matrix(stats::rnorm(n * p), n) %*% fit$L)
  out <- vapply(seq_len(p), function(j) {
    m <- fit$marg[[j]]
    m$k[pmin(findInterval(U[, j], m$cum, left.open = TRUE) + 1L, length(m$k))]
  }, numeric(n))
  out <- as.data.frame(matrix(out, n, dimnames = list(NULL, fit$names)))
  out
}
