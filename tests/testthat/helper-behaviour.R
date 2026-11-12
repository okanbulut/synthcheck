# simulated HEXACO-like data: 2 scales x 3 facets x 4 items, 7 categories,
# every second item reverse-keyed
beh_items <- function() {
  data.frame(item = sprintf("i%02d", 1:24), scale = rep(c("S1", "S2"), each = 12),
             facet = rep(sprintf("f%d", 1:6), each = 4), reverse = rep(c(FALSE, TRUE), 12),
             stringsAsFactors = FALSE)
}

beh_sim <- function(n, seed = 1) {
  it <- beh_items()
  # the same item parameters for every sample; only the respondents change
  set.seed(100)
  a <- matrix(0, 24, 2); a[1:12, 1] <- 1.6; a[13:24, 2] <- 1.6
  d <- t(apply(matrix(rnorm(24 * 6, 0, 1.2), 24), 1, sort, decreasing = TRUE))
  set.seed(seed)
  x <- mirt::simdata(a, d, n, itemtype = "graded", sigma = diag(2)) + 1
  x[, it$reverse] <- 8 - x[, it$reverse]
  x <- as.data.frame(x); names(x) <- it$item
  x
}

beh_random <- function(n, seed = 2) {
  set.seed(seed)
  x <- as.data.frame(matrix(sample(1:7, n * 24, replace = TRUE), n))
  names(x) <- beh_items()$item
  x
}
