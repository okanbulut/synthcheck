# Coverage strip: Overlap, Structure and the best blend of models.
# Ported from mirtverse (R/ai-coverage.R, commit 8810533, GPL-3) by its
# author, Okan Bulut.

#' How well do synthetic respondents cover the real population?
#'
#' `synthetic_coverage()` compares synthetic respondents
#' from one or more language models (each run several times) with real
#' responses to
#' the same items, and finds the blend of models that matches the real
#' population best. [gg_coverage()] draws the result as a *coverage strip*:
#' One row per model and attempt, one column per slice of the real
#' population, coloured by whether the model puts too many (blue) or too
#' few (red) synthetic respondents in that slice.
#'
#' **Slices.** By default (`slices = "score"`) the slices are the deciles of
#' the real total score, so each holds about 10% of real people (ties in the
#' score can make them uneven; when the score has `n_slices` values or
#' fewer, each value is its own slice). `slices = "theta"` uses deciles of
#' EAP scores from a unidimensional model fitted to the real data (or the
#' model given as `model`). `slices = "group"` uses the groups in the column
#' named by `group` (for example personas), and `slices = "item"` switches to
#' item mode: One column per item for right/wrong items, or one column per
#' answer category for polytomous (for example Likert) items. With `group`
#' and `slices = "score"` or `"theta"`, the deciles are formed within each
#' group. By default the shares are then taken over all respondents, so the
#' mix of groups counts too: A model with too few respondents from one group
#' shows red across that group's slices. With `within_group = TRUE` the
#' shares are taken within each group instead, so only how each group's
#' respondents spread over that group's slices counts, and Overlap is the
#' mean over the groups. Use it when the number of synthetic respondents per
#' group was set by design (for example the same number for each country)
#' and does not need to match the real data.
#'
#' **Overlap** is the share of synthetic respondents (or answers) that fall
#' in the same slices as real ones: The sum over slices of the smaller of
#' the synthetic and the real share, which is one minus the total variation
#' distance. In item mode it is computed for each item and averaged over
#' the items (*Item Overlap*). 100% means the same mix as the real data.
#'
#' **Structure** is 100% minus the mean absolute difference between the
#' inter-item correlations of the real and the synthetic responses
#' (polychoric correlations when the polycor package is installed and
#' `cor = "auto"`, otherwise Pearson correlations). It catches synthetic
#' data that match every slice but relate the items to each other in a
#' different way.
#'
#' **Noise.** A cell is coloured only when the gap between the synthetic
#' and the real share is larger than a real sample of the same size would
#' show by chance (outside the `conf` interval of a binomial proportion);
#' all other cells are drawn as a match.
#'
#' **Best Blend.** With two or more models and `blend = TRUE`, the function
#' searches a grid of weights (steps of `step`) for the recipe whose mixture
#' of synthetic respondents has the highest overlap: A blend's share in a
#' slice is the weighted sum of the models' shares. With four or more
#' attempts per model (or `holdout = TRUE`), the recipe is chosen on the
#' first half of the attempts and its numbers are reported on the other
#' half, so that it is not judged on the data it was chosen on. The
#' structure of a blend is computed on a pooled sample drawn with the
#' recipe's weights. See [blend_llms()] to search again with other settings.
#'
#' Use the coverage strip to compare
#' models and to decide how to combine them, not to replace a field test.
#'
#' @param synthetic a named list with one element per language model. Each
#'   element holds that model's attempts: A list of response data frames, one
#'   per attempt (a single data frame counts as one attempt). Results of
#'   `mirtverse::simulate_llm_respondents()` are accepted too.
#' @param real a data frame of real responses to the same items (columns
#'   matched by name). Can be `NULL` with `slices = "group"` and `target`.
#' @param slices what the columns of the strip are: `"score"`, `"theta"`,
#'   `"group"` or `"item"` (see Details).
#' @param group optional name of a column that holds the group or persona of
#'   each respondent, in `real` and in the synthetic data (or in the
#'   `personas` of a `mirtverse::simulate_llm_respondents()` result).
#' @param within_group with `group` and `slices = "score"` or `"theta"`,
#'   compare the shares within each group, so that the mix of groups does
#'   not count (see Details)?
#' @param target with `slices = "group"` and no real data, the intended
#'   share of each group: A named vector of proportions.
#' @param model with `slices = "theta"`, an optional unidimensional model
#'   from [mirt::mirt()] fitted to the real data.
#' @param n_slices number of score or theta slices (per group with `group`).
#' @param conf confidence level for the noise check.
#' @param cor correlations for the structure check: `"auto"`, `"polychoric"`
#'   or `"pearson"`.
#' @param blend find the best blend of the models?
#' @param holdout choose the blend on half of the attempts and report it on
#'   the other half? `NULL` does so when every model has four or more
#'   attempts.
#' @param step grid step for the blend weights.
#' @param seed random seed for the pooled sample behind a blend's structure.
#' @return An object of class `sc_coverage`: A list with `summary` (a tibble
#'   with one row per model, and one for the blend, giving the Overall,
#'   Lowest and Highest overlap and structure over the attempts), `cells`
#'   (the synthetic and real share in every slice for every model and
#'   attempt), `attempts` (overlap and structure of every attempt), `blend`
#'   (weights, recipe and the attempts used), `slices` (the slice
#'   definitions) and `notes`. It has `print()`, `tidy()` and `autoplot()`
#'   methods.
#' @seealso [gg_coverage()], [blend_llms()], [hexaco_real], [hexaco_llm]
#' @examples
#' # made-up example: three "models" whose respondents differ from the
#' # real population in different ways, five attempts each
#' set.seed(1)
#' a <- matrix(rlnorm(12, 0.2, 0.3)); d <- matrix(rnorm(12))
#' real <- as.data.frame(mirt::simdata(a, d, 1000, itemtype = "dich"))
#' llm <- function(mu, s) lapply(1:5, function(i) as.data.frame(
#'   mirt::simdata(a, d, 200, itemtype = "dich", Theta = matrix(rnorm(200, mu, s)))))
#' cov <- synthetic_coverage(list("LLM A" = llm(0.8, 0.7), "LLM B" = llm(0, 0.4),
#'                                "LLM C" = llm(-0.6, 0.9)), real)
#' cov
#' gg_coverage(cov)
#' @export
synthetic_coverage <- function(synthetic, real = NULL,
                               slices = c("score", "theta", "group", "item"),
                               group = NULL, within_group = FALSE,
                               target = NULL, model = NULL,
                               n_slices = 10, conf = 0.95,
                               cor = c("auto", "polychoric", "pearson"),
                               blend = TRUE, holdout = NULL, step = 0.05,
                               seed = 1) {
  slices <- match.arg(slices)
  cor <- match.arg(cor)
  syn <- coverage_inputs(synthetic)
  notes <- character()
  if (is.null(real) && !(slices == "group" && !is.null(target)))
    stop("`real` is needed, except with slices = \"group\" and a `target` mix.", call. = FALSE)
  if (!is.null(real)) real <- as.data.frame(real)
  if (within_group && (is.null(group) || !slices %in% c("score", "theta")))
    stop("`within_group = TRUE` needs `group` and slices = \"score\" or \"theta\".", call. = FALSE)
  if (slices == "group" && is.null(group))
    stop("slices = \"group\" needs `group`, the name of the group or persona column.", call. = FALSE)

  # group labels, then the item columns shared by all data sets
  syn <- lapply(syn, function(m) lapply(m, coverage_attach_group, group = group))
  if (!is.null(real) && !is.null(group)) {
    if (!group %in% names(real))
      stop("`real` has no column `", group, "`.", call. = FALSE)
    real$.group <- as.character(real[[group]])
    real[[group]] <- NULL
  }
  all_sets <- c(if (!is.null(real)) list(real), unlist(syn, recursive = FALSE))
  items <- Reduce(intersect, lapply(all_sets, function(d) setdiff(names(d), ".group")))
  min_items <- if (slices %in% c("item", "group")) 1L else 2L
  if (length(items) < min_items)
    stop("The real and synthetic data share ", length(items), " item column(s); ",
         "at least ", min_items, " are needed. Check that the item names match.", call. = FALSE)
  for (d in all_sets) {
    bad <- items[!vapply(d[items], function(v) is.numeric(v) || is.logical(v), logical(1))]
    if (length(bad))
      stop("Item columns must hold numeric scores; not numeric: ",
           paste(utils::head(bad, 5), collapse = ", "), ".", call. = FALSE)
  }

  # slice definitions from the real data (or the target)
  def <- coverage_slices(slices, real, items, group, target, model, n_slices, within_group)
  notes <- c(notes, def$notes)

  # shares per model and attempt
  z <- stats::qnorm(1 - (1 - conf) / 2)
  cells <- list(); att <- list()
  for (m in names(syn)) for (a in seq_along(syn[[m]])) {
    d <- syn[[m]][[a]]
    sh <- coverage_shares(def, d, items)
    cells[[length(cells) + 1L]] <- data.frame(model = m, attempt = a, def$table,
                                              synthetic = sh$share, n = sh$n,
                                              stringsAsFactors = FALSE)
    att[[length(att) + 1L]] <- data.frame(model = m, attempt = a,
                                          overlap = coverage_overlap(sh$share, def),
                                          n = max(sh$n), stringsAsFactors = FALSE)
  }
  cells <- do.call(rbind, cells)
  att <- do.call(rbind, att)

  # structure
  cor_method <- cor
  if (cor == "auto") cor_method <- if (requireNamespace("polycor", quietly = TRUE)) "polychoric" else "pearson"
  if (cor == "polychoric" && !requireNamespace("polycor", quietly = TRUE)) {
    cor_method <- "pearson"
    notes <- c(notes, "The polycor package is not installed, so Structure uses Pearson correlations.")
  }
  att$structure <- NA_real_
  if (!is.null(real) && length(items) >= 2L) {
    r_real <- coverage_cor(real[items], cor_method)
    for (i in seq_len(nrow(att))) {
      d <- syn[[att$model[i]]][[att$attempt[i]]]
      att$structure[i] <- coverage_structure(r_real, coverage_cor(d[items], cor_method))
    }
  }

  out <- structure(list(
    cells = NULL, attempts = NULL, summary = NULL, blend = NULL, slices = def,
    settings = list(slices = slices, group = group, within_group = within_group, conf = conf, z = z, cor = cor_method,
                    items = items, n_slices = n_slices),
    data = list(synthetic = syn, real = if (!is.null(real)) real[c(items, intersect(".group", names(real)))]),
    notes = notes), class = "sc_coverage")
  out$cells <- coverage_flag(cells, z, def$display)
  out$attempts <- as_tbl(att)
  if (blend && length(syn) >= 2L) {
    out <- blend_llms(out, holdout = holdout, step = step, seed = seed)
  } else {
    out$summary <- coverage_summary(out$attempts)
  }
  out
}

#' Find the best blend of language models
#'
#' Searches the blend weights for an [synthetic_coverage()] result again,
#' for example with a finer grid or without holding out attempts. The
#' recipe with the highest mean overlap on the attempts it is chosen on wins;
#' with `holdout`, it is chosen on the first half of the attempts and
#' reported on the second half.
#'
#' @param x an `sc_coverage` object from [synthetic_coverage()].
#' @param holdout choose on half of the attempts and report on the other
#'   half? `NULL` does so when every model has four or more attempts.
#' @param step grid step for the weights (coarser steps are used for more
#'   than six models).
#' @param seed random seed for the pooled sample behind the blend's
#'   structure.
#' @return `x` with a `"Best Blend"` row in `summary`, its cells and
#'   attempts added, and `blend`: A list with `weights` (a named vector),
#'   `recipe` (text), `train` and `test` (the attempts used) and
#'   `in_sample` (the mean overlap on the attempts the recipe was chosen
#'   on).
#' @seealso [synthetic_coverage()], [gg_coverage()]
#' @examples
#' set.seed(1)
#' a <- matrix(rlnorm(8, 0.2, 0.3)); d <- matrix(rnorm(8))
#' real <- as.data.frame(mirt::simdata(a, d, 600, itemtype = "dich"))
#' llm <- function(mu, s) lapply(1:4, function(i) as.data.frame(
#'   mirt::simdata(a, d, 150, itemtype = "dich", Theta = matrix(rnorm(150, mu, s)))))
#' cov <- synthetic_coverage(list(A = llm(0.8, 0.7), B = llm(-0.6, 0.9)), real,
#'                           blend = FALSE)
#' blend_llms(cov, holdout = FALSE)$blend$recipe
#' @export
blend_llms <- function(x, holdout = NULL, step = 0.05, seed = 1) {
  if (!inherits(x, "sc_coverage"))
    stop("`x` must come from synthetic_coverage().", call. = FALSE)
  # drop an earlier blend
  keep <- x$attempts$model != "Best Blend"
  x$attempts <- x$attempts[keep, ]
  x$cells <- x$cells[x$cells$model != "Best Blend", ]
  models <- unique(x$attempts$model)
  if (length(models) < 2L)
    stop("A blend needs at least two models.", call. = FALSE)
  if (length(models) > 10L)
    stop("Blending more than 10 models at once is not supported; compare them in smaller sets.",
         call. = FALSE)
  n_att <- min(table(x$attempts$model))
  if (is.null(holdout)) holdout <- n_att >= 4L
  if (holdout && n_att < 2L) {
    holdout <- FALSE
    x$notes <- c(x$notes, "Each model has one attempt, so the blend is checked on the attempt it was chosen on.")
  }
  train <- if (holdout) seq_len(ceiling(n_att / 2)) else seq_len(n_att)
  test <- if (holdout) setdiff(seq_len(n_att), train) else train
  if (length(models) > 6L) step <- max(step, 0.1)

  def <- x$slices
  share <- function(m, a) {
    s <- x$cells[x$cells$model == m & x$cells$attempt == a, ]
    s$synthetic[match(def$table$slice, s$slice)]
  }
  S <- lapply(models, function(m) lapply(seq_len(n_att), function(a) share(m, a)))
  names(S) <- models
  mix <- function(w, a) Reduce(`+`, Map(function(wm, m) wm * S[[m]][[a]], w, models))
  grid <- simplex_grid(length(models), step)
  score <- apply(grid, 1, function(w) mean(vapply(train, function(a)
    coverage_overlap(mix(w, a), def), numeric(1))))
  best <- which.max(score)
  w <- stats::setNames(grid[best, ], models)

  # the blend's attempts
  cells <- list(); att <- list()
  real <- x$data$real
  r_real <- if (!is.null(real) && length(x$settings$items) >= 2L)
    coverage_cor(real[x$settings$items], x$settings$cor) else NULL
  old_seed <- if (exists(".Random.seed", envir = globalenv())) get(".Random.seed", envir = globalenv()) else NULL
  on.exit(if (is.null(old_seed)) suppressWarnings(rm(".Random.seed", envir = globalenv()))
          else assign(".Random.seed", old_seed, envir = globalenv()), add = TRUE)
  set.seed(seed)
  for (a in seq_len(n_att)) {
    s <- mix(w, a)
    n <- round(sum(w * vapply(models, function(m)
      max(x$cells$n[x$cells$model == m & x$cells$attempt == a]), numeric(1))))
    cells[[a]] <- data.frame(model = "Best Blend", attempt = a, def$table, synthetic = s, n = n,
                             stringsAsFactors = FALSE)
    st <- NA_real_
    if (!is.null(r_real)) {
      pooled <- blend_pool(x$data$synthetic, models, a, w, x$settings$items)
      st <- coverage_structure(r_real, coverage_cor(pooled, x$settings$cor))
    }
    att[[a]] <- data.frame(model = "Best Blend", attempt = a, overlap = coverage_overlap(s, def),
                           n = n, structure = st, stringsAsFactors = FALSE)
  }
  bc <- coverage_flag(do.call(rbind, cells), x$settings$z, def$display)
  x$cells <- as_tbl(rbind(as.data.frame(x$cells), as.data.frame(bc)))
  ba <- do.call(rbind, att)
  x$attempts <- as_tbl(rbind(as.data.frame(x$attempts), ba))
  recipe <- paste(sprintf("%d%% %s", round(100 * w[w > 0]), names(w)[w > 0]), collapse = " + ")
  x$blend <- list(weights = w, recipe = recipe, train = train, test = test,
                  in_sample = score[best], holdout = holdout)
  x$summary <- coverage_summary(x$attempts, blend_test = test)
  x
}

#' Draw the coverage strip
#'
#' Draws an [synthetic_coverage()] result: One row per model and attempt
#' (and the Best Blend), one column per slice of the real population or,
#' in item mode, per item (or per answer category of polytomous items).
#' Blue cells hold too many synthetic respondents or answers, red cells too
#' few, and pale cells are a match or within what a real sample of the same
#' size would show by chance. On the right, Overlap (Item Overlap in item
#' mode) and Structure give the mean (Overall), the worst (Lowest) and the
#' best (Highest) attempt.
#'
#' In item mode one plot shows at most `max_columns` columns, so the cells
#' stay readable: 20 right/wrong items, 8 five-point Likert items, 5
#' seven-point items, and so on. Larger tests are split into pages; by
#' default the worst-matching items come first. The numbers on the right
#' always use all items.
#'
#' @param x an `sc_coverage` object from [synthetic_coverage()].
#' @param page with more items than fit on one plot, the page to draw, or
#'   `"all"` for a list of all pages.
#' @param order item order in item mode: `"worst"` (lowest Item Overlap
#'   first), `"difficulty"` (real proportion correct or mean, high to low)
#'   or `"original"`.
#' @param items_per_plot number of items on one page; by default as many as
#'   fit in `max_columns`.
#' @param max_columns the most columns on one page.
#' @param title,subtitle optional title and subtitle; by default a question
#'   that fits the view.
#' @return A patchwork object (a list of them with `page = "all"`).
#' @seealso [synthetic_coverage()]
#' @examples
#' set.seed(1)
#' a <- matrix(rlnorm(10, 0.2, 0.3)); d <- matrix(rnorm(10))
#' real <- as.data.frame(mirt::simdata(a, d, 800, itemtype = "dich"))
#' llm <- function(mu, s) lapply(1:3, function(i) as.data.frame(
#'   mirt::simdata(a, d, 200, itemtype = "dich", Theta = matrix(rnorm(200, mu, s)))))
#' cov <- synthetic_coverage(list("LLM A" = llm(0.8, 0.7), "LLM B" = llm(-0.5, 0.9)),
#'                           real, slices = "item")
#' gg_coverage(cov)
#' @export
gg_coverage <- function(x, page = 1, order = c("worst", "difficulty", "original"),
                        items_per_plot = NULL, max_columns = 40,
                        title = NULL, subtitle = NULL) {
  if (!inherits(x, "sc_coverage"))
    stop("`x` must come from synthetic_coverage().", call. = FALSE)
  order <- match.arg(order)
  item_mode <- x$settings$slices == "item"
  pages <- if (item_mode) coverage_pages(x, order, items_per_plot, max_columns) else list(NULL)
  draw <- function(p) plot_coverage(x, pages[[p]], p, length(pages),
                                    sum(lengths(pages[seq_len(p - 1L)])), title, subtitle)
  if (identical(page, "all")) return(lapply(seq_along(pages), draw))
  page <- as.integer(page)
  if (is.na(page) || page < 1L || page > length(pages))
    stop("`page` must be between 1 and ", length(pages), ".", call. = FALSE)
  draw(page)
}

#' @export
print.sc_coverage <- function(x, ...) {
  s <- x$settings
  what <- switch(s$slices, score = "real total-score slices", theta = "real theta slices",
                 group = "groups", item = "items")
  n_models <- length(unique(x$attempts$model[x$attempts$model != "Best Blend"]))
  cat(sprintf("<sc_coverage> %d model(s), %d item(s), coverage of %s\n",
              n_models, length(s$items), what))
  tab <- as.data.frame(x$summary)
  pct <- grepl("^(overlap|structure)_", names(tab))
  tab[pct] <- lapply(tab[pct], function(v) ifelse(is.na(v), NA, sprintf("%.0f%%", 100 * v)))
  print(tab, row.names = FALSE)
  if (!is.null(x$blend)) {
    cat(sprintf("\nBest Blend: %s", x$blend$recipe))
    if (isTRUE(x$blend$holdout))
      cat(sprintf(" (chosen on attempts %s; its numbers come from attempts %s)",
                  coverage_range(x$blend$train), coverage_range(x$blend$test)))
    cat("\n")
  }
  if (length(x$notes)) {
    cat("\n")
    for (n in x$notes) cat(strwrap(n, initial = "* ", prefix = "  "), sep = "\n")
  }
  invisible(x)
}

#' @exportS3Method generics::tidy
tidy.sc_coverage <- function(x, ...) x$summary

#' @exportS3Method ggplot2::autoplot
autoplot.sc_coverage <- function(object, ...) gg_coverage(object, ...)

# ---- internal: inputs ---------------------------------------------------

coverage_inputs <- function(synthetic) {
  if (inherits(synthetic, "mv_synthetic") || is.data.frame(synthetic) || !is.list(synthetic) ||
      is.null(names(synthetic)) || any(!nzchar(names(synthetic))))
    stop("`synthetic` must be a named list with one element per model, for example ",
         "list(\"LLM A\" = attempts_a, \"LLM B\" = attempts_b).", call. = FALSE)
  if (anyDuplicated(names(synthetic)) || "Best Blend" %in% names(synthetic))
    stop("Model names must be unique and cannot be \"Best Blend\".", call. = FALSE)
  lapply(synthetic, function(m) {
    if (inherits(m, "mv_synthetic") || is.data.frame(m) || is.matrix(m)) m <- list(m)
    if (!is.list(m) || !length(m))
      stop("Each model must hold one or more attempts (data frames).",
           call. = FALSE)
    lapply(m, function(a) {
      if (inherits(a, "mv_synthetic")) {
        d <- as.data.frame(a$responses)
        if (!is.null(a$personas)) attr(d, "personas") <- as.data.frame(a$personas)
        d
      } else if (is.data.frame(a) || is.matrix(a)) {
        as.data.frame(a)
      } else {
        stop("Each attempt must be a data frame of responses.",
             call. = FALSE)
      }
    })
  })
}

coverage_attach_group <- function(d, group) {
  if (is.null(group)) return(d)
  p <- attr(d, "personas")
  if (group %in% names(d)) {
    d$.group <- as.character(d[[group]])
    d[[group]] <- NULL
  } else if (!is.null(p) && group %in% names(p) && nrow(p) == nrow(d)) {
    d$.group <- as.character(p[[group]])
  } else {
    stop("The synthetic data have no column `", group, "` (in the responses or the personas).",
         call. = FALSE)
  }
  d
}

# ---- internal: slices ---------------------------------------------------

coverage_slices <- function(slices, real, items, group, target, model, n_slices,
                            within_group = FALSE) {
  notes <- character()
  if (slices == "item") return(coverage_item_slices(real, items))
  if (slices == "group") {
    if (!is.null(real)) {
      g <- real$.group[!is.na(real$.group)]
      lev <- sort(unique(g))
      t <- as.numeric(table(factor(g, levels = lev))) / length(g)
    } else {
      if (is.null(names(target)) || any(target < 0))
        stop("`target` must be a named vector of non-negative shares.", call. = FALSE)
      lev <- names(target)
      t <- as.numeric(target) / sum(target)
    }
    tab <- data.frame(slice = lev, item = "all", label = lev, column = lev, real = t,
                      stringsAsFactors = FALSE)
    return(list(type = "group", table = tab, levels = lev, display = "ratio", notes = notes,
                axis = if (is.null(real)) "Groups (target shares)" else "Groups"))
  }
  # score or theta
  if (slices == "theta") {
    if (is.null(model)) {
      model <- mirt::mirt(real[items], 1, verbose = FALSE)
    } else {
      check_single(model, "model"); check_unidim(model, "slices = \"theta\"")
      if (!setequal(item_names(model), items))
        stop("`model` must be fitted to the same items as the data.", call. = FALSE)
      model_items <- item_names(model)
      items <- model_items
    }
    score_fun <- function(d) {
      d <- d[items]
      keep <- rowSums(!is.na(d)) > 0
      out <- rep(NA_real_, nrow(d))
      if (any(keep)) {
        for (j in items) {
          extra <- setdiff(unique(stats::na.omit(d[[j]])), unique(stats::na.omit(real[[j]])))
          if (length(extra))
            stop("Synthetic answers to ", j, " use categories the real data never use (",
                 paste(extra, collapse = ", "), "), so theta cannot be scored.", call. = FALSE)
        }
        out[keep] <- mirt::fscores(model, response.pattern = as.matrix(d[keep, , drop = FALSE]),
                                   method = "EAP", verbose = FALSE)[, "F1"]
      }
      out
    }
    axis <- "Real test takers' theta (EAP), in slices of the real population"
  } else {
    score_fun <- function(d) {
      v <- rowSums(d[items])
      v
    }
    axis <- "Real test takers' total score, in slices of the real population"
  }
  real_score <- score_fun(real)
  if (anyNA(real_score))
    notes <- c(notes, sprintf("%d real respondent(s) with missing answers are left out of the %s slices.",
                              sum(is.na(real_score)), slices))
  grp <- if (!is.null(group)) real$.group else rep("all", nrow(real))
  ok <- !is.na(real_score) & !is.na(grp)
  real_score <- real_score[ok]; grp <- grp[ok]
  lev <- sort(unique(grp))
  if (!is.null(group) && n_slices * length(lev) > 40) {
    n_slices <- max(2L, floor(40 / length(lev)))
    notes <- c(notes, sprintf("With %d groups, each group is cut into %d slices so the strip stays readable.",
                              length(lev), n_slices))
  }
  cuts <- list(); tab <- list()
  for (g in lev) {
    sc <- real_score[grp == g]
    cut_g <- score_cuts(sc, n_slices)
    k <- score_assign(sc, cut_g)
    share <- tabulate(k, cut_g$n) / length(real_score)
    within <- tabulate(k, cut_g$n) / length(sc)
    hi <- round(100 * cumsum(within)); lo <- c(0, utils::head(hi, -1))
    lab <- sprintf("%d\u2013%d%%", lo, hi)
    lab[1] <- sprintf("Lowest %d%%", hi[1])
    lab[cut_g$n] <- sprintf("Highest %d%%", 100 - lo[cut_g$n])
    cuts[[g]] <- cut_g
    tab[[g]] <- data.frame(slice = paste(g, seq_len(cut_g$n), sep = "::"), item = g, label = lab,
                           column = seq_len(cut_g$n), real = if (within_group) within else share,
                           stringsAsFactors = FALSE)
  }
  tab <- do.call(rbind, tab)
  rownames(tab) <- NULL
  list(type = slices, table = tab, cuts = cuts, score = score_fun, grouped = !is.null(group),
       within = isTRUE(within_group), display = "ratio", notes = notes, axis = axis, levels = lev)
}

score_cuts <- function(x, n) {
  u <- sort(unique(x))
  if (length(u) <= n) {
    mids <- (u[-1] + u[-length(u)]) / 2
    return(list(breaks = mids, n = length(u)))
  }
  q <- unique(stats::quantile(x, probs = seq(0, 1, length.out = n + 1), names = FALSE))
  inner <- q[-c(1, length(q))]
  list(breaks = inner, n = length(inner) + 1L, left_open = TRUE)
}

score_assign <- function(x, cut) {
  findInterval(x, cut$breaks, left.open = isTRUE(cut$left_open)) + 1L
}

coverage_item_slices <- function(real, items) {
  cats <- lapply(items, function(j) sort(unique(stats::na.omit(real[[j]]))))
  names(cats) <- items
  binary <- all(vapply(cats, function(k) all(k %in% c(0, 1)), logical(1)))
  tab <- list()
  for (j in items) {
    v <- real[[j]][!is.na(real[[j]])]
    k <- if (binary) c(0, 1) else cats[[j]]
    tab[[j]] <- data.frame(slice = paste(j, k, sep = "::"), item = j, label = as.character(k),
                           column = seq_along(k), category = k,
                           real = vapply(k, function(c) mean(v == c), numeric(1)),
                           stringsAsFactors = FALSE)
  }
  tab <- do.call(rbind, tab)
  rownames(tab) <- NULL
  list(type = "item", table = tab, categories = cats, binary = binary,
       display = if (binary) "difference" else "ratio", notes = character(),
       axis = if (binary) "Items (real proportion correct in brackets)" else "Answer categories of each item",
       real_mean = vapply(items, function(j) mean(real[[j]], na.rm = TRUE), numeric(1)))
}

# ---- internal: shares, overlap, structure -------------------------------

coverage_shares <- function(def, d, items) {
  tab <- def$table
  if (def$type == "item") {
    share <- numeric(nrow(tab)); n <- numeric(nrow(tab))
    for (j in unique(tab$item)) {
      rows <- which(tab$item == j)
      v <- d[[j]][!is.na(d[[j]])]
      n[rows] <- length(v)
      share[rows] <- if (length(v)) vapply(tab$category[rows], function(c) mean(v == c), numeric(1)) else NA_real_
    }
    return(list(share = share, n = n))
  }
  if (def$type == "group") {
    g <- d$.group[!is.na(d$.group)]
    unknown <- setdiff(unique(g), def$levels)
    if (length(unknown))
      stop("Synthetic groups not in the real data or target: ",
           paste(utils::head(unknown, 5), collapse = ", "), ".", call. = FALSE)
    share <- as.numeric(table(factor(g, levels = def$levels))) / max(1, length(g))
    return(list(share = share, n = rep(length(g), nrow(tab))))
  }
  sc <- def$score(d)
  grp <- if (isTRUE(def$grouped)) d$.group else rep("all", nrow(d))
  ok <- !is.na(sc) & !is.na(grp)
  sc <- sc[ok]; grp <- grp[ok]
  unknown <- setdiff(unique(grp), def$levels)
  if (length(unknown))
    stop("Synthetic groups not in the real data: ", paste(utils::head(unknown, 5), collapse = ", "),
         ".", call. = FALSE)
  share <- numeric(nrow(tab)); n <- rep(length(sc), nrow(tab))
  for (g in def$levels) {
    rows <- which(tab$item == g)
    k <- score_assign(sc[grp == g], def$cuts[[g]])
    if (isTRUE(def$within)) n[rows] <- length(k)
    share[rows] <- tabulate(k, def$cuts[[g]]$n) / max(1, if (isTRUE(def$within)) length(k) else length(sc))
  }
  list(share = share, n = n)
}

coverage_overlap <- function(share, def) {
  tab <- def$table
  if (def$type == "item" || isTRUE(def$within)) {
    per <- tapply(pmin(share, tab$real), tab$item, sum)
    return(mean(per, na.rm = TRUE))
  }
  sum(pmin(share, tab$real), na.rm = TRUE)
}

coverage_item_overlap <- function(share, def) {
  tapply(pmin(share, def$table$real), def$table$item, sum)
}

coverage_cor <- function(d, method) {
  d <- as.data.frame(d)
  if (method == "pearson")
    return(suppressWarnings(stats::cor(d, use = "pairwise.complete.obs")))
  p <- ncol(d)
  r <- diag(p)
  for (i in seq_len(p - 1L)) for (j in (i + 1L):p) {
    x <- d[[i]]; y <- d[[j]]
    ok <- !is.na(x) & !is.na(y)
    v <- NA_real_
    if (sum(ok) > 2L && length(unique(x[ok])) > 1L && length(unique(y[ok])) > 1L) {
      v <- tryCatch(suppressWarnings(polycor::polychor(x[ok], y[ok])),
                    error = function(e) suppressWarnings(stats::cor(x[ok], y[ok])))
    }
    r[i, j] <- r[j, i] <- v
  }
  r
}

coverage_structure <- function(r_real, r_syn) {
  up <- upper.tri(r_real)
  dif <- abs(r_real[up] - r_syn[up])
  if (all(is.na(dif))) return(NA_real_)
  max(0, 1 - mean(dif, na.rm = TRUE))
}

coverage_flag <- function(cells, z, display) {
  se <- sqrt(cells$real * (1 - cells$real) / pmax(cells$n, 1))
  gap <- cells$synthetic - cells$real
  cells$flagged <- !is.na(gap) & abs(gap) > z * se + 1e-12
  if (display == "difference") {
    v <- pmax(-1, pmin(1, gap / 0.3))
  } else {
    r <- ifelse(cells$real <= 0 & cells$synthetic <= 0, 0,
                ifelse(cells$real <= 0, 2, ifelse(cells$synthetic <= 0, -2,
                       log2(cells$synthetic / cells$real))))
    v <- pmax(-1, pmin(1, r / 2))
  }
  cells$fill <- ifelse(cells$flagged, v, 0)
  cells$fill[is.na(cells$fill)] <- 0
  as_tbl(cells)
}

coverage_summary <- function(att, blend_test = NULL) {
  models <- unique(att$model)
  rows <- lapply(models, function(m) {
    a <- att[att$model == m, ]
    if (m == "Best Blend" && !is.null(blend_test)) a <- a[a$attempt %in% blend_test, ]
    f <- function(v) if (all(is.na(v))) c(NA_real_, NA_real_, NA_real_) else
      c(mean(v, na.rm = TRUE), min(v, na.rm = TRUE), max(v, na.rm = TRUE))
    o <- f(a$overlap); s <- f(a$structure)
    data.frame(model = m, attempts = nrow(a),
               overlap_overall = o[1], overlap_lowest = o[2], overlap_highest = o[3],
               structure_overall = s[1], structure_lowest = s[2], structure_highest = s[3],
               stringsAsFactors = FALSE)
  })
  as_tbl(do.call(rbind, rows))
}

simplex_grid <- function(k, step) {
  n <- round(1 / step)
  rec <- function(k, n) {
    if (k == 1L) return(matrix(n, 1, 1))
    do.call(rbind, lapply(0:n, function(i) cbind(i, rec(k - 1L, n - i))))
  }
  g <- rec(k, n) / n
  unname(g)
}

blend_pool <- function(syn, models, a, w, items) {
  sets <- lapply(models, function(m) syn[[m]][[a]][items])
  N <- min(vapply(sets, nrow, numeric(1)))
  k <- round(w * N)
  do.call(rbind, Map(function(d, ki) {
    if (ki <= 0) return(d[0, , drop = FALSE])
    d[sample.int(nrow(d), ki, replace = ki > nrow(d)), , drop = FALSE]
  }, sets, k))
}

coverage_range <- function(v) {
  if (length(v) == 1L) return(as.character(v))
  if (all(diff(v) == 1L)) sprintf("%d to %d", min(v), max(v)) else paste(v, collapse = ", ")
}

# ---- internal: drawing --------------------------------------------------

coverage_pages <- function(x, order, items_per_plot, max_columns) {
  def <- x$slices
  items <- unique(def$table$item)
  width <- if (isTRUE(def$binary)) stats::setNames(rep(1L, length(items)), items) else
    table(def$table$item)[items]
  ord <- switch(order,
    original = items,
    difficulty = items[order(-def$real_mean[items])],
    worst = {
      cl <- x$cells[x$cells$model != "Best Blend", ]
      per <- tapply(pmin(cl$synthetic, cl$real), list(cl$item, paste(cl$model, cl$attempt)), sum)
      items[order(rowMeans(per[items, , drop = FALSE], na.rm = TRUE))]
    })
  pages <- list(); cur <- character(); used <- 0
  for (j in ord) {
    wj <- as.numeric(width[[j]])
    full <- if (!is.null(items_per_plot)) length(cur) >= items_per_plot else used + wj > max_columns
    if (length(cur) && full) {
      pages[[length(pages) + 1L]] <- cur
      cur <- character(); used <- 0
    }
    cur <- c(cur, j); used <- used + wj
  }
  if (length(cur)) pages[[length(pages) + 1L]] <- cur
  pages
}

plot_coverage <- function(x, items, page, n_pages, before, title, subtitle) {
  def <- x$slices
  item_mode <- def$type == "item"
  binary <- isTRUE(def$binary)
  att <- as.data.frame(x$attempts)
  models <- unique(att$model)
  n_att <- tapply(att$attempt, att$model, max)[models]
  cells <- as.data.frame(x$cells)
  if (item_mode) {
    cells <- cells[cells$item %in% items, ]
    if (binary) cells <- cells[cells$category == 1, ]
    cells$item <- factor(cells$item, levels = items)
  } else if (isTRUE(def$grouped)) {
    cells$item <- factor(cells$item, levels = def$levels)
  }

  strip_lab <- vapply(models, function(m) {
    if (m == "Best Blend" && !is.null(x$blend)) paste0(m, "\n", x$blend$recipe)
    else paste0(m, "\n", n_att[[m]], if (n_att[[m]] == 1) " attempt" else " attempts")
  }, character(1))
  cells$model <- factor(cells$model, levels = models, labels = strip_lab)

  pal <- c("#c0302b", "#f0a09a", "#f0efec", "#86b6ef", "#1c5cab")
  if (binary || def$display == "difference") {
    brk <- c(-1, -0.5, 0, 0.5, 1)
    lab <- c("\u221230 pts", "\u221215", "match", "+15", "+30 pts")
  } else {
    brk <- c(-1, -0.5, 0, 0.5, 1)
    lab <- c("\u00bc\u00d7", "\u00bd\u00d7", "match", "2\u00d7", "4\u00d7")
  }
  cells$slice <- factor(cells$slice, levels = def$table$slice)
  x_lab <- stats::setNames(def$table$label, def$table$slice)
  # many score or theta slices (for example deciles within groups) get angled labels
  angled <- !item_mode && (isTRUE(def$grouped) || length(x_lab) > 12)
  if (!item_mode && !angled) x_lab <- gsub(" ", "\n", x_lab)
  p <- ggplot2::ggplot(cells, ggplot2::aes(x = slice, y = attempt, fill = fill)) +
    ggplot2::geom_tile(width = 0.92, height = 0.84) +
    ggplot2::scale_fill_gradientn(colours = pal, limits = c(-1, 1), breaks = brk, labels = lab,
                                  name = NULL) +
    ggplot2::scale_y_reverse(expand = c(0, 0.1)) +
    ggplot2::guides(fill = ggplot2::guide_colourbar(barwidth = 12, barheight = 0.6))
  if (binary) {
    p <- p + ggplot2::facet_grid(model ~ item, scales = "free", space = "free", switch = "y",
                                 labeller = ggplot2::labeller(item = function(v) sprintf(
                                   "%s (%.2f)", v, def$real_mean[v]))) +
      ggplot2::scale_x_discrete(breaks = NULL, expand = c(0, 0.5))
  } else if (item_mode || isTRUE(def$grouped)) {
    p <- p + ggplot2::facet_grid(model ~ item, scales = "free", space = "free", switch = "y") +
      ggplot2::scale_x_discrete(labels = x_lab, position = "top", expand = c(0, 0.5))
  } else {
    p <- p + ggplot2::facet_grid(model ~ ., scales = "free_y", space = "free_y", switch = "y") +
      ggplot2::scale_x_discrete(labels = x_lab, position = "top", expand = c(0, 0.5))
  }
  p <- p + ggplot2::labs(x = NULL, y = NULL, caption = def$axis) +
    theme_synthcheck() +
    ggplot2::theme(panel.grid = ggplot2::element_blank(),
                   axis.text.y = ggplot2::element_blank(),
                   strip.placement = "outside",
                   strip.text.y.left = ggplot2::element_text(angle = 0, hjust = 1, face = "bold"),
                   strip.text.x = if (binary) ggplot2::element_text(angle = 90, hjust = 0, vjust = 0.5)
                                  else ggplot2::element_text(hjust = 0.5),
                   plot.caption = ggplot2::element_text(hjust = 0.5, colour = "grey30"),
                   legend.position = "bottom", legend.justification = "right",
                   panel.spacing.y = ggplot2::unit(0.6, "lines"),
                   panel.spacing.x = ggplot2::unit(0.35, "lines"))
  if (angled)
    p <- p + ggplot2::theme(axis.text.x.top = ggplot2::element_text(angle = 45, hjust = 0, vjust = 0,
                                                                    size = 8))

  # numbers on the right
  s <- as.data.frame(x$summary)
  s$model <- factor(s$model, levels = models, labels = strip_lab)
  pct <- function(v) ifelse(is.na(v), "n/a", sprintf("%.0f%%", 100 * v))
  n_by <- n_att[match(as.character(x$summary$model), models)]
  num <- rbind(
    data.frame(model = s$model, x = 0, y = 0.5 + 0.22 * n_by, size = 4.6, face = "bold",
               label = paste0("Overall: ", pct(s$overlap_overall))),
    data.frame(model = s$model, x = 0, y = 0.5 + 0.48 * n_by, size = 3.2, face = "plain",
               label = paste0("Lowest: ", pct(s$overlap_lowest))),
    data.frame(model = s$model, x = 0, y = 0.5 + 0.66 * n_by, size = 3.2, face = "plain",
               label = paste0("Highest: ", pct(s$overlap_highest))))
  has_structure <- any(!is.na(s$structure_overall))
  if (has_structure) num <- rbind(num,
    data.frame(model = s$model, x = 1, y = 0.5 + 0.22 * n_by, size = 4.6, face = "bold",
               label = paste0("Overall: ", pct(s$structure_overall))),
    data.frame(model = s$model, x = 1, y = 0.5 + 0.48 * n_by, size = 3.2, face = "plain",
               label = paste0("Lowest: ", pct(s$structure_lowest))),
    data.frame(model = s$model, x = 1, y = 0.5 + 0.66 * n_by, size = 3.2, face = "plain",
               label = paste0("Highest: ", pct(s$structure_highest))))
  # invisible points keep each panel's height equal to the strip's
  span <- data.frame(model = rep(factor(strip_lab, levels = strip_lab), each = 2), x = 0,
                     y = c(rbind(rep(0.6, length(models)), n_att + 0.4)))
  ov_name <- if (item_mode) "Item Overlap" else "Overlap"
  right <- ggplot2::ggplot(num, ggplot2::aes(x = x, y = y)) +
    ggplot2::geom_blank(data = span) +
    ggplot2::geom_text(ggplot2::aes(label = label, size = size, fontface = face), hjust = 0,
                       colour = "grey15") +
    ggplot2::scale_size_identity() +
    ggplot2::scale_y_reverse(expand = c(0, 0.1)) +
    ggplot2::scale_x_continuous(limits = c(0, if (has_structure) 1.9 else 0.9),
                                breaks = if (has_structure) c(0, 1) else 0,
                                labels = if (has_structure) c(ov_name, "Structure") else ov_name,
                                position = "top", expand = c(0, 0)) +
    ggplot2::facet_grid(model ~ ., scales = "free_y", space = "free_y") +
    ggplot2::labs(x = NULL, y = NULL) +
    ggplot2::theme_void(base_size = 11) +
    ggplot2::theme(strip.text = ggplot2::element_blank(),
                   axis.text.x.top = ggplot2::element_text(face = "bold", hjust = 0, size = 11,
                                                           margin = ggplot2::margin(b = 6)),
                   panel.spacing.y = ggplot2::unit(0.6, "lines"))
  if (item_mode) {
    right <- right + ggplot2::theme(plot.margin = ggplot2::margin(t = 0, l = 8))
  }

  # notes under the figure
  ov_def <- switch(def$type,
    item = if (binary) sprintf("How closely each item's proportion correct matches the real one (100%% = identical), averaged over all %d items.", length(x$settings$items))
           else sprintf("The share of synthetic answers that fall in the same category as real answers would, averaged over all %d items.", length(x$settings$items)),
    group = "The share of synthetic respondents in the same groups as the real (or target) population (100% = the same mix).",
    if (isTRUE(def$within)) sprintf("Within each group, the share of synthetic respondents who land in the same slices as real respondents of that group, averaged over the %d groups.", length(def$levels))
    else "The share of synthetic respondents who land in the same slices as real respondents (100% = the same mix as the real data).")
  lines <- c(sprintf('bold("%s:")~"%s"', ov_name, coverage_plotmath(ov_def)))
  if (has_structure) lines <- c(lines, sprintf('bold("Structure:")~"%s"', coverage_plotmath(
    sprintf("How closely the correlations between items match the real ones (%s correlations; 100%% = identical).",
            if (x$settings$cor == "pearson") "Pearson" else x$settings$cor))))
  lines <- c(lines, sprintf('"%s"', coverage_plotmath(paste0(
    if (has_structure) "In both columns, " else "",
    "Overall is the mean over the attempts; Lowest and Highest are the worst and best attempt."))))
  if (!is.null(x$blend) && isTRUE(x$blend$holdout))
    lines <- c(lines, sprintf('bold("Best Blend:")~"%s"', coverage_plotmath(sprintf(
      "Recipe chosen on attempts %s; its numbers come from attempts %s.",
      coverage_range(x$blend$train), coverage_range(x$blend$test)))))
  foot <- ggplot2::ggplot() +
    ggplot2::annotate("text", x = 0, y = -seq_along(lines), label = lines, parse = TRUE,
                      hjust = 0, size = 3.3, colour = "grey20") +
    ggplot2::scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) +
    ggplot2::scale_y_continuous(limits = c(-length(lines) - 0.5, -0.5)) +
    ggplot2::theme_void()

  if (is.null(title)) title <- switch(def$type,
    item = if (binary) "Does each LLM get the same items right and wrong as real people?"
           else "Does each LLM use the answer categories the way real respondents do?",
    group = "Does each LLM produce the real mix of groups?",
    "Where does each LLM put its synthetic respondents in the real population?")
  if (is.null(subtitle)) {
    subtitle <- if (binary) "Blue: Synthetic respondents answer correctly too often.  Red: Too rarely."
                else "Blue: Too many synthetic respondents (or answers) there.  Red: Too few."
    subtitle <- paste0(subtitle, sprintf("  Pale: About right, or within what a real sample of the same size would show by chance (%d%%).",
                                         round(100 * x$settings$conf)))
    if (n_pages > 1L) {
      all_items <- length(unique(def$table$item))
      subtitle <- paste0(subtitle, sprintf("\nItems %d to %d of %d (page %d of %d).", before + 1L,
                                           before + length(items), all_items, page, n_pages))
    }
  }
  widths <- ggplot2::unit(c(1, if (has_structure) 7 else 3.6), c("null", "cm"))
  out <- patchwork::wrap_plots(p, right, nrow = 1, widths = widths) /
    foot + patchwork::plot_layout(heights = c(sum(n_att) + 2, 0.95 * length(lines))) +
    patchwork::plot_annotation(title = title, subtitle = subtitle,
                               theme = ggplot2::theme(
                                 plot.title = ggplot2::element_text(face = "bold", size = 14),
                                 plot.subtitle = ggplot2::element_text(colour = "grey30", size = 9.5)))
  out
}

coverage_plotmath <- function(s) gsub('"', "'", s, fixed = TRUE)
