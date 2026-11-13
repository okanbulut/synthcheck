# A cache of model answers on disk, so that runs can be repeated without new calls.

#' Keep model answers on disk
#'
#' `sc_cache()` sets up the response cache that [generate_synthetic()] and
#' [cognitive_interview()] use. Every answer a model gives is saved in a
#' folder, under a key made of everything that shapes the answer: The
#' provider, the model id, the temperature, the address of the API, the
#' system prompt (the persona), the prompts (the instructions, scale and
#' items, in the order asked), and which respondent, attempt, interview and
#' retry it is, with the run's `seed`. When the same call comes again, the
#' saved answer is used instead of a new call. That makes a run repeatable
#' and costs nothing the second time.
#'
#' Because the respondent, attempt and `seed` are part of the key, the
#' respondents of one run still get separate calls. Running the same
#' settings again gives the same data. More attempts or more respondents add
#' new calls for the new ones only. A new `seed`, `mode = "refresh"` or a
#' change to any prompt, model or setting asks the model again. Answers
#' from `provider = "mock"` are never saved, since they cost nothing.
#'
#' Calls that fail are not saved, so a rerun tries them again. Invalid
#' answers (out of range or missing items) are saved like any other answer,
#' and the retry that followed is saved under its own key.
#'
#' The cache holds answers only: No API keys. It lives in
#' [tools::R_user_dir()] unless you give another folder. See what it holds
#' with `sc_cache_info()` and delete it with `sc_cache_clear()`.
#'
#' @param dir the folder of the cache. The default is
#'   `tools::R_user_dir("synthcheck", "cache")`, or the option
#'   `synthcheck.cache_dir` when it is set.
#' @param mode `"reuse"` (use saved answers and save new ones), `"refresh"`
#'   (always ask the model and replace the saved answers) or `"off"`
#'   (neither read nor write the cache).
#' @return An object of class `sc_cache`.
#' @seealso [sc_cache_info()], [sc_cache_clear()], [estimate_cost()]
#' @examples
#' sc_cache()
#' sc_cache(tempfile("cache"), mode = "refresh")
#' \dontrun{
#' # needs ANTHROPIC_API_KEY
#' ins <- sc_instrument(hexaco_items[1:10, ], scale = c(1, 7))
#' a <- generate_synthetic(ins, sc_model("anthropic"), respondents = 5)
#' b <- generate_synthetic(ins, sc_model("anthropic"), respondents = 5) # from the cache
#' identical(a, b)
#' }
#' @export
sc_cache <- function(dir = sc_cache_dir(), mode = c("reuse", "refresh", "off")) {
  mode <- match.arg(mode)
  if (!is.character(dir) || length(dir) != 1L || is.na(dir) || !nzchar(dir))
    stop("`dir` must be one folder path.", call. = FALSE)
  structure(list(dir = path.expand(dir), mode = mode), class = "sc_cache")
}

#' @export
print.sc_cache <- function(x, ...) {
  what <- switch(x$mode, reuse = "reuses saved answers and saves new ones",
                 refresh = "asks the models again and replaces saved answers",
                 off = "is off")
  cat(sprintf("Response cache in %s: %s.\n", x$dir, what))
  invisible(x)
}

# the default folder; the option synthcheck.cache_dir moves it (used by the tests)
sc_cache_dir <- function() getOption("synthcheck.cache_dir", tools::R_user_dir("synthcheck", "cache"))

# a cache from what the user gave: An sc_cache, a folder, TRUE, FALSE or NULL
sc_as_cache <- function(cache) {
  if (inherits(cache, "sc_cache")) return(cache)
  if (is.null(cache) || isFALSE(cache)) return(sc_cache(mode = "off"))
  if (isTRUE(cache)) return(sc_cache())
  if (is.character(cache) && length(cache) == 1L) return(sc_cache(cache))
  stop("`cache` must be made with sc_cache(), a folder, TRUE or FALSE.", call. = FALSE)
}

#' See or clear the response cache
#'
#' `sc_cache_info()` counts the saved answers per provider and model.
#' `sc_cache_clear()` deletes them, all of them or those of one provider or
#' model.
#'
#' @param cache an [sc_cache()] or a folder.
#' @param provider optional provider to clear, for example `"openai"`.
#' @param model optional model id to clear, for example `"gpt-4.1-nano"`.
#' @return `sc_cache_info()`: A tibble with `provider`, `model`, `answers`,
#'   `megabytes`, `oldest` and `newest`. `sc_cache_clear()`: The number of
#'   answers deleted, invisibly.
#' @seealso [sc_cache()]
#' @examples
#' cache <- sc_cache(tempfile("cache"))
#' sc_cache_info(cache)
#' sc_cache_clear(cache)
#' @export
sc_cache_info <- function(cache = sc_cache()) {
  cache <- sc_as_cache(cache)
  files <- sc_cache_files(cache$dir)
  empty <- as_tbl(data.frame(provider = character(0), model = character(0), answers = integer(0),
                             megabytes = numeric(0), oldest = as.POSIXct(character(0)),
                             newest = as.POSIXct(character(0)), stringsAsFactors = FALSE))
  if (!length(files)) return(empty)
  rel <- substring(files, nchar(normalizePath(cache$dir, winslash = "/")) + 2L)
  parts <- strsplit(rel, "/", fixed = TRUE)
  info <- file.info(files)
  d <- data.frame(provider = vapply(parts, `[`, character(1), 1L),
                  model = vapply(parts, `[`, character(1), 2L),
                  size = info$size, time = info$mtime, stringsAsFactors = FALSE)
  g <- split(seq_len(nrow(d)), list(d$provider, d$model), drop = TRUE)
  out <- do.call(rbind, lapply(g, function(i) {
    x <- d[i, , drop = FALSE]
    # the folder name is a slug; the saved answers carry the model id itself
    one <- tryCatch(readRDS(files[i[1]]), error = function(e) NULL)
    if (!is.null(one$model)) x$model <- one$model
    if (!is.null(one$provider)) x$provider <- one$provider
    data.frame(provider = x$provider[1], model = x$model[1], answers = nrow(x),
               megabytes = round(sum(x$size) / 1024^2, 3), oldest = min(x$time),
               newest = max(x$time), stringsAsFactors = FALSE)
  }))
  as_tbl(out[order(out$provider, out$model), , drop = FALSE])
}

#' @rdname sc_cache_info
#' @export
sc_cache_clear <- function(cache = sc_cache(), provider = NULL, model = NULL) {
  cache <- sc_as_cache(cache)
  root <- cache$dir
  if (!is.null(provider)) root <- file.path(root, sc_cache_slug(provider))
  if (!is.null(model)) {
    if (is.null(provider)) {
      dirs <- list.dirs(cache$dir, recursive = FALSE)
      root <- file.path(dirs, sc_cache_slug(model))
    } else root <- file.path(root, sc_cache_slug(model))
  }
  files <- unlist(lapply(root, sc_cache_files))
  if (length(files)) unlink(files)
  # remove the folders that are now empty
  for (d in rev(list.dirs(cache$dir, recursive = TRUE)))
    if (d != cache$dir && !length(list.files(d, all.files = TRUE, no.. = TRUE))) unlink(d, recursive = TRUE)
  invisible(length(files))
}

sc_cache_files <- function(dir) {
  if (!dir.exists(dir)) return(character(0))
  f <- list.files(dir, pattern = "\\.rds$", recursive = TRUE, full.names = TRUE)
  normalizePath(f, winslash = "/")
}

# ---- internal -------------------------------------------------------------

# the counts of one run, kept beside the cache settings
sc_cache_run <- function(cache) {
  cache <- sc_as_cache(cache)
  cache$stats <- new.env()
  cache$stats$hits <- 0L
  cache$stats$saved <- 0L
  cache
}

sc_cache_stats <- function(cache) {
  if (is.null(cache) || is.null(cache$stats)) return(list(mode = "off", hits = 0L, saved = 0L))
  list(mode = cache$mode, hits = cache$stats$hits, saved = cache$stats$saved)
}

sc_cache_used <- function(cache, m) !is.null(cache) && cache$mode != "off" && m$provider != "mock"

# the key: Everything that shapes the answer. Bump the version when the
# saved format changes.
sc_cache_key <- function(m, ...) {
  temp <- if (is.null(m$temperature)) "none" else format(m$temperature, digits = 15)
  txt <- paste(c("synthcheck-cache-v1", m$provider, m$model, temp,
                 if (is.null(m$base_url)) "" else m$base_url,
                 vapply(list(...), function(x) paste(as.character(unlist(x)), collapse = "\x1e"),
                        character(1))),
               collapse = "\x1f")
  rlang::hash(txt)
}

sc_cache_slug <- function(x) {
  x <- gsub("[^A-Za-z0-9._-]+", "-", x)
  if (!nzchar(x)) "model" else x
}

sc_cache_path <- function(cache, m, key)
  file.path(cache$dir, sc_cache_slug(m$provider), sc_cache_slug(m$model), paste0(key, ".rds"))

sc_cache_has <- function(cache, m, key)
  sc_cache_used(cache, m) && cache$mode == "reuse" && file.exists(sc_cache_path(cache, m, key))

# the saved answer, or NULL
sc_cache_get <- function(cache, m, key) {
  if (!sc_cache_used(cache, m) || cache$mode != "reuse") return(NULL)
  f <- sc_cache_path(cache, m, key)
  if (!file.exists(f)) return(NULL)
  x <- tryCatch(readRDS(f), error = function(e) NULL)
  if (is.null(x) || is.null(x$value)) return(NULL)
  if (!is.null(cache$stats)) cache$stats$hits <- cache$stats$hits + 1L
  x$value
}

sc_cache_put <- function(cache, m, key, value) {
  if (!sc_cache_used(cache, m) || is.null(value)) return(invisible(FALSE))
  f <- sc_cache_path(cache, m, key)
  ok <- tryCatch({
    dir.create(dirname(f), showWarnings = FALSE, recursive = TRUE)
    tmp <- paste0(f, ".", Sys.getpid(), ".tmp")
    saveRDS(list(value = value, provider = m$provider, model = m$model,
                 temperature = m$temperature, saved = Sys.time()), tmp)
    file.rename(tmp, f)
  }, error = function(e) FALSE)
  if (isTRUE(ok) && !is.null(cache$stats)) cache$stats$saved <- cache$stats$saved + 1L
  invisible(isTRUE(ok))
}
