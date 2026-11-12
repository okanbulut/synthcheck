test_that("sc_instrument() takes a table or statements and checks the scale", {
  ins <- sc_instrument(hexaco_items[1:5, ], scale = c(1, 7), name = "HEXACO")
  expect_s3_class(ins, "sc_instrument")
  expect_equal(ins$min, 1L); expect_equal(ins$max, 7L)
  expect_length(ins$labels, 7)
  expect_true("scale" %in% names(ins$items))
  s <- sc_instrument(c("I like parties.", "I am tidy."), scale = c(1, 4))
  expect_equal(s$items$item, c("i1", "i2"))
  expect_null(s$labels)
  expect_error(sc_instrument(c("a"), scale = c(3, 1)), "lowest and highest")
  expect_error(sc_instrument(c("a", "b"), scale = c(1, 3), labels = c("x", "y")), "one label")
  expect_error(sc_instrument(data.frame(item = c("a", "a"), statement = c("x", "y"))), "unique")
  expect_output(print(ins), "5 items")
})

test_that("sc_personas() and sc_persona_grid() build persona tables", {
  p <- sc_personas(c("You are a nurse.", "", "You are a farmer."))
  expect_equal(nrow(p), 2)
  expect_equal(p$persona_id, c("p001", "p002"))
  g <- sc_persona_grid(age = c(25, 65), country = c("Canada", "Mexico"),
                       template = "You are {age} and live in {country}.")
  expect_equal(nrow(g), 4)
  expect_equal(g$description[1], "You are 25 and live in Canada.")
  expect_true(all(c("age", "country") %in% names(g)))
  expect_error(sc_persona_grid(age = 30, template = "You are {age} in {city}."), "city")
})

test_that("sc_prompt() puts the persona in the system prompt and every item in the user prompt", {
  ins <- sc_instrument(hexaco_items[1:3, ], scale = c(1, 7))
  p <- sc_prompt(ins, "You are a 30-year-old teacher.")
  expect_match(p$system, "30-year-old teacher")
  for (i in ins$items$item) expect_match(p$user, paste0(i, ": "), fixed = TRUE)
  expect_match(p$user, "7 = Strongly agree", fixed = TRUE)
  expect_match(sc_prompt(ins)$system, "taking part in a survey")
  expect_false(grepl(ins$items$item[3], sc_prompt(ins, items = ins$items$item[1:2])$user, fixed = TRUE))
})

test_that("sc_check() keeps whole answers in range and drops the rest", {
  v <- sc_check(list(a = 3, b = 9, c = "2", d = 2.5), c("a", "b", "c", "d", "e"), 1, 7)
  expect_equal(unname(v), c(3L, NA, 2L, NA, NA))
})

test_that("sc_model() fills defaults and checks the temperature", {
  m <- sc_model("anthropic")
  expect_equal(m$model, sc_default_models$anthropic)
  expect_equal(m$name, m$model)
  expect_null(sc_model("openai", temperature = NULL)$temperature)
  expect_error(sc_model("openai", temperature = 3), "between 0 and 2")
  expect_error(sc_model("ollama"), "model id")
  expect_output(print(m), "anthropic")
})

test_that("generate_synthetic() makes one row per respondent and saves each attempt", {
  ins <- sc_instrument(hexaco_items[hexaco_items$trait == "H", ], scale = c(1, 7))
  per <- sc_persona_grid(age = c(25, 65), template = "You are {age} years old.")
  dir <- withr::local_tempdir()
  seen <- 0
  syn <- generate_synthetic(ins, list(sc_model("mock", name = "A"), sc_model("mock", name = "B")),
                            per, attempts = 2, respondents = 3, output = dir, format = "csv",
                            progress = function(info) seen <<- info$done)
  expect_equal(nrow(syn), 2 * 2 * 2 * 3)
  expect_equal(seen, 24)
  expect_true(all(ins$items$item %in% names(syn)))
  expect_true(all(c("model", "attempt", "persona_id", "respondent", "age") %in% names(syn)))
  expect_true(all(unlist(syn[ins$items$item]) %in% 1:7))
  files <- list.files(dir)
  expect_true(all(c("run.json", "prompts.json", "A_attempt01.csv", "B_attempt02.csv") %in% files))
  run <- jsonlite::read_json(file.path(dir, "run.json"), simplifyVector = TRUE)
  expect_equal(run$attempts, 2)
  expect_false(any(grepl("api_key|sk-", readLines(file.path(dir, "run.json")))))
  back <- read_synthetic(dir)
  expect_equal(nrow(back), nrow(syn))
  # the same seed gives the same answers
  again <- generate_synthetic(ins, list(sc_model("mock", name = "A"), sc_model("mock", name = "B")),
                              per, attempts = 2, respondents = 3, progress = FALSE)
  expect_equal(as.data.frame(again), as.data.frame(syn), ignore_attr = TRUE)
  # benchmark input
  l <- as_synthetic_list(syn)
  expect_named(l, c("A", "B"))
  expect_length(l$A, 2)
  expect_equal(nrow(l$A[[1]]), 6)
})

test_that("generate_synthetic() writes progress and stops on the stop file", {
  ins <- sc_instrument(c("x", "y", "z"), scale = c(1, 5))
  dir <- withr::local_tempdir()
  stop_file <- file.path(dir, "STOP")
  n <- 0
  syn <- generate_synthetic(ins, sc_model("mock"), attempts = 3, respondents = 4, output = dir,
                            progress_file = file.path(dir, "progress.json"), stop_file = stop_file,
                            progress = function(info) {
                              n <<- info$done
                              if (info$done == 4) writeLines("stop", stop_file)
                            })
  expect_true(attr(syn, "stopped"))
  expect_equal(nrow(syn), 4)
  p <- jsonlite::read_json(file.path(dir, "progress.json"))
  expect_equal(p$status, "stopped")
  expect_equal(p$total, 12)
  expect_equal(p$done, 4)
})

test_that("generate_synthetic() checks its input", {
  ins <- sc_instrument(c("x", "y"), scale = c(1, 5))
  expect_error(generate_synthetic(list(), sc_model("mock")), "sc_instrument")
  expect_error(generate_synthetic(ins, "mock"), "sc_model")
  expect_error(generate_synthetic(ins, list(sc_model("mock"), sc_model("mock"))), "own `name`")
  expect_error(generate_synthetic(ins, sc_model("mock"), attempts = 0), "at least 1")
})

test_that("write_synthetic() and read_synthetic() round-trip every format", {
  d <- data.frame(model = "m", attempt = 1:3, i1 = c(1L, NA, 3L), i2 = 4:6)
  for (f in c("csv", "json", "rds")) {
    path <- withr::local_tempfile(fileext = paste0(".", f))
    write_synthetic(d, path)
    back <- as.data.frame(read_synthetic(path))
    expect_equal(back$i1, d$i1, info = f)
    expect_equal(back$attempt, d$attempt, info = f)
  }
  expect_error(write_synthetic(d, "x.txt"), "format")
  expect_error(read_synthetic(file.path(tempdir(), "no-such-file.csv")), "No file")
})

test_that("sc_duration() reads as minutes and hours", {
  expect_equal(sc_duration(42), "42s")
  expect_equal(sc_duration(125), "2m 05s")
  expect_equal(sc_duration(7300), "2h 01m")
  expect_equal(sc_duration(NA), "--")
})

test_that("sc_respondent() asks blocks in one conversation and retries invalid answers", {
  skip_if_not_installed("ellmer")
  ins <- sc_instrument(c("a", "b", "c", "d", "e"), scale = c(1, 5))
  calls <- list()
  bad <- TRUE
  fake_chat <- function(system) {
    n <- 0
    list(chat_structured = function(prompt, type) {
      n <<- n + 1
      calls[[length(calls) + 1L]] <<- list(system = system, prompt = prompt, turn = n)
      items <- names(type@properties)
      # the very first answer is out of range
      out <- stats::setNames(as.list(ifelse(seq_along(items) == 1 & bad, 9, 3)), items)
      bad <<- FALSE
      out
    })
  }
  local_mocked_bindings(sc_chat = function(m, system) fake_chat(system))
  r <- sc_respondent(sc_model("openai"), ins, "You are a nurse.", ins$items$item, 1L,
                     block_size = 2, max_retries = 2)[[1]]
  expect_true(r$ok)
  expect_equal(unname(r$values), rep(3L, 5))
  expect_equal(r$retries, 1L)
  # three blocks in the first conversation, then only the missing item again
  expect_length(calls, 4)
  expect_equal(vapply(calls, `[[`, numeric(1), "turn"), c(1, 2, 3, 1))
  expect_match(calls[[1]]$system, "nurse")
})

test_that("batches ask for several respondents in one call and retry only the invalid ones", {
  skip_if_not_installed("ellmer")
  ins <- sc_instrument(c("a", "b", "c"), scale = c(1, 5))
  asked <- integer(0)
  local_mocked_bindings(sc_chat = function(m, system) list(chat_structured = function(prompt, type) {
    many <- grepl("different people", prompt, fixed = TRUE)
    n <- if (many) as.integer(sub("(?s).*Answer as ([0-9]+) different people.*", "\\1", prompt, perl = TRUE)) else 1L
    asked <<- c(asked, n)
    # the first call gets one invalid respondent back
    v <- rep(2L, n); if (length(asked) == 1) v[2] <- 7L
    if (!many) return(list(i1 = 2L, i2 = 3L, i3 = 4L))
    list(respondents = data.frame(i1 = v, i2 = 3L, i3 = 4L))
  }))
  r <- sc_respondent(sc_model("openai"), ins, "You are a nurse.", ins$items$item, 1L, NULL, 2L, k = 4)
  expect_length(r, 4)
  expect_true(all(vapply(r, `[[`, logical(1), "ok")))
  expect_equal(asked, c(4L, 1L))
  expect_match(sc_prompt(ins, "x", n = 4)$user, "4 different people", fixed = TRUE)
})

test_that("generate_synthetic() splits each persona's respondents into batches", {
  ins <- sc_instrument(c("x", "y"), scale = c(1, 5))
  calls <- 0
  syn <- generate_synthetic(ins, sc_model("mock"), c("A person.", "Another person."),
                            attempts = 2, respondents = 5, batch_size = 2)
  expect_equal(nrow(syn), 2 * 2 * 5)
  expect_equal(as.vector(table(syn$persona_id)), c(10L, 10L))
  expect_error(generate_synthetic(ins, sc_model("mock"), batch_size = 2, block_size = 1), "not both")
  expect_error(generate_synthetic(ins, sc_model("mock"), batch_size = 0), "at least 1")
})

test_that("parallel calls run through the async path and keep the order", {
  skip_if_not_installed("ellmer")
  skip_if_not_installed("promises")
  skip_if_not_installed("later")
  ins <- sc_instrument(c("a", "b"), scale = c(1, 5))
  local_mocked_bindings(sc_chat = function(m, system) list(chat_structured_async = function(prompt, type) {
    # each persona answers with its own number
    k <- as.integer(sub("^You are person ([0-9]+)\\..*", "\\1", system))
    promises::promise(function(resolve, reject) later::later(function() resolve(list(i1 = k, i2 = k)), 0.01))
  }))
  per <- sprintf("You are person %d.", 1:5)
  syn <- generate_synthetic(ins, sc_model("openai"), per, attempts = 1, respondents = 2,
                            parallel = 4, progress = FALSE)
  expect_equal(nrow(syn), 10)
  expect_equal(syn$i1, rep(1:5, each = 2))
  expect_equal(syn$persona_id, rep(sprintf("p%03d", 1:5), each = 2))
})

test_that("the templates load as an instrument and personas", {
  ins <- sc_instrument(read.csv(system.file("templates", "instrument_template.csv",
                                            package = "synthcheck")), scale = c(1, 5))
  expect_equal(nrow(ins$items), 8)
  expect_equal(sum(ins$items$reverse), 4)
  per <- sc_personas(read.csv(system.file("templates", "personas_template.csv",
                                          package = "synthcheck")))
  expect_equal(nrow(per), 4)
  expect_true(all(c("age", "country") %in% names(per)))
})
