test_that("authenticity_benchmark() anchors real-like models near 100 and shuffled ones near 0", {
  real <- beh_sim(1200)
  shuffle <- function(n, seed) {
    set.seed(seed)
    as.data.frame(lapply(real, function(v) sample(v, n, replace = TRUE)))
  }
  syn <- list("Real-like" = list(beh_sim(250, 5), beh_sim(250, 6)),
              "Shuffled" = list(shuffle(250, 7), shuffle(250, 8)),
              "Random" = list(beh_random(250, 9), beh_random(250, 10)))
  bm <- authenticity_benchmark(syn, real, beh_items(), n_splits = 6, n_floor = 6)
  expect_s3_class(bm, "sc_benchmark")
  tab <- bm$table
  expect_equal(tab$model[1], "Real-like")
  expect_equal(bm$settings$anchor_n, 250L)
  r <- tab[tab$model == "Real-like", ]
  expect_true(all(c(r$overlap, r$structure, r$behaviour) > 60))
  s <- tab[tab$model == "Shuffled", ]
  expect_lt(abs(s$structure), 25)
  expect_lt(s$behaviour, 40)
  # weakest score
  expect_equal(tab$score, pmin(tab$overlap, tab$structure, tab$behaviour))
  expect_true(all(tab$weakest %in% c("overlap", "structure", "behaviour")))
  # anchors: floor below ceiling
  expect_true(all(bm$anchors$floor < bm$anchors$ceiling))
  # attempts carry raw and anchored values
  expect_equal(nrow(bm$attempts), 6)
  a <- bm$anchors
  expect_equal(bm$attempts$overlap,
               100 * (bm$attempts$overlap_raw - a$floor[1]) / (a$ceiling[1] - a$floor[1]))
  expect_s3_class(bm$behaviour, "sc_behaviour")
  expect_output(print(bm), "authenticity benchmark")
  expect_identical(tidy(bm), bm$table)
  expect_s3_class(gg_benchmark(bm), "ggplot")
  expect_s3_class(autoplot(bm), "ggplot")
})

test_that("the score can be the mean, the geometric mean or a user function", {
  v <- c(80, 40, 60)
  expect_equal(bm_score(v, "weakest", bm_weights(NULL))$score, 40)
  expect_equal(bm_score(v, "weakest", bm_weights(NULL))$weakest, "structure")
  expect_equal(bm_score(v, "mean", bm_weights(NULL))$score, 60)
  expect_equal(bm_score(v, "mean", bm_weights(c(overlap = 2)))$score, (160 + 40 + 60) / 4)
  expect_equal(bm_score(v, "geometric", bm_weights(NULL))$score, (80 * 40 * 60)^(1 / 3))
  expect_equal(bm_score(c(120, -5, 50), "geometric", bm_weights(NULL))$score, 0)
  expect_equal(bm_score(v, function(overlap, structure, behaviour) overlap - behaviour,
                        bm_weights(NULL))$score, 20)
  expect_error(bm_weights(c(foo = 1)), "weights")
  expect_error(bm_weights(c(overlap = -1)), "weights")
})

test_that("authenticity_benchmark() handles options and bad input", {
  real <- beh_sim(600)
  syn <- list(A = list(beh_sim(100, 3), beh_sim(100, 4)))
  bm <- authenticity_benchmark(syn, real, beh_items(), score = "mean", n_splits = 3, n_floor = 3,
                               ceiling_n = "half", fit_scales = character(0))
  expect_equal(bm$settings$anchor_n, 300L)
  expect_equal(bm$table$score, mean(c(bm$table$overlap, bm$table$structure, bm$table$behaviour)))
  expect_error(authenticity_benchmark(list(beh_sim(50)), real, beh_items()), "named list")
  expect_error(authenticity_benchmark(syn, real, beh_items(), score = "best"))
})
