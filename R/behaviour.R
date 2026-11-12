# Behaviour: Do synthetic respondents answer the way real people do?

#' The eight behaviour features of each respondent
#'
#' **Experimental.** `behaviour_features()` describes how each respondent
#' answers, apart from what they answer. The eight features are the
#' building blocks of the Behaviour index in [synthetic_behaviour()] and of
#' the careless flags in [flag_careless()].
#'
#' | Feature | Definition | Careless side |
#' |---|---|---|
#' | `variability` | SD of the raw answers across all items | Very low or very high |
#' | `extreme` | Share of answers at the lowest or highest category | High |
#' | `midpoint` | Share of answers at the middle category (odd number of categories only) | High |
#' | `acquiescence` | Mean raw answer minus the scale midpoint | High |
#' | `key_inconsistency` | Mean over facets of the absolute difference between the keyed means of the positive and the reverse-keyed items | High |
#' | `even_odd` | Correlation across facets between the keyed means of the odd-numbered and the even-numbered items of each facet | Low |
#' | `mahalanobis` | Square root of the Mahalanobis distance of the keyed facet means, using the real data's mean and covariance | High |
#' | `person_fit` | Standardized log-likelihood \eqn{l_z} (Drasgow) under a graded response model fitted to the real data, one model per scale, averaged over scales | Low (misfit); very high means "too coherent" |
#'
#' **Keying.** Keyed answers recode reverse-keyed items as
#' `(min + max) - x`, where `min` and `max` are the lowest and highest
#' answers in the reference data (for HEXACO: `8 - x`). Variability,
#' Extreme, Midpoint and Acquiescence use the raw answers.
#'
#' **Reference.** The facet means and covariance for `mahalanobis` and the
#' graded response models for `person_fit` come from `real` (from `data`
#' itself when `real` is `NULL`). The models are fitted once per scale with
#' `mirt::mirt(real_keyed[scale_items], 1, "graded")` and are never refitted
#' on synthetic data. Every respondent gets the MAP theta on a grid of 81
#' points from -5 to 5 with a standard normal prior, and \eqn{l_z} is
#' computed at that theta. Answers in a category that the real data never
#' use count as missing for person fit.
#'
#' **Facets.** Without a `facet` column, the scales stand in for facets in
#' `key_inconsistency`, `even_odd` and `mahalanobis`. `even_odd` needs at
#' least three facets with two or more items.
#'
#' **Missing answers.** A feature is `NA` for a respondent who answered fewer
#' than half of the items it needs (all items, or a scale's items for person
#' fit).
#'
#' @param data a data frame of responses (one row per respondent, items as
#'   columns, matched by name to `items$item`).
#' @param items a data frame with one row per item: `item` (column name),
#'   `scale` (or `trait`, as in [hexaco_items]), an optional `facet` and an
#'   optional logical `reverse`.
#' @param real optional data frame of real responses used as the reference
#'   (see Details). `NULL` uses `data`.
#' @param fit_scales the scales used for person fit. `NULL` uses all scales;
#'   `character(0)` skips person fit (the `person_fit` column is then `NA`).
#' @return A tibble with one row per respondent of `data` and the eight
#'   feature columns.
#' @seealso [synthetic_behaviour()], [flag_careless()]
#' @examples
#' h <- hexaco_items[hexaco_items$trait == "H", ]
#' real <- hexaco_real[hexaco_real$country == "Canada", ]
#' syn <- hexaco_llm[hexaco_llm$country == "Canada" & hexaco_llm$attempt == 1, ]
#' f <- behaviour_features(syn[1:200, ], h, real = real, fit_scales = character(0))
#' summary(f)
#' \donttest{
#' # with person fit (fits a graded response model to the real data)
#' f <- behaviour_features(syn[1:200, ], h, real = real)
#' summary(f$person_fit)
#' }
#' @export
behaviour_features <- function(data, items, real = NULL, fit_scales = NULL) {
  data <- as.data.frame(data)
  ref_data <- if (is.null(real)) data else as.data.frame(real)
  it <- bh_items(items, intersect(names(data), names(ref_data)))
  ref <- bh_reference(ref_data, it, fit_scales)
  as_tbl(bh_features(data, ref))
}

#' Flag careless real respondents
#'
#' **Experimental.** `flag_careless()` marks real respondents whose answers
#' look careless, using the eight [behaviour_features()]. By default a
#' respondent is careless when at least two features fall in the real data's
#' most extreme 2.5% on the careless side: The highest 2.5% for `extreme`,
#' `midpoint`, `acquiescence`, `key_inconsistency` and `mahalanobis`, the
#' lowest 2.5% for `even_odd` and `person_fit`, and the lowest or highest
#' 1.25% for `variability`. These are the flags behind `clean_real = TRUE`
#' in [synthetic_behaviour()] and [authenticity_benchmark()].
#'
#' @inheritParams behaviour_features
#' @param real a data frame of real responses.
#' @param rule optional function that takes the tibble of features (one row
#'   per respondent) and returns a logical vector, `TRUE` for careless
#'   respondents. It replaces the default rule.
#' @return A tibble with one row per respondent of `real`: `row` (the row in
#'   `real`), the eight features, `n_flags` (the number of features in the
#'   careless 2.5%, or `NA` with a user `rule`) and `careless`.
#' @seealso [behaviour_features()], [synthetic_behaviour()]
#' @examples
#' h <- hexaco_items[hexaco_items$trait == "H", ]
#' real <- hexaco_real[hexaco_real$country == "Canada", ]
#' fl <- flag_careless(real, h, fit_scales = character(0))
#' mean(fl$careless)
#' @export
flag_careless <- function(real, items, rule = NULL, fit_scales = NULL) {
  real <- as.data.frame(real)
  f <- behaviour_features(real, items, fit_scales = fit_scales)
  if (is.null(rule)) {
    n <- careless_count(f)
    careless <- n >= 2L
  } else {
    if (!is.function(rule)) stop("`rule` must be a function of the features.", call. = FALSE)
    careless <- as.logical(rule(f))
    if (length(careless) != nrow(f))
      stop("`rule` must return one logical value per respondent.", call. = FALSE)
    careless[is.na(careless)] <- FALSE
    n <- rep(NA_integer_, nrow(f))
  }
  tibble::tibble(row = seq_len(nrow(f)), f, n_flags = n, careless = careless)
}

#' Behaviour: Do synthetic respondents answer the way real people do?
#'
#' **Experimental.** `synthetic_behaviour()` compares how synthetic and real
#' respondents answer, using the eight [behaviour_features()]. For each
#' feature, the real values are cut at their deciles and the share of
#' synthetic respondents in each decile is counted, as Overlap does for
#' score deciles in [synthetic_coverage()]. Then
#'
#' \deqn{B_f = 100 \sum_d \min(p_{f,d}, 0.10), \qquad
#'   \mathrm{Behaviour} = \mathrm{mean}_f(B_f).}
#'
#' \eqn{B_f} is 100 when synthetic respondents spread over the real deciles
#' of feature \eqn{f} like real people do, and 10 when they all fall in one
#' decile. Ties at the cut points (common for `extreme` and `midpoint`) are
#' broken at random with `seed`. Features that cannot be computed (for
#' example `midpoint` with an even number of categories) are left out of the
#' mean.
#'
#' Each \eqn{B_f} has a direction: Whether the synthetic median is
#' `"lower"` or `"higher"` than the real median. That tells "too tidy" from
#' "too noisy". The person fit tails give the share of synthetic respondents
#' below the real 5th percentile of \eqn{l_z} (careless-like) and above the
#' real 95th percentile (too coherent); real data have 5% in each by
#' construction.
#'
#' Synthetic respondents are experimental: Use Behaviour to compare models,
#' not to replace a field test.
#'
#' @inheritParams behaviour_features
#' @param synthetic a named list with one element per model, each a list of
#'   attempts (data frames of responses), as in [synthetic_coverage()].
#' @param real a data frame of real responses to the same items.
#' @param clean_real compare against real respondents after removing those
#'   flagged by [flag_careless()]? The default compares against all real
#'   respondents.
#' @param careless_rule optional `rule` passed to [flag_careless()].
#' @param seed random seed for breaking ties.
#' @return An object of class `sc_behaviour`: A list with `summary` (one row
#'   per model: Overall, Lowest and Highest Behaviour over the attempts and
#'   the person fit tails), `attempts` (Behaviour and person fit tails per
#'   attempt), `features` (\eqn{B_f}, the medians and the direction per
#'   model, attempt and feature), `real_features` (the features of the real
#'   respondents), `careless` (the flags, with `clean_real = TRUE`) and
#'   `settings`. It has `print()`, `tidy()` and `autoplot()` methods.
#' @seealso [behaviour_features()], [gg_behaviour()],
#'   [authenticity_benchmark()]
#' @examples
#' h <- hexaco_items[hexaco_items$trait == "H", ]
#' real <- hexaco_real[hexaco_real$country == "Canada", ]
#' ca <- hexaco_llm[hexaco_llm$country == "Canada" & hexaco_llm$attempt <= 2, ]
#' syn <- lapply(split(ca, ca$model, drop = TRUE), function(m) split(m, m$attempt))
#' beh <- synthetic_behaviour(syn, real, h, fit_scales = character(0))
#' beh
#' gg_behaviour(beh)
#' @export
synthetic_behaviour <- function(synthetic, real, items, fit_scales = NULL,
                                clean_real = FALSE, careless_rule = NULL, seed = 1) {
  syn <- coverage_inputs(synthetic)
  real <- as.data.frame(real)
  cols <- Reduce(intersect, c(list(names(real)), lapply(unlist(syn, recursive = FALSE), names)))
  it <- bh_items(items, cols)
  prep <- bh_prepare_real(real, it, fit_scales, clean_real, careless_rule)
  ref <- prep$ref
  fr <- prep$features
  feats <- list(); att <- list()
  with_seed(seed, {
    for (m in names(syn)) for (a in seq_along(syn[[m]])) {
      fs <- bh_features(syn[[m]][[a]], ref)
      cmp <- bh_compare(fs, fr)
      feats[[length(feats) + 1L]] <- data.frame(model = m, attempt = a, cmp, stringsAsFactors = FALSE)
      att[[length(att) + 1L]] <- data.frame(model = m, attempt = a, n = nrow(fs),
                                            behaviour = bh_index(cmp$B),
                                            bh_tails(fs$person_fit, fr$person_fit),
                                            stringsAsFactors = FALSE)
    }
  })
  feats <- do.call(rbind, feats)
  att <- do.call(rbind, att)
  structure(list(
    summary = bh_summary(att), attempts = as_tbl(att), features = as_tbl(feats),
    real_features = as_tbl(fr), careless = prep$careless,
    settings = list(items = it$item, fit_scales = ref$fit_scales, clean_real = clean_real,
                    n_real = nrow(prep$real), seed = seed)),
    class = "sc_behaviour")
}

#' Draw the behaviour strip
#'
#' **Experimental.** One row per model (or per attempt), one column per
#' behaviour feature. Each tile is coloured by the direction of the gap
#' (red: Synthetic respondents lower than real people, blue: Higher) with a
#' strength of `100 - B_f`, so a pale tile is a match. The number in the
#' tile is \eqn{B_f}, and the row label gives Behaviour.
#'
#' @param x a result of [synthetic_behaviour()].
#' @param by draw one row per `"model"` (\eqn{B_f} averaged over attempts)
#'   or per `"attempt"`.
#' @param title,subtitle plot titles. `NULL` uses the defaults.
#' @return A ggplot object.
#' @seealso [synthetic_behaviour()]
#' @examples
#' # see synthetic_behaviour()
#' @export
gg_behaviour <- function(x, by = c("model", "attempt"), title = NULL, subtitle = NULL) {
  if (!inherits(x, "sc_behaviour")) stop("`x` must be a result of synthetic_behaviour().", call. = FALSE)
  by <- match.arg(by)
  f <- as.data.frame(x$features)
  f <- f[!is.na(f$B), ]
  models <- unique(x$summary$model)
  if (by == "model") {
    d <- do.call(rbind, lapply(split(f, list(f$model, f$feature), drop = TRUE), function(g) {
      data.frame(model = g$model[1], feature = g$feature[1], B = mean(g$B),
                 gap = stats::median(g$median_synthetic) - g$median_real[1],
                 stringsAsFactors = FALSE)
    }))
    s <- x$summary
    lab <- sprintf("%s (%.0f)", s$model, s$behaviour_overall)
    d$row <- factor(lab[match(d$model, s$model)], levels = rev(lab))
  } else {
    d <- data.frame(model = f$model, feature = f$feature, B = f$B,
                    gap = f$median_synthetic - f$median_real, attempt = f$attempt,
                    stringsAsFactors = FALSE)
    a <- x$attempts
    lab <- sprintf("%s #%d (%.0f)", a$model, a$attempt, a$behaviour)
    key <- paste(a$model, a$attempt)
    d$row <- factor(lab[match(paste(d$model, d$attempt), key)], levels = rev(lab))
  }
  d$sign <- ifelse(d$gap < 0, -1, ifelse(d$gap > 0, 1, 0))
  d$fill <- d$sign * (100 - d$B) / 90
  d$fill <- pmax(-1, pmin(1, d$fill))
  d$feature <- factor(bh_labels[d$feature], levels = bh_labels)
  d$text <- sprintf("%.0f", d$B)
  d$ink <- ifelse(abs(d$fill) > 0.6, "white", "grey15")
  if (is.null(title)) title <- "Behaviour strip"
  if (is.null(subtitle))
    subtitle <- paste0("Numbers are B_f (100 = spread over the real deciles like real people).\n",
                       "Red: Synthetic lower than real. Blue: Higher.")
  ggplot2::ggplot(d, ggplot2::aes(x = .data$feature, y = .data$row, fill = .data$fill)) +
    ggplot2::geom_tile(colour = "white", linewidth = 0.8) +
    ggplot2::geom_text(ggplot2::aes(label = .data$text, colour = .data$ink), size = 3.4) +
    ggplot2::scale_colour_identity() +
    ggplot2::scale_fill_gradientn(colours = sc_palette, limits = c(-1, 1),
                                  breaks = c(-1, 0, 1),
                                  labels = c("Lower than real", "Match", "Higher than real"),
                                  name = NULL) +
    ggplot2::scale_x_discrete(position = "top") +
    ggplot2::labs(x = NULL, y = NULL, title = title, subtitle = subtitle) +
    theme_synthcheck() +
    ggplot2::theme(panel.grid = ggplot2::element_blank(),
                   legend.key.width = ggplot2::unit(2.5, "lines"))
}

#' @export
print.sc_behaviour <- function(x, digits = 1, ...) {
  cat("Behaviour of synthetic respondents (experimental)\n")
  cat(sprintf("%d items, %d real respondents%s; person fit on %s.\n\n",
              length(x$settings$items), x$settings$n_real,
              if (x$settings$clean_real) " after removing careless ones" else "",
              if (length(x$settings$fit_scales)) paste(x$settings$fit_scales, collapse = ", ") else "no scales"))
  s <- as.data.frame(x$summary)
  s$lz_low <- 100 * s$lz_low; s$lz_high <- 100 * s$lz_high
  names(s) <- c("model", "attempts", "Behaviour", "Lowest", "Highest", "lz < P5 (%)", "lz > P95 (%)")
  num <- vapply(s, is.numeric, logical(1))
  s[num] <- lapply(s[num], round, digits)
  print(s, row.names = FALSE)
  cat("\nBehaviour is 100 when synthetic respondents spread over the real deciles of every feature.\n")
  invisible(x)
}

#' @exportS3Method generics::tidy
tidy.sc_behaviour <- function(x, ...) x$summary

#' @exportS3Method ggplot2::autoplot
autoplot.sc_behaviour <- function(object, ...) gg_behaviour(object, ...)

# ---- internal -------------------------------------------------------------

bh_names <- c("variability", "extreme", "midpoint", "acquiescence", "key_inconsistency",
              "even_odd", "mahalanobis", "person_fit")
bh_labels <- c(variability = "Variability", extreme = "Extreme", midpoint = "Midpoint",
               acquiescence = "Acquiescence", key_inconsistency = "Key\ninconsistency",
               even_odd = "Even-odd", mahalanobis = "Mahalanobis", person_fit = "Person\nfit")
sc_palette <- c("#c0302b", "#f0a09a", "#f0efec", "#86b6ef", "#1c5cab")

bh_items <- function(items, cols) {
  if (is.null(items) || !is.data.frame(items) || !"item" %in% names(items))
    stop("`items` must be a data frame with an `item` column (see hexaco_items).", call. = FALSE)
  items <- as.data.frame(items)
  scale <- if ("scale" %in% names(items)) items$scale else if ("trait" %in% names(items)) items$trait else
    stop("`items` needs a `scale` (or `trait`) column.", call. = FALSE)
  facet <- if ("facet" %in% names(items)) items$facet else scale
  facet[is.na(facet)] <- scale[is.na(facet)]
  reverse <- if ("reverse" %in% names(items)) as.logical(items$reverse) else rep(FALSE, nrow(items))
  reverse[is.na(reverse)] <- FALSE
  it <- data.frame(item = as.character(items$item), scale = as.character(scale),
                   facet = paste(scale, facet, sep = "::"), reverse = reverse,
                   stringsAsFactors = FALSE)
  it <- it[it$item %in% cols, , drop = FALSE]
  if (nrow(it) < 2L)
    stop("Fewer than two items of `items` are columns of the data. Check the item names.", call. = FALSE)
  rownames(it) <- NULL
  it
}

bh_matrix <- function(data, it) {
  X <- data[it$item]
  bad <- it$item[!vapply(X, is.numeric, logical(1))]
  if (length(bad))
    stop("Item columns must hold numeric answers; not numeric: ",
         paste(utils::head(bad, 5), collapse = ", "), ".", call. = FALSE)
  X <- as.matrix(X)
  storage.mode(X) <- "double"
  X
}

bh_key <- function(X, it, lo, hi) {
  if (any(it$reverse)) X[, it$reverse] <- (lo + hi) - X[, it$reverse]
  X
}

bh_reference <- function(real, it, fit_scales) {
  X <- bh_matrix(real, it)
  if (all(is.na(X))) stop("The reference data hold no answers.", call. = FALSE)
  lo <- min(X, na.rm = TRUE); hi <- max(X, na.rm = TRUE)
  K <- bh_key(X, it, lo, hi)
  fm <- bh_facet_means(K, it)
  ok <- stats::complete.cases(fm)
  if (sum(ok) < ncol(fm) + 2L)
    stop("Too few complete reference respondents for the facet covariance.", call. = FALSE)
  mu <- colMeans(fm[ok, , drop = FALSE])
  S <- stats::cov(fm[ok, , drop = FALSE])
  scales <- unique(it$scale)
  if (is.null(fit_scales)) fit_scales <- scales
  fit_scales <- as.character(fit_scales)
  if (length(setdiff(fit_scales, scales)))
    stop("`fit_scales` not found in `items`: ", paste(setdiff(fit_scales, scales), collapse = ", "),
         ".", call. = FALSE)
  pf <- lapply(fit_scales, function(s) bh_grm(K[, it$scale == s, drop = FALSE]))
  names(pf) <- fit_scales
  list(items = it, lo = lo, hi = hi, mid = (lo + hi) / 2, odd = ((hi - lo) %% 2) == 0,
       mu = mu, S = S, pf = pf, fit_scales = fit_scales)
}

bh_facet_means <- function(K, it) {
  fac <- unique(it$facet)
  fm <- vapply(fac, function(f) {
    sub <- K[, it$facet == f, drop = FALSE]
    v <- rowMeans(sub, na.rm = TRUE)
    v[is.nan(v)] <- NA_real_
    v
  }, numeric(nrow(K)))
  matrix(fm, nrow(K), dimnames = list(NULL, fac))
}

bh_grm <- function(K) {
  ncat <- apply(K, 2, function(v) length(unique(stats::na.omit(v))))
  K <- K[, ncat >= 2L, drop = FALSE]
  if (ncol(K) < 2L) stop("Person fit needs at least two items with two or more answer categories per scale.",
                         call. = FALSE)
  # mirt's notes on the last EM steps do not matter for person fit
  mod <- withCallingHandlers(
    mirt::mirt(as.data.frame(K), 1, itemtype = "graded", verbose = FALSE,
               technical = list(NCYCLES = 2000)),
    warning = function(w) if (grepl("og-likelihood", conditionMessage(w))) invokeRestart("muffleWarning"))
  grid <- seq(-5, 5, length.out = 81)
  tr <- lapply(seq_len(ncol(K)), function(j) {
    cats <- sort(unique(stats::na.omit(K[, j])))
    P <- mirt::probtrace(mirt::extract.item(mod, j), matrix(grid))
    if (ncol(P) != length(cats)) stop("Unexpected number of categories in the graded model.", call. = FALSE)
    lp <- log(pmax(P, 1e-300))
    e <- rowSums(P * lp)
    list(cats = cats, logP = lp, E = e, V = rowSums(P * lp^2) - e^2)
  })
  list(items = colnames(K), traces = tr, prior = stats::dnorm(grid, log = TRUE))
}

bh_lz <- function(K, g) {
  K <- K[, g$items, drop = FALSE]
  N <- nrow(K); G <- length(g$prior); J <- ncol(K)
  ll <- matrix(0, N, G)
  xs <- vector("list", J)
  n_ans <- numeric(N)
  for (j in seq_len(J)) {
    x <- match(K[, j], g$traces[[j]]$cats)
    xs[[j]] <- x
    ok <- !is.na(x)
    n_ans <- n_ans + ok
    if (any(ok)) ll[ok, ] <- ll[ok, ] + t(g$traces[[j]]$logP[, x[ok], drop = FALSE])
  }
  post <- ll + matrix(g$prior, N, G, byrow = TRUE)
  gi <- max.col(post, ties.method = "first")
  l0 <- numeric(N); E <- numeric(N); V <- numeric(N)
  for (j in seq_len(J)) {
    x <- xs[[j]]; ok <- !is.na(x)
    tr <- g$traces[[j]]
    l0[ok] <- l0[ok] + tr$logP[cbind(gi[ok], x[ok])]
    E[ok] <- E[ok] + tr$E[gi[ok]]
    V[ok] <- V[ok] + tr$V[gi[ok]]
  }
  lz <- (l0 - E) / sqrt(V)
  lz[n_ans < J / 2 | V <= 0] <- NA_real_
  lz
}

bh_rowcor <- function(A, B) {
  m <- !is.na(A) & !is.na(B)
  A[!m] <- NA; B[!m] <- NA
  n <- rowSums(m)
  ac <- A - rowMeans(A, na.rm = TRUE)
  bc <- B - rowMeans(B, na.rm = TRUE)
  num <- rowSums(ac * bc, na.rm = TRUE)
  den <- sqrt(rowSums(ac^2, na.rm = TRUE) * rowSums(bc^2, na.rm = TRUE))
  r <- num / den
  r[n < 3 | !is.finite(r)] <- NA_real_
  r
}

bh_features <- function(data, ref) {
  it <- ref$items
  X <- bh_matrix(as.data.frame(data), it)
  N <- nrow(X); J <- ncol(X)
  enough <- rowSums(!is.na(X)) >= J / 2
  K <- bh_key(X, it, ref$lo, ref$hi)
  na_out <- function(v) { v[!enough] <- NA_real_; v }

  variability <- na_out(apply(X, 1, stats::sd, na.rm = TRUE))
  extreme <- na_out(rowMeans(X == ref$lo | X == ref$hi, na.rm = TRUE))
  midpoint <- if (ref$odd) na_out(rowMeans(X == ref$mid, na.rm = TRUE)) else rep(NA_real_, N)
  acquiescence <- na_out(rowMeans(X, na.rm = TRUE) - ref$mid)

  # key inconsistency: facets with both positive and reverse-keyed items
  fac <- unique(it$facet)
  ki <- lapply(fac, function(f) {
    pos <- it$facet == f & !it$reverse; rev <- it$facet == f & it$reverse
    if (!any(pos) || !any(rev)) return(NULL)
    abs(rowMeans(K[, pos, drop = FALSE], na.rm = TRUE) - rowMeans(K[, rev, drop = FALSE], na.rm = TRUE))
  })
  ki <- ki[!vapply(ki, is.null, logical(1))]
  key_inconsistency <- if (length(ki)) {
    m <- do.call(cbind, ki); m[is.nan(m)] <- NA
    v <- rowMeans(m, na.rm = TRUE); v[is.nan(v)] <- NA; na_out(v)
  } else rep(NA_real_, N)

  # even-odd consistency: odd- and even-numbered items within each facet
  eo <- lapply(fac, function(f) {
    idx <- which(it$facet == f)
    if (length(idx) < 2L) return(NULL)
    o <- idx[seq(1, length(idx), by = 2)]; e <- idx[seq(2, length(idx), by = 2)]
    cbind(rowMeans(K[, o, drop = FALSE], na.rm = TRUE), rowMeans(K[, e, drop = FALSE], na.rm = TRUE))
  })
  eo <- eo[!vapply(eo, is.null, logical(1))]
  even_odd <- if (length(eo) >= 3L) {
    O <- vapply(eo, function(m) m[, 1], numeric(N)); E <- vapply(eo, function(m) m[, 2], numeric(N))
    O <- matrix(O, N); E <- matrix(E, N)
    O[is.nan(O)] <- NA; E[is.nan(E)] <- NA
    na_out(bh_rowcor(O, E))
  } else rep(NA_real_, N)

  # Mahalanobis distance of the keyed facet means
  fm <- bh_facet_means(K, it)
  mahalanobis <- bh_mahalanobis(fm, ref$mu, ref$S)
  mahalanobis <- na_out(mahalanobis)

  # person fit
  person_fit <- rep(NA_real_, N)
  if (length(ref$pf)) {
    lz <- vapply(ref$pf, function(g) bh_lz(K, g), numeric(N))
    lz <- matrix(lz, N)
    person_fit <- rowMeans(lz, na.rm = TRUE)
    person_fit[is.nan(person_fit)] <- NA_real_
  }

  data.frame(variability, extreme, midpoint, acquiescence, key_inconsistency, even_odd,
             mahalanobis, person_fit)
}

bh_inverse <- function(S) {
  out <- tryCatch(solve(S), error = function(e) NULL)
  if (is.null(out)) out <- solve(S + diag(1e-6 * mean(diag(S)), nrow(S)))
  out
}

bh_mahalanobis <- function(fm, mu, S) {
  N <- nrow(fm); out <- rep(NA_real_, N)
  ok <- stats::complete.cases(fm)
  if (any(ok)) out[ok] <- sqrt(stats::mahalanobis(fm[ok, , drop = FALSE], mu, bh_inverse(S), inverted = TRUE))
  for (i in which(!ok)) {
    have <- !is.na(fm[i, ])
    if (sum(have) < ncol(fm) / 2) next
    out[i] <- sqrt(stats::mahalanobis(fm[i, have], mu[have], bh_inverse(S[have, have, drop = FALSE]),
                                      inverted = TRUE))
  }
  out
}

# decile overlap of one feature: 100 * sum_d min(p_syn[d], 0.10)
bh_overlap <- function(syn, real) {
  syn <- syn[!is.na(syn)]; real <- real[!is.na(real)]
  if (length(syn) < 1L || length(real) < 10L) return(NA_real_)
  u <- sort(unique(c(syn, real)))
  eps <- if (length(u) > 1L) min(diff(u)) * 0.49 else 0.49
  rj <- real + stats::runif(length(real), 0, eps)
  sj <- syn + stats::runif(length(syn), 0, eps)
  cuts <- stats::quantile(rj, probs = seq(0.1, 0.9, by = 0.1), names = FALSE)
  p <- tabulate(findInterval(sj, cuts) + 1L, 10L) / length(sj)
  100 * sum(pmin(p, 0.1))
}

bh_compare <- function(fs, fr) {
  rows <- lapply(bh_names, function(f) {
    ms <- stats::median(fs[[f]], na.rm = TRUE); mr <- stats::median(fr[[f]], na.rm = TRUE)
    B <- bh_overlap(fs[[f]], fr[[f]])
    dir <- if (is.na(B) || is.na(ms) || is.na(mr)) NA_character_ else
      if (ms < mr) "lower" else if (ms > mr) "higher" else "same"
    data.frame(feature = f, B = B, median_synthetic = ms, median_real = mr, direction = dir,
               stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}

bh_index <- function(B) if (all(is.na(B))) NA_real_ else mean(B, na.rm = TRUE)

bh_tails <- function(lz_syn, lz_real) {
  lz_syn <- lz_syn[!is.na(lz_syn)]; lz_real <- lz_real[!is.na(lz_real)]
  if (!length(lz_syn) || length(lz_real) < 20L)
    return(data.frame(lz_low = NA_real_, lz_high = NA_real_))
  q <- stats::quantile(lz_real, c(0.05, 0.95), names = FALSE)
  data.frame(lz_low = mean(lz_syn < q[1]), lz_high = mean(lz_syn > q[2]))
}

bh_summary <- function(att) {
  rows <- lapply(unique(att$model), function(m) {
    a <- att[att$model == m, ]
    v <- a$behaviour
    data.frame(model = m, attempts = nrow(a), behaviour_overall = mean(v, na.rm = TRUE),
               behaviour_lowest = min(v, na.rm = TRUE), behaviour_highest = max(v, na.rm = TRUE),
               lz_low = mean(a$lz_low, na.rm = TRUE), lz_high = mean(a$lz_high, na.rm = TRUE),
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  out$lz_low[is.nan(out$lz_low)] <- NA; out$lz_high[is.nan(out$lz_high)] <- NA
  as_tbl(out)
}

careless_count <- function(f) {
  q <- function(v, p) stats::quantile(v, p, na.rm = TRUE, names = FALSE)
  hit <- function(v) { v[is.na(v)] <- FALSE; v }
  n <- integer(nrow(f))
  if (!all(is.na(f$variability)))
    n <- n + hit(f$variability < q(f$variability, 0.0125) | f$variability > q(f$variability, 0.9875))
  for (v in c("extreme", "midpoint", "acquiescence", "key_inconsistency", "mahalanobis"))
    if (!all(is.na(f[[v]]))) n <- n + hit(f[[v]] > q(f[[v]], 0.975))
  for (v in c("even_odd", "person_fit"))
    if (!all(is.na(f[[v]]))) n <- n + hit(f[[v]] < q(f[[v]], 0.025))
  as.integer(n)
}

# the real target: All respondents, or those left after removing careless ones
bh_prepare_real <- function(real, it, fit_scales, clean_real, careless_rule) {
  careless <- NULL
  if (isTRUE(clean_real)) {
    careless <- flag_careless(real[it$item], it, rule = careless_rule, fit_scales = fit_scales)
    real <- real[!careless$careless, , drop = FALSE]
    if (nrow(real) < 20L) stop("Fewer than 20 real respondents are left after removing careless ones.",
                               call. = FALSE)
  }
  ref <- bh_reference(real, it, fit_scales)
  list(real = real, ref = ref, features = bh_features(real, ref), careless = careless)
}
