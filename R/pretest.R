# Pretest without real data: Screen a scale on synthetic respondents alone,
# check whether the flags hold across conditions (models, temperatures,
# wordings, persona sets) and whether the designed structure comes back.

#' Pretest a scale on synthetic respondents, without real data
#'
#' `synthetic_pretest()` is for the stage before any real
#' data exist. It runs a standard item analysis on synthetic respondents and
#' flags items worth a second look. It is **pilot screening, not
#' validation**: Language models answer more tidily than people (see
#' [authenticity_benchmark()] on the HEXACO data), so a clean result here
#' does not show that a scale works in people. Items that fail even with
#' tidy respondents are the ones to rewrite first.
#'
#' **Item and scale screening.** For every item, on the keyed answers
#' (reverse-keyed items recoded as `(min + max) - x`): The mean and SD, the
#' share of answers in the most common category (`top_share`), the
#' item-rest correlation with the other items of its scale, alpha when the
#' item is dropped, its highest absolute correlation with any other item
#' (`max_r`, with that item as `twin`) and, with `irt = TRUE`, the slope of
#' a graded response model fitted by mirt to each scale (`slope`; `NA`
#' when the model fails or the slope is beyond 10, which synthetic answers
#' that are close to deterministic can produce). For
#' every scale: Cronbach's alpha, the mean inter-item correlation and the
#' number of dimensions that parallel analysis finds (`n_factors`).
#'
#' **Flags.** An item is flagged as
#'
#' - `low_variance` ("Barely varies") when its SD is below `thresholds$sd`
#'   or `top_share` is at least `thresholds$top_share`;
#' - `key` ("Reverse key not working" for reverse-keyed items, "Runs
#'   against its scale" for the others) when its keyed item-rest
#'   correlation is below 0;
#' - `weak` ("Weak link to its scale") when the item-rest correlation is
#'   below `thresholds$item_rest`, or the slope is below `thresholds$slope`;
#' - `other_scale` ("Closer to another scale") when the item correlates
#'   more with another scale's score than with the rest of its own scale;
#' - `redundant` ("Near-duplicate") when `max_r` is at least
#'   `thresholds$redundant`.
#'
#' **Expected structure.** The `scale` and `reverse` columns of `items` are
#' the structure you designed. `summary` reports, for each condition, the
#' share of items that relate most to their own scale (`own_scale`), the
#' share of reverse-keyed items whose key comes through (`reverse_ok`), and
#' how many dimensions parallel analysis finds over all items
#' (`n_factors`) next to the number of scales you designed (`scales`).
#'
#' **Stability.** Each value of `by` is a condition: A model, a
#' temperature, a prompt wording or a persona set. Give each run its own
#' label in that column (for example `"Haiku, wording B"`). The flags are
#' computed on the pooled attempts of each condition and again in every
#' single attempt. `agreement` has one row per item: In how many conditions
#' it is flagged (`flagged_in`) and the share of single attempts that flag
#' it (`attempt_share`, a check on sampling noise). `stability` compares
#' every pair of conditions: The rank correlation of their item-rest
#' correlations (`rho`) and the overlap of their flagged items
#' (`jaccard`). Flags shared by most conditions are the ones to act on.
#'
#' The settings and the item table are kept in the result, so the same
#' synthetic data can be compared with real data later with
#' [authenticity_benchmark()] once real responses are in.
#'
#' The function works on any responses, so running it on real data shows
#' which synthetic flags hold in people (see the tutorial "Pretesting a
#' scale without real data").
#'
#' @param synthetic synthetic respondents: A data frame with one row per
#'   respondent, the item columns, the `by` column(s) and optionally an
#'   `attempt` column (as from [generate_synthetic()] or [hexaco_llm]), or a
#'   named list with one element per condition, each a data frame or a list
#'   of attempts (as in [authenticity_benchmark()]).
#' @param items the item table: `item`, `scale` (or `trait`), and
#'   optionally `reverse` (as in [hexaco_items]). An [sc_instrument()] also
#'   works, and then gives `scale_range` too. Without a `scale` column, all
#'   items form one scale.
#' @param by the column(s) of a data frame `synthetic` that define the
#'   conditions. Several columns are joined with `" / "`. A data frame
#'   without these columns is one condition, `"Data"`.
#' @param scale_range the lowest and highest response categories, used to
#'   key reverse items. `NULL` takes them from the instrument or the data.
#' @param irt fit a graded response model per scale and condition with mirt
#'   to get the slopes? It is the slowest step.
#' @param n_pa number of random data sets for parallel analysis.
#' @param thresholds a named list that changes any of the defaults
#'   `list(sd = 0.5, top_share = 0.9, item_rest = 0.3, slope = 0.5,
#'   redundant = 0.85)`.
#' @param seed random seed (parallel analysis).
#' @return An object of class `sc_pretest`: A list with `summary` (one row
#'   per condition: `attempts`, `n`, `items`, `flagged`, `alpha` (mean over
#'   scales), `scales`, `n_factors`, `own_scale`, `reverse_ok`), `items`
#'   (one row per condition and item, with the statistics, the logical flag
#'   columns, `flags` (the labels) and `attempt_share`), `scales` (one row
#'   per condition and scale), `agreement`, `stability` and `settings`. It
#'   has `print()`, `tidy()` and `autoplot()` methods, and
#'   [summarise_pretest()] describes it in plain language.
#' @references Horn, J. L. (1965). A rationale and test for the number of
#'   factors in factor analysis. *Psychometrika, 30*(2), 179-185.
#' @seealso [gg_pretest()], [summarise_pretest()], [generate_synthetic()]
#' @examples
#' h <- hexaco_items[hexaco_items$trait %in% c("H", "C"), ]
#' ca <- hexaco_llm[hexaco_llm$country == "Canada" & hexaco_llm$attempt <= 3, ]
#' pt <- synthetic_pretest(ca, h, irt = FALSE, n_pa = 5)
#' pt
#' summarise_pretest(pt)
#' gg_pretest(pt)
#' \donttest{
#' # with the graded response model slopes (slower)
#' pt <- synthetic_pretest(ca, h)
#' }
#' @export
synthetic_pretest <- function(synthetic, items, by = "model", scale_range = NULL, irt = TRUE,
                              n_pa = 20, thresholds = list(), seed = 1) {
  if (inherits(items, "sc_instrument")) {
    if (is.null(scale_range)) scale_range <- c(items$min, items$max)
    items <- items$items
  }
  thr <- pt_thresholds(thresholds)
  conds <- pt_conditions(synthetic, by)
  cols <- Reduce(intersect, lapply(unlist(conds, recursive = FALSE), names))
  it <- pt_items(items, cols)
  if (is.null(scale_range)) {
    v <- unlist(lapply(unlist(conds, recursive = FALSE), function(a) bh_matrix(a, it)))
    if (all(is.na(v))) stop("The data hold no answers.", call. = FALSE)
    scale_range <- range(v, na.rm = TRUE)
  }
  lo <- scale_range[1]; hi <- scale_range[2]

  res <- with_seed(seed, lapply(names(conds), function(cn) {
    att <- lapply(conds[[cn]], function(a) bh_matrix(a, it))
    X <- do.call(rbind, att)
    st <- pt_stats(X, it, lo, hi, thr, irt = irt, n_pa = n_pa)
    share <- if (length(att) > 1L) {
      fl <- vapply(att, function(A) pt_any(pt_stats(A, it, lo, hi, thr, irt = FALSE, n_pa = 0)$items),
                   logical(nrow(it)))
      rowMeans(matrix(fl, nrow(it)))
    } else rep(NA_real_, nrow(it))
    st$items$attempt_share <- share
    st$items <- cbind(condition = cn, st$items, stringsAsFactors = FALSE)
    st$scales <- cbind(condition = cn, st$scales, stringsAsFactors = FALSE)
    st$summary <- cbind(condition = cn, attempts = length(att), st$summary, stringsAsFactors = FALSE)
    st
  }))
  items_out <- do.call(rbind, lapply(res, `[[`, "items"))
  scales_out <- do.call(rbind, lapply(res, `[[`, "scales"))
  summ <- do.call(rbind, lapply(res, `[[`, "summary"))
  agree <- pt_agreement(items_out, names(conds))
  stab <- pt_stability(items_out, names(conds))
  structure(list(summary = as_tbl(summ), items = as_tbl(items_out), scales = as_tbl(scales_out),
                 agreement = as_tbl(agree), stability = as_tbl(stab),
                 settings = list(items = as_tbl(it), conditions = names(conds), by = by,
                                 scale_range = c(lo, hi), irt = isTRUE(irt), n_pa = n_pa,
                                 thresholds = thr, seed = seed)),
            class = "sc_pretest")
}

#' Draw the pretest
#'
#' With `what = "items"`, one row per flagged item and one
#' column per condition. Red tiles are items with too little signal (they
#' barely vary, link weakly to their scale, run against it or sit closer to
#' another scale), blue tiles are near-duplicates of another item, pale
#' tiles have no flag. The letters name the flags, and the row label gives
#' the number of conditions that flag the item. With `what = "scales"`, one
#' row per condition and one tile per scale: Cronbach's alpha, red below
#' 0.7, pale around 0.8, blue at 0.95 or more (often a sign of tidy
#' synthetic respondents), with the number of dimensions parallel analysis
#' finds.
#'
#' @param x a result of [synthetic_pretest()].
#' @param what `"items"` or `"scales"`.
#' @param max_items show at most this many items, those flagged most often
#'   first.
#' @param title,subtitle plot titles. `NULL` uses the defaults.
#' @return A ggplot object.
#' @seealso [synthetic_pretest()]
#' @examples
#' # see synthetic_pretest()
#' @export
gg_pretest <- function(x, what = c("items", "scales"), max_items = 30, title = NULL,
                       subtitle = NULL) {
  if (!inherits(x, "sc_pretest")) stop("`x` must be a result of synthetic_pretest().", call. = FALSE)
  what <- match.arg(what)
  conds <- x$settings$conditions
  if (what == "scales") {
    d <- as.data.frame(x$scales)
    d$condition <- factor(d$condition, levels = rev(conds))
    d$scale <- factor(d$scale, levels = unique(x$settings$items$scale))
    d$fill <- pmax(0.6, pmin(1, d$alpha))
    d$text <- ifelse(is.na(d$alpha), "", sprintf("%.2f%s", d$alpha,
                                                 ifelse(is.na(d$n_factors), "",
                                                        sprintf(", %d dim.", d$n_factors))))
    d$ink <- ifelse(!is.na(d$fill) & (d$fill < 0.66 | d$fill > 0.96), "white", "grey15")
    if (is.null(title)) title <- "Reliability of each scale"
    if (is.null(subtitle)) subtitle <- paste(
      "Cronbach's alpha and the dimensions found by parallel analysis.",
      "Red: Below 0.7, blue: 0.95 or more, often too tidy.")
    return(
      ggplot2::ggplot(d, ggplot2::aes(x = .data$scale, y = .data$condition)) +
        ggplot2::geom_tile(ggplot2::aes(fill = .data$fill), colour = "white", linewidth = 1) +
        ggplot2::geom_text(ggplot2::aes(label = .data$text, colour = .data$ink), size = 3.2,
                           lineheight = 0.9) +
        ggplot2::scale_colour_identity() +
        ggplot2::scale_fill_gradientn(colours = sc_palette, values = c(0, 0.25, 0.5, 0.75, 1),
                                      limits = c(0.6, 1), breaks = c(0.6, 0.8, 1),
                                      labels = c("0.6 or less", "0.8", "1"), name = NULL,
                                      na.value = "grey85") +
        ggplot2::scale_x_discrete(position = "top") +
        ggplot2::labs(x = NULL, y = NULL, title = title, subtitle = subtitle) +
        theme_synthcheck() +
        ggplot2::theme(panel.grid = ggplot2::element_blank(),
                       legend.key.width = ggplot2::unit(2.5, "lines")))
  }
  ag <- as.data.frame(x$agreement)
  ag <- ag[ag$flagged_in > 0, , drop = FALSE]
  if (!nrow(ag)) {
    return(ggplot2::ggplot() +
             ggplot2::annotate("text", x = 0, y = 0, label = "No item is flagged in any condition.") +
             ggplot2::theme_void() + ggplot2::labs(title = title %||% "Flagged items"))
  }
  ag <- utils::head(ag, max_items)
  d <- as.data.frame(x$items)
  d <- d[d$item %in% ag$item, , drop = FALSE]
  lab <- stats::setNames(sprintf("%s (%d/%d)", ag$item, ag$flagged_in, length(conds)), ag$item)
  d$row <- factor(lab[d$item], levels = rev(lab))
  d$condition <- factor(d$condition, levels = conds)
  red <- d$low_variance | d$key | d$weak | d$other_scale
  d$kind <- ifelse(red, "Too little signal", ifelse(d$redundant, "Near-duplicate", "No flag"))
  d$kind <- factor(d$kind, levels = c("Too little signal", "No flag", "Near-duplicate"))
  d$code <- pt_codes(d)
  if (is.null(title)) title <- "Items flagged in the pretest"
  if (is.null(subtitle)) subtitle <- paste0(
    "V: Barely varies, K: Key runs against the scale, W: Weak link to its scale,\n",
    "S: Closer to another scale, D: Near-duplicate. (n/N): Conditions that flag the item.")
  ggplot2::ggplot(d, ggplot2::aes(x = .data$condition, y = .data$row)) +
    ggplot2::geom_tile(ggplot2::aes(fill = .data$kind), colour = "white", linewidth = 1) +
    ggplot2::geom_text(ggplot2::aes(label = .data$code,
                                    colour = ifelse(.data$kind == "No flag", "grey15", "white")),
                       size = 3.2, fontface = "bold") +
    ggplot2::scale_colour_identity() +
    ggplot2::scale_fill_manual(values = c("Too little signal" = sc_palette[1], "No flag" = sc_palette[3],
                                          "Near-duplicate" = sc_palette[5]), name = NULL, drop = FALSE) +
    ggplot2::scale_x_discrete(position = "top") +
    ggplot2::labs(x = NULL, y = NULL, title = title, subtitle = subtitle) +
    theme_synthcheck() +
    ggplot2::theme(panel.grid = ggplot2::element_blank(),
                   axis.text.x.top = ggplot2::element_text(angle = 30, hjust = 0, vjust = 0))
}

#' Describe the pretest in plain language
#'
#' `summarise_pretest()` writes a few sentences from a
#' result of [synthetic_pretest()]: Which items are flagged by most
#' conditions and why, how well the conditions agree, whether the designed
#' structure comes back, and whether the scales look too tidy. The text
#' follows fixed rules, so it is the same every time and states only values
#' in the result. It always starts with the reminder that this is pilot
#' screening, not validation.
#'
#' @param x a result of [synthetic_pretest()].
#' @param n_items how many items to name.
#' @return A tibble with `topic` and `text`. Printing it shows the text.
#' @seealso [synthetic_pretest()]
#' @examples
#' # see synthetic_pretest()
#' @export
summarise_pretest <- function(x, n_items = 5) {
  if (!inherits(x, "sc_pretest")) stop("`x` must be a result of synthetic_pretest().", call. = FALSE)
  s <- as.data.frame(x$summary); ag <- as.data.frame(x$agreement)
  sc <- as.data.frame(x$scales)
  nc <- nrow(s); ni <- nrow(x$settings$items)
  cond_word <- if (nc == 1) "the one condition" else sprintf("all %d conditions", nc)
  out <- list()
  out$screening <- paste(
    "This is pilot screening on synthetic respondents only. It flags items worth a second look;",
    "it does not show that the scale works in people.")
  flagged <- ag[ag$flagged_in > 0, , drop = FALSE]
  if (!nrow(flagged)) {
    out$items <- sprintf("No item is flagged in %s.", if (nc == 1) "the data" else "any condition")
  } else {
    most <- flagged[flagged$flagged_in == max(flagged$flagged_in), , drop = FALSE]
    top <- utils::head(flagged, n_items)
    named <- sc_join(sprintf("%s (%s)", top$item, tolower(top$flags)))
    out$items <- if (nc == 1) {
      sprintf("%d of %d items are flagged. The first %s: %s.", nrow(flagged), ni,
              if (nrow(top) == 1) "is" else sprintf("%d are", nrow(top)), named)
    } else {
      sprintf(paste("%d of %d items are flagged in at least one condition, and %d in %s.",
                    "Flagged most often: %s."), nrow(flagged), ni,
              sum(flagged$flagged_in == nc), cond_word, named)
    }
    if (any(!is.na(flagged$attempt_share))) {
      noisy <- sum(flagged$attempt_share < 0.5, na.rm = TRUE)
      if (noisy > 0)
        out$items <- paste(out$items, sprintf(
          "%d of the flagged items are flagged in fewer than half of the single attempts, so their flags may be sampling noise.",
          noisy))
    }
    if (nrow(flagged) >= 0.5 * ni)
      out$items <- paste(out$items, paste(
        "When most items are flagged, the flags describe the model's tidy answers as much as the items.",
        "Start with the items that most conditions agree on."))
    if (max(flagged$flagged_in) < nc && nc > 1)
      out$items <- paste(out$items, sprintf("No item is flagged in %s; the most is %d.", cond_word,
                                            max(most$flagged_in)))
  }
  st <- as.data.frame(x$stability)
  if (nrow(st)) {
    rho <- mean(st$rho, na.rm = TRUE)
    out$stability <- sprintf(paste(
      "The conditions %s on which items link weakly to their scale (mean rank correlation %.2f)",
      "and share %.0f%% of their flagged items on average."),
      if (is.na(rho)) "cannot be compared" else if (rho >= 0.7) "agree well" else
        if (rho >= 0.4) "agree in part" else "disagree", rho, 100 * mean(st$jaccard, na.rm = TRUE))
  }
  own <- s$own_scale; rev_ok <- s$reverse_ok
  str <- character(0)
  if (any(!is.na(own)))
    str <- c(str, sprintf("%s of the items relate most to the scale they were written for%s.",
                          sc_range_pct(own), if (nc > 1) " (range over conditions)" else ""))
  if (any(!is.na(rev_ok)))
    str <- c(str, sprintf("The reverse key comes through for %s of the reverse-keyed items.",
                          sc_range_pct(rev_ok)))
  nf <- s$n_factors
  if (any(!is.na(nf))) {
    str <- c(str, sprintf("You designed %d scale%s; parallel analysis finds %s dimension%s over all items.",
                          s$scales[1], if (s$scales[1] == 1) "" else "s",
                          if (min(nf, na.rm = TRUE) == max(nf, na.rm = TRUE)) min(nf, na.rm = TRUE) else
                            sprintf("%d to %d", min(nf, na.rm = TRUE), max(nf, na.rm = TRUE)),
                          if (max(nf, na.rm = TRUE) == 1) "" else "s"))
  }
  if (length(str)) out$structure <- paste(str, collapse = " ")
  tidy <- sc[!is.na(sc$alpha) & sc$alpha >= 0.95, , drop = FALSE]
  low <- sc[!is.na(sc$alpha) & sc$alpha < 0.7, , drop = FALSE]
  rel <- character(0)
  if (nrow(low))
    rel <- c(rel, sprintf("Alpha is below 0.7 for %s.", sc_join(unique(sprintf("%s in %s", low$scale, low$condition)))))
  if (nrow(tidy))
    rel <- c(rel, sprintf(paste("Alpha is 0.95 or higher in %d of %d scale results. Synthetic respondents",
                                "are often more consistent than people, so expect lower values in real data."),
                          nrow(tidy), nrow(sc)))
  if (length(rel)) out$reliability <- paste(rel, collapse = " ")
  res <- as_tbl(data.frame(topic = names(out), text = unlist(out), stringsAsFactors = FALSE))
  class(res) <- c("sc_pretest_summary", class(res))
  res
}

#' @export
print.sc_pretest_summary <- function(x, ...) {
  cat("Pretest without real data, in plain language\n\n")
  for (i in seq_len(nrow(x))) {
    cat(strwrap(x$text[i], width = 0.9 * getOption("width")), sep = "\n")
    cat("\n")
  }
  invisible(x)
}

#' @export
print.sc_pretest <- function(x, digits = 2, ...) {
  s <- x$settings
  cat("Pretest without real data: Pilot screening, not validation\n")
  cat(sprintf("%d items in %d scale%s, %d condition%s.\n\n", nrow(s$items),
              length(unique(s$items$scale)), if (length(unique(s$items$scale)) == 1) "" else "s",
              length(s$conditions), if (length(s$conditions) == 1) "" else "s"))
  t <- as.data.frame(x$summary)
  num <- vapply(t, is.numeric, logical(1))
  t[num] <- lapply(t[num], round, digits)
  print(t, row.names = FALSE)
  ag <- as.data.frame(x$agreement)
  ag <- ag[ag$flagged_in > 0, c("item", "scale", "flagged_in", "flags"), drop = FALSE]
  if (nrow(ag)) {
    cat(sprintf("\nFlagged items (%d), most often first:\n", nrow(ag)))
    print(utils::head(ag, 10), row.names = FALSE)
    if (nrow(ag) > 10) cat(sprintf("... and %d more in `$agreement`.\n", nrow(ag) - 10))
  } else cat("\nNo item is flagged.\n")
  cat("\nflagged: Items with at least one flag; own_scale: Share of items closest to their own scale;",
      "\nreverse_ok: Share of reverse-keyed items whose key comes through;",
      "\nn_factors: Dimensions by parallel analysis over all items (designed: `scales`).\n")
  invisible(x)
}

#' @exportS3Method generics::tidy
tidy.sc_pretest <- function(x, ...) x$agreement

#' @exportS3Method ggplot2::autoplot
autoplot.sc_pretest <- function(object, ...) gg_pretest(object, ...)

# ---- internal -------------------------------------------------------------

pt_flag_labels <- c(low_variance = "Barely varies", key = "Runs against its scale",
                    weak = "Weak link to its scale", other_scale = "Closer to another scale",
                    redundant = "Near-duplicate")
pt_flag_codes <- c(low_variance = "V", key = "K", weak = "W", other_scale = "S", redundant = "D")

pt_thresholds <- function(x) {
  def <- list(sd = 0.5, top_share = 0.9, item_rest = 0.3, slope = 0.5, redundant = 0.85)
  if (!is.list(x) || (length(x) && is.null(names(x))))
    stop("`thresholds` must be a named list.", call. = FALSE)
  bad <- setdiff(names(x), names(def))
  if (length(bad)) stop("Unknown `thresholds`: ", paste(bad, collapse = ", "), ".", call. = FALSE)
  def[names(x)] <- x
  def
}

# a named list of conditions, each a list of attempts (data frames)
pt_conditions <- function(synthetic, by) {
  if (is.data.frame(synthetic) || is.matrix(synthetic)) {
    d <- as.data.frame(synthetic)
    if (length(by) && all(by %in% names(d))) {
      lab <- if (length(by) == 1L) as.character(d[[by]]) else
        do.call(paste, c(lapply(by, function(b) as.character(d[[b]])), sep = " / "))
      if (anyNA(lab)) stop("The `by` column(s) hold missing values.", call. = FALSE)
      d$.condition <- lab
      lev <- unique(lab)
      out <- as_synthetic_list(d, model = ".condition")
      return(out[lev])
    }
    if (length(by) && any(by %in% names(d)))
      stop("Only some of the `by` columns are in `synthetic`: ", paste(by, collapse = ", "), ".",
           call. = FALSE)
    if (!"attempt" %in% names(d)) return(list(Data = list(d)))
    return(lapply(list(Data = d), function(m) split(m, m$attempt, drop = TRUE)))
  }
  coverage_inputs(synthetic)
}

pt_items <- function(items, cols) {
  if (is.data.frame(items) && "item" %in% names(items) &&
      !any(c("scale", "trait") %in% names(items))) {
    items <- as.data.frame(items)
    items$scale <- "All"
  }
  it <- bh_items(items, cols)
  if (nrow(it) < 3L) stop("A pretest needs at least three items in the data.", call. = FALSE)
  it
}

pt_alpha <- function(C) {
  k <- ncol(C)
  if (k < 2L || anyNA(C) || sum(C) <= 0) return(NA_real_)
  (k / (k - 1)) * (1 - sum(diag(C)) / sum(C))
}

pt_cor <- function(a, b) {
  ok <- !is.na(a) & !is.na(b)
  if (sum(ok) < 3L) return(NA_real_)
  a <- a[ok]; b <- b[ok]
  if (stats::sd(a) == 0 || stats::sd(b) == 0) return(NA_real_)
  stats::cor(a, b)
}

pt_top_share <- function(v) {
  v <- v[!is.na(v)]
  if (!length(v)) return(NA_real_)
  max(tabulate(match(v, unique(v)))) / length(v)
}

# parallel analysis (Horn, 1965): Leading eigenvalues above the 95th
# percentile of eigenvalues from random normal data of the same size
pt_parallel <- function(K, n_pa) {
  if (n_pa < 1) return(NA_integer_)
  sdv <- apply(K, 2, stats::sd, na.rm = TRUE)
  K <- K[, !is.na(sdv) & sdv > 0, drop = FALSE]
  K <- K[rowSums(!is.na(K)) > 0, , drop = FALSE]
  p <- ncol(K); n <- nrow(K)
  if (p < 2L || n < 3L) return(NA_integer_)
  R <- suppressWarnings(stats::cor(K, use = "pairwise.complete.obs"))
  R[is.na(R)] <- 0
  diag(R) <- 1
  ev <- eigen(R, symmetric = TRUE, only.values = TRUE)$values
  rand <- vapply(seq_len(n_pa), function(i)
    eigen(stats::cor(matrix(stats::rnorm(n * p), n)), symmetric = TRUE, only.values = TRUE)$values,
    numeric(p))
  q <- apply(matrix(rand, p), 1, stats::quantile, 0.95)
  k <- which(ev <= q)[1] - 1L
  if (is.na(k)) k <- p
  as.integer(k)
}

pt_slopes <- function(K, idx) {
  out <- rep(NA_real_, length(idx))
  sub <- K[, idx, drop = FALSE]
  nc <- apply(sub, 2, function(v) length(unique(v[!is.na(v)])))
  ok <- nc >= 2L
  if (sum(ok) < 3L) return(out)
  d <- as.data.frame(sub[, ok, drop = FALSE])
  d <- d[rowSums(!is.na(d)) > 0, , drop = FALSE]
  fit <- tryCatch(suppressWarnings(suppressMessages(
    mirt::mirt(d, 1, itemtype = "graded", verbose = FALSE, SE = FALSE,
               technical = list(NCYCLES = 500)))), error = function(e) NULL)
  if (is.null(fit)) return(out)
  a <- tryCatch(mirt::coef(fit, simplify = TRUE)$items[, "a1"], error = function(e) NULL)
  if (is.null(a)) return(out)
  # slopes beyond 10 are not estimable (near-deterministic answers)
  a[abs(a) > 10] <- NA_real_
  out[ok] <- unname(a)
  out
}

pt_stats <- function(X, it, lo, hi, thr, irt = FALSE, n_pa = 0) {
  K <- bh_key(X, it, lo, hi)
  scales <- unique(it$scale)
  p <- nrow(it)
  R <- suppressWarnings(stats::cor(K, use = "pairwise.complete.obs"))
  diag(R) <- NA
  S <- vapply(scales, function(s) bm_scale_score(K, it$scale == s), numeric(nrow(K)))
  S <- matrix(S, nrow(K), dimnames = list(NULL, scales))
  item_rest <- alpha_drop <- r_other <- slope <- rep(NA_real_, p)
  closest <- rep(NA_character_, p)
  sc_rows <- list()
  for (s in scales) {
    idx <- which(it$scale == s)
    C <- suppressWarnings(stats::cov(K[, idx, drop = FALSE], use = "pairwise.complete.obs"))
    for (j in seq_along(idx)) {
      i <- idx[j]
      if (length(idx) > 1L) {
        rest <- bm_scale_score(K, setdiff(idx, i))
        item_rest[i] <- pt_cor(K[, i], rest)
        if (length(idx) > 2L) alpha_drop[i] <- pt_alpha(C[-j, -j, drop = FALSE])
      }
      others <- setdiff(scales, s)
      if (length(others)) {
        ro <- vapply(others, function(o) pt_cor(K[, i], S[, o]), numeric(1))
        if (any(!is.na(ro))) {
          r_other[i] <- max(ro, na.rm = TRUE)
          closest[i] <- others[which.max(ro)]
        }
      }
    }
    if (irt) slope[idx] <- pt_slopes(K, idx)
    Rs <- R[idx, idx, drop = FALSE]
    sc_rows[[s]] <- data.frame(scale = s, items = length(idx), alpha = pt_alpha(C),
                               mean_r = if (length(idx) > 1L) mean(Rs, na.rm = TRUE) else NA_real_,
                               n_factors = pt_parallel(K[, idx, drop = FALSE], n_pa),
                               stringsAsFactors = FALSE)
  }
  sdv <- apply(X, 2, stats::sd, na.rm = TRUE)
  top <- apply(X, 2, pt_top_share)
  absR <- abs(R)
  max_r <- apply(absR, 1, function(v) if (all(is.na(v))) NA_real_ else max(v, na.rm = TRUE))
  twin <- apply(absR, 1, function(v) if (all(is.na(v))) NA_character_ else it$item[which.max(v)])
  key <- !is.na(item_rest) & item_rest < 0
  items <- data.frame(
    item = it$item, scale = it$scale, reverse = it$reverse,
    n = colSums(!is.na(X)), mean = colMeans(X, na.rm = TRUE), sd = sdv, top_share = top,
    item_rest = item_rest, alpha_drop = alpha_drop, max_r = max_r, twin = twin,
    r_other = r_other, closest = closest, slope = slope,
    low_variance = (!is.na(sdv) & sdv < thr$sd) | (!is.na(top) & top >= thr$top_share),
    key = key,
    weak = !key & ((!is.na(item_rest) & item_rest < thr$item_rest) |
                     (!is.na(slope) & slope < thr$slope)),
    other_scale = !is.na(r_other) & !is.na(item_rest) & r_other > item_rest,
    redundant = !is.na(max_r) & max_r >= thr$redundant,
    stringsAsFactors = FALSE)
  rownames(items) <- NULL
  items$flags <- pt_labels(items)
  scl <- do.call(rbind, sc_rows)
  rownames(scl) <- NULL
  scl$flagged <- vapply(scl$scale, function(s) sum(pt_any(items[items$scale == s, , drop = FALSE])),
                        integer(1))
  has_other <- !is.na(items$r_other) & !is.na(items$item_rest)
  summ <- data.frame(
    n = nrow(X), items = p, flagged = sum(pt_any(items)),
    alpha = mean(scl$alpha, na.rm = TRUE), scales = length(scales),
    n_factors = pt_parallel(K, n_pa),
    own_scale = if (any(has_other)) mean(items$item_rest[has_other] >= items$r_other[has_other]) else NA_real_,
    reverse_ok = if (any(it$reverse & !is.na(item_rest))) mean(item_rest[it$reverse] > 0, na.rm = TRUE) else NA_real_,
    stringsAsFactors = FALSE)
  if (is.nan(summ$alpha)) summ$alpha <- NA_real_
  list(items = items, scales = scl, summary = summ)
}

pt_any <- function(items) {
  items$low_variance | items$key | items$weak | items$other_scale | items$redundant
}

pt_labels <- function(items) {
  f <- names(pt_flag_labels)
  vapply(seq_len(nrow(items)), function(i) {
    on <- f[vapply(f, function(k) isTRUE(items[[k]][i]), logical(1))]
    lab <- pt_flag_labels[on]
    if ("key" %in% on && isTRUE(items$reverse[i])) lab[on == "key"] <- "Reverse key not working"
    if ("redundant" %in% on) lab[on == "redundant"] <- sprintf("Near-duplicate of %s", items$twin[i])
    paste(lab, collapse = ", ")
  }, character(1))
}

pt_codes <- function(items) {
  f <- names(pt_flag_codes)
  vapply(seq_len(nrow(items)), function(i)
    paste(pt_flag_codes[f[vapply(f, function(k) isTRUE(items[[k]][i]), logical(1))]], collapse = ""),
    character(1))
}

pt_agreement <- function(items, conds) {
  items$any <- pt_any(items)
  base <- items[items$condition == conds[1], c("item", "scale", "reverse")]
  rows <- lapply(base$item, function(i) {
    d <- items[items$item == i, , drop = FALSE]
    f <- names(pt_flag_labels)
    counts <- vapply(f, function(k) sum(d[[k]]), numeric(1))
    lab <- pt_flag_labels[f[counts > 0]]
    if ("key" %in% f[counts > 0] && isTRUE(d$reverse[1])) lab[f[counts > 0] == "key"] <- "Reverse key not working"
    data.frame(flagged_in = sum(d$any), conditions = nrow(d), share = mean(d$any),
               flags = paste(lab[order(-counts[counts > 0])], collapse = ", "),
               attempt_share = if (all(is.na(d$attempt_share))) NA_real_ else mean(d$attempt_share, na.rm = TRUE),
               mean_item_rest = mean(d$item_rest, na.rm = TRUE),
               stringsAsFactors = FALSE)
  })
  out <- cbind(base, do.call(rbind, rows))
  out$mean_item_rest[is.nan(out$mean_item_rest)] <- NA_real_
  ord <- order(-out$flagged_in, -ifelse(is.na(out$attempt_share), 0, out$attempt_share),
               ifelse(is.na(out$mean_item_rest), -Inf, out$mean_item_rest))
  out <- out[ord, , drop = FALSE]
  rownames(out) <- NULL
  out
}

pt_stability <- function(items, conds) {
  empty <- data.frame(condition_a = character(0), condition_b = character(0), rho = numeric(0),
                      jaccard = numeric(0), stringsAsFactors = FALSE)
  if (length(conds) < 2L) return(empty)
  pr <- utils::combn(conds, 2)
  do.call(rbind, lapply(seq_len(ncol(pr)), function(j) {
    a <- items[items$condition == pr[1, j], , drop = FALSE]
    b <- items[items$condition == pr[2, j], , drop = FALSE]
    b <- b[match(a$item, b$item), , drop = FALSE]
    ok <- !is.na(a$item_rest) & !is.na(b$item_rest)
    rho <- if (sum(ok) >= 3L) suppressWarnings(stats::cor(a$item_rest[ok], b$item_rest[ok],
                                                          method = "spearman")) else NA_real_
    fa <- pt_any(a); fb <- pt_any(b)
    data.frame(condition_a = pr[1, j], condition_b = pr[2, j], rho = rho,
               jaccard = if (any(fa | fb)) sum(fa & fb) / sum(fa | fb) else NA_real_,
               stringsAsFactors = FALSE)
  }))
}

sc_range_pct <- function(p) {
  p <- p[!is.na(p)]
  lo <- round(100 * min(p)); hi <- round(100 * max(p))
  if (lo == hi) sprintf("%d%%", lo) else sprintf("%d%% to %d%%", lo, hi)
}
