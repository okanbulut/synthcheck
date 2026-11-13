# Generating synthetic respondents with language models (through ellmer).

#' Generate synthetic respondents with language models
#'
#' `generate_synthetic()` asks one or more language models
#' to take an instrument as each persona and returns one row per synthetic
#' respondent. Each call makes one respondent: The persona is the system
#' prompt, and the instructions, the response scale and the items are the
#' user prompt (see [sc_prompt()]). The model answers in structured JSON, one
#' whole number per item.
#'
#' An **attempt** is one full pass over the personas, with `respondents`
#' respondents per persona, as in [hexaco_llm]. The number of calls is the
#' number of models times `attempts` times the number of personas times
#' `respondents`. Answers outside the scale, missing items and failed calls
#' are retried up to `max_retries` times and then stored as `NA`.
#'
#' With `output`, each attempt is written to its own file as soon as it is
#' done, with `run.json` (the settings, without API keys) and
#' `prompts.json` (every prompt sent) beside it, so a stopped run keeps the
#' finished attempts. Read the folder back with [read_synthetic()].
#'
#' Use them to compare models with
#' [authenticity_benchmark()], not to replace a field test.
#'
#' @param instrument an [sc_instrument()].
#' @param models one [sc_model()] or a list of them.
#' @param personas an [sc_personas()] table, a character vector of
#'   descriptions, or `NULL` for respondents without a persona.
#' @param attempts number of attempts per model.
#' @param respondents number of respondents per persona in each attempt.
#' @param batch_size number of respondents per call. The default, 1, keeps
#'   every respondent independent. A larger batch asks one call for several
#'   respondents of the same persona: That is cheaper, but the respondents in
#'   a batch may depend on each other (the model sees its own earlier
#'   answers), which can make them look more alike or more deliberately
#'   different than independent people would.
#' @param block_size ask at most this many items per call. A respondent's
#'   blocks are asked one after another in the same conversation. `NULL`
#'   asks all items at once.
#' @param shuffle shuffle the item order for each call?
#' @param max_retries how often to retry a call that fails or gives invalid
#'   answers.
#' @param parallel number of calls to run at the same time.
#' @param output optional folder to write the data to.
#' @param format file format for `output`: `"csv"`, `"json"`, `"rds"` or
#'   `"xlsx"` (needs writexl).
#' @param progress show a progress bar with the time left in the console?
#'   A function also works: It is called after every respondent with a list
#'   (`done`, `total`, `failed`, `elapsed`, `eta` in seconds, and so on).
#' @param progress_file optional path of a JSON file updated after every
#'   respondent (used by [run_synthcheck_app()]).
#' @param stop_file optional path: When this file appears, the run stops
#'   after the calls in progress and returns what is done.
#' @param seed random seed for shuffling and for the mock provider.
#' @return A tibble with `model`, `provider`, `model_id`, `temperature`,
#'   `attempt`, `persona_id`, `respondent`, any persona attributes, and one
#'   column per item. The attribute `log` holds the failed calls.
#' @seealso [sc_instrument()], [sc_personas()], [sc_model()],
#'   [as_synthetic_list()], [authenticity_benchmark()]
#' @examples
#' ins <- sc_instrument(hexaco_items[hexaco_items$trait == "H", ], scale = c(1, 7))
#' per <- sc_persona_grid(age = c(25, 65), template = "You are {age} years old.")
#' syn <- generate_synthetic(ins, sc_model("mock"), per, attempts = 2, respondents = 3)
#' syn
#' \dontrun{
#' # needs ANTHROPIC_API_KEY and OPENAI_API_KEY
#' syn <- generate_synthetic(ins, list(sc_model("anthropic"), sc_model("openai")), per,
#'                           attempts = 5, respondents = 10, parallel = 8,
#'                           output = "hexaco_run")
#' }
#' @export
generate_synthetic <- function(instrument, models, personas = NULL, attempts = 1,
                               respondents = 1, batch_size = 1, block_size = NULL, shuffle = FALSE,
                               max_retries = 2, parallel = 1, output = NULL,
                               format = c("csv", "json", "rds", "xlsx"), progress = interactive(),
                               progress_file = NULL, stop_file = NULL, seed = 1) {
  if (!inherits(instrument, "sc_instrument"))
    stop("`instrument` must be made with sc_instrument().", call. = FALSE)
  format <- match.arg(format)
  if (inherits(models, "sc_model")) models <- list(models)
  if (!length(models) || !all(vapply(models, inherits, logical(1), "sc_model")))
    stop("`models` must be an sc_model() or a list of them.", call. = FALSE)
  labels <- vapply(models, `[[`, character(1), "name")
  if (anyDuplicated(labels))
    stop("Every model needs its own `name`: ", paste(unique(labels[duplicated(labels)]),
                                                      collapse = ", "), ".", call. = FALSE)
  if (any(vapply(models, function(m) m$provider != "mock", logical(1))))
    sc_need("ellmer", "to call language models")
  personas <- if (is.null(personas)) NULL else sc_personas(personas)
  attempts <- as.integer(attempts); respondents <- as.integer(respondents)
  parallel <- max(1L, as.integer(parallel))
  if (attempts < 1L || respondents < 1L) stop("`attempts` and `respondents` must be at least 1.",
                                              call. = FALSE)
  if (!is.null(block_size) && block_size < 1) stop("`block_size` must be at least 1.", call. = FALSE)
  batch_size <- as.integer(batch_size)
  if (length(batch_size) != 1L || is.na(batch_size) || batch_size < 1L)
    stop("`batch_size` must be at least 1.", call. = FALSE)
  if (batch_size > 1L && !is.null(block_size))
    stop("Use either `batch_size` or `block_size`, not both.", call. = FALSE)
  if (!is.null(output) || !is.null(progress_file)) sc_need("jsonlite", "to save the run")
  if (!is.null(output)) {
    dir.create(output, showWarnings = FALSE, recursive = TRUE)
    sc_write_run(output, instrument, models, personas, attempts, respondents, batch_size,
                 block_size, shuffle, seed, format)
  }

  pers <- if (is.null(personas)) data.frame(persona_id = "none", description = NA_character_,
                                            stringsAsFactors = FALSE) else as.data.frame(personas)
  n_per <- nrow(pers) * respondents
  total <- length(models) * attempts * n_per
  state <- new.env()
  state$done <- 0L; state$failed <- 0L; state$retries <- 0L; state$start <- Sys.time()
  state$total <- total; state$model <- ""; state$attempt <- 0L; state$status <- "running"
  state$per_model <- stats::setNames(integer(length(models)), labels)
  report <- sc_reporter(progress, progress_file, state, labels, attempts * n_per)
  report()

  rows <- list(); log <- list()
  stopped <- FALSE
  with_seed(seed, {
    for (mi in seq_along(models)) {
      m <- models[[mi]]
      for (a in seq_len(attempts)) {
        state$model <- m$name; state$attempt <- a
        jobs <- data.frame(p = rep(seq_len(nrow(pers)), each = respondents),
                           r = rep(seq_len(respondents), nrow(pers)))
        # one call per unit: a respondent, or a batch of one persona's respondents
        units <- unlist(lapply(seq_len(nrow(pers)), function(p) {
          idx <- which(jobs$p == p)
          split(idx, ceiling(seq_along(idx) / batch_size))
        }), recursive = FALSE)
        # item orders and seeds drawn up front, so results do not depend on `parallel`
        orders <- lapply(units, function(u)
          if (shuffle) sample(instrument$items$item) else instrument$items$item)
        seeds <- sample.int(.Machine$integer.max, length(units))
        res <- vector("list", nrow(jobs))
        for (chunk in split(seq_along(units), ceiling(seq_along(units) / parallel))) {
          if (!is.null(stop_file) && file.exists(stop_file)) { stopped <- TRUE; break }
          out <- sc_run_chunk(m, instrument, pers$description[jobs$p[vapply(units[chunk], `[`, 1L, 1L)]],
                              lengths(units[chunk]), orders[chunk], seeds[chunk], block_size,
                              max_retries,
                              on_done = function(r) {
                                state$done <- state$done + 1L
                                state$per_model[mi] <- state$per_model[mi] + 1L
                                state$retries <- state$retries + r$retries
                                if (!r$ok) state$failed <- state$failed + 1L
                                report()
                              })
          for (j in seq_along(chunk)) res[units[[chunk[j]]]] <- out[[j]]
        }
        keep <- which(!vapply(res, is.null, logical(1)))
        if (length(keep)) {
          d <- sc_rows(res[keep], jobs[keep, , drop = FALSE], pers, m, a, instrument)
          rows[[length(rows) + 1L]] <- d
          if (!is.null(output) && !stopped) write_synthetic(d, file.path(output, sprintf(
            "%s_attempt%02d.%s", sc_slug(m$name), a, format)), format = format)
          for (k in keep) if (length(res[[k]]$errors))
            log[[length(log) + 1L]] <- data.frame(model = m$name, attempt = a,
                                                  persona_id = pers$persona_id[jobs$p[k]],
                                                  respondent = jobs$r[k],
                                                  error = paste(unique(res[[k]]$errors), collapse = " | "),
                                                  stringsAsFactors = FALSE)
        }
        if (stopped) break
      }
      if (stopped) break
    }
  })
  state$status <- if (stopped) "stopped" else "done"
  report(final = TRUE)
  out <- if (length(rows)) do.call(rbind, rows) else sc_rows(list(), jobs[0, ], pers, models[[1]], 1L, instrument)
  out <- as_tbl(out)
  log <- if (length(log)) as_tbl(do.call(rbind, log)) else NULL
  if (!is.null(output) && !is.null(log))
    utils::write.csv(log, file.path(output, "log.csv"), row.names = FALSE)
  attr(out, "log") <- log
  attr(out, "stopped") <- stopped
  out
}

# ---- internal -------------------------------------------------------------

sc_need <- function(pkg, why) {
  if (!requireNamespace(pkg, quietly = TRUE))
    stop(sprintf("Install the %s package %s: install.packages(\"%s\")", pkg, why, pkg),
         call. = FALSE)
  invisible(TRUE)
}

sc_slug <- function(x) {
  x <- gsub("[^A-Za-z0-9]+", "-", x)
  x <- gsub("^-+|-+$", "", x)
  if (!nzchar(x)) "model" else x
}

# the rows of one model and attempt
sc_rows <- function(res, jobs, pers, m, a, instrument) {
  items <- instrument$items$item
  n <- length(res)
  vals <- if (n) do.call(rbind, lapply(res, function(r) r$values[items])) else
    matrix(integer(0), 0, length(items))
  colnames(vals) <- items
  extra <- setdiff(names(pers), c("persona_id", "description"))
  d <- data.frame(model = rep(m$name, n), provider = rep(m$provider, n),
                  model_id = rep(m$model, n),
                  temperature = rep(if (is.null(m$temperature)) NA_real_ else m$temperature, n),
                  attempt = rep(as.integer(a), n), persona_id = pers$persona_id[jobs$p],
                  respondent = as.integer(jobs$r), stringsAsFactors = FALSE)
  for (e in extra) d[[e]] <- pers[[e]][jobs$p]
  cbind(d, as.data.frame(vals))
}

# progress: Console bar, JSON file, a callback, or any of them
sc_reporter <- function(progress, progress_file, state, labels, per_model_total) {
  last <- -Inf
  function(final = FALSE) {
    el <- as.numeric(difftime(Sys.time(), state$start, units = "secs"))
    eta <- if (state$done > 0 && state$done < state$total)
      el / state$done * (state$total - state$done) else if (state$done >= state$total) 0 else NA_real_
    info <- list(done = state$done, total = state$total, failed = state$failed,
                 retries = state$retries, model = state$model, attempt = state$attempt,
                 elapsed = el, eta = eta, status = state$status,
                 per_model = lapply(seq_along(labels), function(i)
                   list(model = labels[i], done = state$per_model[[i]], total = per_model_total)))
    if (!is.null(progress_file) && (final || el - last >= 0.5)) {
      last <<- el
      tmp <- paste0(progress_file, ".tmp")
      writeLines(jsonlite::toJSON(info, auto_unbox = TRUE, na = "null", digits = NA), tmp)
      file.rename(tmp, progress_file)
    }
    if (is.function(progress)) progress(info)
    if (isTRUE(progress)) {
      w <- 30L
      k <- if (state$total) round(w * state$done / state$total) else w
      cat(sprintf("\r[%s%s] %d/%d  %s  elapsed %s  left %s%s   ", strrep("=", k), strrep(" ", w - k),
                  state$done, state$total, state$model, sc_duration(el), sc_duration(eta),
                  if (state$failed) sprintf("  failed %d", state$failed) else ""))
      if (final) cat("\n")
    }
    invisible(NULL)
  }
}

sc_duration <- function(s) {
  if (is.null(s) || is.na(s)) return("--")
  s <- round(s)
  if (s < 60) return(sprintf("%ds", s))
  if (s < 3600) return(sprintf("%dm %02ds", s %/% 60, s %% 60))
  sprintf("%dh %02dm", s %/% 3600, (s %% 3600) %/% 60)
}

# run a chunk of calls, at the same time when there is more than one; each
# call gives a list of respondents
sc_run_chunk <- function(m, instrument, personas, sizes, orders, seeds, block_size, max_retries,
                         on_done) {
  n <- length(personas)
  if (m$provider == "mock" || n == 1L || !is.null(block_size) ||
      !requireNamespace("promises", quietly = TRUE) || !requireNamespace("later", quietly = TRUE)) {
    return(lapply(seq_len(n), function(j) {
      r <- sc_respondent(m, instrument, personas[j], orders[[j]], seeds[j], block_size,
                         max_retries, k = sizes[j])
      for (x in r) on_done(x)
      r
    }))
  }
  out <- vector("list", n)
  pending <- n
  for (j in seq_len(n)) local({
    jj <- j
    sc_respondent_async(m, instrument, personas[jj], orders[[jj]], max_retries, k = sizes[jj],
                        done = function(r) {
                          out[[jj]] <<- r
                          pending <<- pending - 1L
                          for (x in r) on_done(x)
                        })
  })
  while (pending > 0L) later::run_now(0.05)
  out
}

# check and clean one structured answer
sc_check <- function(x, items, lo, hi) {
  v <- stats::setNames(rep(NA_integer_, length(items)), items)
  if (is.data.frame(x)) x <- as.list(x)
  if (is.list(x) || is.atomic(x)) {
    got <- intersect(names(x), items)
    for (i in got) {
      a <- suppressWarnings(as.numeric(unlist(x[[i]])[1]))
      if (length(a) == 1L && !is.na(a) && a == round(a) && a >= lo && a <= hi) v[i] <- as.integer(a)
    }
  }
  v
}

sc_type <- function(instrument, items, k = 1L) {
  props <- lapply(items, function(i)
    ellmer::type_integer(sprintf("Answer from %d to %d", instrument$min, instrument$max)))
  names(props) <- items
  one <- do.call(ellmer::type_object, c(list(.description = "One answer per statement."), props))
  if (k <= 1L) return(one)
  ellmer::type_object(.description = sprintf("Answers of %d different respondents.", k),
                      respondents = ellmer::type_array(one, description = "One element per respondent."))
}

# the respondents in one structured answer, checked
sc_unpack <- function(ans, items, lo, hi, k) {
  if (k <= 1L) return(list(sc_check(ans, items, lo, hi)))
  r <- if (is.list(ans) && !is.data.frame(ans)) ans$respondents else NULL
  rows <- if (is.data.frame(r)) lapply(seq_len(nrow(r)), function(i) as.list(r[i, , drop = FALSE])) else
    if (is.list(r)) r else list()
  lapply(utils::head(rows, k), sc_check, items = items, lo = lo, hi = hi)
}

sc_result <- function(v, retries, errors, t0) {
  if (anyNA(v) && !length(errors)) errors <- sprintf("%d answers missing or out of range", sum(is.na(v)))
  list(values = v, ok = !anyNA(v), retries = retries, errors = errors,
       seconds = as.numeric(difftime(Sys.time(), t0, units = "secs")))
}

sc_chat <- function(m, system) {
  fun <- switch(m$provider, anthropic = ellmer::chat_anthropic, openai = ellmer::chat_openai,
                ollama = ellmer::chat_ollama)
  args <- list(system_prompt = system, model = m$model, echo = "none")
  if (!is.null(m$temperature)) args$params <- ellmer::params(temperature = m$temperature)
  if (!is.null(m$base_url)) args$base_url <- m$base_url
  do.call(fun, args)
}

sc_blocks <- function(order, block_size) {
  if (is.null(block_size) || block_size >= length(order)) return(list(order))
  split(order, ceiling(seq_along(order) / block_size))
}

# k synthetic respondents (one call, or one batch), one call after another
sc_respondent <- function(m, instrument, persona, order, seed, block_size, max_retries, k = 1L) {
  items <- instrument$items$item
  empty <- stats::setNames(rep(NA_integer_, length(items)), items)
  t0 <- Sys.time()
  if (m$provider == "mock") {
    return(with_seed(seed, lapply(seq_len(k), function(i) {
      v <- empty
      v[] <- sample(seq(instrument$min, instrument$max), length(items), replace = TRUE)
      sc_result(v, 0L, character(0), t0)
    })))
  }
  vals <- rep(list(empty), k)
  errors <- character(0); retries <- 0L
  for (try in 0:max_retries) {
    todo <- which(vapply(vals, anyNA, logical(1)))
    if (!length(todo)) break
    if (try > 0L) retries <- retries + 1L
    chat <- sc_chat(m, sc_prompt(instrument, persona)$system)
    if (k > 1L) {
      ans <- tryCatch(chat$chat_structured(sc_prompt(instrument, persona, order, n = length(todo))$user,
                                           type = sc_type(instrument, order, length(todo))),
                      error = function(e) { errors <<- c(errors, conditionMessage(e)); NULL })
      if (!is.null(ans)) {
        got <- sc_unpack(ans, items, instrument$min, instrument$max, length(todo))
        for (i in seq_along(got)) vals[[todo[i]]] <- got[[i]]
      }
      next
    }
    v <- vals[[1]]
    for (b in sc_blocks(order, block_size)) {
      need <- b[is.na(v[b])]
      if (!length(need)) next
      ans <- tryCatch(chat$chat_structured(sc_prompt(instrument, persona, need)$user,
                                           type = sc_type(instrument, need)),
                      error = function(e) { errors <<- c(errors, conditionMessage(e)); NULL })
      if (!is.null(ans)) v[need] <- sc_check(ans, need, instrument$min, instrument$max)
    }
    vals[[1]] <- v
  }
  lapply(vals, sc_result, retries = retries, errors = errors, t0 = t0)
}

# the same without blocking, for parallel calls (no item blocks)
sc_respondent_async <- function(m, instrument, persona, order, max_retries, k = 1L, done) {
  items <- instrument$items$item
  empty <- stats::setNames(rep(NA_integer_, length(items)), items)
  vals <- rep(list(empty), k)
  errors <- character(0)
  t0 <- Sys.time()
  attempt <- function(try) {
    todo <- which(vapply(vals, anyNA, logical(1)))
    if (!length(todo) || try > max_retries)
      return(done(lapply(vals, sc_result, retries = max(0L, try - 1L), errors = errors, t0 = t0)))
    n <- length(todo)
    chat <- sc_chat(m, sc_prompt(instrument, persona)$system)
    pr <- tryCatch(chat$chat_structured_async(sc_prompt(instrument, persona, order, n = n)$user,
                                              type = sc_type(instrument, order, n)),
                   error = function(e) e)
    take <- function(ans) {
      if (!is.null(ans)) {
        got <- sc_unpack(ans, items, instrument$min, instrument$max, n)
        for (i in seq_along(got)) vals[[todo[i]]] <<- got[[i]]
      }
      attempt(try + 1L)
    }
    if (inherits(pr, "error")) {
      errors <<- c(errors, conditionMessage(pr))
      return(take(NULL))
    }
    promises::then(pr, onFulfilled = take,
                   onRejected = function(e) { errors <<- c(errors, conditionMessage(e)); take(NULL) })
    invisible(NULL)
  }
  attempt(0L)
}

sc_write_run <- function(output, instrument, models, personas, attempts, respondents,
                         batch_size, block_size, shuffle, seed, format) {
  run <- list(
    synthcheck = as.character(utils::packageVersion("synthcheck")),
    created = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    instrument = list(name = instrument$name, min = instrument$min, max = instrument$max,
                      labels = instrument$labels, instructions = instrument$instructions,
                      items = as.data.frame(instrument$items)),
    models = lapply(models, function(m) unclass(m)[c("name", "provider", "model", "temperature",
                                                     "base_url")]),
    personas = if (is.null(personas)) NULL else as.data.frame(personas),
    attempts = attempts, respondents = respondents, batch_size = batch_size,
    block_size = block_size, shuffle = shuffle,
    seed = seed, format = format)
  jsonlite::write_json(run, file.path(output, "run.json"), auto_unbox = TRUE, pretty = TRUE,
                       null = "null", na = "null", digits = NA)
  sys <- if (is.null(personas)) sc_prompt(instrument)$system else
    vapply(personas$description, function(d) sc_prompt(instrument, d)$system, character(1),
           USE.NAMES = FALSE)
  prompts <- list(user = sc_prompt(instrument)$user,
                  system = data.frame(persona_id = if (is.null(personas)) "none" else personas$persona_id,
                                      system = sys, stringsAsFactors = FALSE))
  jsonlite::write_json(prompts, file.path(output, "prompts.json"), auto_unbox = TRUE, pretty = TRUE)
  invisible(TRUE)
}
