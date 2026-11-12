cov_data <- function(n_att = 4, n = 150, polytomous = FALSE) {
  set.seed(11)
  a <- matrix(rlnorm(8, 0.2, 0.3))
  if (polytomous) {
    d <- t(apply(matrix(rnorm(8 * 4), 8), 1, sort, decreasing = TRUE))
    type <- "graded"
  } else {
    d <- matrix(rnorm(8)); type <- "dich"
  }
  sim <- function(n, mu = 0, s = 1) as.data.frame(
    mirt::simdata(a, d, n, itemtype = type, Theta = matrix(rnorm(n, mu, s))))
  real <- sim(1000)
  llm <- function(mu, s) lapply(seq_len(n_att), function(i) sim(n, mu, s))
  list(real = real, syn = list("LLM A" = llm(0.9, 0.6), "LLM B" = llm(-0.9, 0.6)))
}

test_that("synthetic_coverage() scores score slices, structure and a held-out blend", {
  dd <- cov_data()
  cov <- synthetic_coverage(dd$syn, dd$real)
  expect_s3_class(cov, "sc_coverage")
  expect_equal(cov$summary$model, c("LLM A", "LLM B", "Best Blend"))
  expect_true(all(cov$attempts$overlap >= 0 & cov$attempts$overlap <= 1))
  expect_true(all(cov$summary$structure_overall > 0 & cov$summary$structure_overall <= 1))
  # real shares sum to one and are close to tenths
  expect_equal(sum(cov$slices$table$real), 1)
  expect_equal(nrow(cov$slices$table), 9)  # 8 dichotomous items: scores 0-8 are 9 slices
  # one model too high, one too low: The blend covers both halves and beats each
  expect_equal(sum(cov$blend$weights), 1)
  expect_true(all(cov$blend$weights > 0.2))
  s <- cov$summary
  expect_gt(s$overlap_overall[3], max(s$overlap_overall[1:2]))
  expect_true(cov$blend$holdout)
  expect_equal(cov$blend$train, 1:2)
  expect_equal(cov$blend$test, 3:4)
  expect_equal(s$attempts[3], 2L)
  expect_output(print(cov), "Best Blend")
  expect_identical(tidy(cov), cov$summary)
  # cells within noise are not coloured
  expect_true(all(cov$cells$fill[!cov$cells$flagged] == 0))
})

test_that("a perfect copy of the real data gets full overlap and structure", {
  dd <- cov_data()
  cov <- synthetic_coverage(list(Copy = list(dd$real, dd$real)), dd$real, blend = FALSE)
  expect_equal(cov$summary$overlap_overall, 1)
  expect_equal(cov$summary$structure_overall, 1)
  expect_true(all(cov$cells$fill == 0))
  expect_null(cov$blend)
})

test_that("few attempts give an in-sample blend", {
  dd <- cov_data(n_att = 2)
  cov <- synthetic_coverage(dd$syn, dd$real)
  expect_false(cov$blend$holdout)
  expect_equal(cov$blend$test, 1:2)
  cov2 <- blend_llms(cov, holdout = TRUE, step = 0.1)
  expect_equal(cov2$blend$train, 1L)
  expect_equal(sum(cov2$summary$model == "Best Blend"), 1L)
})

test_that("item mode works for dichotomous and Likert items", {
  dd <- cov_data()
  cov <- synthetic_coverage(dd$syn, dd$real, slices = "item", blend = FALSE)
  expect_true(cov$slices$binary)
  expect_equal(length(unique(cov$slices$table$item)), 8)
  expect_s3_class(gg_coverage(cov), "patchwork")
  dl <- cov_data(polytomous = TRUE)
  cl <- synthetic_coverage(dl$syn, dl$real, slices = "item", cor = "pearson")
  expect_false(cl$slices$binary)
  expect_equal(nrow(cl$slices$table), 8 * 5)
  # 40 columns per plot: Five-category items fit 8 per page
  expect_length(gg_coverage(cl, page = "all"), 1L)
  pages <- gg_coverage(cl, page = "all", max_columns = 20)
  expect_length(pages, 2L)
  expect_length(gg_coverage(cl, page = "all", items_per_plot = 3), 3L)
  expect_error(gg_coverage(cl, page = 5), "between 1 and 1")
})

test_that("group slices work with a target and with real groups", {
  dd <- cov_data(n_att = 2)
  pers <- c("low", "mid", "high")
  syn <- lapply(dd$syn, function(m) lapply(m, function(d) {
    d$persona <- sample(pers, nrow(d), replace = TRUE); d
  }))
  cov <- synthetic_coverage(syn, NULL, slices = "group", group = "persona",
                            target = c(low = 0.2, mid = 0.6, high = 0.2))
  expect_equal(nrow(cov$slices$table), 3)
  expect_true(all(is.na(cov$summary$structure_overall)))
  expect_s3_class(gg_coverage(cov), "patchwork")
  real <- dd$real
  real$persona <- sample(pers, nrow(real), replace = TRUE)
  within <- synthetic_coverage(syn, real, group = "persona", n_slices = 3)
  expect_equal(sort(unique(within$slices$table$item)), sort(pers))
  expect_s3_class(gg_coverage(within), "patchwork")
})

test_that("within_group ignores the mix of groups", {
  dd <- cov_data(n_att = 2)
  real <- dd$real
  real$country <- rep(c("Canada", "UK"), c(800, 200))
  # a copy of the real respondents, but with equal numbers per country
  copy <- rbind(real[real$country == "Canada", ][1:200, ], real[real$country == "UK", ])
  pooled <- synthetic_coverage(list(Copy = list(copy, copy)), real, group = "country",
                               n_slices = 4, blend = FALSE)
  within <- synthetic_coverage(list(Copy = list(copy, copy)), real, group = "country",
                               n_slices = 4, within_group = TRUE, blend = FALSE)
  expect_lt(pooled$summary$overlap_overall, 0.75)
  expect_gt(within$summary$overlap_overall, 0.9)
  expect_true(within$slices$within)
  # each country's real shares sum to one
  expect_equal(as.vector(tapply(within$slices$table$real, within$slices$table$item, sum)), c(1, 1))
  expect_s3_class(gg_coverage(within), "patchwork")
  expect_error(synthetic_coverage(dd$syn, real, within_group = TRUE), "needs `group`")
})

test_that("theta slices and the default plot work", {
  dd <- cov_data(n_att = 2, n = 80)
  cov <- synthetic_coverage(dd$syn, dd$real, slices = "theta", n_slices = 5, blend = FALSE)
  expect_equal(nrow(cov$slices$table), 5)
  p <- autoplot(cov)
  expect_s3_class(p, "patchwork")
})

test_that("synthetic_coverage() checks its inputs", {
  dd <- cov_data(n_att = 1)
  expect_error(synthetic_coverage(dd$syn[[1]], dd$real), "named list")
  expect_error(synthetic_coverage(list("Best Blend" = dd$real), dd$real), "Best Blend")
  expect_error(synthetic_coverage(dd$syn), "`real` is needed")
  bad <- dd$real; names(bad) <- paste0("x", seq_along(bad))
  expect_error(synthetic_coverage(list(A = bad), dd$real), "item names")
  expect_error(synthetic_coverage(dd$syn, dd$real, slices = "group"), "needs `group`")
})
