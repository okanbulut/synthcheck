# Persona check: Do personas change the answers, and in the intended direction?

#' Check whether personas change synthetic answers
#'
#' `persona_fidelity()` asks whether the personas given to a language model
#' change its answers, which a persona-based run takes for granted. It scores
#' every synthetic respondent on each scale of the instrument (the keyed mean
#' of its items) and answers two questions per model:
#'
#' 1. **Do personas separate respondents?** The share of the variance of each
#'    scale score that lies between personas (eta squared). It is compared
#'    with the same data after shuffling the persona labels `n_perm` times:
#'    `null` is the 95th percentile of eta squared without any persona
#'    effect, and `p` the share of shuffles that reach the observed value. A
#'    model that ignores its personas has eta squared near `null`.
#' 2. **Do they move in the intended direction?** Only when the persona table
#'    holds targets: One column `target_<scale>` per scale, with the
#'    standardized score the persona should have (for example 1 for "high",
#'    0 for "average", -1 for "low"; `NA` for no target). Each persona's mean
#'    standardized scale scores are compared with its targets: `r` is their
#'    correlation across scales (needs three or more targets), `gap` the mean
#'    absolute difference, and `agree` the share of targets whose sign the
#'    persona matches.
#'
#' Scale scores are standardized with the mean and standard deviation of the
#' real data when `real` is given, so a target of 1 means one standard
#' deviation above real people. Without `real`, each model's own respondents
#' are the reference, so targets compare personas with each other.
#'
#' The check shows whether a model follows its personas. It does not show
#' that the persona's answers resemble those of real people like the
#' persona. For that, benchmark the run against real data (see
#' [authenticity_benchmark()]).
#'
#' @param synthetic the synthetic responses: A data frame with a `model`
#'   column, a persona column and one column per item, as returned by
#'   [generate_synthetic()].
#' @param instrument an [sc_instrument()] whose items have a `scale` column,
#'   or an item table such as [hexaco_items] (then `scale` gives the
#'   response range).
#' @param personas optional [sc_personas()] table with `target_<scale>`
#'   columns (see Details).
#' @param real optional data frame of real responses, used to standardize
#'   the scale scores.
#' @param persona name of the persona column in `synthetic`.
#' @param scale the lowest and highest response category, needed only when
#'   `instrument` is an item table.
#' @param n_perm number of label shuffles for the null distribution.
#' @param seed random seed for the shuffles.
#' @return An object of class `sc_fidelity`: A list with `separation` (one
#'   row per model and scale: `eta2`, `null`, `p`, `separated`), `direction`
#'   (one row per model and persona, when there are targets: `n`, `r`,
#'   `gap`, `agree`), `profiles` (mean standardized score and target per
#'   model, persona and scale), `scores` (per respondent) and `settings`. It
#'   has `print()`, `tidy()` and `autoplot()` methods.
#' @seealso [gg_persona_fidelity()], [sc_personas()], [generate_synthetic()]
#' @examples
#' # Personas that should differ in Conscientiousness, answered by the mock
#' # provider, which ignores personas: The check finds no separation.
#' ins <- sc_instrument(hexaco_items[hexaco_items$trait %in% c("C", "X", "E"), ],
#'                      scale = c(1, 7))
#' per <- sc_personas(data.frame(
#'   description = c("You plan everything and never miss a deadline.",
#'                   "You act on impulse and leave tasks unfinished."),
#'   target_C = c(1, -1)))
#' syn <- generate_synthetic(ins, sc_model("mock"), per, respondents = 10,
#'                           progress = FALSE, cache = FALSE)
#' fid <- persona_fidelity(syn, ins, per, n_perm = 50)
#' fid
#' gg_persona_fidelity(fid)
#' @export
persona_fidelity <- function(synthetic, instrument, personas = NULL, real = NULL,
                             persona = "persona_id", scale = NULL, n_perm = 200, seed = 1) {
  syn <- as.data.frame(synthetic)
  if (!persona %in% names(syn))
    stop("`synthetic` has no column `", persona, "`. Name the persona column with `persona`.",
         call. = FALSE)
  if (!"model" %in% names(syn)) syn$model <- "model"
  if (inherits(instrument, "sc_instrument")) {
    items <- as.data.frame(instrument$items)
    lo <- instrument$min; hi <- instrument$max
  } else {
    items <- as.data.frame(instrument)
    if (is.null(scale) || length(scale) != 2L)
      stop("Give `scale`, the lowest and highest category, when `instrument` is an item table.",
           call. = FALSE)
    lo <- scale[1]; hi <- scale[2]
  }
  it <- bh_items(items, names(syn))
  scales <- unique(it$scale)
  syn <- syn[!is.na(syn[[persona]]), , drop = FALSE]
  if (length(unique(syn[[persona]])) < 2L)
    stop("The persona check needs at least two personas.", call. = FALSE)
  n_perm <- as.integer(n_perm)
  if (n_perm < 10L) stop("`n_perm` must be at least 10.", call. = FALSE)

  S <- fid_scores(syn, it, lo, hi)
  if (!is.null(real)) {
    R <- fid_scores(as.data.frame(real), bh_items(items, names(real)), lo, hi)
    ref <- list(mu = colMeans(R, na.rm = TRUE), sd = apply(R, 2, stats::sd, na.rm = TRUE))
  }
  Z <- S
  for (mo in unique(syn$model)) {
    rows <- syn$model == mo
    mu <- if (is.null(real)) colMeans(S[rows, , drop = FALSE], na.rm = TRUE) else ref$mu[scales]
    sdv <- if (is.null(real)) apply(S[rows, , drop = FALSE], 2, stats::sd, na.rm = TRUE) else ref$sd[scales]
    sdv[!is.finite(sdv) | sdv == 0] <- NA_real_
    Z[rows, ] <- sweep(sweep(S[rows, , drop = FALSE], 2, mu), 2, sdv, "/")
  }

  sep <- with_seed(seed, do.call(rbind, lapply(unique(syn$model), function(mo) {
    rows <- syn$model == mo
    g <- as.character(syn[[persona]][rows])
    do.call(rbind, lapply(scales, function(s) {
      y <- S[rows, s]
      ok <- !is.na(y)
      e <- fid_eta2(y[ok], g[ok])
      null <- vapply(seq_len(n_perm), function(b) fid_eta2(y[ok], sample(g[ok])), numeric(1))
      data.frame(model = mo, scale = s, eta2 = e, null = unname(stats::quantile(null, 0.95, na.rm = TRUE)),
                 p = (1 + sum(null >= e, na.rm = TRUE)) / (1 + sum(!is.na(null))),
                 stringsAsFactors = FALSE)
    }))
  })))
  sep$separated <- !is.na(sep$eta2) & sep$p < 0.05

  targets <- fid_targets(personas, scales)
  prof <- do.call(rbind, lapply(unique(syn$model), function(mo) {
    rows <- syn$model == mo
    g <- as.character(syn[[persona]][rows])
    do.call(rbind, lapply(sort(unique(g)), function(p) {
      z <- colMeans(Z[rows, , drop = FALSE][g == p, , drop = FALSE], na.rm = TRUE)
      tg <- if (is.null(targets) || !p %in% rownames(targets)) rep(NA_real_, length(scales)) else
        unname(targets[p, scales])
      data.frame(model = mo, persona = p, scale = scales, n = sum(g == p), z = unname(z[scales]),
                 target = tg, stringsAsFactors = FALSE)
    }))
  }))
  dirn <- NULL
  if (any(!is.na(prof$target))) {
    keys <- unique(prof[c("model", "persona")])
    dirn <- do.call(rbind, lapply(seq_len(nrow(keys)), function(i) {
      d <- prof[prof$model == keys$model[i] & prof$persona == keys$persona[i] &
                  !is.na(prof$target) & !is.na(prof$z), , drop = FALSE]
      if (!nrow(d)) return(NULL)
      r <- if (nrow(d) >= 3L && stats::sd(d$target) > 0 && stats::sd(d$z) > 0)
        stats::cor(d$target, d$z) else NA_real_
      signed <- d$target != 0
      data.frame(model = keys$model[i], persona = keys$persona[i], n = d$n[1], targets = nrow(d),
                 r = r, gap = mean(abs(d$z - d$target)),
                 agree = if (any(signed)) mean(sign(d$z[signed]) == sign(d$target[signed])) else NA_real_,
                 stringsAsFactors = FALSE)
    }))
  }

  sc <- data.frame(syn["model"], persona = as.character(syn[[persona]]), Z, check.names = FALSE,
                   stringsAsFactors = FALSE)
  structure(list(
    separation = as_tbl(sep), direction = if (is.null(dirn)) NULL else as_tbl(dirn),
    profiles = as_tbl(prof), scores = as_tbl(sc),
    settings = list(scales = scales, standardized = if (is.null(real)) "synthetic" else "real",
                    n_perm = n_perm, persona = persona, seed = seed)),
    class = "sc_fidelity")
}

#' Draw the persona check
#'
#' One panel per model, one row per persona and one tile per scale. The
#' tile colour is the persona's mean standardized score: Red is lower than
#' the reference, pale about the same, blue higher. The number is the mean;
#' when the persona has a target for that scale, the target follows in
#' brackets. Scales whose scores do not differ between personas more than
#' shuffled labels do are marked "n.s." under their name.
#'
#' @param x a result of [persona_fidelity()].
#' @param title,subtitle plot titles. `NULL` uses the defaults.
#' @return A ggplot object.
#' @seealso [persona_fidelity()]
#' @examples
#' # see persona_fidelity()
#' @export
gg_persona_fidelity <- function(x, title = NULL, subtitle = NULL) {
  if (!inherits(x, "sc_fidelity")) stop("`x` must be a result of persona_fidelity().", call. = FALSE)
  d <- as.data.frame(x$profiles)
  sep <- as.data.frame(x$separation)
  scales <- x$settings$scales
  lab <- vapply(scales, function(s) {
    ns <- all(!sep$separated[sep$scale == s])
    if (ns) paste0(s, "\nn.s.") else s
  }, character(1))
  d$column <- factor(lab[match(d$scale, scales)], levels = lab)
  d$persona <- factor(d$persona, levels = rev(sort(unique(d$persona))))
  d$fill <- pmax(-1.5, pmin(1.5, d$z))
  d$text <- ifelse(is.na(d$z), "", ifelse(is.na(d$target), sprintf("%.1f", d$z),
                                         sprintf("%.1f (%+.0f)", d$z, d$target)))
  d$text <- gsub("-0.0", "0.0", d$text, fixed = TRUE)
  ref <- if (x$settings$standardized == "real") "real people" else "the model's respondents"
  if (is.null(title)) title <- "Do personas change the answers?"
  if (is.null(subtitle))
    subtitle <- paste0("Mean standardized score per persona, target in brackets.\n0 = the mean of ", ref,
                       ".\nn.s.: The personas differ no more than with shuffled labels.")
  p <- ggplot2::ggplot(d, ggplot2::aes(x = .data$column, y = .data$persona)) +
    ggplot2::geom_tile(ggplot2::aes(fill = .data$fill), colour = "white", linewidth = 1) +
    ggplot2::geom_text(ggplot2::aes(label = .data$text), size = 3.6, colour = "grey15") +
    ggplot2::scale_fill_gradientn(colours = sc_palette, limits = c(-1.5, 1.5), breaks = c(-1.5, 0, 1.5),
                                  labels = c("Lower", "Same", "Higher"), name = NULL,
                                  na.value = "grey90") +
    ggplot2::scale_x_discrete(position = "top") +
    ggplot2::labs(x = NULL, y = NULL, title = title, subtitle = subtitle) +
    theme_synthcheck() +
    ggplot2::theme(panel.grid = ggplot2::element_blank(),
                   legend.key.width = ggplot2::unit(2.5, "lines"))
  if (length(unique(d$model)) > 1L) p <- p + ggplot2::facet_wrap(~model)
  p
}

#' @export
print.sc_fidelity <- function(x, digits = 2, ...) {
  s <- x$settings
  sep <- as.data.frame(x$separation)
  cat("Persona check\n")
  cat(sprintf("%d scale%s; scores standardized against %s; %d label shuffles.\n\n",
              length(s$scales), if (length(s$scales) == 1L) "" else "s",
              if (s$standardized == "real") "real people" else "each model's own respondents",
              s$n_perm))
  cat("Do personas separate respondents? (eta squared, against shuffled labels)\n")
  t <- sep[c("model", "scale", "eta2", "null", "p", "separated")]
  t[c("eta2", "null", "p")] <- lapply(t[c("eta2", "null", "p")], round, digits)
  print(t, row.names = FALSE)
  if (!is.null(x$direction)) {
    cat("\nDo they move in the intended direction?\n")
    d <- as.data.frame(x$direction)
    d[c("r", "gap", "agree")] <- lapply(d[c("r", "gap", "agree")], round, digits)
    print(d, row.names = FALSE)
  }
  cat("\n", fid_sentence(x), "\n", sep = "")
  invisible(x)
}

#' @exportS3Method generics::tidy
tidy.sc_fidelity <- function(x, ...) x$separation

#' @exportS3Method ggplot2::autoplot
autoplot.sc_fidelity <- function(object, ...) gg_persona_fidelity(object, ...)

# ---- internal -------------------------------------------------------------

fid_scores <- function(data, it, lo, hi) {
  K <- bh_key(bh_matrix(data, it), it, lo, hi)
  scales <- unique(it$scale)
  out <- vapply(scales, function(s) bm_scale_score(K, it$scale == s), numeric(nrow(K)))
  if (!is.matrix(out)) out <- matrix(out, ncol = length(scales))
  colnames(out) <- scales
  out
}

fid_eta2 <- function(y, g) {
  if (length(y) < 3L) return(NA_real_)
  tot <- sum((y - mean(y))^2)
  if (tot <= 0) return(0)
  m <- tapply(y, g, mean)
  n <- tapply(y, g, length)
  sum(n * (m - mean(y))^2) / tot
}

fid_targets <- function(personas, scales) {
  if (is.null(personas)) return(NULL)
  p <- as.data.frame(personas)
  if (!"persona_id" %in% names(p)) return(NULL)
  cols <- paste0("target_", scales)
  have <- cols %in% names(p)
  if (!any(have)) return(NULL)
  m <- matrix(NA_real_, nrow(p), length(scales), dimnames = list(as.character(p$persona_id), scales))
  for (j in which(have)) m[, j] <- suppressWarnings(as.numeric(p[[cols[j]]]))
  m
}

fid_sentence <- function(x) {
  sep <- as.data.frame(x$separation)
  out <- vapply(unique(sep$model), function(mo) {
    s <- sep[sep$model == mo, ]
    k <- sum(s$separated)
    txt <- if (k == 0) {
      sprintf("%s: Personas do not change the scale scores more than shuffled labels do.", mo)
    } else {
      sprintf("%s: Personas separate respondents on %d of %d scales (largest eta squared %.2f, %s).",
              mo, k, nrow(s), max(s$eta2, na.rm = TRUE), s$scale[which.max(s$eta2)])
    }
    if (!is.null(x$direction)) {
      d <- as.data.frame(x$direction)
      d <- d[d$model == mo, ]
      if (nrow(d) && any(!is.na(d$agree)))
        txt <- paste(txt, sprintf("The personas match the sign of %.0f%% of their targets.",
                                  100 * mean(d$agree, na.rm = TRUE)))
    }
    txt
  }, character(1))
  paste(out, collapse = "\n")
}
