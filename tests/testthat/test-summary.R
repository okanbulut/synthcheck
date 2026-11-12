test_that("summarise_benchmark() writes one plain summary per model from the table", {
  real <- beh_sim(800)
  shuffle <- function(n, seed) {
    set.seed(seed)
    as.data.frame(lapply(real, function(v) sample(v, n, replace = TRUE)))
  }
  syn <- list("Real-like" = list(beh_sim(200, 5), beh_sim(200, 6)),
              "Random" = list(beh_random(200, 9), beh_random(200, 10)))
  bm <- authenticity_benchmark(syn, real, beh_items(), fit_scales = character(0),
                               n_splits = 4, n_floor = 4)
  s <- summarise_benchmark(bm)
  expect_s3_class(s, "sc_summary")
  expect_equal(s$model, bm$table$model)
  expect_match(s$summary[1], "^Real-like scores")
  expect_match(s$summary[1], "1st of 2", fixed = TRUE)
  r <- bm$table[bm$table$model == "Random", ]
  expect_match(s$summary[s$model == "Random"], sprintf("scores %.0f", r$score), fixed = TRUE)
  expect_match(s$summary[s$model == "Random"], "Compared with real people")
  expect_output(print(s), "plain language")
  expect_error(summarise_benchmark(list()), "authenticity_benchmark")
})

test_that("sc_band() reads anchored values", {
  expect_equal(sc_band(-20), "worse than shuffled columns")
  expect_equal(sc_band(90), "close to a second sample of real people")
  expect_equal(sc_ordinal(c(1)), "1st")
  expect_equal(sc_ordinal(12), "12th")
  expect_equal(sc_ordinal(23), "23rd")
})
