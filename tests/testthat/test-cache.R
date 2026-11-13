# a fake model: Counts the calls and answers with the respondent's number of calls so far
fake_model <- function(env) {
  env$n <- 0L
  function(m, system) list(
    chat_structured = function(prompt, type) {
      env$n <- env$n + 1L
      items <- names(type@properties)
      stats::setNames(as.list(rep((env$n %% 5L) + 1L, length(items))), items)
    },
    chat_structured_async = function(prompt, type) {
      env$n <- env$n + 1L
      items <- names(type@properties)
      v <- (env$n %% 5L) + 1L
      promises::promise(function(resolve, reject)
        later::later(function() resolve(stats::setNames(as.list(rep(v, length(items))), items)), 0.01))
    })
}

test_that("sc_cache() takes a folder and a mode, and other forms turn into one", {
  d <- withr::local_tempdir()
  c1 <- sc_cache(d)
  expect_s3_class(c1, "sc_cache")
  expect_equal(c1$mode, "reuse")
  expect_output(print(c1), "reuses saved answers")
  expect_equal(sc_as_cache(FALSE)$mode, "off")
  expect_equal(sc_as_cache(NULL)$mode, "off")
  expect_equal(sc_as_cache(d)$dir, d)
  expect_error(sc_as_cache(3), "sc_cache")
  expect_error(sc_cache(d, mode = "sometimes"))
  expect_equal(nrow(sc_cache_info(c1)), 0)
})

test_that("a second run with the same settings comes from the cache", {
  skip_if_not_installed("ellmer")
  ins <- sc_instrument(c("a", "b", "c"), scale = c(1, 5))
  cache <- sc_cache(withr::local_tempdir())
  calls <- new.env()
  local_mocked_bindings(sc_chat = fake_model(calls))
  per <- c("You are a nurse.", "You are a farmer.")
  a <- generate_synthetic(ins, sc_model("openai"), per, attempts = 2, respondents = 3,
                          progress = FALSE, cache = cache)
  expect_equal(calls$n, 12L)
  expect_equal(attr(a, "cache")$saved, 12L)
  # respondents of one persona still get their own calls
  expect_gt(length(unique(a$i1)), 1)
  b <- generate_synthetic(ins, sc_model("openai"), per, attempts = 2, respondents = 3,
                          progress = FALSE, cache = cache)
  expect_equal(calls$n, 12L)
  expect_equal(attr(b, "cache")$hits, 12L)
  expect_equal(a, b, ignore_attr = TRUE)
  # more respondents call only for the new ones
  generate_synthetic(ins, sc_model("openai"), per, attempts = 2, respondents = 4,
                     progress = FALSE, cache = cache)
  expect_equal(calls$n, 16L)
  # a new seed, another temperature or refresh asks again
  generate_synthetic(ins, sc_model("openai"), per, respondents = 3, seed = 2, progress = FALSE,
                     cache = cache)
  expect_equal(calls$n, 22L)
  generate_synthetic(ins, sc_model("openai", temperature = 0.5), per, respondents = 3,
                     progress = FALSE, cache = cache)
  expect_equal(calls$n, 28L)
  generate_synthetic(ins, sc_model("openai"), per, respondents = 3, progress = FALSE,
                     cache = sc_cache(cache$dir, mode = "refresh"))
  expect_equal(calls$n, 34L)
  generate_synthetic(ins, sc_model("openai"), per, respondents = 3, progress = FALSE, cache = FALSE)
  expect_equal(calls$n, 40L)

  generate_synthetic(ins, sc_model("ollama", "gemma3:4b"), per, progress = FALSE, cache = cache)
  info <- sc_cache_info(cache)
  expect_equal(info$model, c("gemma3:4b", "gpt-4.1-nano"))
  expect_equal(sc_cache_clear(cache, provider = "ollama"), 2L)
  info <- sc_cache_info(cache)
  expect_equal(info$provider, "openai")
  expect_equal(info$model, "gpt-4.1-nano")
  expect_equal(info$answers, 28L)
  expect_equal(sc_cache_clear(cache, model = "gpt-4.1-nano"), 28L)
  expect_equal(nrow(sc_cache_info(cache)), 0)
})

test_that("parallel calls, batches and item blocks share the cache", {
  skip_if_not_installed("ellmer")
  skip_if_not_installed("promises")
  skip_if_not_installed("later")
  ins <- sc_instrument(c("a", "b", "c", "d"), scale = c(1, 5))
  cache <- sc_cache(withr::local_tempdir())
  calls <- new.env()
  local_mocked_bindings(sc_chat = fake_model(calls))
  per <- sprintf("You are person %d.", 1:3)
  a <- generate_synthetic(ins, sc_model("anthropic"), per, respondents = 2, progress = FALSE,
                          cache = cache)
  n <- calls$n
  b <- generate_synthetic(ins, sc_model("anthropic"), per, respondents = 2, parallel = 3,
                          progress = FALSE, cache = cache)
  expect_equal(calls$n, n)
  expect_equal(a, b, ignore_attr = TRUE)
  # blocks: One conversation per respondent, saved together
  generate_synthetic(ins, sc_model("anthropic"), per, respondents = 1, block_size = 2,
                     progress = FALSE, cache = cache)
  expect_equal(calls$n, n + 3L * 2L)
  generate_synthetic(ins, sc_model("anthropic"), per, respondents = 1, block_size = 2,
                     progress = FALSE, cache = cache)
  expect_equal(calls$n, n + 3L * 2L)
})

test_that("failed calls are not saved", {
  skip_if_not_installed("ellmer")
  ins <- sc_instrument(c("a", "b"), scale = c(1, 5))
  cache <- sc_cache(withr::local_tempdir())
  local_mocked_bindings(sc_chat = function(m, system)
    list(chat_structured = function(prompt, type) stop("no connection")))
  syn <- generate_synthetic(ins, sc_model("openai"), respondents = 2, max_retries = 1,
                            progress = FALSE, cache = cache)
  expect_true(all(is.na(syn$i1)))
  expect_equal(nrow(sc_cache_info(cache)), 0)
})

test_that("mock answers are never saved", {
  ins <- sc_instrument(c("a", "b"), scale = c(1, 5))
  cache <- sc_cache(withr::local_tempdir())
  generate_synthetic(ins, sc_model("mock"), respondents = 3, progress = FALSE, cache = cache)
  expect_equal(nrow(sc_cache_info(cache)), 0)
})

test_that("cognitive interviews are cached, coding included", {
  skip_if_not_installed("ellmer")
  ins <- sc_instrument(data.frame(item = c("q1", "q2"),
                                  statement = c("I like parties and quiet nights.", "I keep promises.")),
                       scale = c(1, 5))
  cache <- sc_cache(withr::local_tempdir())
  n <- 0L
  local_mocked_bindings(sc_chat = function(m, system) list(chat_structured = function(prompt, type) {
    n <<- n + 1L
    p <- names(type@properties)
    if ("think_aloud" %in% p) return(list(think_aloud = "I think so.", answer = 3L))
    if (!"severity" %in% p) return(stats::setNames(as.list(paste("About", p)), p))
    out <- list()
    for (k in c("comprehension", "retrieval", "judgement", "response", "sensitivity")) {
      out[[k]] <- FALSE; out[[paste0(k, "_note")]] <- ""
    }
    c(out, list(severity = "none", revision = ""))
  }))
  run <- function(...) suppressMessages(cognitive_interview(ins, sc_model("openai"), "You are 40.",
                                                            progress = FALSE, cache = cache, ...))
  a <- run()
  expect_equal(n, 6L)
  b <- run()
  expect_equal(n, 6L)
  expect_equal(attr(b, "cache")$hits, 4L)
  expect_equal(a$think_aloud, b$think_aloud)
  est <- estimate_interview_cost(ins, sc_model("openai"), "You are 40.", cache = cache)
  expect_equal(est$cached, est$calls)
  expect_equal(attr(est, "total"), 0)
})

test_that("estimate_cost() counts calls, tokens and prices", {
  ins <- sc_instrument(hexaco_items[1:20, ], scale = c(1, 7))
  per <- c("You are 25.", "You are 65.")
  est <- estimate_cost(ins, list(sc_model("anthropic"), sc_model("openai"), sc_model("mock"),
                                 sc_model("ollama", "gemma3:4b")),
                       per, attempts = 2, respondents = 5, cache = FALSE)
  expect_s3_class(est, "sc_cost")
  expect_equal(est$calls, rep(20L, 4))
  expect_equal(est$cached, rep(0L, 4))
  expect_true(all(est$input_tokens > 20 * 100))
  expect_equal(est$input_price[1:2], c(0.10, 0.10))
  expect_equal(est$cost[3:4], c(0, 0))
  expect_true(est$cost[1] > 0)
  expect_equal(attr(est, "total"), sum(est$cost))
  expect_output(print(est), "Estimated cost")
  # batches make fewer calls; blocks make more
  expect_equal(estimate_cost(ins, sc_model("openai"), per, respondents = 5, batch_size = 5,
                             cache = FALSE)$calls, 2L)
  expect_equal(estimate_cost(ins, sc_model("openai"), per, respondents = 1, block_size = 5,
                             cache = FALSE)$calls, 8L)
  # an unknown model has no price; a dated snapshot has its model's price
  u <- estimate_cost(ins, sc_model("openai", "my-model"), cache = FALSE)
  expect_true(is.na(u$cost))
  expect_true(is.na(attr(u, "total")))
  expect_output(print(u), "No price for my-model")
  expect_equal(estimate_cost(ins, sc_model("openai", "gpt-4.1-nano-2025-04-14"), cache = FALSE)$input_price,
               0.10)
  own <- rbind(sc_prices, data.frame(provider = "openai", model = "my-model", input = 1, output = 2,
                                     checked = "2026-11-13"))
  expect_false(is.na(estimate_cost(ins, sc_model("openai", "my-model"), prices = own, cache = FALSE)$cost))
})

test_that("estimate_cost() counts cached calls as free", {
  skip_if_not_installed("ellmer")
  ins <- sc_instrument(c("a", "b", "c"), scale = c(1, 5))
  cache <- sc_cache(withr::local_tempdir())
  calls <- new.env()
  local_mocked_bindings(sc_chat = fake_model(calls))
  generate_synthetic(ins, sc_model("openai"), "You are 30.", respondents = 3, shuffle = TRUE,
                     progress = FALSE, cache = cache)
  est <- estimate_cost(ins, sc_model("openai"), "You are 30.", respondents = 5, shuffle = TRUE,
                       cache = cache)
  expect_equal(est$calls, 5L)
  expect_equal(est$cached, 3L)
  expect_equal(estimate_cost(ins, sc_model("openai"), "You are 30.", respondents = 5, shuffle = TRUE,
                             cache = sc_cache(cache$dir, mode = "refresh"))$cached, 0L)
})

test_that("a separate coder gets its own row in the interview estimate", {
  ins <- sc_instrument(c("I like parties.", "I am tidy."), scale = c(1, 5))
  est <- estimate_interview_cost(ins, list(sc_model("openai"), sc_model("mock")), "You are 40.",
                                 coder = sc_model("anthropic"), cache = FALSE)
  expect_equal(est$model, c("gpt-4.1-nano", "mock", "claude-haiku-5-5 (coder)"))
  expect_equal(est$calls, c(4L, 4L, 4L))
  self <- estimate_interview_cost(ins, sc_model("openai"), cache = FALSE)
  expect_equal(self$calls, 6L)
})
