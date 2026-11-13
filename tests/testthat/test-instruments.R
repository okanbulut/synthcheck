test_that("the bundled instruments match their real data", {
  for (nm in names(sc_builtin)) {
    ins <- sc_builtin_instrument(nm)
    expect_s3_class(ins, "sc_instrument")
    real <- sc_builtin_real(nm)
    expect_true(all(ins$items$item %in% names(real)), info = nm)
    x <- unlist(real[ins$items$item])
    expect_true(all(x[!is.na(x)] %in% ins$min:ins$max), info = nm)
    expect_length(ins$labels, ins$max - ins$min + 1)
  }
  expect_equal(nrow(sc_builtin_instrument("rses")$items), 10)
  expect_equal(sum(rses_items$reverse), 5)
  expect_equal(as.vector(table(dass_items$scale)), c(7, 7, 7))
  expect_equal(as.vector(table(mini_ipip_items$scale)), rep(4, 5))
  expect_equal(sum(mini_ipip_items$reverse), 11)
  expect_equal(nrow(sc_builtin_instrument("dass21", scales = "D")$items), 7)
  expect_equal(nrow(sc_builtin_instrument("hexaco", scales = "H")$items), 40)
  expect_error(sc_builtin_instrument("dass21", scales = "X"), "Unknown scale")
})

test_that("the R code for built-in items selects the chosen scales", {
  expect_equal(sc_builtin_items_code("rses", "SE"), "items <- rses_items")
  expect_equal(sc_builtin_items_code("mini_ipip", c("E", "I")),
               'items <- mini_ipip_items[mini_ipip_items$scale %in% c("E", "I"), ]')
})
