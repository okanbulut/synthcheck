fid_data <- function(effect, n = 40, seed = 1) {
  it <- beh_items()
  set.seed(seed)
  per <- rep(c("p1", "p2"), each = n)
  shift <- ifelse(per == "p1", effect, -effect)
  x <- vapply(seq_len(nrow(it)), function(j) {
    s <- if (it$scale[j] == "S1") shift else 0
    v <- pmin(7, pmax(1, round(4 + s + rnorm(2 * n, 0, 1.2))))
    if (it$reverse[j]) 8 - v else v
  }, numeric(2 * n))
  d <- data.frame(model = "M", persona_id = per, x)
  names(d)[-(1:2)] <- it$item
  d
}

test_that("persona_fidelity() finds personas that move a scale and not those that do not", {
  ins <- sc_instrument(cbind(beh_items(), statement = "x"), scale = c(1, 7))
  per <- sc_personas(data.frame(persona_id = c("p1", "p2"), description = c("a", "b"),
                                target_S1 = c(1, -1), target_S2 = c(0, 0)))
  fid <- persona_fidelity(fid_data(1.5), ins, per, n_perm = 100)
  expect_s3_class(fid, "sc_fidelity")
  sep <- fid$separation
  expect_true(sep$separated[sep$scale == "S1"])
  expect_false(sep$separated[sep$scale == "S2"])
  expect_gt(sep$eta2[sep$scale == "S1"], 0.5)
  d <- fid$direction
  expect_equal(nrow(d), 2)
  expect_equal(d$agree, c(1, 1))
  pr <- fid$profiles
  expect_gt(pr$z[pr$persona == "p1" & pr$scale == "S1"], 0)
  expect_lt(pr$z[pr$persona == "p2" & pr$scale == "S1"], 0)
  expect_output(print(fid), "separate respondents on 1 of 2 scales")
  expect_identical(tidy(fid), fid$separation)
  expect_s3_class(gg_persona_fidelity(fid), "ggplot")
  expect_s3_class(autoplot(fid), "ggplot")

  # no effect: no separation
  none <- persona_fidelity(fid_data(0, seed = 2), ins, per, n_perm = 100)
  expect_false(any(none$separation$separated & none$separation$scale == "S1" &
                     none$separation$p < 0.01))
  expect_output(print(none), "Persona check")
})

test_that("persona_fidelity() standardizes against real data and checks its inputs", {
  real <- fid_data(0, n = 200, seed = 3)[-(1:2)]
  syn <- fid_data(1, seed = 4)
  fid <- persona_fidelity(syn, beh_items(), real = real, scale = c(1, 7), n_perm = 50)
  expect_equal(fid$settings$standardized, "real")
  expect_null(fid$direction)
  expect_error(persona_fidelity(syn, beh_items(), n_perm = 50), "scale")
  expect_error(persona_fidelity(syn, beh_items(), scale = c(1, 7), persona = "who"), "who")
  one <- syn; one$persona_id <- "p1"
  expect_error(persona_fidelity(one, beh_items(), scale = c(1, 7)), "two personas")
  expect_error(persona_fidelity(syn, beh_items(), scale = c(1, 7), n_perm = 5), "n_perm")
})
