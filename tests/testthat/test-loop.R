lp_h <- function() {
  h <- hexaco_items[hexaco_items$facet %in% c("HSinc", "HFair"), ]
  h$scale <- h$facet
  h
}
lp_con <- function() loop_construct("Honesty-Humility", "Sincerity and fairness.",
                                    scales = c(HSinc = "Sincerity", HFair = "Fairness"),
                                    scale = c(1, 7))
lp_run <- function(...) revision_loop(lp_con(), ..., models = sc_model("mock"), respondents = 40,
                                      evaluator = NULL, checker = loop_checker(n_pa = 3),
                                      cache = FALSE, progress = FALSE)

expect_schema <- function(run) {
  for (t in unique(loop_log_schema()$table))
    expect_equal(names(run[[t]]), loop_log_schema(t)$column, info = t)
}

test_that("loop_construct() checks its input", {
  con <- lp_con()
  expect_s3_class(con, "sc_construct_spec")
  expect_equal(con$scale, c(1L, 7L))
  expect_output(print(con), "2 scales")
  expect_equal(names(loop_construct("Grit")$scales), "Grit")
  expect_error(loop_construct(""), "non-empty")
  expect_error(loop_construct("x", scales = c("a", "b")), "named")
  expect_error(loop_construct("x", reverse_share = 2), "between 0 and 1")
})

test_that("the drop reviser logs every round in the schema", {
  run <- lp_run(items = lp_h(), max_rounds = 4)
  expect_s3_class(run, "sc_loop")
  expect_schema(run)
  expect_true(run$runs$status %in% c("stalled", "max_rounds", "polished"))
  expect_equal(run$rounds$round, seq_len(run$runs$rounds))
  drops <- run$edits[run$edits$action == "drop", ]
  expect_gt(nrow(drops), 0)
  expect_true(all(drops$cites_flagged))
  expect_true(all(is.na(drops$resolved)))
  # items shrink by the drops, and every scale keeps 3 items
  r1 <- run$items[run$items$round == 1, ]
  r2 <- run$items[run$items$round == 2, ]
  expect_equal(nrow(r2), nrow(r1) - sum(drops$round == 1))
  expect_true(all(table(run$final_items$scale) >= 3))
  expect_equal(run$rounds$n_items, as.vector(table(run$items$round)))
  expect_true(all(run$flags$severity %in% c("fail", "warn")))
  expect_true(all(c("alpha", "own_scale", "careless_share") %in% run$stats$stat))
  expect_output(print(run), "Item-revision loop")
  expect_s3_class(gg_loop(run), "ggplot")
  expect_identical(generics::tidy(run, "edits"), run$edits)
})

test_that("a reviser's rewords are versioned and linked to their flags", {
  run <- lp_run(items = lp_h(), max_rounds = 3, reviser = loop_reviser_llm(sc_model("mock")))
  expect_schema(run)
  ed <- run$edits
  expect_true(all(ed$action == "reword"))
  expect_true(all(ed$applied))
  expect_true(all(ed$similarity > 0 & ed$similarity <= 1))
  expect_true(all(ed$cites_flagged))
  expect_false(anyNA(ed$resolved[ed$round < max(run$rounds$round)]))
  it <- run$items
  e1 <- ed[ed$round == 1, ]
  r2 <- it[it$round == 2 & it$item %in% e1$item, ]
  expect_true(all(r2$change == "reworded"))
  expect_true(all(r2$version == 2L))
  expect_equal(r2$statement[match(e1$item, r2$item)], e1$new_statement)
  expect_true(all(it$change[it$round == 1] == "first"))
})

test_that("a writer can supply the first items", {
  run <- lp_run(writer = loop_writer_llm(sc_model("mock")), max_rounds = 1)
  expect_equal(run$runs$writer, "mock (language model writer)")
  expect_equal(run$runs$writer_reasoning, "Mock items.")
  expect_equal(nrow(run$items), 12L)
  expect_match(run$items$item[1], "^HSinc0[1-6]$")
  expect_equal(run$runs$status, "max_rounds")
  expect_error(revision_loop(lp_con()), "starting `items` or a `writer`")
})

test_that("the loop stops when the criterion passes", {
  crit <- loop_criterion(no_failing_items = FALSE, min = list(), max = list(), min_items = 3)
  run <- revision_loop(lp_con(), lp_h(), respondents = 10, evaluator = NULL, checker = NULL,
                       criterion = crit, cache = FALSE)
  expect_equal(run$runs$status, "polished")
  expect_equal(run$runs$rounds, 1L)
  expect_true(run$rounds$polished)
  expect_equal(nrow(run$edits), 0L)
  # a stat no step reports fails rather than passing quietly
  f <- loop_criterion(min = list(marginal_rxx = 0.8))
  cr <- f(lp_table(data.frame(), "flags"), lp_table(data.frame(), "stats"), lp_items(lp_h()), list())
  expect_false(cr$pass[cr$criterion == "min_marginal_rxx"])
  expect_match(attr(loop_criterion(), "label"), "alpha >= 0.8")
})

test_that("a failing step keeps the rounds done so far", {
  bad <- function(items, flags, context) if (context$round == 2) stop("no answer") else
    list(edits = data.frame(item = items$item[1], action = "reword", statement = "New text."))
  expect_warning(run <- lp_run(items = lp_h(), max_rounds = 4, reviser = bad), "round 2")
  expect_equal(run$runs$status, "error")
  expect_match(run$runs$message, "The reviser failed: no answer")
  expect_equal(run$runs$rounds, 2L)
  expect_equal(nrow(run$rounds), 2L)
})

test_that("edits are checked before they are applied", {
  it <- lp_items(lp_h())
  fl <- lp_table(data.frame(item = "HSinc1", check = "weak", severity = "fail"), "flags")
  e <- lp_edits(data.frame(
    item = c("HSinc1", "HSinc1", "nope", NA, "HFair1", "HFair2", "HFair3"),
    action = c("reword", "drop", "drop", "add", "rekey", "reword", "jump"),
    statement = c("I tell the truth.", "", "", "I keep my promises.", "", "", ""),
    scale = c(NA, NA, NA, "HFair", NA, NA, NA),
    cites = I(list("weak", "weak", "", "", c("key", "weak"), "", "")),
    stringsAsFactors = FALSE))
  ap <- lp_apply_edits(it, e, 1L, fl)
  expect_equal(ap$edits$applied, c(TRUE, FALSE, FALSE, TRUE, TRUE, FALSE, FALSE))
  expect_match(ap$edits$note[2], "already edited")
  expect_match(ap$edits$note[3], "No such item")
  expect_match(ap$edits$note[6], "needs a new statement")
  expect_match(ap$edits$note[7], "Unknown action")
  expect_equal(ap$edits$item[4], "HFair.r1.1")
  expect_true("HFair.r1.1" %in% ap$items$item)
  j <- match("HFair1", it$item)
  expect_equal(ap$items$reverse[match("HFair1", ap$items$item)], !it$reverse[j])
  expect_equal(ap$items$version[match("HSinc1", ap$items$item)], 2L)
  expect_equal(ap$edits$cites_flagged[c(1, 5)], c(TRUE, FALSE))
  expect_equal(ap$edits$cites[5], "key,weak")
})

test_that("read_loop() stacks runs with the schema's types", {
  dir <- withr::local_tempdir()
  for (s in 1:2) lp_run(items = lp_h(), max_rounds = 2, seed = s,
                        output = file.path(dir, paste0("seed", s)))
  expect_true(file.exists(file.path(dir, "seed1", "responses", "round-01.csv")))
  one <- read_loop(file.path(dir, "seed1"))
  expect_equal(nrow(one$runs), 1L)
  both <- read_loop(dir)
  expect_schema(both)
  expect_equal(both$runs$run_id, c("Honesty_Humility-seed1", "Honesty_Humility-seed2"))
  expect_type(both$items$reverse, "logical")
  expect_type(both$rounds$round, "integer")
  expect_output(print(both), "2 item-revision loops")
  expect_s3_class(gg_loop(both, run = "Honesty_Humility-seed2"), "ggplot")
  expect_error(read_loop(withr::local_tempdir()), "No loop log")
})

test_that("loop_irt() flags misfitting, weak and constant items", {
  skip_on_cran()
  set.seed(3)
  a <- matrix(c(rep(1.6, 5), 0))
  d <- t(apply(matrix(rnorm(6 * 4), 6), 1, sort, decreasing = TRUE))
  X <- mirt::simdata(a, d, 400, itemtype = "graded") + 1
  colnames(X) <- paste0("i", 1:6)
  X <- as.data.frame(X)
  X$i7 <- 3
  items <- data.frame(item = paste0("i", 1:7), scale = "s", reverse = FALSE,
                      statement = "x", stringsAsFactors = FALSE)
  ctx <- list(construct = loop_construct("s", scale = c(1, 5)))
  # the partial credit model (default): The noise item misfits
  out <- loop_irt()(X, items, ctx)
  fl <- out$flags
  expect_true("i6" %in% fl$item[fl$check %in% c("msq_misfit", "misfit") & fl$severity == "fail"])
  expect_true("i7" %in% fl$item[fl$check == "no_variance"])
  expect_false("low_slope" %in% fl$check)
  expect_true(all(c("infit", "outfit", "location", "sx2_p", "info_mean", "marginal_rxx") %in%
                    out$stats$stat))
  expect_false("slope" %in% out$stats$stat)
  expect_match(attr(loop_irt(), "label"), "partial credit")
  # the graded response model: The noise item has a low slope
  out <- loop_irt("graded")(X, items, ctx)
  fl <- out$flags
  expect_true("i6" %in% fl$item[fl$check == "low_slope"])
  expect_false(any(fl$item[fl$check == "low_slope"] %in% paste0("i", 1:5)))
  expect_true("slope" %in% out$stats$stat)
  expect_error(loop_irt(thresholds = list(msq = 1)), "lower and an upper")
  # too few items to fit
  out <- loop_irt()(X[, c("i1", "i7")], items[c(1, 7), ], ctx)
  expect_true("irt_failed" %in% out$flags$check)
})

test_that("the language-model steps send the evidence and parse the answer", {
  skip_if_not_installed("ellmer")
  sent <- new.env()
  local_mocked_bindings(sc_chat = function(m, system) {
    list(chat_structured = function(prompt, type) {
      sent$system <- system; sent$prompt <- prompt
      if (grepl("Write 2 items", prompt))
        return(list(items = data.frame(scale = c("HSinc", "HSinc", "HFair", "HFair", "zz"),
                                       statement = c("a", "b", "c", "d", "e"),
                                       reverse = c(FALSE, TRUE, FALSE, TRUE, FALSE)),
                    reasoning = "Covers both."))
      list(edits = list(list(item = "HSinc1", action = "reword", statement = "I am honest.",
                             reverse = FALSE, scale = "HSinc", rationale = "Clearer.",
                             cites = list("weak"))),
           reasoning = "One fix.")
    }, get_tokens = function() data.frame(input = 100, output = 20))
  })
  con <- lp_con(); con$n_per_scale <- 2L
  m <- sc_model("anthropic", "claude-haiku-5-5")
  expect_warning(w <- loop_writer_llm(m)(con, list()), "unknown scales")
  expect_equal(w$items$item, c("HSinc01", "HSinc02", "HFair01", "HFair02"))
  expect_equal(w$reasoning, "Covers both.")
  expect_equal(w$usage$input_tokens, 100)
  expect_equal(w$usage$cost, (100 * 0.1 + 20 * 0.5) / 1e6)
  expect_match(sent$prompt, "HSinc: Sincerity")

  it <- lp_items(lp_h())
  fl <- lp_table(data.frame(item = "HSinc1", scale = "HSinc", check = "weak", severity = "fail",
                            message = "Weak link to its scale."), "flags")[, -(1:2)]
  hist <- lp_empty_log()
  hist$edits <- lp_table(data.frame(round = 1, item = "HSinc2", action = "reword", cites = "key",
                                    applied = TRUE, resolved = FALSE), "edits")
  rv <- loop_reviser_llm(m)(it, fl, list(construct = con, round = 2L, history = hist))
  expect_match(sent$prompt, "weak \\[fail\\]: Weak link to its scale")
  expect_match(sent$prompt, "Round 1, reword HSinc2 for key: not resolved")
  expect_match(sent$system, "Keep at least 3 items")
  expect_equal(rv$edits$cites, "weak")
  expect_equal(rv$reasoning, "One fix.")
  ap <- lp_apply_edits(it, lp_edits(rv$edits), 2L, fl)
  expect_true(ap$edits$applied)
  expect_true(ap$edits$cites_flagged)
})

test_that("the log schema is documented", {
  s <- loop_log_schema()
  expect_setequal(unique(s$table), c("runs", "rounds", "items", "flags", "stats", "criteria",
                                     "edits"))
  expect_true(all(s$type %in% c("character", "integer", "numeric", "logical")))
  expect_error(loop_log_schema("nope"), "Unknown table")
})

test_that("loop_outcomes() summarises each run", {
  run <- lp_run(items = lp_h(), max_rounds = 3, reviser = loop_reviser_llm(sc_model("mock")))
  out <- loop_outcomes(run)
  expect_equal(nrow(out), 1L)
  expect_equal(out$rounds, 3L)
  expect_equal(out$reworded, nrow(run$edits))
  expect_equal(out$cites_flagged, 1)
  expect_true(out$similarity > 0 && out$similarity < 1)
  expect_true(is.na(out$rounds_to_polish))
  expect_equal(out$items_start, 20L)
})

test_that("the financial well-being construct is ready to use", {
  fwb <- loop_builtin_construct("financial_wellbeing")
  expect_equal(names(fwb$scales), c("control", "cushion", "goals", "freedom"))
  expect_equal(fwb$scale, c(1L, 5L))
  expect_equal(loop_builtin_construct(n_per_scale = 8)$n_per_scale, 8L)
  w <- loop_writer_llm(sc_model("mock"))(fwb, list())
  expect_equal(nrow(w$items), 24L)
  expect_setequal(unique(w$items$scale), names(fwb$scales))
})

test_that("a construct can carry its own stopping rule", {
  fwb <- loop_builtin_construct("financial_wellbeing")
  expect_match(attr(fwb$criterion, "label"), "marginal_rxx >= 0.8")
  expect_match(attr(fwb$criterion, "label"), "dimensions match scales")
  run <- revision_loop(fwb, writer = loop_writer_llm(sc_model("mock")), respondents = 30,
                       max_rounds = 1, evaluator = NULL, checker = loop_checker(n_pa = 3),
                       cache = FALSE)
  expect_match(run$runs$criterion, "marginal_rxx")
  expect_true(all(c("min_marginal_rxx", "factors") %in% run$criteria$criterion))
  expect_error(loop_construct("x", criterion = 1), "loop_criterion")
})
