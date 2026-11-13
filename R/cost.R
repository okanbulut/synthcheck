# What a run is likely to cost, before it starts.

#' Prices of language models
#'
#' The prices `estimate_cost()` and `estimate_interview_cost()` use, in US
#' dollars per million tokens, from the providers' list prices on the date in
#' `checked`. Prices change: Check them before a large run, and pass your own
#' table as `prices` (the same columns; add rows with [rbind()]). Ollama
#' models run on your machine and cost nothing. A model that is not in the
#' table gets no estimate.
#'
#' Anthropic's prices are from its price list of 2026-11-03 (Claude Haiku 5.5
#' costs more for prompts over 100,000 tokens, which synthcheck prompts are
#' not). OpenAI's are from a published comparison of its list prices of
#' 2026-02-18.
#'
#' @format A data frame with `provider`, `model` (the model id; dated
#'   snapshots such as `gpt-4.1-nano-2025-04-14` match too), `input` and
#'   `output` (dollars per million tokens), and `checked` (the date of the
#'   prices).
#' @seealso [estimate_cost()]
#' @examples
#' sc_prices
#' # a price of your own
#' my_prices <- rbind(sc_prices, data.frame(provider = "openai", model = "gpt-5.2-mini",
#'                                          input = 0.3, output = 2.4, checked = "2026-12-01"))
#' @export
sc_prices <- data.frame(
  provider = c(rep("anthropic", 9), rep("openai", 12)),
  model = c("claude-haiku-5-5", "claude-haiku-4-5", "claude-sonnet-5-5", "claude-sonnet-5",
            "claude-sonnet-4-6", "claude-opus-5-5", "claude-opus-5", "claude-opus-4-8",
            "claude-fable-5-2",
            "gpt-4.1-nano", "gpt-4.1-mini", "gpt-4.1", "gpt-4o-mini", "gpt-4o", "gpt-5-nano",
            "gpt-5-mini", "gpt-5", "gpt-5.1", "gpt-5.2", "o3", "o4-mini"),
  input = c(0.10, 1.00, 2.00, 2.00, 3.00, 4.00, 5.00, 5.00, 8.00,
            0.10, 0.40, 2.00, 0.15, 2.50, 0.05, 0.25, 1.25, 1.25, 1.75, 2.00, 1.10),
  output = c(0.50, 5.00, 10.00, 10.00, 15.00, 20.00, 25.00, 25.00, 40.00,
             0.40, 1.60, 8.00, 0.60, 10.00, 0.40, 2.00, 10.00, 10.00, 14.00, 8.00, 4.40),
  checked = c(rep("2026-11-03", 9), rep("2026-02-18", 12)),
  stringsAsFactors = FALSE)

#' Estimate what a run will cost
#'
#' `estimate_cost()` counts the calls that [generate_synthetic()] would make
#' with the same arguments, guesses their tokens and multiplies them by the
#' prices in [sc_prices]. `estimate_interview_cost()` does the same for
#' [cognitive_interview()]. No model is called.
#'
#' Calls whose answers are in the response cache (see [sc_cache()]) are
#' counted as free, since the run will not make them. Ollama and the mock
#' provider are free too.
#'
#' It is an estimate. Tokens are guessed from the length of the prompts
#' (about four characters a token) plus the structured-output schema, and
#' from the length of typical answers. Retries for invalid answers add to it.
#' Reasoning models (such as `gpt-5-nano`) also bill their hidden reasoning
#' as output, which the estimate leaves out. Treat the result as a guide to
#' the size of the bill, and check the providers' prices for a large run.
#'
#' @inheritParams generate_synthetic
#' @param prices the price table, [sc_prices] or your own with the same
#'   columns.
#' @return A tibble of class `sc_cost` with one row per model: `model`,
#'   `provider`, `model_id`, `calls`, `cached` (calls answered from the
#'   cache), `input_tokens` and `output_tokens` (of the calls still to make),
#'   `input_price` and `output_price` (dollars per million tokens),
#'   `checked` (the date of the price) and `cost` (dollars, `NA` when the
#'   model has no price). The attribute `total` holds the sum.
#' @seealso [sc_prices], [sc_cache()], [generate_synthetic()]
#' @examples
#' ins <- sc_instrument(hexaco_items, scale = c(1, 7))
#' per <- sc_persona_grid(age = c(25, 45, 65), template = "You are {age} years old.")
#' estimate_cost(ins, list(sc_model("anthropic"), sc_model("openai")), per,
#'               attempts = 5, respondents = 10, cache = FALSE)
#' @export
estimate_cost <- function(instrument, models, personas = NULL, attempts = 1, respondents = 1,
                          batch_size = 1, block_size = NULL, shuffle = FALSE, seed = 1,
                          cache = sc_cache(), prices = sc_prices) {
  if (!inherits(instrument, "sc_instrument"))
    stop("`instrument` must be made with sc_instrument().", call. = FALSE)
  models <- sc_check_models(models)
  personas <- if (is.null(personas)) NULL else sc_personas(personas)
  attempts <- as.integer(attempts); respondents <- as.integer(respondents)
  batch_size <- max(1L, as.integer(batch_size))
  cache <- sc_as_cache(cache)
  pers <- if (is.null(personas)) data.frame(persona_id = "none", description = NA_character_,
                                            stringsAsFactors = FALSE) else as.data.frame(personas)
  plan <- sc_gen_plan(models, pers, attempts, respondents, batch_size, shuffle, instrument, seed)
  rows <- lapply(seq_along(models), function(mi) {
    m <- models[[mi]]
    n <- c(calls = 0, cached = 0, input = 0, output = 0)
    for (pl in plan[[mi]]) for (u in seq_along(pl$units)) {
      k <- length(pl$units[[u]])
      persona <- pers$description[pl$persona[u]]
      system <- sc_prompt(instrument, persona)$system
      empty <- stats::setNames(rep(NA_integer_, nrow(instrument$items)), instrument$items$item)
      pr <- sc_try_prompts(instrument, persona, pl$orders[[u]], block_size, rep(list(empty), k),
                           seq_len(k), k)
      n["calls"] <- n["calls"] + length(pr$users)
      if (sc_cache_has(cache, m, sc_cache_key(m, "generate", system, pr$users, pl$slots[u], 0L))) {
        n["cached"] <- n["cached"] + length(pr$users)
        next
      }
      tk <- sc_gen_tokens(m, system, pr, k)
      n["input"] <- n["input"] + tk[1]; n["output"] <- n["output"] + tk[2]
    }
    n
  })
  sc_cost_table(models, rows, prices)
}

#' @rdname estimate_cost
#' @inheritParams cognitive_interview
#' @export
estimate_interview_cost <- function(instrument, models, personas = NULL, items = NULL,
                                    probes = sc_probes(), coder = NULL, pretest = NULL,
                                    interviews = 1, seed = 1, cache = sc_cache(),
                                    prices = sc_prices) {
  if (!inherits(instrument, "sc_instrument"))
    stop("`instrument` must be made with sc_instrument().", call. = FALSE)
  models <- sc_check_models(models)
  cache <- sc_as_cache(cache)
  st <- sc_iv_setup(instrument, models, personas, items, probes, coder, pretest, interviews)
  specs <- sc_iv_specs(st, rep(NA_integer_, nrow(st$jobs)), seed)
  out <- list(); priced <- list()
  coder_n <- c(calls = 0, cached = 0, input = 0, output = 0)
  for (mi in seq_along(models)) {
    m <- models[[mi]]
    cd <- sc_iv_coder(if (is.null(coder)) m else coder)
    n <- c(calls = 0, cached = 0, input = 0, output = 0)
    nc <- n
    for (spec in specs) {
      n["calls"] <- n["calls"] + 2
      nc["calls"] <- nc["calls"] + 1
      hit <- if (m$provider != "mock" && sc_cache_has(cache, m, sc_iv_key_answers(m, spec, instrument, 0L)))
        sc_cache_get(cache, m, sc_iv_key_answers(m, spec, instrument, 0L))
      if (!is.null(hit)) {
        n["cached"] <- n["cached"] + 2
        prompt <- sc_iv_coder_input(instrument, spec, hit$a1, hit$a2)
        if (sc_cache_has(cache, cd, sc_iv_key_code(cd, prompt, 0L))) {
          nc["cached"] <- nc["cached"] + 1
          next
        }
      } else {
        tk <- sc_iv_tokens(m, instrument, spec)
        n["input"] <- n["input"] + tk[1]; n["output"] <- n["output"] + tk[2]
        prompt <- NULL
      }
      tk <- sc_iv_coder_tokens(cd, instrument, spec, prompt)
      nc["input"] <- nc["input"] + tk[1]; nc["output"] <- nc["output"] + tk[2]
    }
    # a separate coder gets its own row; a model coding itself adds to its row
    priced[[length(priced) + 1L]] <- m
    out[[length(out) + 1L]] <- if (is.null(coder)) n + nc else n
    coder_n <- coder_n + nc
  }
  if (!is.null(coder)) {
    cd <- sc_iv_coder(coder)
    cd$name <- paste0(cd$name, " (coder)")
    priced[[length(priced) + 1L]] <- cd
    out[[length(out) + 1L]] <- coder_n
  }
  sc_cost_table(priced, out, prices)
}

#' @export
print.sc_cost <- function(x, ...) {
  tot <- attr(x, "total")
  calls <- sum(x$calls); cached <- sum(x$cached)
  cat(sprintf("Estimated cost: %s for %s call%s%s.\n", sc_dollars(tot), format(calls, big.mark = ","),
              if (calls == 1) "" else "s",
              if (cached) sprintf(", %s of them from the cache (free)", format(cached, big.mark = ",")) else ""))
  if (anyNA(x$cost))
    cat(sprintf("No price for %s: Add it to `prices`.\n", paste(x$model[is.na(x$cost)], collapse = ", ")))
  d <- data.frame(model = x$model, calls = x$calls, cached = x$cached,
                  tokens_in = format(x$input_tokens, big.mark = ","),
                  tokens_out = format(x$output_tokens, big.mark = ","),
                  cost = vapply(x$cost, sc_dollars, character(1)),
                  prices_of = ifelse(is.na(x$checked), "", x$checked), stringsAsFactors = FALSE)
  print(d, row.names = FALSE, right = FALSE)
  cat("An estimate: Tokens are guessed from the prompts, and retries add to it.\n")
  invisible(x)
}

# ---- internal -------------------------------------------------------------

sc_check_models <- function(models) {
  if (inherits(models, "sc_model")) models <- list(models)
  if (!length(models) || !all(vapply(models, inherits, logical(1), "sc_model")))
    stop("`models` must be an sc_model() or a list of them.", call. = FALSE)
  models
}

sc_dollars <- function(x) {
  if (is.null(x) || is.na(x)) return("unknown")
  if (x == 0) return("$0")
  if (x < 0.01) return("< $0.01")
  paste0("$", formatC(x, format = "f", digits = 2, big.mark = ","))
}

# a rough token count: About four characters a token
sc_tokens <- function(x) sum(ceiling(nchar(x, type = "chars") / 4))

# extra input of a structured-output call: Anthropic's tool definition and
# instructions are larger than OpenAI's response format
sc_call_overhead <- function(m) switch(m$provider, anthropic = 350, 30)

# tokens of the schema and of the answers for some items
sc_schema_tokens <- function(items) 15 + sum(sc_tokens(items) + 12)
sc_answer_tokens <- function(items) 5 + sum(sc_tokens(sprintf("\"%s\": 4, ", items)))

# input and output tokens of one try of a respondent or batch: Later blocks
# also send the earlier turns of the conversation
sc_gen_tokens <- function(m, system, pr, k) {
  input <- 0; output <- 0; history <- 0
  for (j in seq_along(pr$users)) {
    out <- k * sc_answer_tokens(pr$items[[j]]) + if (k > 1L) 10 else 0
    input <- input + sc_call_overhead(m) + sc_tokens(system) + history + sc_tokens(pr$users[j]) +
      sc_schema_tokens(pr$items[[j]])
    output <- output + out
    history <- history + sc_tokens(pr$users[j]) + out
  }
  c(input, output)
}

# typical lengths of interview answers, in tokens
sc_iv_lengths <- list(think = 220, probe = 80, coder = 280)

sc_iv_tokens <- function(m, instrument, spec) {
  sys <- sc_tokens(sc_iv_system(spec$persona))
  think <- sc_tokens(sc_iv_think_prompt(instrument, spec$item))
  probe <- sc_tokens(sc_iv_probe_prompt(spec$probes))
  np <- nrow(spec$probes)
  out1 <- sc_iv_lengths$think + 10
  out2 <- sc_iv_lengths$probe * np
  in1 <- sc_call_overhead(m) + sys + think + 60
  in2 <- sc_call_overhead(m) + sys + think + out1 + probe + 20 * np
  c(in1 + in2, out1 + out2)
}

sc_iv_coder_tokens <- function(cd, instrument, spec, prompt = NULL) {
  if (is.null(prompt)) {
    filler <- function(n) strrep("word ", n * 4 / 5)
    pa <- stats::setNames(as.list(rep(filler(sc_iv_lengths$probe), nrow(spec$probes))),
                          spec$probes$probe_id)
    tr <- sc_iv_transcript(spec$item$statement, filler(sc_iv_lengths$think), 4L, spec$probes, pa)
    prompt <- sc_iv_coder_prompt(instrument, spec$item, tr)
  }
  c(sc_call_overhead(cd) + sc_tokens(sc_iv_coder_system) + sc_tokens(prompt) + 180,
    sc_iv_lengths$coder)
}

# the price of a model: Ollama and the mock provider are free; a dated
# snapshot of a listed model gets its price
sc_price <- function(m, prices) {
  if (m$provider %in% c("ollama", "mock")) return(list(input = 0, output = 0, checked = NA_character_))
  if (!is.data.frame(prices) || !all(c("provider", "model", "input", "output") %in% names(prices)))
    stop("`prices` needs the columns provider, model, input and output.", call. = FALSE)
  p <- prices[prices$provider == m$provider, , drop = FALSE]
  hit <- which(p$model == m$model)
  if (!length(hit)) hit <- which(startsWith(m$model, paste0(p$model, "-20")))
  if (!length(hit)) return(list(input = NA_real_, output = NA_real_, checked = NA_character_))
  hit <- hit[which.max(nchar(p$model[hit]))]
  list(input = as.numeric(p$input[hit]), output = as.numeric(p$output[hit]),
       checked = if ("checked" %in% names(p)) as.character(p$checked[hit]) else NA_character_)
}

sc_cost_table <- function(models, rows, prices) {
  d <- do.call(rbind, lapply(seq_along(models), function(i) {
    m <- models[[i]]; n <- rows[[i]]
    pr <- sc_price(m, prices)
    data.frame(model = m$name, provider = m$provider, model_id = m$model,
               calls = as.integer(n[["calls"]]), cached = as.integer(n[["cached"]]),
               input_tokens = round(n[["input"]]), output_tokens = round(n[["output"]]),
               input_price = pr$input, output_price = pr$output, checked = pr$checked,
               cost = (n[["input"]] * pr$input + n[["output"]] * pr$output) / 1e6,
               stringsAsFactors = FALSE)
  }))
  out <- as_tbl(d)
  class(out) <- c("sc_cost", class(out))
  attr(out, "total") <- if (anyNA(d$cost)) NA_real_ else sum(d$cost)
  out
}
