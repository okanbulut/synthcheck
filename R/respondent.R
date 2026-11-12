# Respondent coverage: Does every real person have a synthetic look-alike?

#' Respondent coverage of synthetic respondents
#'
#' **Experimental.** `respondent_coverage()` compares whole answer profiles.
#' Overlap and Structure in [authenticity_benchmark()] look at scale scores
#' and item pairs, so a model can match both while its respondents give
#' combinations of answers that no real person gives, or crowd around a few
#' kinds of people. Following Kumagae and Kaneko (2026), each respondent is
#' a point (the keyed answers to all items) and two ratios use the
#' distance to the nearest neighbour:
#'
#' - **RCG** (respondent coverage gap): The 95th percentile, over real
#'   people, of the distance from a real person to the nearest synthetic
#'   respondent, divided by the same percentile of the distance from a real
#'   person to the nearest other real person. Above 1 means some real people
#'   have no synthetic look-alike.
#' - **OSR** (off-support ratio): The 95th percentile, over synthetic
#'   respondents, of the distance to the nearest real person, divided by the
#'   same real-to-real percentile. Above 1 means some synthetic respondents
#'   sit outside the real data.
#'
#' Both are near 1 for a second sample of real people. Their combination
#' gives the `pattern` of each model: `"Human-like"` (RCG at most
#' `1 + tol`), `"Off-support"` (RCG and OSR above `1 + tol`: Synthetic
#' respondents lie away from real ones) and `"Contraction"` (RCG above
#' `1 + tol`, OSR not: Synthetic respondents stay close to some real people
#' and leave the others uncovered).
#'
#' **Samples.** Nearest-neighbour distances shrink as a sample grows, so
#' each synthetic attempt is compared with a random sample of real people of
#' the same size (`n_draws` samples, averaged). Distances are Euclidean on
#' the keyed answers. A missing answer is replaced by the real item mean.
#'
#' **Reference.** `reference` holds the same ratios for a second sample of
#' real people (near 1) and for shuffled real columns (each item drawn
#' independently, as the floor of [authenticity_benchmark()]), both of the
#' median attempt size.
#'
#' This is a diagnostic. It is not part of the benchmark score.
#'
#' @inheritParams synthetic_behaviour
#' @param n_draws number of real samples per attempt.
#' @param tol tolerance for `pattern` (see Details).
#' @param seed random seed.
#' @return An object of class `sc_respondent`: A list with `summary` (one row
#'   per model: `rcg`, `osr`, their lowest and highest values over attempts,
#'   and `pattern`), `attempts` (one row per attempt), `reference` and
#'   `settings`. It has `print()`, `tidy()` and `autoplot()` methods.
#' @references Kumagae, Y., & Kaneko, M. (2026). Silicon samples match the
#'   answers but not the respondents. arXiv:2610.30900.
#' @seealso [gg_respondent_coverage()], [authenticity_benchmark()]
#' @examples
#' real <- hexaco_real[hexaco_real$country == "Canada", ]
#' ca <- hexaco_llm[hexaco_llm$country == "Canada" & hexaco_llm$attempt <= 2, ]
#' syn <- lapply(split(ca, ca$model, drop = TRUE), function(m) split(m, m$attempt))
#' rc <- respondent_coverage(syn, real, hexaco_items, n_draws = 2)
#' rc
#' gg_respondent_coverage(rc)
#' @export
respondent_coverage <- function(synthetic, real, items, clean_real = FALSE, careless_rule = NULL,
                                n_draws = 5, tol = 0.1, seed = 1) {
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
  mu <- colMeans(Kr, na.rm = TRUE)
  Kr <- rc_fill(Kr, mu)
  n_real <- nrow(Kr)
  sizes <- unlist(lapply(syn, function(m) vapply(m, nrow, integer(1))))
  m_ref <- min(floor(n_real / 2), as.integer(stats::median(sizes)))

  with_seed(seed, {
    att <- list()
    for (mo in names(syn)) for (a in seq_along(syn[[mo]])) {
      G <- rc_fill(bh_key(bh_matrix(syn[[mo]][[a]], it), it, lo, hi), mu)
      G <- G[rowSums(is.na(G)) == 0, , drop = FALSE]
      n <- min(nrow(G), n_real - 1L)
      if (nrow(G) > n) G <- G[sample.int(nrow(G), n), , drop = FALSE]
      v <- rowMeans(vapply(seq_len(n_draws), function(b)
        rc_ratios(Kr[sample.int(n_real, n), , drop = FALSE], G), numeric(2)))
      att[[length(att) + 1L]] <- data.frame(model = mo, attempt = a, n = n, rcg = v[1], osr = v[2],
                                            stringsAsFactors = FALSE)
    }
    ref_real <- rowMeans(vapply(seq_len(n_draws), function(b) {
      s <- sample.int(n_real, 2L * m_ref)
      rc_ratios(Kr[s[seq_len(m_ref)], , drop = FALSE], Kr[s[m_ref + seq_len(m_ref)], , drop = FALSE])
    }, numeric(2)))
    ref_shuf <- rowMeans(vapply(seq_len(n_draws), function(b) {
      S <- vapply(seq_len(ncol(Kr)), function(j) Kr[sample.int(n_real, m_ref, replace = TRUE), j],
                  numeric(m_ref))
      rc_ratios(Kr[sample.int(n_real, m_ref), , drop = FALSE], matrix(S, m_ref))
    }, numeric(2)))
  })
  att <- do.call(rbind, att)
  summ <- do.call(rbind, lapply(names(syn), function(mo) {
    a <- att[att$model == mo, , drop = FALSE]
    data.frame(model = mo, attempts = nrow(a), rcg = mean(a$rcg), osr = mean(a$osr),
               rcg_lowest = min(a$rcg), rcg_highest = max(a$rcg),
               osr_lowest = min(a$osr), osr_highest = max(a$osr), stringsAsFactors = FALSE)
  }))
  summ$pattern <- rc_pattern(summ$rcg, summ$osr, tol)
  summ <- summ[order(summ$rcg, summ$model), , drop = FALSE]
  ref <- data.frame(model = c("Real (second sample)", "Shuffled columns"),
                    rcg = c(ref_real[1], ref_shuf[1]), osr = c(ref_real[2], ref_shuf[2]),
                    stringsAsFactors = FALSE)
  ref$pattern <- rc_pattern(ref$rcg, ref$osr, tol)
  structure(list(summary = as_tbl(summ), attempts = as_tbl(att), reference = as_tbl(ref),
                 settings = list(items = it$item, n_real = n_real, n_draws = n_draws, tol = tol,
                                 sample_n = m_ref, clean_real = isTRUE(clean_real), seed = seed)),
            class = "sc_respondent")
}

#' Draw the respondent coverage
#'
#' **Experimental.** One point per model at its RCG (across) and OSR (up),
#' with the second sample of real people and the shuffled real columns as
#' grey references. Real-like models sit near the bottom left corner (both
#' ratios near 1). Far to the right and up means off-support, far to the
#' right but low means contraction (see [respondent_coverage()]).
#'
#' @param x a result of [respondent_coverage()].
#' @param title,subtitle plot titles. `NULL` uses the defaults.
#' @return A ggplot object.
#' @seealso [respondent_coverage()]
#' @examples
#' # see respondent_coverage()
#' @export
gg_respondent_coverage <- function(x, title = NULL, subtitle = NULL) {
  if (!inherits(x, "sc_respondent")) stop("`x` must be a result of respondent_coverage().", call. = FALSE)
  s <- as.data.frame(x$summary)
  r <- as.data.frame(x$reference)
  d <- rbind(data.frame(model = s$model, rcg = s$rcg, osr = s$osr, kind = "model"),
             data.frame(model = r$model, rcg = r$rcg, osr = r$osr, kind = "reference"))
  d$colour <- ifelse(d$kind == "model", sc_palette[5], "grey55")
  d$label_y <- rc_spread(d$rcg, d$osr)
  if (is.null(title)) title <- "Respondent coverage"
  if (is.null(subtitle))
    subtitle <- paste0("RCG above 1: Some real people have no synthetic look-alike.\n",
                       "OSR above 1: Some synthetic respondents sit outside the real data.")
  rng <- range(c(1, d$rcg, d$osr), na.rm = TRUE)
  ggplot2::ggplot(d, ggplot2::aes(x = .data$rcg, y = .data$osr)) +
    ggplot2::geom_hline(yintercept = 1, colour = "grey75", linetype = "dashed") +
    ggplot2::geom_vline(xintercept = 1, colour = "grey75", linetype = "dashed") +
    ggplot2::geom_point(ggplot2::aes(colour = .data$colour), size = 3) +
    ggplot2::geom_text(ggplot2::aes(y = .data$label_y, label = .data$model, colour = .data$colour),
                       size = 3.3, hjust = -0.12, vjust = 0.4) +
    ggplot2::scale_colour_identity() +
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = c(0.05, 0.35))) +
    ggplot2::coord_cartesian(xlim = c(min(rng[1], 0.9), rng[2]), ylim = c(min(rng[1], 0.9), rng[2])) +
    ggplot2::labs(x = "RCG (real people left uncovered)", y = "OSR (synthetic respondents off the real data)",
                  title = title, subtitle = subtitle) +
    theme_synthcheck()
}

#' @export
print.sc_respondent <- function(x, digits = 2, ...) {
  s <- x$settings
  cat("Respondent coverage (experimental)\n")
  cat(sprintf("%d items, %d real respondents, %d real samples per attempt.\n\n", length(s$items),
              s$n_real, s$n_draws))
  t <- rbind(as.data.frame(x$summary)[c("model", "rcg", "osr", "pattern")],
             as.data.frame(x$reference)[c("model", "rcg", "osr", "pattern")])
  t$rcg <- round(t$rcg, digits); t$osr <- round(t$osr, digits)
  names(t) <- c("model", "RCG", "OSR", "pattern")
  print(t, row.names = FALSE)
  cat("\nBoth ratios are near 1 for a second sample of real people.\n")
  invisible(x)
}

#' @exportS3Method generics::tidy
tidy.sc_respondent <- function(x, ...) x$summary

#' @exportS3Method ggplot2::autoplot
autoplot.sc_respondent <- function(object, ...) gg_respondent_coverage(object, ...)

# ---- internal -------------------------------------------------------------

rc_fill <- function(K, mu) {
  miss <- which(is.na(K), arr.ind = TRUE)
  if (nrow(miss)) K[miss] <- mu[miss[, 2]]
  K
}

# nearest-neighbour distance from each row of A to the rows of B
rc_nn <- function(A, B, self = FALSE) {
  D <- outer(rowSums(A^2), rowSums(B^2), `+`) - 2 * tcrossprod(A, B)
  D[D < 0] <- 0
  if (self) diag(D) <- Inf
  sqrt(apply(D, 1, min))
}

rc_ratios <- function(H, G) {
  q <- function(v) stats::quantile(v, 0.95, names = FALSE)
  hh <- q(rc_nn(H, H, self = TRUE))
  if (hh <= 0) return(c(NA_real_, NA_real_))
  c(q(rc_nn(H, G)) / hh, q(rc_nn(G, H)) / hh)
}

# move labels of nearby points apart vertically so that none is hidden
rc_spread <- function(x, y) {
  ok <- !is.na(x) & !is.na(y)
  if (sum(ok) < 2L) return(y)
  rx <- diff(range(c(1, x[ok]))); ry <- diff(range(c(1, y[ok])))
  gap <- 0.045 * max(ry, 0.2)
  out <- y
  o <- which(ok)[order(y[ok])]
  for (i in seq_along(o)[-1]) for (j in seq_len(i - 1L)) {
    a <- o[i]; b <- o[j]
    if (abs(x[a] - x[b]) < 0.25 * max(rx, 0.2) && out[a] - out[b] < gap) out[a] <- out[b] + gap
  }
  out
}

rc_pattern <- function(rcg, osr, tol) {
  ifelse(is.na(rcg), NA_character_,
         ifelse(rcg <= 1 + tol, "Human-like", ifelse(osr > 1 + tol, "Off-support", "Contraction")))
}
