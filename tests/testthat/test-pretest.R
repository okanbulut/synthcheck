# simulated data with a known structure: Two scales of five items, one
# reverse-keyed item per scale, one dead item, one near-duplicate pair, one
# item written for A that measures B, and one reverse item keyed wrongly
sim_pretest <- function(n = 400, seed = 1) {
  set.seed(seed)
  fa <- stats::rnorm(n); fb <- stats::rnorm(n)
  cat7 <- function(z) pmin(7, pmax(1, round(4 + 1.3 * z)))
  d <- data.frame(
    a1 = cat7(fa + stats::rnorm(n, 0, .7)), a2 = cat7(fa + stats::rnorm(n, 0, .7)),
    a3 = cat7(-fa + stats::rnorm(n, 0, .7)),          # reverse-keyed, keyed correctly
    a4 = cat7(fb + stats::rnorm(n, 0, .5)),           # written for A, measures B
    a5 = rep(4, n),                                   # dead item
    b1 = cat7(fb + stats::rnorm(n, 0, .7)), b2 = cat7(fb + stats::rnorm(n, 0, .7)),
    b3 = cat7(fb + stats::rnorm(n, 0, .7)),           # marked reverse, but is not
    b4 = NA, b5 = cat7(fb + stats::rnorm(n, 0, .7)))
  d$b4 <- pmin(7, pmax(1, d$b1 + sample(c(0, 0, 0, 0, 1, -1), n, TRUE)))  # near-duplicate of b1
  items <- data.frame(item = names(d), scale = rep(c("A", "B"), each = 5),
                      reverse = c(FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE))
  list(data = d, items = items)
}

test_that("the pretest flags the planted problem items", {
  s <- sim_pretest()
  pt <- synthetic_pretest(s$data, s$items, irt = FALSE, n_pa = 5, scale_range = c(1, 7))
  expect_s3_class(pt, "sc_pretest")
  expect_equal(pt$settings$conditions, "Data")
  it <- as.data.frame(pt$items)
  flag <- function(i, f) it[[f]][it$item == i]
  expect_true(flag("a5", "low_variance"))
  expect_true(flag("a4", "other_scale"))
  expect_equal(it$closest[it$item == "a4"], "B")
  expect_true(flag("b3", "key"))
  expect_match(it$flags[it$item == "b3"], "Reverse key not working", fixed = TRUE)
  expect_true(flag("b4", "redundant"))
  expect_equal(it$twin[it$item == "b4"], "b1")
  # the correctly keyed reverse item is fine
  expect_false(flag("a3", "key"))
  expect_gt(it$item_rest[it$item == "a3"], 0.5)
  expect_false(any(unlist(it[it$item %in% c("a1", "a2", "b2", "b5"),
                             c("low_variance", "key", "weak", "other_scale")])))
  s1 <- as.data.frame(pt$summary)
  expect_equal(s1$reverse_ok, 0.5)
  expect_equal(s1$scales, 2)
  expect_equal(s1$n_factors, 2L)
})

test_that("the expected structure is recovered from clean simulated data", {
  s <- sim_pretest()
  d <- s$data; it <- s$items
  keep <- c("a1", "a2", "a3", "b1", "b2", "b5")
  pt <- synthetic_pretest(d[keep], it[it$item %in% keep, ], irt = FALSE, n_pa = 5)
  expect_equal(pt$summary$own_scale, 1)
  expect_equal(pt$summary$reverse_ok, 1)
  expect_equal(pt$summary$flagged, 0L)
  expect_equal(pt$scales$n_factors, c(1L, 1L))
})

test_that("conditions, attempts and agreement work on hexaco_llm", {
  h <- hexaco_items[hexaco_items$trait %in% c("H", "C"), ]
  ca <- hexaco_llm[hexaco_llm$country == "Canada" & hexaco_llm$attempt <= 2 &
                     hexaco_llm$model %in% c("Qwen 3.8 27B", "Gemma 4 26B", "GPT-4.1 mini"), ]
  pt <- synthetic_pretest(ca, h, irt = FALSE, n_pa = 3)
  expect_setequal(pt$settings$conditions, unique(ca$model))
  expect_equal(nrow(pt$items), 3 * 80)
  expect_equal(nrow(pt$agreement), 80)
  expect_equal(nrow(pt$stability), 3)
  expect_true(all(pt$summary$attempts == 2))
  expect_true(all(pt$agreement$flagged_in %in% 0:3))
  expect_true(all(pt$items$attempt_share >= 0 & pt$items$attempt_share <= 1))
  # the agreement table is sorted, most often flagged first
  expect_false(is.unsorted(rev(pt$agreement$flagged_in)))
  expect_equal(pt$settings$scale_range, c(1, 7))
  # the list input gives the same result
  pl <- synthetic_pretest(as_synthetic_list(ca), h, irt = FALSE, n_pa = 3)
  expect_equal(sort(pl$summary$flagged), sort(pt$summary$flagged))
  # several `by` columns are joined
  ca$wording <- ifelse(ca$attempt == 1, "A", "B")
  pw <- synthetic_pretest(ca, h, by = c("model", "wording"), irt = FALSE, n_pa = 0)
  expect_length(pw$settings$conditions, 6)
  expect_match(pw$settings$conditions[1], " / ", fixed = TRUE)
  expect_true(all(is.na(pw$summary$n_factors)))
})

test_that("the summary, plots, print and tidy work", {
  s <- sim_pretest()
  d <- rbind(cbind(model = "M1", s$data), cbind(model = "M2", sim_pretest(seed = 2)$data))
  pt <- synthetic_pretest(d, s$items, irt = FALSE, n_pa = 3)
  sm <- summarise_pretest(pt)
  expect_s3_class(sm, "sc_pretest_summary")
  expect_match(sm$text[1], "pilot screening", fixed = TRUE)
  expect_true(any(grepl("a5", sm$text, fixed = TRUE)))
  expect_output(print(sm), "Pretest without real data")
  expect_output(print(pt), "Pilot screening, not validation")
  expect_s3_class(gg_pretest(pt), "ggplot")
  expect_s3_class(gg_pretest(pt, "scales"), "ggplot")
  expect_s3_class(ggplot2::autoplot(pt), "ggplot")
  expect_identical(generics::tidy(pt), pt$agreement)
})

test_that("an instrument gives the items and the scale range", {
  s <- sim_pretest()
  ins <- sc_instrument(cbind(s$items, statement = paste("Statement", 1:10)), scale = c(1, 7))
  pt <- synthetic_pretest(s$data, ins, irt = FALSE, n_pa = 0)
  expect_equal(pt$settings$scale_range, c(1, 7))
  # without a scale column, all items form one scale
  p1 <- synthetic_pretest(s$data, data.frame(item = names(s$data)), irt = FALSE, n_pa = 0)
  expect_equal(unique(p1$items$scale), "All")
  expect_error(synthetic_pretest(s$data, s$items, thresholds = list(foo = 1)), "Unknown")
  expect_error(synthetic_pretest(cbind(model = "x", s$data), s$items, by = c("model", "nope")),
               "Only some")
})

test_that("IRT slopes come from mirt", {
  skip_on_cran()
  s <- sim_pretest()
  pt <- synthetic_pretest(s$data, s$items, irt = TRUE, n_pa = 0)
  sl <- stats::setNames(pt$items$slope, pt$items$item)
  expect_true(is.na(sl[["a5"]]))
  expect_gt(sl[["a1"]], 1)
  expect_lt(sl[["b3"]], 0)
})
