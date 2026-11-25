# Steps for the item-revision loop that call a language model (the item
# writer and the reviser) or fit IRT models (the evaluator).

#' A language-model item writer for the item-revision loop
#'
#' `loop_writer_llm()` makes the `writer` step of [revision_loop()]: One call
#' asks a language model to write `n_per_scale` Likert items for every scale
#' of the [loop_construct()], with about `reverse_share` of them
#' reverse-keyed, and to explain its choices in a short note (logged as
#' `writer_reasoning` in the `runs` table). Items are named after their
#' scale (`sincerity01`, `sincerity02`, ...).
#'
#' With `sc_model("mock")`, no model is called: The items are placeholders,
#' which is enough to try the loop.
#'
#' @param model an [sc_model()] for the item writer. Use a different model
#'   family from the respondents to avoid items that are only easy for one
#'   family to agree with.
#' @param guidelines item-writing guidelines added to the system prompt.
#' @return A function for the `writer` argument of [revision_loop()].
#' @seealso [revision_loop()], [loop_reviser_llm()]
#' @examples
#' w <- loop_writer_llm(sc_model("mock"))
#' w(loop_construct("Grit", "Perseverance and passion for long-term goals.",
#'                  n_per_scale = 3), list())$items
#' @export
loop_writer_llm <- function(model, guidelines = lp_guidelines) {
  if (!inherits(model, "sc_model")) stop("`model` must be an sc_model().", call. = FALSE)
  force(guidelines)
  f <- function(construct, context) {
    scales <- names(construct$scales)
    if (model$provider == "mock") {
      it <- do.call(rbind, lapply(scales, function(s) {
        k <- construct$n_per_scale
        rev <- seq_len(k) > round(k * (1 - construct$reverse_share))
        data.frame(scale = s, statement = sprintf("Mock item %d about %s%s.", seq_len(k),
                                                  construct$scales[[s]],
                                                  ifelse(rev, " (reversed)", "")),
                   reverse = rev, stringsAsFactors = FALSE)
      }))
      return(list(items = lp_name_items(it), reasoning = "Mock items.", usage = lp_usage(NULL)))
    }
    sc_need("ellmer", "to call language models")
    chat <- sc_chat(model, paste(lp_writer_system, guidelines, sep = "\n\n"))
    ty <- ellmer::type_object(
      items = ellmer::type_array(ellmer::type_object(
        scale = ellmer::type_string(paste("Short name of the scale, one of:",
                                          paste(scales, collapse = ", "))),
        statement = ellmer::type_string("The item, a statement respondents rate."),
        reverse = ellmer::type_boolean("TRUE if agreeing means less of the scale's trait."))),
      reasoning = ellmer::type_string("A short note on how the items cover each scale."))
    res <- chat$chat_structured(lp_writer_prompt(construct), type = ty)
    it <- lp_llm_rows(res$items)
    bad <- !it$scale %in% scales
    if (all(bad)) stop("The writer returned no items for the construct's scales.", call. = FALSE)
    if (any(bad)) warning(sum(bad), " items with unknown scales were left out.", call. = FALSE)
    list(items = lp_name_items(it[!bad, , drop = FALSE]), reasoning = lp_chr1(res$reasoning),
         usage = lp_chat_usage(chat, model))
  }
  structure(f, label = sprintf("%s (language model writer)", model$name))
}

#' A language-model reviser for the item-revision loop
#'
#' `loop_reviser_llm()` makes the `reviser` step of [revision_loop()]. After
#' each round, one call shows a language model the construct, every item
#' with its flags and main statistics, the parts of the stopping rule that
#' fail, and the earlier edits with whether they worked. It asks for edits
#' (reword, rekey, drop, add or keep), each with a rationale and the names
#' of the checks it responds to, and one note on the round. These are logged
#' in the `edits` and `rounds` tables, so you can see whether the revisions
#' follow the evidence.
#'
#' With `sc_model("mock")`, no model is called: The reviser rewords up to
#' `max_edits` failing items by adding a word, which is enough to try the
#' loop.
#'
#' @param model an [sc_model()] for the reviser.
#' @param actions the actions the reviser may take.
#' @param min_items smallest number of items a scale should keep. The model
#'   is told, and a drop that would leave a scale with fewer is not applied
#'   (the round's `reasoning` says so).
#' @param max_edits most edits per round, or `Inf`.
#' @param guidelines item-writing guidelines added to the system prompt.
#' @param min_total smallest number of items in all, or `NULL`, enforced in
#'   the same way.
#' @return A function for the `reviser` argument of [revision_loop()].
#' @seealso [revision_loop()], [loop_writer_llm()], [loop_reviser_drop()]
#' @examples
#' # see revision_loop()
#' @export
loop_reviser_llm <- function(model, actions = c("reword", "rekey", "drop", "add", "keep"),
                             min_items = 3, max_edits = Inf, guidelines = lp_guidelines,
                             min_total = NULL) {
  if (!inherits(model, "sc_model")) stop("`model` must be an sc_model().", call. = FALSE)
  actions <- match.arg(actions, several.ok = TRUE)
  force(min_items); force(max_edits); force(guidelines); force(min_total)
  f <- function(items, flags, context) {
    fail <- flags[flags$severity == "fail" & !is.na(flags$item), , drop = FALSE]
    if (model$provider == "mock") {
      ids <- utils::head(unique(fail$item), if (is.finite(max_edits)) max_edits else 3L)
      if (!length(ids) || !"reword" %in% actions)
        return(list(edits = NULL, reasoning = "Mock reviser: Nothing to reword."))
      st <- items$statement[match(ids, items$item)]
      return(list(edits = data.frame(
        item = ids, action = "reword", statement = paste0(sub("[.]$", "", st), ", usually."),
        rationale = "Mock reword.",
        cites = vapply(ids, function(i) paste(unique(fail$check[fail$item == i]), collapse = ","), ""),
        stringsAsFactors = FALSE),
        reasoning = sprintf("Mock reviser: Reworded %d failing items.", length(ids)),
        usage = lp_usage(NULL)))
    }
    sc_need("ellmer", "to call language models")
    chat <- sc_chat(model, paste(lp_reviser_system(actions, min_items, max_edits, min_total,
                                                   isTRUE(context$construct$single_scale)),
                                 guidelines, sep = "\n\n"))
    ty <- ellmer::type_object(
      edits = ellmer::type_array(ellmer::type_object(
        item = ellmer::type_string("Name of the item; for an added item, an empty string."),
        action = ellmer::type_enum(actions, "What to do with the item."),
        statement = ellmer::type_string(
          "The new wording for reword, rekey or add; an empty string otherwise."),
        reverse = ellmer::type_boolean("The item's key after the edit: TRUE for reverse-keyed."),
        scale = ellmer::type_string("The item's scale."),
        rationale = ellmer::type_string("Why: The evidence and how the edit should fix it."),
        cites = ellmer::type_array(ellmer::type_string(),
                                   "Names of the checks the edit responds to, exactly as shown."))),
      reasoning = ellmer::type_string("A short note on the round: What is wrong and the plan."))
    res <- chat$chat_structured(lp_reviser_prompt(items, flags, context), type = ty)
    ed <- lp_llm_rows(res$edits, cites = TRUE)
    if (nrow(ed)) {
      ed$item[!nzchar(ed$item)] <- NA_character_
      if (is.finite(max_edits)) ed <- utils::head(ed, max_edits)
      ed <- lp_guard_drops(items, ed, min_items, min_total)
    }
    reasoning <- lp_chr1(res$reasoning)
    if (!is.null(attr(ed, "refused")))
      reasoning <- paste(c(stats::na.omit(reasoning), attr(ed, "refused")), collapse = " ")
    list(edits = ed, reasoning = reasoning, usage = lp_chat_usage(chat, model))
  }
  structure(f, label = sprintf("%s (language model reviser)", model$name))
}

#' IRT checks for the item-revision loop
#'
#' `loop_irt()` makes the `evaluator` step of [revision_loop()]. For every
#' scale, it fits a unidimensional IRT model with mirt to the keyed answers
#' of the round. By default this is the partial credit model (Masters, 1982),
#' a Rasch model for ordered categories with every slope fixed at 1;
#' `model = "gpcm"` (generalized partial credit) and `model = "graded"`
#' (graded response) estimate a slope per item instead. It flags
#'
#' - `msq_misfit` (fail, partial credit model): Infit or outfit mean square
#'   outside `thresholds$msq` (0.6 to 1.4 by default, the range Wright and
#'   Linacre (1994) give for rating scales). Below the range, answers are
#'   more predictable than the model expects (often a sign of redundant
#'   items or tidy synthetic respondents); above it, they are noisy. With
#'   `overfit = "warn"`, an item that is only too predictable is a warning,
#'   and only noisy items fail.
#' - `misfit` (fail): The S-X2 item fit test (Orlando & Thissen, 2000) has
#'   a p value below `thresholds$misfit_p`.
#' - `disordered` (warn): The item's thresholds (the points where one
#'   category becomes more likely than the one below) are not in increasing
#'   order, so some categories are never the most likely answer.
#' - `low_slope` (fail, `"gpcm"` and `"graded"` only): A discrimination
#'   below `thresholds$slope`; a negative slope means the item runs against
#'   its scale.
#' - `steep_slope` (warn, `"gpcm"` and `"graded"` only): A discrimination
#'   above `thresholds$steep`, which synthetic respondents that answer
#'   almost deterministically produce.
#' - `local_dependence` (warn): The item's largest Q3 residual correlation
#'   (Yen, 1984) exceeds the mean Q3 of its scale by more than
#'   `thresholds$q3`, a sign that two items share more than the trait.
#' - `no_variance` (fail): Every respondent gives the same answer, so the
#'   item cannot be fitted.
#' - `low_info` (fail, only with `thresholds$info`): The mean test
#'   information of the scale between theta -2 and 2 is below the target.
#' - `irt_failed` (fail): The model could not be fitted for the scale.
#'
#' Stats: Per item `location` (the mean of its thresholds), `infit` and
#' `outfit` (partial credit model), `slope` (`"gpcm"` and `"graded"`) and
#' `sx2_p`, and per scale `info_mean` and `marginal_rxx` (marginal
#' reliability), which [loop_criterion()] can use as targets, for example
#' `min = list(marginal_rxx = 0.8)`. Both are taken over the estimated
#' latent distribution, with the trait standardized: `info_mean` is the mean
#' information between 2 SD below and 2 SD above the latent mean, and
#' `marginal_rxx` is the mean of \eqn{\sigma^2 I / (\sigma^2 I + 1)}. With
#' a latent variance of 1 these equal the usual values.
#'
#' @param model the IRT model: `"pcm"` (partial credit, the default),
#'   `"gpcm"` (generalized partial credit) or `"graded"` (graded response).
#' @param thresholds a named list that changes any of the defaults
#'   `list(msq = c(0.6, 1.4), misfit_p = 0.01, slope = 0.65, steep = 4,
#'   q3 = 0.2, info = NULL)`.
#' @param itemfit,q3 compute the item fit statistics and the Q3 residuals?
#'   They are the slowest parts.
#' @param overfit severity of a mean square below the range (answers more
#'   predictable than the model expects): `"fail"` or `"warn"`. Language
#'   models often answer almost deterministically for a given persona,
#'   which rewording cannot change, so `"warn"` lets the stopping rule rest
#'   on the other checks.
#' @return A function for the `evaluator` argument of [revision_loop()].
#' @references Masters, G. N. (1982). A Rasch model for partial credit
#'   scoring. *Psychometrika, 47*(2), 149-174.
#'
#'   Orlando, M., & Thissen, D. (2000). Likelihood-based item-fit indices for
#'   dichotomous item response theory models. *Applied Psychological
#'   Measurement, 24*(1), 50-64.
#'
#'   Wright, B. D., & Linacre, J. M. (1994). Reasonable mean-square fit
#'   values. *Rasch Measurement Transactions, 8*(3), 370.
#'
#'   Yen, W. M. (1984). Effects of local item dependence on the fit and
#'   equating performance of the three-parameter logistic model. *Applied
#'   Psychological Measurement, 8*(2), 125-145.
#' @seealso [revision_loop()], [loop_checker()]
#' @examples
#' \donttest{
#' h <- hexaco_items[hexaco_items$facet %in% c("HSinc", "HFair"), ]
#' ca <- hexaco_real[hexaco_real$country == "Canada", ]
#' irt <- loop_irt()
#' out <- irt(ca[1:400, ], h, list(construct = loop_construct("H", scale = c(1, 7))))
#' out$flags
#' }
#' @export
loop_irt <- function(model = c("pcm", "gpcm", "graded"), thresholds = list(), itemfit = TRUE,
                     q3 = TRUE, overfit = c("fail", "warn")) {
  model <- match.arg(model)
  overfit <- match.arg(overfit)
  thr <- utils::modifyList(list(msq = c(0.6, 1.4), misfit_p = 0.01, slope = 0.65, steep = 4,
                                q3 = 0.2, info = NULL), thresholds)
  if (length(thr$msq) != 2L || thr$msq[1] >= thr$msq[2])
    stop("`thresholds$msq` must be a lower and an upper limit.", call. = FALSE)
  itemtype <- c(pcm = "Rasch", gpcm = "gpcm", graded = "graded")[[model]]
  force(itemfit); force(q3)
  f <- function(responses, items, context) {
    lo <- context$construct$scale[1]; hi <- context$construct$scale[2]
    it <- bh_items(items, names(responses))
    K <- bh_key(bh_matrix(as.data.frame(responses), it), it, lo, hi)
    fl <- list(); st <- list()
    flag <- function(item, scale, check, value, threshold, severity, message)
      fl[[length(fl) + 1L]] <<- data.frame(item = item, scale = scale, check = check, value = value,
                                           threshold = threshold, severity = severity,
                                           message = message, stringsAsFactors = FALSE)
    stat <- function(item, scale, name, value) if (length(value))
      st[[length(st) + 1L]] <<- data.frame(item = item, scale = scale, stat = name,
                                           value = as.numeric(value), stringsAsFactors = FALSE)
    for (s in unique(it$scale)) {
      idx <- it$item[it$scale == s]
      X <- K[, idx, drop = FALSE]
      X <- X[rowSums(!is.na(X)) > 0, , drop = FALSE]
      nvar <- vapply(idx, function(i) length(unique(stats::na.omit(X[, i]))), integer(1))
      for (i in idx[nvar < 2L])
        flag(i, s, "no_variance", 0, 2, "fail",
             "Every respondent gives the same answer, so the item cannot be fitted.")
      use <- idx[nvar >= 2L]
      if (length(use) < 3L) {
        flag(NA_character_, s, "irt_failed", length(use), 3, "fail",
             sprintf("Only %d items vary; an IRT model needs 3 or more.", length(use)))
        next
      }
      fit <- tryCatch(suppressMessages(suppressWarnings(
        mirt::mirt(as.data.frame(X[, use, drop = FALSE]), 1, itemtype, verbose = FALSE,
                   technical = list(NCYCLES = 1000)))), error = function(e) e)
      if (inherits(fit, "error")) {
        flag(NA_character_, s, "irt_failed", NA_real_, NA_real_, "fail",
             sprintf("The %s model failed: %s", lp_irt_label[[model]], conditionMessage(fit)))
        next
      }
      pars <- mirt::coef(fit, IRTpars = TRUE, simplify = TRUE)$items
      b <- pars[, grepl("^b[0-9]*$", colnames(pars)), drop = FALSE]
      stat(use, s, "location", rowMeans(b, na.rm = TRUE))
      for (j in seq_along(use)) {
        bj <- b[j, !is.na(b[j, ])]
        if (length(bj) > 1L && is.unsorted(bj))
          flag(use[j], s, "disordered", sum(diff(bj) < 0), 0, "warn", sprintf(
            "Thresholds out of order (%s): Some categories are never the most likely answer.",
            paste(sprintf("%.2f", bj), collapse = ", ")))
      }
      if (model != "pcm") {
        a <- pars[, "a"]
        stat(use, s, "slope", a)
        for (j in seq_along(use)) {
          if (a[j] < thr$slope)
            flag(use[j], s, "low_slope", a[j], thr$slope, "fail", sprintf(
              "Discrimination %.2f is below %.2f%s.", a[j], thr$slope,
              if (a[j] < 0) "; the item runs against its scale" else ""))
          else if (a[j] > thr$steep)
            flag(use[j], s, "steep_slope", a[j], thr$steep, "warn", sprintf(
              "Discrimination %.2f is above %.2f: Answers look almost deterministic.", a[j],
              thr$steep))
        }
      }
      if (itemfit) {
        stats_fit <- c("S_X2", if (model == "pcm") "infit")
        ifit <- tryCatch(suppressMessages(suppressWarnings(
          mirt::itemfit(fit, fit_stats = stats_fit, na.rm = TRUE))), error = function(e) NULL)
        if (!is.null(ifit) && nrow(ifit) == length(use)) {
          p <- ifit$p.S_X2
          if (!is.null(p)) {
            stat(use, s, "sx2_p", p)
            for (j in which(!is.na(p) & p < thr$misfit_p))
              flag(use[j], s, "misfit", p[j], thr$misfit_p, "fail",
                   sprintf("S-X2 item fit p = %.3g: The model does not describe the answers.", p[j]))
          }
          if (model == "pcm" && all(c("infit", "outfit") %in% names(ifit))) {
            stat(use, s, "infit", ifit$infit)
            stat(use, s, "outfit", ifit$outfit)
            for (j in seq_along(use)) {
              v <- c(infit = ifit$infit[j], outfit = ifit$outfit[j])
              out <- !is.na(v) & (v < thr$msq[1] | v > thr$msq[2])
              if (!any(out)) next
              # noisy answers (above the range) count first, as they always fail
              hi_out <- out & v > thr$msq[2]
              pick <- if (any(hi_out)) hi_out else out
              worst <- names(v)[pick][which.max(abs(log(v[pick])))]
              flag(use[j], s, "msq_misfit", v[[worst]],
                   if (v[[worst]] < thr$msq[1]) thr$msq[1] else thr$msq[2],
                   if (v[[worst]] < thr$msq[1]) overfit else "fail", sprintf(
                     "%s mean square %.2f is outside %.1f to %.1f: Answers are %s.",
                     if (worst == "infit") "Infit" else "Outfit", v[[worst]], thr$msq[1],
                     thr$msq[2], if (v[[worst]] < thr$msq[1])
                       "more predictable than the model expects" else "noisier than the model expects"))
            }
          }
        }
      }
      if (q3 && length(use) >= 4L) {
        Q <- tryCatch(suppressMessages(suppressWarnings(
          mirt::residuals(fit, type = "Q3", verbose = FALSE))), error = function(e) NULL)
        if (is.matrix(Q)) {
          diag(Q) <- NA
          m <- mean(Q, na.rm = TRUE)
          for (j in seq_along(use)) {
            v <- Q[j, ] - m
            if (all(is.na(v))) next
            k <- which.max(v)
            if (v[k] > thr$q3)
              flag(use[j], s, "local_dependence", Q[j, k], m + thr$q3, "warn", sprintf(
                "Q3 = %.2f with %s, %.2f above the scale's mean Q3.", Q[j, k], use[k], v[k]))
          }
        }
      }
      # the partial credit model estimates the latent mean and variance, so
      # take the information and reliability over that distribution
      g <- lp_latent(fit)
      th <- matrix(g[1] + g[2] * seq(-2, 2, length.out = 41))
      info <- tryCatch(mean(mirt::testinfo(fit, th)) * g[2]^2, error = function(e) NA_real_)
      rxx <- tryCatch(lp_marginal_rxx(fit, g), error = function(e) NA_real_)
      stat(NA_character_, s, "info_mean", info)
      stat(NA_character_, s, "marginal_rxx", rxx)
      if (!is.null(thr$info) && !is.na(info) && info < thr$info)
        flag(NA_character_, s, "low_info", info, thr$info, "fail", sprintf(
          "Mean test information %.2f between theta -2 and 2 is below %.2f.", info, thr$info))
    }
    list(flags = if (length(fl)) do.call(rbind, fl) else NULL,
         stats = if (length(st)) do.call(rbind, st) else NULL)
  }
  structure(f, label = sprintf("mirt %s model (%s, S-X2, Q3, information)", lp_irt_label[[model]],
                               if (model == "pcm") paste0(
                                 "infit and outfit", if (overfit == "warn") " (overfit warns)",
                                 ", threshold order") else "slopes, threshold order"))
}

lp_irt_label <- c(pcm = "partial credit", gpcm = "generalized partial credit",
                  graded = "graded response")

# ---- internal -------------------------------------------------------------

lp_guidelines <- paste(
  "Item-writing guidelines: Write short, plain statements about one idea each.",
  "Avoid double negatives, double-barrelled statements, absolutes such as 'always' or 'never',",
  "jargon, and wording tied to one culture, gender or region.",
  "Reverse-keyed items should state the low end of the trait, not negate a positive item.",
  "Items of the same scale should differ in content, not only in wording.")

lp_writer_system <- paste(
  "You are an experienced psychometrician writing Likert-type items for a new self-report scale.",
  "Write original items that measure the stated construct and scales for the stated population.")

lp_writer_prompt <- function(con) {
  paste(c(
    sprintf("Construct: %s", con$name),
    if (!is.null(con$definition)) sprintf("Definition: %s", con$definition),
    if (!is.null(con$population)) sprintf("Respondents: %s", con$population),
    sprintf("Response scale: %d to %d%s", con$scale[1], con$scale[2],
            if (is.null(con$labels)) "" else sprintf(" (%s)", paste(con$labels, collapse = ", "))),
    "", "Scales:", sprintf("- %s: %s", names(con$scales), con$scales), "",
    sprintf(paste("Write %d items for each scale. About %.0f%% of the items of each scale should",
                  "be reverse-keyed."), con$n_per_scale, 100 * con$reverse_share),
    if (!is.null(con$notes)) c("", "Further guidance:", con$notes)),
    collapse = "\n")
}

# Keep the drops that leave every scale at least `min_items` items and the
# whole set at least `min_total`, counting the items the same edits add.
# Latent mean and SD of a unidimensional mirt fit.
lp_latent <- function(fit) {
  cf <- mirt::coef(fit, simplify = TRUE)
  m <- as.numeric(cf$means)[1]; v <- as.numeric(cf$cov)[1]
  c(if (is.finite(m)) m else 0, if (is.finite(v) && v > 0) sqrt(v) else 1)
}

# Marginal reliability over the estimated latent distribution:
# The mean of var * I / (var * I + 1), which is I / (I + 1) when var = 1.
# (mirt::marginal_rxx() integrates over N(0, 1) and divides by var + I, so it
# is too low when a Rasch-type model estimates a latent variance above 1.)
lp_marginal_rxx <- function(fit, g = lp_latent(fit)) {
  f <- function(theta) {
    I <- mirt::testinfo(fit, matrix(theta))
    g[2]^2 * I / (g[2]^2 * I + 1) * stats::dnorm(theta, g[1], g[2])
  }
  stats::integrate(f, g[1] - 6 * g[2], g[1] + 6 * g[2])$value
}

lp_guard_drops <- function(items, ed, min_items, min_total) {
  if (!nrow(ed) || !"action" %in% names(ed)) return(ed)
  is_add <- ed$action == "add"
  n_scale <- table(factor(c(items$scale, ed$scale[is_add]),
                          levels = unique(c(items$scale, ed$scale[is_add]))))
  n_total <- nrow(items) + sum(is_add)
  keep <- rep(TRUE, nrow(ed))
  for (i in which(ed$action == "drop" & ed$item %in% items$item)) {
    s <- items$scale[match(ed$item[i], items$item)]
    if ((!is.null(min_items) && n_scale[[s]] <= min_items) ||
        (!is.null(min_total) && n_total <= min_total)) {
      keep[i] <- FALSE
      next
    }
    n_scale[[s]] <- n_scale[[s]] - 1L
    n_total <- n_total - 1L
  }
  out <- ed[keep, , drop = FALSE]
  if (any(!keep))
    attr(out, "refused") <- sprintf(
      "Not dropped, to keep the minimum number of items: %s.", paste(ed$item[!keep], collapse = ", "))
  out
}

lp_reviser_system <- function(actions, min_items, max_edits, min_total = NULL,
                              single_scale = FALSE) paste(
  "You are an experienced psychometrician revising Likert-type items after a pilot.",
  "Each round, synthetic respondents answer the items, and checks flag problems.",
  "Propose edits that respond to the evidence: Reword an item whose wording is the likely cause,",
  "rekey an item whose key is wrong, drop an item that cannot be saved, add an item to a scale",
  "that is short or narrow, or keep an item on purpose.",
  sprintf("Allowed actions: %s.", paste(actions, collapse = ", ")),
  if (single_scale) paste(
    "The scales are content domains of one scale: The checks treat all items as one scale,",
    "so a good item measures the one construct well while it covers its domain."),
  sprintf("Keep at least %d item%s in every %s.", min_items, if (min_items == 1) "" else "s",
          if (single_scale) "domain" else "scale"),
  if (!is.null(min_total)) sprintf("Keep at least %d items in all.", min_total),
  if (is.finite(max_edits)) sprintf("Make at most %d edits.", max_edits),
  "For each edit, name the checks it responds to exactly as they are shown, and explain the fix.",
  "Look at the earlier edits: Do not undo an edit that resolved its flags, and try something",
  "different when an earlier edit did not work. Do not edit items without flags unless the",
  "scale as a whole needs it.")

lp_reviser_prompt <- function(items, flags, context) {
  con <- context$construct
  st <- context$history$stats
  st <- st[st$round == context$round & !is.na(st$item) &
             st$stat %in% c("item_rest", "slope", "sd"), , drop = FALSE]
  line <- function(i) {
    f <- flags[flags$item %in% items$item[i], , drop = FALSE]
    s <- st[st$item == items$item[i], , drop = FALSE]
    paste0("- ", items$item[i], " [", items$scale[i], if (items$reverse[i]) ", reverse-keyed", "] ",
           "\"", items$statement[i], "\"",
           if (nrow(s)) paste0(" (", paste(sprintf("%s %.2f", s$stat, s$value), collapse = ", "), ")"),
           if (nrow(f)) paste0("\n    flags: ", paste(sprintf("%s [%s]: %s", f$check, f$severity,
                                                            f$message), collapse = "; ")))
  }
  other <- flags[is.na(flags$item), , drop = FALSE]
  cr <- context$history$criteria
  cr <- cr[cr$round == context$round & !cr$pass %in% TRUE, , drop = FALSE]
  ed <- context$history$edits
  ed <- ed[ed$applied %in% TRUE & ed$action != "keep", , drop = FALSE]
  hist <- if (nrow(ed)) sprintf("- Round %d, %s %s%s%s", ed$round, ed$action, ed$item,
                                ifelse(is.na(ed$cites) | !nzchar(ed$cites), "",
                                       paste0(" for ", ed$cites)),
                                ifelse(is.na(ed$resolved), "",
                                       ifelse(ed$resolved, ": resolved", ": not resolved")))
  paste(c(
    sprintf("Construct: %s%s", con$name,
            if (is.null(con$definition)) "" else paste0(". ", con$definition)),
    if (!is.null(con$population)) sprintf("Respondents: %s", con$population),
    "Scales:", sprintf("- %s: %s", names(con$scales), con$scales),
    sprintf("Response scale: %d to %d.", con$scale[1], con$scale[2]),
    if (!is.null(con$notes)) c("Further guidance:", con$notes),
    "", sprintf("Round %d. Items, with their statistics and flags:", context$round),
    vapply(seq_len(nrow(items)), line, ""),
    if (nrow(other)) c("", "Scale and respondent flags:",
                       sprintf("- %s%s: %s", other$check,
                               ifelse(is.na(other$scale), "", paste0(" (", other$scale, ")")),
                               other$message)),
    if (nrow(cr)) c("", "Parts of the stopping rule that fail:",
                    sprintf("- %s: %s (target %s)", cr$criterion, signif(cr$value, 3), cr$target)),
    if (length(hist)) c("", "Earlier edits:", hist)),
    collapse = "\n")
}

# rows from a structured answer (a data frame or a list of objects)
lp_llm_rows <- function(x, cites = FALSE) {
  if (is.null(x) || !length(x)) return(data.frame())
  if (!is.data.frame(x)) {
    x <- lapply(x, function(r) {
      if (cites) r$cites <- paste(as.character(unlist(r$cites)), collapse = ",")
      as.data.frame(lapply(r, function(v) if (length(v)) v[[1]] else NA), stringsAsFactors = FALSE)
    })
    x <- do.call(rbind, x)
  } else if (cites && is.list(x$cites)) {
    x$cites <- vapply(x$cites, function(v) paste(as.character(unlist(v)), collapse = ","), "")
  }
  x <- as.data.frame(x, stringsAsFactors = FALSE)
  if ("reverse" %in% names(x)) x$reverse <- as.logical(x$reverse)
  x
}

lp_name_items <- function(it) {
  it$scale <- as.character(it$scale)
  it$item <- NA_character_
  for (s in unique(it$scale)) {
    j <- which(it$scale == s)
    it$item[j] <- sprintf("%s%02d", lp_id(s), seq_along(j))
  }
  it[, c("item", "scale", "reverse", "statement")]
}

lp_chat_usage <- function(chat, m) {
  tk <- tryCatch(chat$get_tokens(), error = function(e) NULL)
  if (is.null(tk) || !nrow(tk)) return(lp_usage(NULL))
  if (all(c("input", "output") %in% names(tk))) {
    i <- sum(tk$input, na.rm = TRUE); o <- sum(tk$output, na.rm = TRUE)
  } else if (all(c("role", "tokens") %in% names(tk))) {
    i <- sum(tk$tokens[tk$role == "user"], na.rm = TRUE)
    o <- sum(tk$tokens[tk$role == "assistant"], na.rm = TRUE)
  } else return(lp_usage(NULL))
  pr <- sc_price(m, sc_prices)
  list(input_tokens = i, output_tokens = o, cost = (i * pr$input + o * pr$output) / 1e6)
}
