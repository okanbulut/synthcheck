# Construct structure: Do the scales hold together and relate as they do in real people?

#' Construct structure of synthetic respondents
#'
#' `synthetic_construct()` checks the scales rather than
#' the items. Structure in [authenticity_benchmark()] averages over every
#' pair of items, so a model can score well there and still blur the traits
#' together or make every scale too coherent. Three checks, for each model
#' and attempt, against the real data:
#'
#' - **Trait correlations:** The keyed scale means are correlated, and
#'   `trait_cor_gap` is the mean absolute difference between the synthetic
#'   and the real correlations over all pairs of scales (needs two or more
#'   scales). The Artificial Societies Benchmark (Chidichimo et al., 2026)
#'   reports that language models often change how traits relate.
#' - **Reliability:** Cronbach's alpha of each scale on the keyed answers.
#'   `alpha_gap` is the synthetic minus the real alpha, averaged over scales.
#'   Above 0 means the items hang together more tightly than in real people,
#'   which is the "too coherent" pattern, not a better result
#'   (Lukauskas & Šarkauskaitė, 2026).
#' - **Loadings:** Each scale's one-factor loadings (first principal
#'   component of the item correlations, signed so that the loadings sum to
#'   a positive value) are compared with Tucker's congruence \eqn{\phi}.
#'   Because loadings of similar size give a high \eqn{\phi} by chance, each
#'   \eqn{\phi} is read against a permutation null: The synthetic loadings
#'   are shuffled over the items `n_perm` times, and `p` is
#'   \eqn{(k + 1) / (n_{perm} + 1)}, where \eqn{k} is the number of shuffled
#'   values at or above the observed one (Lukauskas & Šarkauskaitė, 2026).
#'   `phi_null` is the mean of the null, and `rejects` is the share of
#'   scales with `p < 0.05`.
#'
#' **Reference.** The same checks on `n_splits` random samples of real
#' people (of the median attempt size), each scored against the remaining
#' real people, show how large the gaps are from sampling noise alone. They
#' are the `"Real (second sample)"` rows of `reference`.
#'
#' These are diagnostics. They are not part of the benchmark score.
#'
#' @inheritParams synthetic_behaviour
#' @param n_perm number of permutations for the null of Tucker's \eqn{\phi}.
#' @param n_splits number of real samples for the reference.
#' @param seed random seed.
#' @return An object of class `sc_construct`: A list with `summary` (one row
#'   per model: `trait_cor_gap`, `alpha_gap`, `phi`, `phi_null`, `rejects`),
#'   `scales` (one row per model, attempt and scale: `alpha`, `alpha_real`,
#'   `alpha_gap`, `phi`, `phi_null`, `p`), `pairs` (one row per model,
#'   attempt and pair of scales: `cor`, `cor_real`, `difference`),
#'   `reference` (the same summary for samples of real people) and
#'   `settings`. It has `print()`, `tidy()` and `autoplot()` methods.
#' @references Chidichimo, E., Jung, M. J., Wallis, F. P. S., & He, J. K.
#'   (2026). Artificial Societies Benchmark: A validation framework for
#'   synthetic research. arXiv:2609.30030.
#'
#'   Lukauskas, M., & Šarkauskaitė, V. (2026). Plausible but not valid: A
#'   psychometric audit of LLMs as synthetic survey respondents.
#'   arXiv:2608.14606.
#'
#'   Tucker, L. R. (1951). A method for synthesis of factor analysis studies
#'   (Personnel Research Section Report No. 984). Department of the Army.
#' @seealso [gg_construct()], [authenticity_benchmark()]
#' @examples
#' h <- hexaco_items[hexaco_items$trait %in% c("H", "E", "X"), ]
#' real <- hexaco_real[hexaco_real$country == "Canada", ]
#' ca <- hexaco_llm[hexaco_llm$country == "Canada" & hexaco_llm$attempt <= 2, ]
#' syn <- lapply(split(ca, ca$model, drop = TRUE), function(m) split(m, m$attempt))
#' cs <- synthetic_construct(syn, real, h, n_perm = 50, n_splits = 5)
#' cs
#' gg_construct(cs)
#' @export
synthetic_construct <- function(synthetic, real, items, clean_real = FALSE, careless_rule = NULL,
                                n_perm = 200, n_splits = 20, seed = 1) {
  syn <- coverage_inputs(synthetic)
  real <- as.data.frame(real)
  cols <- Reduce(intersect, c(list(names(real)), lapply(unlist(syn, recursive = FALSE), names)))
  it <- bh_items(items, cols)
  if (isTRUE(clean_real)) {
    fl <- flag_careless(real[it$item], it, rule = careless_rule, fit_scales = character(0))
    real <- real[!fl$careless, , drop = FALSE]
  }
  Xr <- bh_matrix(real, it)
  lo <- min(Xr, na.rm = TRUE); hi <- max(Xr, na.rm = TRUE)
  Kr <- bh_key(Xr, it, lo, hi)
  ref <- cs_stats(Kr, it)
  sizes <- unlist(lapply(syn, function(m) vapply(m, nrow, integer(1))))
  m <- min(nrow(Kr), as.integer(stats::median(sizes)))

  with_seed(seed, {
    att <- list()
    for (mo in names(syn)) for (a in seq_along(syn[[mo]])) {
      K <- bh_key(bh_matrix(syn[[mo]][[a]], it), it, lo, hi)
      att[[length(att) + 1L]] <- cs_compare(cs_stats(K, it), ref, n_perm, mo, a)
    }
    if (2L * m > nrow(Kr)) m <- floor(nrow(Kr) / 2)
    rs <- lapply(seq_len(n_splits), function(b) {
      A <- sample.int(nrow(Kr), m)
      cs_compare(cs_stats(Kr[A, , drop = FALSE], it), cs_stats(Kr[-A, , drop = FALSE], it), n_perm,
                 "Real (second sample)", b)
    })
  })
  sc <- do.call(rbind, lapply(att, `[[`, "scales"))
  pr <- do.call(rbind, lapply(att, `[[`, "pairs"))
  summ <- cs_summary(sc, pr, names(syn))
  rsum <- cs_summary(do.call(rbind, lapply(rs, `[[`, "scales")),
                     do.call(rbind, lapply(rs, `[[`, "pairs")), "Real (second sample)")
  structure(list(summary = as_tbl(summ), scales = as_tbl(sc), pairs = as_tbl(pr),
                 reference = as_tbl(rsum),
                 real = list(alpha = ref$alpha, cor = ref$cor),
                 settings = list(items = it$item, scales = unique(it$scale), n_perm = n_perm,
                                 n_splits = n_splits, sample_n = m, n_real = nrow(Kr),
                                 clean_real = isTRUE(clean_real), seed = seed)),
            class = "sc_construct")
}

#' Draw the construct structure
#'
#' One row per model and one tile per scale (`what =
#' "alpha"`) or per pair of scales (`what = "cor"`), averaged over attempts.
#' Red means lower than in real people, blue means higher, pale means a
#' match. With `"alpha"`, the tile is the synthetic minus the real alpha and
#' the number is the synthetic alpha (the real alpha is in the column
#' label). With `"cor"`, the tile and the number are the synthetic minus the
#' real correlation between two scales.
#'
#' @param x a result of [synthetic_construct()].
#' @param what `"alpha"` or `"cor"`.
#' @param title,subtitle plot titles. `NULL` uses the defaults.
#' @return A ggplot object.
#' @seealso [synthetic_construct()]
#' @examples
#' # see synthetic_construct()
#' @export
gg_construct <- function(x, what = c("alpha", "cor"), title = NULL, subtitle = NULL) {
  if (!inherits(x, "sc_construct")) stop("`x` must be a result of synthetic_construct().", call. = FALSE)
  what <- match.arg(what)
  models <- x$summary$model
  if (what == "alpha") {
    s <- as.data.frame(x$scales)
    d <- stats::aggregate(cbind(alpha, alpha_gap) ~ model + scale, data = s, FUN = mean)
    lab <- stats::setNames(sprintf("%s\n(real %.2f)", names(x$real$alpha), x$real$alpha),
                           names(x$real$alpha))
    d$column <- factor(lab[d$scale], levels = lab)
    d$value <- d$alpha_gap
    d$text <- sprintf("%.2f", d$alpha)
    lim <- 0.3
    if (is.null(title)) title <- "Reliability of each scale"
    if (is.null(subtitle)) subtitle <- "Cronbach's alpha of synthetic respondents. Blue: More coherent than real people, red: Less."
    leg <- c("-0.3 or less", "0: Match", "+0.3 or more")
  } else {
    p <- as.data.frame(x$pairs)
    if (!nrow(p)) stop("`what = \"cor\"` needs two or more scales.", call. = FALSE)
    d <- stats::aggregate(difference ~ model + pair, data = p, FUN = mean)
    d$column <- factor(d$pair, levels = unique(p$pair))
    d$value <- d$difference
    d$text <- sprintf("%+.2f", d$difference)
    lim <- 0.5
    if (is.null(title)) title <- "Correlations between scales"
    if (is.null(subtitle)) subtitle <- "Synthetic minus real correlation. Blue: Traits relate more strongly than in real people, red: Less."
    leg <- c("-0.5 or less", "0: Match", "+0.5 or more")
  }
  d$fill <- pmax(-lim, pmin(lim, d$value))
  d$ink <- ifelse(abs(d$fill) > 0.75 * lim, "white", "grey15")
  d$model <- factor(d$model, levels = rev(models))
  ggplot2::ggplot(d, ggplot2::aes(x = .data$column, y = .data$model)) +
    ggplot2::geom_tile(ggplot2::aes(fill = .data$fill), colour = "white", linewidth = 1) +
    ggplot2::geom_text(ggplot2::aes(label = .data$text, colour = .data$ink), size = 3.5) +
    ggplot2::scale_colour_identity() +
    ggplot2::scale_fill_gradientn(colours = sc_palette, limits = c(-lim, lim),
                                  breaks = c(-lim, 0, lim), labels = leg, name = NULL) +
    ggplot2::scale_x_discrete(position = "top") +
    ggplot2::labs(x = NULL, y = NULL, title = title, subtitle = subtitle) +
    theme_synthcheck() +
    ggplot2::theme(panel.grid = ggplot2::element_blank(),
                   legend.key.width = ggplot2::unit(2.5, "lines"))
}

#' @export
print.sc_construct <- function(x, digits = 2, ...) {
  s <- x$settings
  cat("Construct structure\n")
  cat(sprintf("%d items in %d scales, %d real respondents.\n\n", length(s$items), length(s$scales),
              s$n_real))
  t <- rbind(as.data.frame(x$summary), as.data.frame(x$reference))
  num <- vapply(t, is.numeric, logical(1))
  t[num] <- lapply(t[num], round, digits)
  print(t, row.names = FALSE)
  cat("\ntrait_cor_gap: Mean |difference| of the correlations between scales.",
      "\nalpha_gap: Synthetic minus real alpha (above 0 = too coherent).",
      "\nphi: Tucker's congruence of the loadings; phi_null: Its value by chance;",
      "rejects: Share of scales with phi above chance (p < 0.05).\n")
  invisible(x)
}

#' @exportS3Method generics::tidy
tidy.sc_construct <- function(x, ...) x$summary

#' @exportS3Method ggplot2::autoplot
autoplot.sc_construct <- function(object, ...) gg_construct(object, ...)

# ---- internal -------------------------------------------------------------

cs_stats <- function(K, it) {
  scales <- unique(it$scale)
  alpha <- load <- list()
  for (s in scales) {
    sub <- K[, it$scale == s, drop = FALSE]
    C <- suppressWarnings(stats::cov(sub, use = "pairwise.complete.obs"))
    k <- ncol(sub)
    alpha[[s]] <- if (k < 2L || anyNA(C) || sum(C) <= 0) NA_real_ else
      (k / (k - 1)) * (1 - sum(diag(C)) / sum(C))
    load[[s]] <- cs_loadings(suppressWarnings(stats::cor(sub, use = "pairwise.complete.obs")))
  }
  sm <- vapply(scales, function(s) bm_scale_score(K, it$scale == s), numeric(nrow(K)))
  sm <- matrix(sm, nrow(K), dimnames = list(NULL, scales))
  list(alpha = unlist(alpha), load = load,
       cor = suppressWarnings(stats::cor(sm, use = "pairwise.complete.obs")))
}

# first principal component loadings of a correlation matrix; items with no
# variance get NA
cs_loadings <- function(R) {
  ok <- !is.na(diag(R))
  out <- stats::setNames(rep(NA_real_, nrow(R)), rownames(R))
  if (sum(ok) < 2L) return(out)
  R <- R[ok, ok, drop = FALSE]
  R[is.na(R)] <- 0
  e <- eigen(R, symmetric = TRUE)
  l <- e$vectors[, 1] * sqrt(max(e$values[1], 0))
  if (sum(l) < 0) l <- -l
  out[ok] <- l
  out
}

cs_phi <- function(a, b) {
  ok <- !is.na(a) & !is.na(b)
  if (sum(ok) < 2L) return(NA_real_)
  a <- a[ok]; b <- b[ok]
  den <- sqrt(sum(a^2) * sum(b^2))
  if (den <= 0) NA_real_ else sum(a * b) / den
}

cs_compare <- function(st, ref, n_perm, model, attempt) {
  scales <- names(ref$alpha)
  sc <- do.call(rbind, lapply(scales, function(s) {
    a <- st$load[[s]]; b <- ref$load[[s]]
    phi <- cs_phi(a, b)
    null <- if (is.na(phi) || n_perm < 1) NA_real_ else
      vapply(seq_len(n_perm), function(i) cs_phi(sample(a), b), numeric(1))
    data.frame(model = model, attempt = attempt, scale = s, alpha = st$alpha[[s]],
               alpha_real = ref$alpha[[s]], alpha_gap = st$alpha[[s]] - ref$alpha[[s]],
               phi = phi, phi_null = mean(null, na.rm = TRUE),
               p = if (is.na(phi) || n_perm < 1) NA_real_ else (sum(null >= phi - 1e-12) + 1) / (n_perm + 1),
               stringsAsFactors = FALSE)
  }))
  pr <- NULL
  if (length(scales) > 1L) {
    up <- which(upper.tri(ref$cor), arr.ind = TRUE)
    pr <- data.frame(model = model, attempt = attempt,
                     pair = paste(scales[up[, 1]], scales[up[, 2]], sep = "-"),
                     cor = st$cor[up], cor_real = ref$cor[up], stringsAsFactors = FALSE)
    pr$difference <- pr$cor - pr$cor_real
  }
  list(scales = sc, pairs = pr)
}

cs_summary <- function(sc, pr, models) {
  do.call(rbind, lapply(models, function(mo) {
    s <- sc[sc$model == mo, , drop = FALSE]
    p <- if (is.null(pr)) NULL else pr[pr$model == mo, , drop = FALSE]
    data.frame(model = mo, attempts = length(unique(s$attempt)),
               trait_cor_gap = if (is.null(p) || !nrow(p)) NA_real_ else mean(abs(p$difference), na.rm = TRUE),
               alpha_gap = mean(s$alpha_gap, na.rm = TRUE), phi = mean(s$phi, na.rm = TRUE),
               phi_null = mean(s$phi_null, na.rm = TRUE), rejects = mean(s$p < 0.05, na.rm = TRUE),
               stringsAsFactors = FALSE)
  }))
}
