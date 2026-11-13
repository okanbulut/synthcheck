# The synthetic authenticity benchmark: Overlap, Structure and Behaviour,
# each anchored between a shuffled floor and a real split-half ceiling.

#' The synthetic authenticity benchmark
#'
#' `authenticity_benchmark()` scores several language
#' models on three indices and puts them in one table, with one row per
#' model:
#'
#' - **Overlap:** Do synthetic respondents land where real people land? For
#'   each scale, the real keyed scale scores are cut into deciles and
#'   Overlap is the sum over slices of the smaller of the synthetic and the
#'   real share, as in [synthetic_coverage()]. The benchmark averages it
#'   over the scales.
#' - **Structure:** Do the items relate to each other as they do in real
#'   people? 100 minus 100 times the mean absolute difference between the
#'   real and the synthetic inter-item correlations of all items.
#' - **Behaviour:** Do synthetic respondents answer the way real people do?
#'   See [synthetic_behaviour()].
#'
#' **Anchoring.** Each index \eqn{X} is rescaled to
#' \eqn{A = 100 (X - X_{floor}) / (X_{ceiling} - X_{floor})}. The floor is a
#' dumb generator: Each item column is drawn independently, with
#' replacement, from the real data, which keeps every item's distribution
#' but breaks people apart (`n_floor` draws). The ceiling scores one random
#' sample of real people against another, disjoint one (`n_splits` splits).
#' With `ceiling_n = "attempt"` (the default) both samples have the size of
#' a typical synthetic attempt (the median), so the sampling noise is
#' comparable; with `"half"` they are the two halves of the real data. The
#' floor draws have the same size.
#'
#' **Negative values.** The floor uses the real data, which a language model
#' never sees, so it is a strict baseline. A value below 0 means the model is
#' further from real people than respondents pieced together from shuffled
#' real answers: For example, its respondents bunch into fewer score deciles
#' (Overlap), its items correlate more than real ones (Structure), or its
#' answers are tidier than real people's (Behaviour). The table shows the
#' values unclamped, and [gg_benchmark()] colours them from -100 (red) to 100 (blue).
#'
#' **Score.** `score = "weakest"` (the default) takes the lowest of the three
#' anchored columns and names it in `weakest`. `"mean"` takes the (weighted)
#' mean, `"geometric"` the (weighted) geometric mean of the values clamped
#' to 0 to 100, and a function of three arguments (`overlap`, `structure`,
#' `behaviour`) gives any other score.
#'
#' **Copula reference.** With `copula = TRUE`, a row named "Gaussian copula
#' (reference)" is added. Its respondents come from [synthetic_copula()],
#' which keeps every item's distribution and the correlations between items
#' of the real data and nothing else. It has the median number and size of
#' the synthetic attempts. A model below this row does no better than a
#' generator without a language model. The copula is fitted to the real
#' target, so it is an in-sample reference (`reference = TRUE` in the
#' table), not a competitor. For the same reason, its Overlap and Structure
#' can be above 100: It reproduces the full real sample more closely than
#' a second, smaller sample of real people does.
#'
#' The benchmark compares models and
#' supports decisions about them. It does not show that synthetic data can
#' replace a field test.
#'
#' @inheritParams synthetic_behaviour
#' @param score how to combine the anchored columns: `"weakest"`, `"mean"`,
#'   `"geometric"` or a function (see Details).
#' @param weights optional named vector of weights for `"mean"` and
#'   `"geometric"`, with names `overlap`, `structure` and `behaviour`.
#' @param n_splits number of real splits for the ceiling.
#' @param n_floor number of shuffled draws for the floor.
#' @param ceiling_n size of the ceiling samples: `"attempt"` or `"half"`.
#' @param cor correlations for Structure: `"pearson"` (the default, fast on
#'   many items) or `"polychoric"` (needs the polycor package; slow).
#' @param copula add the Gaussian copula reference row (see Details).
#' @return An object of class `sc_benchmark`: A list with `table` (a tibble
#'   with one row per model, sorted by score: `model`, `reference` (`TRUE`
#'   for the copula row), `attempts`, `score`,
#'   `weakest`, the anchored `overlap`, `structure` and `behaviour`, their
#'   raw values (`*_raw`), and the lowest and highest anchored values over
#'   the attempts), `attempts` (raw and anchored values per attempt),
#'   `anchors` (floor and ceiling of each index), `behaviour` (the
#'   [synthetic_behaviour()] result), `careless` (the flags, with
#'   `clean_real = TRUE`) and `settings`. It has `print()`, `tidy()` and
#'   `autoplot()` methods.
#' @seealso [synthetic_behaviour()], [synthetic_coverage()],
#'   [gg_benchmark()]
#' @examples
#' h <- hexaco_items[hexaco_items$trait %in% c("H", "C"), ]
#' real <- hexaco_real[hexaco_real$country == "Canada", ]
#' ca <- hexaco_llm[hexaco_llm$country == "Canada" & hexaco_llm$attempt <= 2, ]
#' syn <- lapply(split(ca, ca$model, drop = TRUE), function(m) split(m, m$attempt))
#' bm <- authenticity_benchmark(syn, real, h, fit_scales = character(0),
#'                              n_splits = 5, n_floor = 5)
#' bm
#' gg_benchmark(bm)
#' \donttest{
#' # all 240 items, with person fit on every trait
#' ca <- hexaco_llm[hexaco_llm$country == "Canada", ]
#' syn <- lapply(split(ca, ca$model, drop = TRUE), function(m) split(m, m$attempt))
#' bm <- authenticity_benchmark(syn, real, hexaco_items)
#' bm
#' }
#' @export
authenticity_benchmark <- function(synthetic, real, items, score = "weakest", weights = NULL,
                                   clean_real = FALSE, careless_rule = NULL, n_splits = 20,
                                   n_floor = 20, ceiling_n = c("attempt", "half"),
                                   fit_scales = NULL, cor = c("pearson", "polychoric"),
                                   copula = FALSE, seed = 1) {
  ceiling_n <- match.arg(ceiling_n)
  cor <- match.arg(cor)
  if (cor == "polychoric" && !requireNamespace("polycor", quietly = TRUE))
    stop("cor = \"polychoric\" needs the polycor package.", call. = FALSE)
  if (!is.function(score)) score <- match.arg(score, c("weakest", "mean", "geometric"))
  w <- bm_weights(weights)
  syn <- coverage_inputs(synthetic)
  real <- as.data.frame(real)
  cols <- Reduce(intersect, c(list(names(real)), lapply(unlist(syn, recursive = FALSE), names)))
  it <- bh_items(items, cols)
  prep <- bh_prepare_real(real, it, fit_scales, clean_real, careless_rule)
  ref <- prep$ref
  real <- prep$real
  fr <- prep$features
  Kr <- bh_key(bh_matrix(real, it), it, ref$lo, ref$hi)
  n_real <- nrow(Kr)
  sizes <- unlist(lapply(syn, function(m) vapply(m, nrow, integer(1))))
  m <- if (ceiling_n == "half") floor(n_real / 2) else min(floor(n_real / 2), stats::median(sizes))
  m <- max(10L, as.integer(m))
  if (2L * m > n_real) stop("The real data are too small for the ceiling.", call. = FALSE)
  if (isTRUE(copula)) {
    if (copula_name %in% names(syn))
      stop("A model cannot be called \"", copula_name, "\" when `copula = TRUE`.", call. = FALSE)
    n_att <- max(1L, as.integer(stats::median(lengths(syn))))
    syn[[copula_name]] <- synthetic_copula(real, n = as.integer(stats::median(sizes)), items = it$item,
                                           attempts = n_att, seed = seed + 1L)
  }

  raw <- bh_matrix(real, it)
  def_full <- bm_overlap_def(Kr, it)
  r_full <- bm_cor(Kr, cor)

  with_seed(seed, {
    # synthetic attempts
    att <- list(); feats <- list()
    for (mo in names(syn)) for (a in seq_along(syn[[mo]])) {
      d <- syn[[mo]][[a]]
      K <- bh_key(bh_matrix(d, it), it, ref$lo, ref$hi)
      fs <- bh_features(d, ref)
      cmp <- bh_compare(fs, fr)
      feats[[length(feats) + 1L]] <- data.frame(model = mo, attempt = a, cmp, stringsAsFactors = FALSE)
      att[[length(att) + 1L]] <- data.frame(
        model = mo, attempt = a, n = nrow(d),
        overlap_raw = bm_overlap(K, def_full),
        structure_raw = bm_structure(r_full, bm_cor(K, cor)),
        behaviour_raw = bh_index(cmp$B), bh_tails(fs$person_fit, fr$person_fit),
        stringsAsFactors = FALSE)
    }
    att <- do.call(rbind, att); feats <- do.call(rbind, feats)

    # floor: shuffled columns of the real data
    fl <- t(vapply(seq_len(n_floor), function(b) {
      idx <- vapply(seq_len(ncol(Kr)), function(j) sample.int(n_real, m, replace = TRUE), integer(m))
      X <- matrix(raw[cbind(as.vector(idx), rep(seq_len(ncol(Kr)), each = m))], m,
                  dimnames = list(NULL, it$item))
      K <- bh_key(X, it, ref$lo, ref$hi)
      c(bm_overlap(K, def_full), bm_structure(r_full, bm_cor(K, cor)),
        bh_index(bh_compare(bh_features(as.data.frame(X), ref), fr)$B))
    }, numeric(3)))
    # ceiling: one real sample against another
    ce <- t(vapply(seq_len(n_splits), function(b) {
      s <- sample.int(n_real, 2L * m)
      A <- s[seq_len(m)]; B <- s[m + seq_len(m)]
      defB <- bm_overlap_def(Kr[B, , drop = FALSE], it)
      c(bm_overlap(Kr[A, , drop = FALSE], defB),
        bm_structure(bm_cor(Kr[B, , drop = FALSE], cor), bm_cor(Kr[A, , drop = FALSE], cor)),
        bh_index(bh_compare(fr[A, , drop = FALSE], fr[B, , drop = FALSE])$B))
    }, numeric(3)))
  })

  idx <- c("overlap", "structure", "behaviour")
  anchors <- data.frame(index = idx, floor = colMeans(fl, na.rm = TRUE), ceiling = colMeans(ce, na.rm = TRUE),
                        floor_sd = apply(fl, 2, stats::sd, na.rm = TRUE),
                        ceiling_sd = apply(ce, 2, stats::sd, na.rm = TRUE), stringsAsFactors = FALSE)
  rownames(anchors) <- NULL
  anchor <- function(x, i) 100 * (x - anchors$floor[i]) / (anchors$ceiling[i] - anchors$floor[i])
  for (i in seq_along(idx)) att[[idx[i]]] <- anchor(att[[paste0(idx[i], "_raw")]], i)

  tab <- do.call(rbind, lapply(names(syn), function(mo) {
    a <- att[att$model == mo, ]
    v <- vapply(idx, function(k) mean(a[[k]], na.rm = TRUE), numeric(1))
    sc <- bm_score(v, score, w)
    out <- data.frame(model = mo, reference = mo == copula_name && isTRUE(copula),
                      attempts = nrow(a), score = sc$score, weakest = sc$weakest,
                      overlap = v[1], structure = v[2], behaviour = v[3],
                      overlap_raw = mean(a$overlap_raw), structure_raw = mean(a$structure_raw),
                      behaviour_raw = mean(a$behaviour_raw), stringsAsFactors = FALSE)
    for (k in idx) {
      out[[paste0(k, "_lowest")]] <- min(a[[k]], na.rm = TRUE)
      out[[paste0(k, "_highest")]] <- max(a[[k]], na.rm = TRUE)
    }
    out
  }))
  tab <- tab[order(-tab$score, tab$model), ]
  rownames(tab) <- NULL

  beh_att <- att[c("model", "attempt", "n", "behaviour_raw", "lz_low", "lz_high")]
  names(beh_att)[4] <- "behaviour"
  beh <- structure(list(
    summary = bh_summary(beh_att), attempts = as_tbl(beh_att), features = as_tbl(feats),
    real_features = as_tbl(fr), careless = prep$careless,
    settings = list(items = it$item, fit_scales = ref$fit_scales, clean_real = clean_real,
                    n_real = n_real, seed = seed)), class = "sc_behaviour")

  structure(list(
    table = as_tbl(tab), attempts = as_tbl(att), anchors = as_tbl(anchors), behaviour = beh,
    careless = prep$careless,
    settings = list(score = if (is.function(score)) "custom" else score, weights = w,
                    clean_real = clean_real, n_splits = n_splits, n_floor = n_floor,
                    ceiling_n = ceiling_n, anchor_n = m, cor = cor, n_real = n_real, copula = isTRUE(copula),
                    items = it$item, fit_scales = ref$fit_scales, seed = seed)),
    class = "sc_benchmark")
}

#' Draw the synthetic authenticity benchmark
#'
#' One row per model, sorted by the benchmark score (best
#' at the top), and one tile for each anchored column (Overlap, Structure,
#' Behaviour). Tiles run from red (-100 or lower, far worse than shuffled
#' columns) through pale (around 0, no better than shuffled columns) to blue
#' (100, as close as a second sample of real people). The number in each
#' tile is the unclamped value. The column that sets the score is
#' outlined when `score = "weakest"`. The score is printed at the right.
#'
#' @param x a result of [authenticity_benchmark()].
#' @param title,subtitle plot titles. `NULL` uses the defaults.
#' @return A ggplot object.
#' @seealso [authenticity_benchmark()]
#' @examples
#' # see authenticity_benchmark()
#' @export
gg_benchmark <- function(x, title = NULL, subtitle = NULL) {
  if (!inherits(x, "sc_benchmark")) stop("`x` must be a result of authenticity_benchmark().", call. = FALSE)
  tab <- as.data.frame(x$table)
  idx <- c("overlap", "structure", "behaviour")
  lev <- c("Overlap", "Structure", "Behaviour", "Score")
  d <- do.call(rbind, lapply(idx, function(k) data.frame(
    model = tab$model, column = tools::toTitleCase(k), value = tab[[k]],
    weakest = x$settings$score == "weakest" & tab$weakest == k, stringsAsFactors = FALSE)))
  d$fill <- pmax(-100, pmin(100, d$value))
  d$text <- bm_num(d$value)
  d$ink <- ifelse(abs(d$fill) > 75, "white", "grey15")
  sc <- data.frame(model = tab$model, column = "Score", value = tab$score, stringsAsFactors = FALSE)
  sc$text <- bm_num(sc$value)
  d$model <- factor(d$model, levels = rev(tab$model)); sc$model <- factor(sc$model, levels = rev(tab$model))
  d$column <- factor(d$column, levels = lev); sc$column <- factor(sc$column, levels = lev)
  if (is.null(title)) title <- "Synthetic authenticity benchmark"
  if (is.null(subtitle))
    subtitle <- paste0("0 = shuffled real columns, 100 = a second sample of real people.\n",
                       if (x$settings$score == "weakest") "Outlined: The weakest column, which sets the score." else
                         paste0("Score: ", x$settings$score, "."))
  ggplot2::ggplot(d, ggplot2::aes(x = .data$column, y = .data$model)) +
    ggplot2::geom_tile(ggplot2::aes(fill = .data$fill), colour = "white", linewidth = 1) +
    ggplot2::geom_tile(data = d[d$weakest, , drop = FALSE], fill = NA, colour = "grey15",
                       linewidth = 0.9, width = 0.92, height = 0.88) +
    ggplot2::geom_text(ggplot2::aes(label = .data$text, colour = .data$ink), size = 3.8) +
    ggplot2::scale_colour_identity() +
    ggplot2::geom_text(data = sc, ggplot2::aes(label = .data$text), size = 4.2, fontface = "bold",
                       colour = "grey15") +
    ggplot2::scale_fill_gradientn(colours = sc_palette, limits = c(-100, 100),
                                  breaks = c(-100, 0, 100),
                                  labels = c("-100 or less", "0: Shuffled", "100: Real"),
                                  name = NULL) +
    ggplot2::scale_x_discrete(position = "top", drop = FALSE) +
    ggplot2::labs(x = NULL, y = NULL, title = title, subtitle = subtitle) +
    theme_synthcheck() +
    ggplot2::theme(panel.grid = ggplot2::element_blank(),
                   legend.key.width = ggplot2::unit(2.5, "lines"))
}

#' @export
print.sc_benchmark <- function(x, digits = 0, ...) {
  s <- x$settings
  cat("Synthetic authenticity benchmark\n")
  cat(sprintf("%d items, %d real respondents%s. Score: %s.\n\n", length(s$items), s$n_real,
              if (s$clean_real) " after removing careless ones" else "", s$score))
  t <- as.data.frame(x$table)[c("model", "attempts", "overlap", "structure", "behaviour", "score", "weakest")]
  names(t) <- c("model", "attempts", "Overlap", "Structure", "Behaviour", "Score", "Weakest")
  t$Weakest <- tools::toTitleCase(t$Weakest)
  num <- vapply(t, is.numeric, logical(1))
  t[num] <- lapply(t[num], round, digits)
  print(t, row.names = FALSE)
  a <- as.data.frame(x$anchors)
  cat(sprintf("\nAnchors (raw, floor to ceiling, samples of %d): %s.\n", s$anchor_n,
              paste(sprintf("%s %.1f to %.1f", tools::toTitleCase(a$index), a$floor, a$ceiling),
                    collapse = ", ")))
  cat("0 = shuffled real columns, 100 = a second sample of real people.\n")
  invisible(x)
}

#' @exportS3Method generics::tidy
tidy.sc_benchmark <- function(x, ...) x$table

#' @exportS3Method ggplot2::autoplot
autoplot.sc_benchmark <- function(object, ...) gg_benchmark(object, ...)

# ---- internal -------------------------------------------------------------

copula_name <- "Gaussian copula (reference)"

bm_weights <- function(weights) {
  w <- c(overlap = 1, structure = 1, behaviour = 1)
  if (is.null(weights)) return(w)
  if (!is.numeric(weights) || is.null(names(weights)) || any(weights < 0) ||
      length(setdiff(names(weights), names(w))))
    stop("`weights` must be a named, non-negative vector with names overlap, structure and behaviour.",
         call. = FALSE)
  w[names(weights)] <- weights
  if (sum(w) <= 0) stop("At least one weight must be positive.", call. = FALSE)
  w
}

bm_score <- function(v, score, w) {
  names(v) <- c("overlap", "structure", "behaviour")
  weakest <- if (all(is.na(v))) NA_character_ else names(v)[which.min(v)]
  if (is.function(score)) {
    s <- score(overlap = v[["overlap"]], structure = v[["structure"]], behaviour = v[["behaviour"]])
    return(list(score = as.numeric(s)[1], weakest = weakest))
  }
  s <- switch(score,
    weakest = min(v),
    mean = sum(w * v) / sum(w),
    geometric = {
      cv <- pmax(0, pmin(100, v))
      if (any(cv[w > 0] == 0)) 0 else exp(sum(w * log(pmax(cv, 1e-12))) / sum(w))
    })
  list(score = s, weakest = weakest)
}

# score deciles of each scale's keyed mean, from the real data
bm_overlap_def <- function(K, it) {
  lapply(stats::setNames(nm = unique(it$scale)), function(s) {
    cols <- it$scale == s
    sc <- bm_scale_score(K, cols)
    sc <- sc[!is.na(sc)]
    cut <- score_cuts(sc, 10)
    list(cols = cols, cut = cut, real = tabulate(score_assign(sc, cut), cut$n) / length(sc))
  })
}

bm_scale_score <- function(K, cols) {
  sub <- K[, cols, drop = FALSE]
  v <- rowMeans(sub, na.rm = TRUE)
  v[rowSums(!is.na(sub)) < ncol(sub) / 2] <- NA_real_
  v
}

bm_overlap <- function(K, def) {
  per <- vapply(names(def), function(s) {
    sc <- bm_scale_score(K, def[[s]]$cols)
    sc <- sc[!is.na(sc)]
    if (!length(sc)) return(NA_real_)
    p <- tabulate(score_assign(sc, def[[s]]$cut), def[[s]]$cut$n) / length(sc)
    sum(pmin(p, def[[s]]$real))
  }, numeric(1))
  100 * mean(per, na.rm = TRUE)
}

bm_cor <- function(K, method) {
  if (method == "pearson") return(suppressWarnings(stats::cor(K, use = "pairwise.complete.obs")))
  coverage_cor(as.data.frame(K), "polychoric")
}

bm_num <- function(v) {
  v <- round(v)
  v[!is.na(v) & v == 0] <- 0
  ifelse(is.na(v), "", sprintf("%.0f", v))
}

bm_structure <- function(r_real, r_syn) 100 * coverage_structure(r_real, r_syn)
