# Plain-language summaries of the synthetic authenticity benchmark.

#' Describe the benchmark in plain language
#'
#' **Experimental.** `summarise_benchmark()` writes a few sentences per model
#' from a result of [authenticity_benchmark()]: The score and its weakest
#' column, how close each anchored column is to real people, the behaviour
#' features that differ most from real people and in which direction, and
#' the person fit tails. The text follows fixed rules, so it is the same
#' every time and states only values in the table.
#'
#' The anchored values read as follows: 100 is as close as a second sample
#' of real people, 0 is no better than shuffling the real answers within
#' each item, and below 0 is worse than that.
#'
#' Synthetic respondents are experimental: The benchmark compares models and
#' supports decisions about them. It does not show that synthetic data can
#' replace a field test.
#'
#' @param x a result of [authenticity_benchmark()].
#' @param n_features how many behaviour features to name per model.
#' @return A tibble with `model`, `score`, `weakest` and `summary` (the text),
#'   in the order of the benchmark table. Printing it shows the text.
#' @seealso [authenticity_benchmark()]
#' @examples
#' h <- hexaco_items[hexaco_items$trait %in% c("H", "C"), ]
#' real <- hexaco_real[hexaco_real$country == "Canada", ]
#' ca <- hexaco_llm[hexaco_llm$country == "Canada" & hexaco_llm$attempt <= 2, ]
#' bm <- authenticity_benchmark(as_synthetic_list(ca), real, h, fit_scales = character(0),
#'                              n_splits = 5, n_floor = 5)
#' summarise_benchmark(bm)
#' @export
summarise_benchmark <- function(x, n_features = 2) {
  if (!inherits(x, "sc_benchmark")) stop("`x` must be a result of authenticity_benchmark().",
                                         call. = FALSE)
  tab <- as.data.frame(x$table)
  f <- as.data.frame(x$behaviour$features)
  tails <- as.data.frame(x$behaviour$summary)
  n <- nrow(tab)
  txt <- vapply(seq_len(n), function(i) {
    r <- tab[i, ]
    s1 <- sprintf("%s scores %s on the benchmark%s, set by its weakest column, %s.",
                  r$model, sc_num(r$score),
                  if (n > 1) sprintf(" (%s of %d)", sc_ordinal(i), n) else "",
                  sc_column_name(r$weakest))
    if (x$settings$score != "weakest")
      s1 <- sprintf("%s scores %s on the benchmark%s (%s of the three columns).", r$model,
                    sc_num(r$score), if (n > 1) sprintf(" (%s of %d)", sc_ordinal(i), n) else "",
                    switch(x$settings$score, mean = "the mean", geometric = "the geometric mean",
                           "a custom score"))
    cols <- c(overlap = r$overlap, structure = r$structure, behaviour = r$behaviour)
    s2 <- paste0(paste(vapply(names(cols), function(k)
      sprintf("%s is %s (%s)", sc_column_name(k, cap = TRUE), sc_num(cols[[k]]), sc_band(cols[[k]])),
      character(1)), collapse = "; "), ".")
    s3 <- sc_feature_sentence(f[f$model == r$model, , drop = FALSE], n_features)
    tl <- tails[tails$model == r$model, , drop = FALSE]
    s4 <- if (nrow(tl) && !is.na(tl$lz_high) && tl$lz_high >= 0.15) {
      sprintf("%s of its respondents fit the response model better than 95%% of real people, so they look too coherent.",
              sc_pct(tl$lz_high))
    } else if (nrow(tl) && !is.na(tl$lz_low) && tl$lz_low >= 0.15) {
      sprintf("%s of its respondents fit the response model worse than 95%% of real people, as careless respondents do.",
              sc_pct(tl$lz_low))
    } else ""
    paste(c(s1, s2, s3, s4)[nzchar(c(s1, s2, s3, s4))], collapse = " ")
  }, character(1))
  out <- as_tbl(data.frame(model = tab$model, score = tab$score, weakest = tab$weakest,
                           summary = txt, stringsAsFactors = FALSE))
  class(out) <- c("sc_summary", class(out))
  out
}

#' @export
print.sc_summary <- function(x, ...) {
  cat("Synthetic authenticity benchmark in plain language (experimental)\n\n")
  for (i in seq_len(nrow(x))) {
    cat(strwrap(x$summary[i], width = 0.9 * getOption("width")), sep = "\n")
    cat("\n")
  }
  cat("100 = as close as a second sample of real people; 0 = no better than shuffled columns.\n")
  invisible(x)
}

# ---- internal -------------------------------------------------------------

sc_num <- function(v) if (is.na(v)) "not available" else sprintf("%.0f", v)
sc_pct <- function(p) sprintf("%.0f%%", 100 * p)
sc_ordinal <- function(i) {
  suf <- if (i %% 100 %in% 11:13) "th" else switch(as.character(i %% 10), "1" = "st", "2" = "nd",
                                                   "3" = "rd", "th")
  paste0(i, suf)
}

sc_column_name <- function(k, cap = FALSE) {
  lab <- c(overlap = "Overlap", structure = "Structure", behaviour = "Behaviour")[k]
  if (is.na(lab)) k else unname(lab)
}

sc_band <- function(v) {
  if (is.na(v)) return("not available")
  if (v < 0) return("worse than shuffled columns")
  if (v < 25) return("barely better than shuffled columns")
  if (v < 50) return("closer to shuffled columns than to real people")
  if (v < 80) return("partly like real people")
  "close to a second sample of real people"
}

sc_feature_text <- list(
  variability = c(lower = "their answers vary less across items", higher = "their answers vary more across items"),
  extreme = c(lower = "they give fewer extreme answers", higher = "they give more extreme answers"),
  midpoint = c(lower = "they use the middle category less", higher = "they use the middle category more"),
  acquiescence = c(lower = "they agree less overall", higher = "they agree more overall (yes-saying)"),
  key_inconsistency = c(lower = "they answer reverse-keyed items more consistently",
                        higher = "they answer reverse-keyed items less consistently"),
  even_odd = c(lower = "their answers are less consistent within facets",
               higher = "their answers are more consistent within facets"),
  mahalanobis = c(lower = "their profiles sit closer to the average person",
                  higher = "their profiles are more unusual"),
  person_fit = c(lower = "they fit the response model worse", higher = "they fit the response model better")
)

sc_feature_sentence <- function(f, k) {
  f <- f[!is.na(f$B), , drop = FALSE]
  if (!nrow(f) || k < 1) return("")
  g <- do.call(rbind, lapply(split(f, f$feature), function(d) {
    gap <- stats::median(d$median_synthetic - d$median_real, na.rm = TRUE)
    data.frame(feature = d$feature[1], B = mean(d$B),
               direction = if (is.na(gap) || gap == 0) NA_character_ else if (gap < 0) "lower" else "higher",
               stringsAsFactors = FALSE)
  }))
  g <- g[order(g$B), , drop = FALSE]
  g <- g[!is.na(g$direction) & g$B < 80, , drop = FALSE]
  if (!nrow(g)) return("Its respondents answer much like real people on all behaviour features.")
  g <- utils::head(g, k)
  parts <- vapply(seq_len(nrow(g)), function(j)
    sprintf("%s (behaviour overlap %s)", sc_feature_text[[g$feature[j]]][[g$direction[j]]],
            sc_num(g$B[j])), character(1))
  paste0("Compared with real people, ", sc_join(parts), ".")
}

sc_join <- function(x) {
  if (length(x) <= 1) return(x)
  paste0(paste(x[-length(x)], collapse = ", "), " and ", x[length(x)])
}
