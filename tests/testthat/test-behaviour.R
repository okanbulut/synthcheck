test_that("behaviour_features() computes the eight features", {
  real <- beh_sim(600)
  odd <- rbind(real[1:2, ], 4, beh_random(1))
  odd[2, 1:20] <- NA
  f <- behaviour_features(odd, beh_items(), real = real)
  expect_s3_class(f, "tbl_df")
  expect_named(f, c("variability", "extreme", "midpoint", "acquiescence", "key_inconsistency",
                    "even_odd", "mahalanobis", "person_fit"))
  expect_equal(nrow(f), 4)
  # too few answers: all features missing
  expect_true(all(is.na(unlist(f[2, ]))))
  # a straight-liner at the midpoint
  expect_equal(f$variability[3], 0)
  expect_equal(f$extreme[3], 0)
  expect_equal(f$midpoint[3], 1)
  expect_equal(f$acquiescence[3], 0)
  expect_true(is.na(f$even_odd[3]))
  # person fit skipped
  f0 <- behaviour_features(real[1:5, ], beh_items(), real = real, fit_scales = character(0))
  expect_true(all(is.na(f0$person_fit)))
  expect_error(behaviour_features(real, beh_items(), fit_scales = "nope"), "fit_scales")
  # trait column in place of scale, no facets
  it2 <- beh_items()[c("item", "scale", "reverse")]; names(it2)[2] <- "trait"
  f2 <- behaviour_features(real[1:5, ], it2, real = real, fit_scales = character(0))
  expect_true(all(is.na(f2$even_odd)))  # only two scales stand in for facets
  expect_false(anyNA(f2$mahalanobis))
})

test_that("random respondents look careless on the careless side", {
  real <- beh_sim(800)
  fr <- behaviour_features(real, beh_items())
  fx <- behaviour_features(beh_random(200), beh_items(), real = real)
  expect_gt(median(fx$key_inconsistency), median(fr$key_inconsistency))
  expect_lt(median(fx$even_odd, na.rm = TRUE), median(fr$even_odd, na.rm = TRUE))
  expect_lt(median(fx$person_fit), median(fr$person_fit) - 1)
  # random answers pull every facet mean to the middle of the scale
  expect_lt(sd(fx$acquiescence), sd(fr$acquiescence))
})

test_that("flag_careless() finds planted careless respondents", {
  real <- rbind(beh_sim(800), beh_random(15))
  fl <- flag_careless(real, beh_items())
  expect_equal(nrow(fl), 815)
  planted <- 801:815
  expect_gt(mean(fl$careless[planted]), 0.4)
  expect_lt(mean(fl$careless[-planted]), 0.05)
  # a user rule
  fl2 <- flag_careless(real, beh_items(), rule = function(f) f$variability > 2.5,
                       fit_scales = character(0))
  expect_true(all(is.na(fl2$n_flags)))
  expect_equal(fl2$careless, !is.na(fl2$variability) & fl2$variability > 2.5)
  expect_error(flag_careless(real, beh_items(), rule = function(f) TRUE), "one logical")
})

test_that("synthetic_behaviour() rewards real-like and penalizes random respondents", {
  real <- beh_sim(1000)
  syn <- list("Real-like" = list(beh_sim(300, 5), beh_sim(300, 6)),
              "Random" = list(beh_random(300, 7), beh_random(300, 8)))
  b <- synthetic_behaviour(syn, real, beh_items())
  expect_s3_class(b, "sc_behaviour")
  s <- b$summary
  expect_equal(s$model, c("Real-like", "Random"))
  expect_gt(s$behaviour_overall[1], 85)
  expect_lt(s$behaviour_overall[2], 60)
  expect_gt(s$lz_low[2], 0.3)
  expect_lt(abs(s$lz_low[1] - 0.05), 0.04)
  f <- b$features
  expect_equal(nrow(f), 4 * 8)
  expect_true(all(f$B >= 10 & f$B <= 100, na.rm = TRUE))
  expect_equal(f$direction[f$model == "Random" & f$feature == "person_fit"][1], "lower")
  expect_equal(f$direction[f$model == "Random" & f$feature == "key_inconsistency"][1], "higher")
  # reproducible, and the caller's random state is untouched
  set.seed(3); r1 <- runif(1)
  set.seed(3); b2 <- synthetic_behaviour(syn, real, beh_items()); r2 <- runif(1)
  expect_identical(b$features, b2$features)
  expect_identical(r1, r2)
  expect_output(print(b), "Behaviour")
  expect_identical(tidy(b), b$summary)
  expect_s3_class(gg_behaviour(b), "ggplot")
  expect_s3_class(gg_behaviour(b, by = "attempt"), "ggplot")
  expect_s3_class(autoplot(b), "ggplot")
  # clean_real removes careless real respondents
  bc <- synthetic_behaviour(syn, rbind(real, beh_random(50)), beh_items(), clean_real = TRUE)
  expect_true(bc$settings$clean_real)
  expect_lt(bc$settings$n_real, 1050)
  expect_equal(nrow(bc$careless), 1050)
})

test_that("the decile overlap breaks ties and stays between 10 and 100", {
  set.seed(1)
  real <- sample(0:3, 500, replace = TRUE)
  expect_equal(bh_overlap(real, real), 100, tolerance = 2)
  expect_equal(bh_overlap(rep(10, 50), real), 10)
  expect_true(is.na(bh_overlap(numeric(0), real)))
})

test_that("Behaviour reproduces the pilot on the HEXACO data", {
  skip_on_cran()
  real <- hexaco_real[hexaco_real$country == "Canada", ]
  ca <- hexaco_llm[hexaco_llm$country == "Canada" &
                     hexaco_llm$model %in% c("Qwen 3.5 122B", "Qwen 3.8 27B", "GPT-OSS-120B", "Gemma 4 26B"), ]
  syn <- lapply(split(ca, ca$model, drop = TRUE), function(m) split(m, m$attempt))
  b <- synthetic_behaviour(syn, real, hexaco_items, fit_scales = "H")
  s <- b$summary
  target <- c("Qwen 3.5 122B" = 48, "Qwen 3.8 27B" = 42, "GPT-OSS-120B" = 38, "Gemma 4 26B" = 20)
  expect_true(all(abs(s$behaviour_overall[match(names(target), s$model)] - target) <= 2))
  fr <- b$real_features
  expect_equal(median(fr$person_fit, na.rm = TRUE), 0.46, tolerance = 0.05)
  expect_equal(median(fr$even_odd, na.rm = TRUE), 0.71, tolerance = 0.03)
  expect_equal(median(fr$extreme, na.rm = TRUE), 0.18, tolerance = 0.02)
  med <- function(m, f) median(b$features$median_synthetic[b$features$model == m & b$features$feature == f])
  expect_equal(med("Qwen 3.5 122B", "person_fit"), 1.08, tolerance = 0.1)
  expect_equal(med("Gemma 4 26B", "person_fit"), 1.56, tolerance = 0.1)
  expect_equal(med("Qwen 3.5 122B", "extreme"), 0.12, tolerance = 0.02)
})
