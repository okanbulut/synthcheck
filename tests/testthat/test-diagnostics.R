test_that("synthetic_copula() keeps item distributions and correlations", {
  real <- beh_sim(1500)
  cop <- synthetic_copula(real, n = 1500, items = beh_items(), attempts = 2, seed = 3)
  expect_length(cop, 2)
  expect_equal(dim(cop[[1]]), c(1500L, 24L))
  expect_identical(names(cop[[1]]), names(real))
  expect_false(anyNA(cop[[1]]))
  expect_true(all(unlist(cop[[1]]) %in% 1:7))
  # marginals
  expect_lt(max(abs(colMeans(cop[[1]]) - colMeans(real))), 0.15)
  # correlations
  r_real <- cor(real); r_cop <- cor(cop[[1]])
  expect_lt(mean(abs(r_real[upper.tri(r_real)] - r_cop[upper.tri(r_cop)])), 0.05)
  # reproducible and independent of the caller's seed
  expect_identical(synthetic_copula(real, 50, seed = 9), synthetic_copula(real, 50, seed = 9))
  expect_error(synthetic_copula(real["i01"], 10), "two item columns")
})

test_that("authenticity_benchmark() adds a copula reference row", {
  real <- beh_sim(1200)
  syn <- list("Real-like" = list(beh_sim(250, 5), beh_sim(250, 6)),
              "Random" = list(beh_random(250, 9), beh_random(250, 10)))
  bm <- authenticity_benchmark(syn, real, beh_items(), n_splits = 4, n_floor = 4,
                               fit_scales = character(0), copula = TRUE)
  tab <- bm$table
  expect_true("Gaussian copula (reference)" %in% tab$model)
  expect_equal(tab$reference, tab$model == "Gaussian copula (reference)")
  cr <- tab[tab$reference, ]
  expect_equal(cr$attempts, 2L)
  expect_gt(cr$structure, 60)
  expect_gt(cr$score, tab$score[tab$model == "Random"])
  expect_true(bm$settings$copula)
  expect_false(any(authenticity_benchmark(syn, real, beh_items(), n_splits = 2, n_floor = 2,
                                          fit_scales = character(0))$table$reference))
  bad <- c(syn, list("Gaussian copula (reference)" = list(beh_sim(50, 3))))
  expect_error(authenticity_benchmark(bad, real, beh_items(), copula = TRUE), "cannot be called")
})

# every answer of a respondent at the rounded scale mean: alpha near 1
too_coherent <- function(n, seed) {
  x <- beh_sim(n, seed)
  it <- beh_items()
  k <- x; k[, it$reverse] <- 8 - k[, it$reverse]
  for (s in unique(it$scale)) {
    cols <- it$scale == s
    v <- round(rowMeans(k[, cols]))
    k[, cols] <- v
  }
  k[, it$reverse] <- 8 - k[, it$reverse]
  k
}

test_that("synthetic_construct() separates real-like, too coherent and random models", {
  real <- beh_sim(1500)
  syn <- list("Real-like" = list(beh_sim(300, 5), beh_sim(300, 6)),
              "Too coherent" = list(too_coherent(300, 7)),
              "Random" = list(beh_random(300, 9)))
  cs <- synthetic_construct(syn, real, beh_items(), n_perm = 99, n_splits = 4)
  expect_s3_class(cs, "sc_construct")
  s <- as.data.frame(cs$summary)
  rl <- s[s$model == "Real-like", ]; tc <- s[s$model == "Too coherent", ]; rd <- s[s$model == "Random", ]
  expect_lt(abs(rl$alpha_gap), 0.03)
  expect_gt(rl$phi, 0.97)
  expect_gt(tc$alpha_gap, 0.05)
  expect_lt(rd$alpha_gap, -0.5)
  expect_lt(rd$phi, rl$phi)
  expect_lt(rl$trait_cor_gap, 0.1)
  expect_equal(nrow(cs$scales), 4 * 2)
  expect_equal(nrow(cs$pairs), 4)
  expect_true(all(cs$scales$p > 0 & cs$scales$p <= 1))
  expect_equal(cs$reference$model, "Real (second sample)")
  expect_lt(abs(cs$reference$alpha_gap), 0.03)
  expect_output(print(cs), "Construct structure")
  expect_identical(tidy(cs), cs$summary)
  expect_s3_class(gg_construct(cs), "ggplot")
  expect_s3_class(gg_construct(cs, "cor"), "ggplot")
  expect_s3_class(autoplot(cs), "ggplot")
})

test_that("Tucker's phi is read against a permutation null", {
  a <- c(0.6, 0.62, 0.58, 0.61, 0.59, 0.6)
  # loadings of the same size: phi is high, but so is the null
  expect_gt(cs_phi(a, rev(a)), 0.99)
  b <- c(0.9, 0.1, 0.8, 0.2, 0.7, 0.3)
  expect_equal(cs_phi(b, b), 1)
  expect_true(is.na(cs_phi(c(NA, 1), c(1, NA))))
  l <- cs_loadings(matrix(c(1, 0.5, 0.5, 1), 2))
  expect_true(all(l > 0))
})

test_that("respondent_coverage() finds real-like, off-support and contraction patterns", {
  real <- beh_sim(2000)
  copies <- function(n, seed) {
    set.seed(seed)
    real[sample(1:10, n, replace = TRUE), ]
  }
  # answers only at the two ends of the scale: far from every real person
  ends <- function(n, seed) {
    x <- beh_random(n, seed)
    x[] <- ifelse(as.matrix(x) <= 4, 1, 7)
    x
  }
  syn <- list("Real-like" = list(beh_sim(300, 5), beh_sim(300, 6)),
              "Endpoints" = list(ends(300, 9)),
              "Ten people" = list(copies(300, 4)))
  rc <- respondent_coverage(syn, real, beh_items(), n_draws = 3)
  expect_s3_class(rc, "sc_respondent")
  s <- as.data.frame(rc$summary)
  rl <- s[s$model == "Real-like", ]
  expect_lt(abs(rl$rcg - 1), 0.1)
  expect_lt(abs(rl$osr - 1), 0.1)
  expect_equal(rl$pattern, "Human-like")
  expect_equal(s$pattern[s$model == "Endpoints"], "Off-support")
  expect_equal(s$pattern[s$model == "Ten people"], "Contraction")
  expect_gt(s$rcg[s$model == "Ten people"], 1.15)
  ref <- as.data.frame(rc$reference)
  expect_lt(abs(ref$rcg[1] - 1), 0.1)
  expect_gt(ref$rcg[2], 1)
  expect_equal(nrow(rc$attempts), 4)
  expect_output(print(rc), "Respondent coverage")
  expect_identical(tidy(rc), rc$summary)
  expect_s3_class(gg_respondent_coverage(rc), "ggplot")
  expect_s3_class(autoplot(rc), "ggplot")
})

test_that("respondent_coverage() handles missing answers", {
  real <- beh_sim(600)
  s1 <- beh_sim(150, 5)
  s1[1:20, 1:3] <- NA
  rc <- respondent_coverage(list(A = list(s1)), real, beh_items(), n_draws = 2)
  expect_false(anyNA(rc$summary$rcg))
})
