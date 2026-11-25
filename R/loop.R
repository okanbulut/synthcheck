# The item-revision loop: Write items, answer them with synthetic respondents,
# check them, revise them, and log every step, until a stopping rule passes
# or a round cap is reached.

#' Describe the construct for an item-revision loop
#'
#' `loop_construct()` holds what an item writer needs to know about the
#' scale being built: The construct, its subscales, how many items to write
#' and the response scale. [revision_loop()] passes it to the item writer and
#' the reviser, and uses `scale`, `labels` and `instructions` to build the
#' [sc_instrument()] that synthetic respondents answer.
#'
#' @param name a short name for the construct, for example `"Honesty-Humility"`.
#' @param definition the definition of the construct, in a sentence or two.
#' @param scales optional subscales: A named character vector, with the
#'   short names (used as `scale` in the item table) as names and their
#'   definitions as values. `NULL` makes one scale named after `name`.
#' @param n_per_scale number of items to write for each scale.
#' @param reverse_share share of reverse-keyed items to aim for.
#' @param population who will answer the items, for example `"adults in
#'   Canada"`.
#' @param scale,labels,instructions the response scale, its labels and the
#'   instructions, as in [sc_instrument()].
#' @param notes optional further guidance for the item writer and reviser,
#'   such as a style guide or a reading level.
#' @param criterion optional stopping rule, a [loop_criterion()], that
#'   [revision_loop()] uses for this construct unless it is given another.
#' @param single_scale are the `scales` content domains of one scale? With
#'   `TRUE`, the items are written and revised domain by domain (and each
#'   item keeps its domain in `scale`), but the checks of [revision_loop()]
#'   treat all items as one scale: One IRT model, one alpha and one
#'   dimension. Use [loop_criterion()] with `min_items` and `min_total` to
#'   require that every domain stays in the scale.
#' @return An object of class `sc_construct_spec`.
#' @seealso [revision_loop()], [loop_builtin_construct()]
#' @examples
#' loop_construct("Honesty-Humility",
#'                "Sincerity, fairness, greed avoidance and modesty.",
#'                scales = c(sincerity = "Not manipulating others for personal gain.",
#'                           fairness = "Not cheating or stealing."),
#'                n_per_scale = 4, scale = c(1, 5))
#' @export
loop_construct <- function(name, definition = NULL, scales = NULL, n_per_scale = 6,
                           reverse_share = 1 / 3, population = NULL, scale = c(1, 5),
                           labels = NULL, instructions = sc_default_instructions, notes = NULL,
                           criterion = NULL, single_scale = FALSE) {
  if (!is.character(name) || length(name) != 1L || !nzchar(name))
    stop("`name` must be one non-empty string.", call. = FALSE)
  if (is.null(scales)) scales <- stats::setNames(definition %||% name, lp_id(name))
  if (!is.character(scales) || is.null(names(scales)) || any(!nzchar(names(scales))))
    stop("`scales` must be a named character vector (short names as names).", call. = FALSE)
  if (!is.numeric(n_per_scale) || n_per_scale < 1)
    stop("`n_per_scale` must be at least 1.", call. = FALSE)
  if (!is.null(criterion) && !is.function(criterion))
    stop("`criterion` must be made with loop_criterion().", call. = FALSE)
  if (!is.numeric(reverse_share) || reverse_share < 0 || reverse_share > 1)
    stop("`reverse_share` must be between 0 and 1.", call. = FALSE)
  if (!is.logical(single_scale) || length(single_scale) != 1L || is.na(single_scale))
    stop("`single_scale` must be TRUE or FALSE.", call. = FALSE)
  ins <- sc_instrument("x", scale = scale, labels = labels, instructions = instructions)
  structure(list(name = name, definition = definition, scales = scales,
                 n_per_scale = as.integer(n_per_scale), reverse_share = reverse_share,
                 population = population, scale = c(ins$min, ins$max), labels = ins$labels,
                 instructions = instructions, notes = notes, criterion = criterion,
                 single_scale = single_scale),
            class = "sc_construct_spec")
}

#' Ready-made constructs for the item-revision loop
#'
#' `loop_builtin_construct()` returns a [loop_construct()] that is ready to
#' use as the target of [revision_loop()].
#'
#' **`"financial_wellbeing"`.** Financial well-being as defined by the
#' Consumer Financial Protection Bureau (2015), with its four elements as
#' scales:
#'
#' - `control`: Control over one's finances: Paying bills on time, not
#'   having unmanageable debt and being able to make ends meet.
#' - `cushion`: A financial cushion against unexpected expenses and
#'   emergencies, such as savings, health insurance, good credit and friends
#'   or family who can help.
#' - `goals`: Financial goals, such as paying off student loans or saving for
#'   retirement, and being on track to meet them.
#' - `freedom`: Being able to make choices that allow one to enjoy life, such
#'   as a vacation, a meal out, going back to school or working less to spend
#'   time with family.
#'
#' Its stopping rule adds two parts to the defaults of [loop_criterion()]:
#' A marginal reliability of at least 0.80 in every scale (from [loop_irt()])
#' and parallel analysis finding four dimensions, one per scale.
#'
#' With `single_scale = TRUE`, the four parts are content domains of one
#' financial well-being scale. The stopping rule is then: No failing items,
#' alpha and marginal reliability of at least .80, one dimension, at most 5%
#' careless respondents, at least 10 items, and every domain kept.
#'
#' @param name the construct: `"financial_wellbeing"`.
#' @param ... arguments of [loop_construct()] that replace the defaults, for
#'   example `n_per_scale`, `population`, `scale` or `single_scale`.
#' @return An object of class `sc_construct_spec`.
#' @references Consumer Financial Protection Bureau. (2015). *Financial
#'   well-being: The goal of financial education*. Washington, DC: CFPB.
#' @seealso [loop_construct()], [revision_loop()]
#' @examples
#' loop_builtin_construct("financial_wellbeing")
#' loop_builtin_construct("financial_wellbeing", n_per_scale = 8, population = "adults in Canada")
#' # one scale that covers the four domains
#' loop_builtin_construct("financial_wellbeing", single_scale = TRUE)
#' @export
loop_builtin_construct <- function(name = "financial_wellbeing", ...) {
  name <- match.arg(name)
  args <- switch(name, financial_wellbeing = list(
    name = "Financial well-being",
    definition = paste(
      "A state in which a person can fully meet current and ongoing financial obligations,",
      "can feel secure in their financial future, and is able to make choices that allow",
      "them to enjoy life."),
    scales = c(
      control = paste(
        "Having control over one's finances: Being able to pay bills on time, not having",
        "unmanageable debt, and being able to make ends meet."),
      cushion = paste(
        "Having a financial cushion against unexpected expenses and emergencies: Savings,",
        "health insurance and good credit, and being able to rely on friends and family for",
        "financial help, which increase the capacity to absorb a financial shock."),
      goals = paste(
        "Having financial goals, such as paying off student loans within a certain number of",
        "years or saving a particular amount toward retirement, and being on track to meet",
        "them."),
      freedom = paste(
        "Being able to make choices that allow one to enjoy life, such as taking a vacation,",
        "enjoying a meal out now and then, going back to school for an advanced degree, or",
        "working less to spend more time with family.")),
    n_per_scale = 6, reverse_share = 1 / 3, population = "adults", scale = c(1, 5),
    criterion = loop_criterion(min = list(alpha = 0.8, own_scale = 0.9, marginal_rxx = 0.8),
                               factors = TRUE),
    notes = paste(
      "Items should describe the respondent's own situation, feelings or behaviour,",
      "not knowledge about finance. Avoid amounts of money and products tied to one country.")))
  dots <- list(...)
  if (isTRUE(dots$single_scale) && is.null(dots$criterion))
    args$criterion <- loop_criterion(min = list(alpha = 0.8, marginal_rxx = 0.8), factors = TRUE,
                                     min_items = 1, min_total = 10)
  args <- utils::modifyList(args, dots)
  do.call(loop_construct, args)
}

#' @export
print.sc_construct_spec <- function(x, ...) {
  cat(sprintf("Construct \"%s\": %d scale%s, %d items each, answers %d to %d.\n", x$name,
              length(x$scales), if (length(x$scales) == 1L) "" else "s", x$n_per_scale,
              x$scale[1], x$scale[2]))
  if (!is.null(x$definition)) cat(x$definition, "\n")
  if (isTRUE(x$single_scale)) cat("One scale; the parts below are its content domains.\n")
  for (s in names(x$scales)) cat(sprintf("  %s: %s\n", s, x$scales[[s]]))
  invisible(x)
}

#' Run an item-revision loop with synthetic respondents
#'
#' `revision_loop()` runs the cycle *write, answer, check, revise* and logs
#' every step. In each round, synthetic respondents answer the current items
#' ([generate_synthetic()]), an `evaluator` (the IRT checks of [loop_irt()]) and a `checker` (the data quality checks of
#' [loop_checker()]) flag problems, and a `criterion` ([loop_criterion()])
#' decides whether the items are polished. If they are not, a `reviser`
#' (a language model through [loop_reviser_llm()], or the rules-based
#' [loop_reviser_drop()]) proposes edits, and the next round starts with the
#' edited items. The loop stops when the criterion passes (`"polished"`),
#' when `max_rounds` is reached (`"max_rounds"`), when the reviser proposes
#' no change (`"stalled"`) or when a step fails (`"error"`, with the rounds
#' done so far kept).
#'
#' **The log.** Every round is recorded in seven tables that share `run_id`
#' and `round`: `runs`, `rounds`, `items`, `flags`, `stats`, `criteria` and
#' `edits`. [loop_log_schema()] lists every column. Each edit names the
#' checks it responds to (`cites`), whether those checks were in fact
#' flagged on that item (`cites_flagged`), whether they are gone in the next
#' round (`resolved`) and how much of the wording changed (`similarity`).
#' These columns link each revision to the diagnostic that prompted it and
#' to its outcome. With `output`, the tables are written as CSV files after
#' every round, so a stopped run keeps the rounds it finished, and
#' [read_loop()] reads one run or a folder of runs back.
#'
#' **Steps.** The steps are plain functions, so you can swap in your own
#' (or another package's):
#'
#' - `writer(construct, context)` returns the first items: A data frame with
#'   `item`, `scale`, `reverse` and `statement`. It is used only when
#'   `items` is `NULL`.
#' - `evaluator(responses, items, context)` and `checker(responses, items,
#'   context)` return a list with `flags` (a data frame with `item`,
#'   `scale`, `check`, `value`, `threshold`, `severity` (`"fail"` or
#'   `"warn"`) and `message`) and `stats` (a data frame with `item`,
#'   `scale`, `stat` and `value`; `item` is `NA` for scale-level values, and
#'   both are `NA` for values over all items).
#' - `reviser(items, flags, context)` returns a list with `edits` (a data
#'   frame with `item`, `action` (`"reword"`, `"rekey"`, `"drop"`, `"add"`,
#'   `"replace"` or `"keep"`), `statement`, `reverse`, `scale`, `rationale`
#'   and `cites`,
#'   the checks the edit responds to, separated by commas) and optionally
#'   `reasoning` (one note for the whole round). The loop applies the edits,
#'   so the log always matches the items.
#' - The writer and reviser may also return `usage`, a list with
#'   `input_tokens`, `output_tokens` and `cost`, which is logged.
#'
#' `context` is a list with `run_id`, `round`, `construct`, `instrument`,
#' `seed` and `history` (the log tables so far). The writer and reviser get
#' it so that they can see earlier edits and avoid undoing them.
#'
#' The same caveat as for the rest of the package applies: Items that look
#' polished to synthetic respondents still need a field test with people.
#' If the same model family writes and answers the items, "polished" may
#' only mean "easy for language models to agree with", so cross the writer
#' and respondent models and check the final items in a small real sample.
#'
#' @param construct a [loop_construct()].
#' @param items optional starting items: A data frame with `item`,
#'   `statement`, `scale` and `reverse` (as in [hexaco_items], where `trait`
#'   also works as `scale`). `NULL` asks the `writer` for them.
#' @param models the respondent model(s), as in [generate_synthetic()].
#' @param personas,attempts,respondents as in [generate_synthetic()]: Each
#'   round asks every model for `attempts` times `respondents` respondents
#'   per persona.
#' @param writer the item writer (see **Steps**), usually
#'   [loop_writer_llm()]. Needed when `items` is `NULL`.
#' @param evaluator the IRT checks; by default [loop_irt()]. `NULL` skips
#'   them.
#' @param checker the data quality checks; by default [loop_checker()].
#'   `NULL` skips them.
#' @param reviser the reviser: [loop_reviser_llm()] for a language model, or
#'   the default [loop_reviser_drop()], which only drops failing items, calls
#'   no model and is a useful baseline.
#' @param criterion the stopping rule, a [loop_criterion()]. By default the
#'   construct's own rule, if it has one (see [loop_builtin_construct()]),
#'   or else the defaults of [loop_criterion()].
#' @param max_rounds the largest number of rounds.
#' @param output optional folder: The log tables are written there after
#'   every round, and the responses of each round to `responses/`.
#' @param run_id a name for the run. `NULL` builds one from the construct and
#'   `seed`. Use one run id per replication when you run a design.
#' @param seed random seed. Round `r` generates its respondents with seed
#'   `1000 * seed + r`, so a run is repeatable and replications with
#'   different seeds draw different respondents.
#' @param cache the response cache, as in [generate_synthetic()].
#' @param progress print one line per round?
#' @param ... further arguments to [generate_synthetic()], such as
#'   `parallel` or `block_size`.
#' @return An object of class `sc_loop`: A list with the seven log tables,
#'   the final `items`, the `construct` and the `responses` of the last
#'   round. It has `print()`, `tidy()` (`table = "rounds"` by default) and
#'   `autoplot()` methods; [gg_loop()] draws it.
#' @seealso [loop_construct()], [loop_writer_llm()], [loop_irt()],
#'   [loop_checker()], [loop_criterion()], [loop_reviser_llm()],
#'   [loop_reviser_drop()], [loop_log_schema()], [read_loop()], [gg_loop()]
#' @examples
#' h <- hexaco_items[hexaco_items$facet %in% c("HSinc", "HFair"), ]
#' h$scale <- h$facet
#' con <- loop_construct("Honesty-Humility", scale = c(1, 7),
#'                       scales = c(HSinc = "Sincerity", HFair = "Fairness"))
#' # the mock provider answers at random, so every item fails and the
#' # rules-based reviser drops items until it cannot drop more
#' run <- revision_loop(con, h, sc_model("mock"), respondents = 40, max_rounds = 3,
#'                      evaluator = NULL, checker = loop_checker(n_pa = 5), cache = FALSE)
#' run
#' run$edits
#' gg_loop(run)
#' \dontrun{
#' # GPT-4.1 mini writes and revises, Claude Haiku answers, mirt checks
#' con <- loop_builtin_construct("financial_wellbeing", population = "adults in Canada")
#' writer <- sc_model("openai", "gpt-4.1-mini")
#' run <- revision_loop(con, models = sc_model("anthropic"), respondents = 200,
#'                      writer = loop_writer_llm(writer),
#'                      reviser = loop_reviser_llm(writer),
#'                      output = "loops/hh-seed1", seed = 1)
#' }
#' @export
revision_loop <- function(construct, items = NULL, models = sc_model("mock"), personas = NULL,
                          attempts = 1, respondents = 100, writer = NULL, evaluator = loop_irt(),
                          checker = loop_checker(), reviser = loop_reviser_drop(),
                          criterion = construct$criterion %||% loop_criterion(), max_rounds = 10, output = NULL,
                          run_id = NULL, seed = 1, cache = sc_cache(), progress = interactive(),
                          ...) {
  if (!inherits(construct, "sc_construct_spec"))
    stop("`construct` must be made with loop_construct().", call. = FALSE)
  if (is.null(items) && is.null(writer))
    stop("Give starting `items` or a `writer` that writes them.", call. = FALSE)
  for (f in c("writer", "evaluator", "checker", "reviser", "criterion")) {
    v <- get(f)
    if (!is.null(v) && !is.function(v)) stop(sprintf("`%s` must be a function.", f), call. = FALSE)
  }
  if (is.null(reviser)) stop("`reviser` must be a function.", call. = FALSE)
  max_rounds <- as.integer(max_rounds)
  if (is.na(max_rounds) || max_rounds < 1L) stop("`max_rounds` must be at least 1.", call. = FALSE)
  if (inherits(models, "sc_model")) models <- list(models)
  run_id <- run_id %||% sprintf("%s-seed%s", lp_id(construct$name), seed)
  cache <- sc_as_cache(cache)

  log <- lp_empty_log()
  run <- list(run_id = run_id, started = lp_now(), finished = NA_character_, status = "running",
              rounds = 0L, message = NA_character_, construct = construct$name,
              scales = paste(sprintf("%s: %s", names(construct$scales), construct$scales),
                             collapse = " | "),
              seed = seed, max_rounds = max_rounds,
              models = paste(vapply(models, `[[`, character(1), "name"), collapse = ", "),
              personas = if (is.null(personas)) 0L else nrow(sc_personas(personas)),
              attempts = as.integer(attempts), respondents = as.integer(respondents),
              writer = lp_label(writer, if (is.null(items)) "unnamed writer" else "given items"),
              evaluator = lp_label(evaluator, "none"), checker = lp_label(checker, "none"),
              reviser = lp_label(reviser, "unnamed reviser"),
              criterion = lp_label(criterion, "custom"),
              writer_reasoning = NA_character_,
              synthcheck_version = as.character(utils::packageVersion("synthcheck")),
              r_version = paste(R.version$major, R.version$minor, sep = "."))
  ctx <- list(run_id = run_id, round = 0L, construct = construct, instrument = NULL,
              seed = seed, history = log)
  pending_usage <- lp_usage(NULL)
  responses <- NULL
  status <- NULL

  step <- function(label, code) tryCatch(code, error = function(e)
    stop(sprintf("%s failed: %s", label, conditionMessage(e)), call. = FALSE))

  res <- tryCatch({
    if (is.null(items)) {
      w <- step("The writer", writer(construct, ctx))
      if (is.data.frame(w)) w <- list(items = w)
      items <- w$items
      run$writer_reasoning <- lp_chr1(w$reasoning)
      pending_usage <- lp_usage(w$usage)
    }
    items <- lp_items(items)
    prev <- NULL
    for (r in seq_len(max_rounds)) {
      t0 <- Sys.time()
      ctx$round <- r
      ins <- sc_instrument(as.data.frame(items[, c("item", "statement", "scale", "reverse")]),
                           scale = construct$scale, labels = construct$labels,
                           instructions = construct$instructions, name = construct$name)
      ctx$instrument <- ins
      gseed <- 1000 * seed + r
      cost <- tryCatch(attr(estimate_cost(ins, models, personas, attempts, respondents,
                                          seed = gseed, cache = cache), "total"),
                       error = function(e) NA_real_)
      responses <- step("Generating responses", generate_synthetic(
        ins, models, personas, attempts = attempts, respondents = respondents, seed = gseed,
        cache = cache, progress = FALSE, ...))
      out <- list()
      # one scale with content domains: The checks see all items as one scale
      check_items <- items
      if (isTRUE(construct$single_scale)) check_items$scale <- lp_id(construct$name)
      if (!is.null(checker)) out$quality <- step("The checker", lp_step_out(
        checker(responses, check_items, ctx), "quality"))
      if (!is.null(evaluator)) out$irt <- step("The evaluator", lp_step_out(
        evaluator(responses, check_items, ctx), "irt"))
      flags <- lp_bind(lapply(out, `[[`, "flags"), "flags")
      stats <- lp_bind(lapply(out, `[[`, "stats"), "stats")
      crit <- if (is.null(criterion)) lp_table(data.frame(), "criteria") else
        lp_table(step("The criterion", criterion(flags, stats, items, ctx)), "criteria")
      polished <- nrow(crit) > 0L && all(crit$pass %in% TRUE)

      key <- function(d) cbind(run_id = rep(run_id, nrow(d)), round = rep(r, nrow(d)), d)
      log$flags <- rbind(log$flags, lp_table(key(flags), "flags"))
      log$stats <- rbind(log$stats, lp_table(key(stats), "stats"))
      log$criteria <- rbind(log$criteria, lp_table(key(crit), "criteria"))
      log$items <- rbind(log$items, lp_table(key(lp_item_rows(items, prev, flags)), "items"))

      status <- if (polished) "polished" else if (r == max_rounds) "max_rounds" else NULL
      reasoning <- NA_character_
      usage <- pending_usage
      new_items <- items
      if (is.null(status)) {
        ctx$history <- log
        rv <- tryCatch(step("The reviser", reviser(items, flags, ctx)), error = function(e) e)
        if (inherits(rv, "error")) {
          # keep this round in the log: Its responses and checks are done
          status <- "error"
          run$message <- lp_sentence(conditionMessage(rv))
          rv <- list()
        }
        if (is.data.frame(rv)) rv <- list(edits = rv)
        reasoning <- lp_chr1(rv$reasoning)
        u <- lp_usage(rv$usage)
        usage <- mapply(function(a, b) if (is.na(a) && is.na(b)) NA_real_ else
          sum(a, b, na.rm = TRUE), usage, u, SIMPLIFY = FALSE)
        ap <- lp_apply_edits(items, lp_edits(rv$edits), r, flags)
        new_items <- ap$items
        log$edits <- rbind(log$edits, lp_table(key(ap$edits), "edits"))
        if (is.null(status) && !any(ap$edits$applied & ap$edits$action != "keep"))
          status <- "stalled"
      }
      pending_usage <- lp_usage(NULL)
      fail_items <- unique(flags$item[flags$severity == "fail" & !is.na(flags$item)])
      log$rounds <- rbind(log$rounds, lp_table(data.frame(
        run_id = run_id, round = r, n_items = nrow(items),
        n_flagged = length(unique(flags$item[!is.na(flags$item)])),
        n_failing = length(fail_items), n_flags = nrow(flags),
        n_criteria = nrow(crit), n_passed = sum(crit$pass %in% TRUE), polished = polished,
        n_respondents = nrow(responses),
        n_failed_calls = if (is.null(attr(responses, "log"))) 0L else nrow(attr(responses, "log")),
        respond_cost = cost, author_input_tokens = usage$input_tokens,
        author_output_tokens = usage$output_tokens, author_cost = usage$cost,
        seconds = as.numeric(difftime(Sys.time(), t0, units = "secs")),
        reasoning = reasoning, stop = status %||% NA_character_,
        stringsAsFactors = FALSE), "rounds"))
      log$edits <- lp_resolve(log$edits, log$flags)
      run$rounds <- r
      if (!is.null(status)) run$status <- status
      log$runs <- lp_table(as.data.frame(run, stringsAsFactors = FALSE), "runs")
      if (!is.null(output)) lp_write(log, responses, output, r)
      if (isTRUE(progress))
        message(sprintf("Round %d: %d items, %d failing, %d of %d criteria pass%s", r,
                        nrow(items), length(fail_items), sum(crit$pass %in% TRUE), nrow(crit),
                        if (is.null(status)) "" else sprintf(" (%s)", status)))
      if (!is.null(status)) break
      prev <- items
      items <- new_items
    }
    NULL
  }, error = function(e) e)

  if (inherits(res, "error")) {
    run$status <- "error"
    run$message <- lp_sentence(conditionMessage(res))
  }
  if (identical(run$status, "error"))
    warning(sprintf("The loop stopped in round %d: %s The rounds done so far are returned.",
                    ctx$round, run$message), call. = FALSE)
  run$finished <- lp_now()
  log$runs <- lp_table(as.data.frame(run, stringsAsFactors = FALSE), "runs")
  if (!is.null(output)) lp_write(log, NULL, output, NULL)
  structure(c(lapply(log, as_tbl),
              list(final_items = if (is.null(items)) NULL else as_tbl(items),
                   construct = construct, responses = responses)),
            class = "sc_loop")
}

#' Data quality checks for the item-revision loop
#'
#' `loop_checker()` makes the `checker` step of [revision_loop()]. It runs
#' [synthetic_pretest()] on the round's responses (all respondent models
#' pooled) and screens the respondents for answer patterns that make the
#' data unusable.
#'
#' **Item flags** (from [synthetic_pretest()], with its thresholds):
#' `low_variance`, `key`, `weak` and `other_scale` with severity `"fail"`,
#' and `redundant` with severity `"warn"`.
#'
#' **Respondent screening.** A respondent is unusable when the SD of their
#' answers is below `straightline_sd` (straight-lining), when the mean
#' keyed difference between their positive and reverse-keyed items is above
#' `inconsistency` times the width of the scale (they ignore the keys), or
#' when more than half of their answers are missing. The share of unusable
#' respondents is the stat `careless_share`, flagged (with `item` and
#' `scale` `NA`) when it is above `max_careless`. These are absolute rules,
#' because the respondents are compared with no real people here.
#'
#' **Stats:** `alpha`, `mean_r` and `n_factors` per scale; `own_scale`,
#' `reverse_ok`, `n_factors_all`, `scales` and `careless_share` over all
#' items; and per item `mean`, `sd`, `item_rest`, `max_r` and (with
#' `irt = TRUE`) `slope`.
#'
#' @param thresholds thresholds for the item flags, as in
#'   [synthetic_pretest()].
#' @param irt also fit graded response models in [synthetic_pretest()] for
#'   its `slope` flags? Off by default, because [loop_irt()] fits them as the
#'   evaluator.
#' @param n_pa number of random data sets for parallel analysis.
#' @param straightline_sd,inconsistency,max_careless the respondent
#'   screening rules (see above).
#' @param severity a named list that changes the severity of checks, for
#'   example `list(redundant = "fail")` so that near-duplicate items block
#'   the stopping rule.
#' @return A function for the `checker` argument of [revision_loop()].
#' @seealso [revision_loop()], [synthetic_pretest()]
#' @examples
#' ins <- sc_instrument(hexaco_items[hexaco_items$trait == "H", ], scale = c(1, 7))
#' syn <- generate_synthetic(ins, sc_model("mock"), respondents = 30, cache = FALSE)
#' chk <- loop_checker(n_pa = 5)
#' out <- chk(syn, ins$items, list(construct = loop_construct("H", scale = c(1, 7))))
#' head(out$flags)
#' @export
loop_checker <- function(thresholds = list(), irt = FALSE, n_pa = 20, straightline_sd = 0.5,
                         inconsistency = 0.5, max_careless = 0.05, severity = list()) {
  force(thresholds); force(irt); force(n_pa)
  lp_check_severity(severity)
  f <- function(responses, items, context) {
    lo <- context$construct$scale[1]; hi <- context$construct$scale[2]
    d <- as.data.frame(responses)
    d$.round <- "all"
    pt <- synthetic_pretest(d, items, by = ".round", scale_range = c(lo, hi), irt = irt,
                            n_pa = n_pa, thresholds = thresholds,
                            seed = context$seed %||% 1)
    thr <- pt$settings$thresholds
    it <- as.data.frame(pt$items)
    rules <- list(
      low_variance = list(value = "sd", thr = thr$sd, sev = "fail",
                          msg = "Barely varies: SD %.2f or top category share %.2f."),
      key = list(value = "item_rest", thr = 0, sev = "fail",
                 msg = "Runs against its scale: Keyed item-rest correlation %.2f."),
      weak = list(value = "item_rest", thr = thr$item_rest, sev = "fail",
                  msg = "Weak link to its scale: Item-rest correlation %.2f."),
      other_scale = list(value = "r_other", thr = NA_real_, sev = "fail",
                         msg = "Closer to another scale: r = %.2f with %s."),
      redundant = list(value = "max_r", thr = thr$redundant, sev = "warn",
                       msg = "Near-duplicate: r = %.2f with %s."))
    fl <- list()
    for (chk in names(rules)) {
      hit <- which(it[[chk]] %in% TRUE)
      if (!length(hit)) next
      ru <- rules[[chk]]
      msg <- switch(chk,
        low_variance = sprintf(ru$msg, it$sd[hit], it$top_share[hit]),
        other_scale = sprintf(ru$msg, it$r_other[hit], it$closest[hit]),
        redundant = sprintf(ru$msg, it$max_r[hit], it$twin[hit]),
        sprintf(ru$msg, it[[ru$value]][hit]))
      fl[[chk]] <- data.frame(item = it$item[hit], scale = it$scale[hit], check = chk,
                              value = it[[ru$value]][hit],
                              threshold = if (chk == "other_scale") it$item_rest[hit] else ru$thr,
                              severity = ru$sev, message = msg, stringsAsFactors = FALSE)
    }
    # respondents
    itm <- pt$settings$items
    X <- bh_matrix(d, itm)
    K <- bh_key(X, itm, lo, hi)
    sdv <- apply(X, 1, stats::sd, na.rm = TRUE)
    miss <- rowMeans(is.na(X))
    inc <- rep(NA_real_, nrow(X))
    if (any(itm$reverse) && any(!itm$reverse)) {
      inc <- vapply(seq_len(nrow(K)), function(i) {
        v <- vapply(unique(itm$scale), function(s) {
          pos <- K[i, itm$scale == s & !itm$reverse]; neg <- K[i, itm$scale == s & itm$reverse]
          if (!length(pos) || !length(neg) || all(is.na(pos)) || all(is.na(neg))) NA_real_ else
            abs(mean(pos, na.rm = TRUE) - mean(neg, na.rm = TRUE))
        }, numeric(1))
        if (all(is.na(v))) NA_real_ else mean(v, na.rm = TRUE)
      }, numeric(1))
    }
    bad <- (!is.na(sdv) & sdv < straightline_sd) | miss > 0.5 |
      (!is.na(inc) & inc > inconsistency * (hi - lo))
    share <- if (nrow(X)) mean(bad) else NA_real_
    if (!is.na(share) && share > max_careless)
      fl$careless <- data.frame(item = NA_character_, scale = NA_character_, check = "careless",
                                value = share, threshold = max_careless, severity = "fail",
                                message = sprintf(paste(
                                  "%.0f%% of respondents straight-line, ignore the keys or",
                                  "skip most items."), 100 * share),
                                stringsAsFactors = FALSE)
    sc <- as.data.frame(pt$scales)
    su <- as.data.frame(pt$summary)
    long <- function(df, cols, item = TRUE) do.call(rbind, lapply(cols, function(cl)
      data.frame(item = if (item) df$item else NA_character_, scale = df$scale, stat = cl,
                 value = as.numeric(df[[cl]]), stringsAsFactors = FALSE)))
    item_cols <- c("mean", "sd", "item_rest", "max_r", if (irt) "slope")
    stats <- rbind(
      long(it, item_cols),
      long(sc, c("alpha", "mean_r", "n_factors"), item = FALSE),
      data.frame(item = NA_character_, scale = NA_character_,
                 stat = c("own_scale", "reverse_ok", "n_factors_all", "scales", "careless_share"),
                 value = c(su$own_scale, su$reverse_ok, su$n_factors, su$scales, share),
                 stringsAsFactors = FALSE))
    list(flags = lp_resev(if (length(fl)) do.call(rbind, fl) else NULL, severity), stats = stats)
  }
  structure(f, label = paste0("synthcheck data quality (pretest and respondent screening",
                              lp_sev_label(severity), ")"))
}

#' The stopping rule of the item-revision loop
#'
#' `loop_criterion()` makes the `criterion` of [revision_loop()]: The rule
#' that says when items are polished. Decide it before the first run, so that
#' the number of rounds means something. Every part gives one row in the
#' `criteria` table, and the items are polished when every row passes.
#'
#' - `no_failing_items`: No item has a flag with severity `"fail"`, from
#'   any step.
#' - `min`: For each named stat, its lowest value (over scales or items)
#'   must be at least the target. The default asks for alpha of at least
#'   0.80 in every scale and at least 90% of items closest to their own scale.
#' - `max`: For each named stat, its highest value must be at most the
#'   target. The default allows at most 5% unusable respondents.
#' - `min_items`: Every scale keeps at least this many items. A scale of
#'   the construct that lost all its items counts as 0, so `min_items = 1`
#'   requires that every scale (or content domain) is still there.
#' - `min_total`: The items number at least this many in all.
#' - `factors`: Parallel analysis over all items finds as many dimensions as
#'   there are scales, or one dimension for a construct made with
#'   `single_scale = TRUE`.
#'
#' Stats from any step can be named, for example the test information of
#' [loop_irt()] (`min = list(marginal_rxx = 0.8)`). A stat that no
#' step reports fails, so that a missing check never passes quietly.
#'
#' @param no_failing_items require that no item has a failing flag?
#' @param min,max named lists of targets for stats (see above).
#' @param min_items smallest number of items per scale.
#' @param factors require the number of dimensions to match the number of
#'   scales?
#' @param min_total smallest number of items in all, or `NULL`.
#' @return A function for the `criterion` argument of [revision_loop()].
#' @seealso [revision_loop()]
#' @examples
#' loop_criterion()
#' loop_criterion(min = list(alpha = 0.7), factors = TRUE)
#' # one scale: Every domain kept, at least 10 items, one dimension
#' loop_criterion(min_items = 1, min_total = 10, factors = TRUE)
#' @export
loop_criterion <- function(no_failing_items = TRUE, min = list(alpha = 0.8, own_scale = 0.9),
                           max = list(careless_share = 0.05), min_items = 3, factors = FALSE,
                           min_total = NULL) {
  force(min); force(max)
  f <- function(flags, stats, items, context) {
    rows <- list()
    add <- function(name, value, target, pass) rows[[length(rows) + 1L]] <<- data.frame(
      criterion = name, value = value, target = target, pass = pass, stringsAsFactors = FALSE)
    if (no_failing_items) {
      n <- length(unique(flags$item[flags$severity == "fail" & !is.na(flags$item)]))
      add("no_failing_items", n, 0, n == 0)
    }
    for (s in names(min)) {
      v <- stats$value[stats$stat == s]
      v <- if (length(v) && any(!is.na(v))) min(v, na.rm = TRUE) else NA_real_
      add(paste0("min_", s), v, min[[s]], !is.na(v) && v >= min[[s]])
    }
    for (s in names(max)) {
      v <- stats$value[stats$stat == s]
      v <- if (length(v) && any(!is.na(v))) max(v, na.rm = TRUE) else NA_real_
      add(paste0("max_", s), v, max[[s]], !is.na(v) && v <= max[[s]])
    }
    con <- context$construct
    if (!is.null(min_items)) {
      # scales of the construct that lost every item count as 0
      sc <- unique(c(names(con$scales), items$scale))
      n <- min(table(factor(items$scale, levels = sc)))
      add("min_items", n, min_items, n >= min_items)
    }
    if (!is.null(min_total)) add("min_total", nrow(items), min_total, nrow(items) >= min_total)
    if (factors) {
      v <- stats$value[stats$stat == "n_factors_all"][1]
      k <- if (isTRUE(con$single_scale)) 1L else length(unique(items$scale))
      add("factors", v, k, !is.na(v) && v == k)
    }
    if (!length(rows)) return(NULL)
    do.call(rbind, rows)
  }
  lab <- c(if (no_failing_items) "no failing items",
           if (length(min)) sprintf("%s >= %s", names(min), unlist(min)),
           if (length(max)) sprintf("%s <= %s", names(max), unlist(max)),
           if (!is.null(min_items)) sprintf("at least %s items per scale", min_items),
           if (!is.null(min_total)) sprintf("at least %s items in all", min_total),
           if (factors) "dimensions match scales")
  structure(f, label = paste(lab, collapse = "; "))
}

#' A rules-based reviser: Drop failing items
#'
#' `loop_reviser_drop()` makes a `reviser` for [revision_loop()] that never
#' rewrites anything: It drops the items with failing flags, those with the
#' most flags first, as long as each scale keeps `min_items` items. It is the
#' baseline to compare a language-model reviser with: How far does deletion
#' alone get?
#'
#' @param min_items smallest number of items a scale keeps.
#' @param max_drop most items to drop per round. `Inf` drops every failing
#'   item it can.
#' @param severity which flags count: `"fail"`, or `c("fail", "warn")`.
#' @return A function for the `reviser` argument of [revision_loop()].
#' @seealso [revision_loop()]
#' @examples
#' # see revision_loop()
#' @export
loop_reviser_drop <- function(min_items = 3, max_drop = Inf, severity = "fail") {
  force(min_items); force(max_drop); force(severity)
  f <- function(items, flags, context) {
    fl <- flags[flags$severity %in% severity & !is.na(flags$item) & flags$item %in% items$item, ,
                drop = FALSE]
    if (!nrow(fl)) return(list(edits = NULL, reasoning = "No item has a failing flag to drop."))
    n <- sort(table(fl$item), decreasing = TRUE)
    keep_n <- table(items$scale)
    drop <- character(0)
    for (it in names(n)) {
      if (length(drop) >= max_drop) break
      s <- items$scale[items$item == it]
      if (keep_n[[s]] <= min_items) next
      keep_n[[s]] <- keep_n[[s]] - 1L
      drop <- c(drop, it)
    }
    if (!length(drop))
      return(list(edits = NULL, reasoning = sprintf(
        "Every scale with failing items is down to %d items, so nothing more is dropped.",
        min_items)))
    checks <- vapply(drop, function(i) paste(unique(fl$check[fl$item == i]), collapse = ","), "")
    list(edits = data.frame(item = drop, action = "drop", rationale = paste("Fails:", checks),
                            cites = checks, stringsAsFactors = FALSE),
         reasoning = sprintf("Dropped %d failing item%s, most flags first.", length(drop),
                             if (length(drop) == 1L) "" else "s"))
  }
  structure(f, label = sprintf("drop failing items (keep %d per scale)", min_items))
}

#' The log of the item-revision loop
#'
#' `loop_log_schema()` lists every table and column that [revision_loop()]
#' logs, with its type and meaning. The tables share `run_id` (one per run,
#' so replications can be stacked) and, except `runs`, `round`. With
#' `output`, each table is written as `<table>.csv`, and [read_loop()] reads
#' them back with these types.
#'
#' @param table optional table name to show only its columns.
#' @return A tibble with `table`, `column`, `type` and `description`.
#' @seealso [revision_loop()], [read_loop()]
#' @examples
#' loop_log_schema("edits")
#' @export
loop_log_schema <- function(table = NULL) {
  s <- lp_schema
  if (!is.null(table)) {
    bad <- setdiff(table, unique(s$table))
    if (length(bad)) stop("Unknown table: ", paste(bad, collapse = ", "), ". Tables: ",
                          paste(unique(s$table), collapse = ", "), ".", call. = FALSE)
    s <- s[s$table %in% table, , drop = FALSE]
  }
  as_tbl(s)
}

#' Read the log of item-revision loops
#'
#' `read_loop()` reads the CSV files that [revision_loop()] writes with
#' `output`. Give it the folder of one run, or a folder that holds one
#' folder per run (for example one per replication or design cell): The
#' tables of all runs are then stacked, with `run_id` telling them apart.
#'
#' @param path a run folder, or a folder of run folders.
#' @return An object of class `sc_loop` with the seven log tables (see
#'   [loop_log_schema()]).
#' @seealso [revision_loop()]
#' @examples
#' h <- hexaco_items[hexaco_items$facet %in% c("HSinc", "HFair"), ]
#' h$scale <- h$facet
#' con <- loop_construct("Honesty-Humility", scale = c(1, 7))
#' dir <- file.path(tempdir(), "loops")
#' for (s in 1:2) revision_loop(con, h, respondents = 30, max_rounds = 2, seed = s,
#'                              evaluator = NULL, checker = loop_checker(n_pa = 5),
#'                              output = file.path(dir, paste0("seed", s)), cache = FALSE)
#' runs <- read_loop(dir)
#' runs$runs[, c("run_id", "status", "rounds")]
#' loop_outcomes(runs)
#' @export
read_loop <- function(path) {
  if (!dir.exists(path)) stop("No folder ", path, ".", call. = FALSE)
  dirs <- if (file.exists(file.path(path, "runs.csv"))) path else {
    sub <- list.dirs(path, recursive = FALSE)
    sub[file.exists(file.path(sub, "runs.csv"))]
  }
  if (!length(dirs)) stop("No loop log (runs.csv) in ", path, ".", call. = FALSE)
  tabs <- unique(lp_schema$table)
  log <- stats::setNames(lapply(tabs, function(t) {
    parts <- lapply(dirs, function(d) {
      f <- file.path(d, paste0(t, ".csv"))
      if (!file.exists(f) || !length(readLines(f, n = 1L, warn = FALSE))) return(NULL)
      utils::read.csv(f, stringsAsFactors = FALSE, na.strings = "NA", check.names = FALSE,
                      colClasses = "character")
    })
    parts <- Filter(Negate(is.null), parts)
    d <- if (length(parts)) do.call(rbind, parts) else data.frame()
    as_tbl(lp_table(d, t, coerce = TRUE))
  }), tabs)
  structure(c(log, list(final_items = NULL, construct = NULL, responses = NULL)),
            class = "sc_loop")
}

#' Draw an item-revision loop
#'
#' `gg_loop()` shows one run at a glance: One row per item (grouped by
#' scale), one column per round. Red tiles are items with a failing flag,
#' pale tiles items without one, and a dot marks an item that was reworded,
#' rekeyed or added before that round. Dropped items stop. The title says
#' whether and when the items were polished.
#'
#' @param x a result of [revision_loop()] or [read_loop()].
#' @param run the `run_id` to draw; the first run by default.
#' @param title,subtitle plot titles. `NULL` uses the defaults.
#' @return A ggplot object.
#' @seealso [revision_loop()]
#' @examples
#' # see revision_loop()
#' @export
gg_loop <- function(x, run = NULL, title = NULL, subtitle = NULL) {
  if (!inherits(x, "sc_loop")) stop("`x` must be a result of revision_loop().", call. = FALSE)
  run <- run %||% x$runs$run_id[1]
  ru <- x$runs[x$runs$run_id == run, , drop = FALSE]
  if (!nrow(ru)) stop("No run ", run, ".", call. = FALSE)
  d <- as.data.frame(x$items[x$items$run_id == run, , drop = FALSE])
  if (!nrow(d)) stop("The run has no rounds.", call. = FALSE)
  ord <- unique(d[order(d$scale, d$round), c("scale", "item")])
  d$item <- factor(d$item, levels = rev(unique(ord$item)))
  d$scale <- factor(d$scale, levels = unique(ord$scale))
  d$kind <- factor(ifelse(d$failing, "Failing", "No failing flag"),
                   levels = c("Failing", "No failing flag"))
  d$mark <- d$change %in% c("reworded", "rekeyed", "added")
  if (is.null(title)) title <- switch(ru$status,
    polished = sprintf("Polished in round %d", ru$rounds),
    max_rounds = sprintf("Not polished after %d rounds", ru$rounds),
    stalled = sprintf("Stalled in round %d: The reviser proposed no change", ru$rounds),
    error = sprintf("Stopped by an error after round %d", ru$rounds),
    sprintf("%d rounds", ru$rounds))
  if (is.null(subtitle)) subtitle <- paste(
    "Red: A failing flag. Pale: None. Dots: Reworded, rekeyed or added before the round.",
    "\nWriter: ", ru$writer, ". Reviser: ", ru$reviser, ".", sep = "")
  ggplot2::ggplot(d, ggplot2::aes(x = factor(.data$round), y = .data$item)) +
    ggplot2::geom_tile(ggplot2::aes(fill = .data$kind), colour = "white", linewidth = 1) +
    ggplot2::geom_point(data = d[d$mark, , drop = FALSE],
                        ggplot2::aes(colour = ifelse(.data$failing, "white", "grey25")),
                        size = 1.6) +
    ggplot2::scale_colour_identity() +
    ggplot2::scale_fill_manual(values = c("Failing" = sc_palette[1],
                                          "No failing flag" = sc_palette[3]),
                               name = NULL, drop = FALSE) +
    ggplot2::facet_grid(rows = ggplot2::vars(.data$scale), scales = "free_y", space = "free_y") +
    ggplot2::scale_x_discrete(position = "top") +
    ggplot2::labs(x = "Round", y = NULL, title = title, subtitle = subtitle) +
    theme_synthcheck() +
    ggplot2::theme(panel.grid = ggplot2::element_blank(),
                   strip.text.y = ggplot2::element_text(angle = 0, hjust = 0))
}

#' Outcomes of item-revision loops
#'
#' `loop_outcomes()` turns the log of one or more runs into one row per run
#' with the outcomes of an experiment on the loop: How many rounds it took,
#' what the reviser did, whether its edits followed the evidence and worked,
#' how far the wording drifted, and what it cost.
#'
#' - `rounds_to_polish`: The round in which the stopping rule passed, `NA`
#'   if it never did.
#' - `cites_flagged`: Share of edits whose cited checks were flagged on the
#'   item (does the reasoning match the evidence?).
#' - `resolved`: Share of rewords and rekeys whose cited checks were gone in
#'   the next round (did the fix work?).
#' - `relapsed`: Share of resolved edits whose check came back on the same
#'   item in a later round (oscillation).
#' - `similarity`: Mean word overlap (Jaccard) between the first and the
#'   final wording of the items that survived, 1 for no change (drift).
#' - `cost`: Estimated cost of the respondents plus the reported cost of the
#'   writer and reviser, in dollars.
#'
#' @param x a result of [revision_loop()] or [read_loop()].
#' @return A tibble with one row per run.
#' @seealso [revision_loop()], [read_loop()]
#' @examples
#' # see read_loop()
#' @export
loop_outcomes <- function(x) {
  if (!inherits(x, "sc_loop")) stop("`x` must be a result of revision_loop().", call. = FALSE)
  rows <- lapply(x$runs$run_id, function(id) {
    ru <- x$runs[x$runs$run_id == id, , drop = FALSE]
    rd <- x$rounds[x$rounds$run_id == id, , drop = FALSE]
    it <- x$items[x$items$run_id == id, , drop = FALSE]
    ed <- x$edits[x$edits$run_id == id & x$edits$applied %in% TRUE, , drop = FALSE]
    fl <- x$flags[x$flags$run_id == id & !is.na(x$flags$item), , drop = FALSE]
    n <- function(a) sum(ed$action == a)
    share <- function(v) if (length(v) && any(!is.na(v))) mean(v, na.rm = TRUE) else NA_real_
    res <- ed[ed$resolved %in% TRUE, , drop = FALSE]
    relapse <- vapply(seq_len(nrow(res)), function(i) {
      ci <- lp_split(res$cites[i])
      if (!length(ci)) ci <- unique(fl$check[fl$round == res$round[i] & fl$item == res$item[i]])
      any(fl$item == res$item[i] & fl$round > res$round[i] + 1L & fl$check %in% ci)
    }, logical(1))
    first <- it[it$round == min(it$round), , drop = FALSE]
    last <- it[it$round == max(it$round), , drop = FALSE]
    both <- intersect(first$item, last$item)
    sim <- vapply(both, function(i) lp_jaccard(first$statement[first$item == i],
                                               last$statement[last$item == i]), numeric(1))
    pol <- rd$round[rd$polished %in% TRUE]
    data.frame(run_id = id, status = ru$status, rounds = ru$rounds,
               rounds_to_polish = if (length(pol)) min(pol) else NA_integer_,
               items_start = nrow(first), items_end = nrow(last),
               failing_start = if (nrow(rd)) rd$n_failing[1] else NA_integer_,
               failing_end = if (nrow(rd)) rd$n_failing[nrow(rd)] else NA_integer_,
               edits = nrow(ed), reworded = n("reword"), rekeyed = n("rekey"),
               dropped = n("drop"), added = n("add"), replaced = n("replace"),
               cites_flagged = share(ed$cites_flagged), resolved = share(ed$resolved),
               relapsed = if (nrow(res)) mean(relapse) else NA_real_,
               similarity = if (length(sim)) mean(sim) else NA_real_,
               cost = sum(rd$respond_cost, rd$author_cost, na.rm = TRUE),
               stringsAsFactors = FALSE)
  })
  as_tbl(do.call(rbind, rows))
}

#' @export
print.sc_loop <- function(x, ...) {
  runs <- x$runs
  if (nrow(runs) > 1L) {
    cat(sprintf("%d item-revision loops\n\n", nrow(runs)))
    print(as.data.frame(runs[, c("run_id", "status", "rounds", "writer", "reviser")]),
          row.names = FALSE)
    return(invisible(x))
  }
  cat(sprintf("Item-revision loop \"%s\": %s after %d round%s\n", runs$run_id, runs$status,
              runs$rounds, if (runs$rounds == 1L) "" else "s"))
  if (!is.na(runs$message)) cat("Error:", runs$message, "\n")
  cat(sprintf("Writer: %s\nEvaluator: %s\nChecker: %s\nReviser: %s\nStopping rule: %s\n\n",
              runs$writer, runs$evaluator, runs$checker, runs$reviser, runs$criterion))
  if (nrow(x$rounds)) {
    r <- as.data.frame(x$rounds[, c("round", "n_items", "n_failing", "n_passed", "n_criteria",
                                    "stop")])
    print(r, row.names = FALSE)
  }
  ed <- x$edits
  if (nrow(ed)) {
    tab <- table(ed$action[ed$applied])
    cat(sprintf("\nEdits: %s.\n", paste(sprintf("%d %s", tab, names(tab)), collapse = ", ")))
  }
  cat("\nThe tables `rounds`, `items`, `flags`, `stats`, `criteria` and `edits` hold the log;",
      "\nsee loop_log_schema().\n")
  invisible(x)
}

#' @exportS3Method generics::tidy
tidy.sc_loop <- function(x, table = "rounds", ...) {
  table <- match.arg(table, unique(lp_schema$table))
  x[[table]]
}

#' @exportS3Method ggplot2::autoplot
autoplot.sc_loop <- function(object, ...) gg_loop(object, ...)

# ---- internal -------------------------------------------------------------

lp_schema <- local({
  s <- function(table, ...) {
    x <- list(...)
    data.frame(table = table, column = names(x),
               type = vapply(x, `[[`, character(1), 1L),
               description = vapply(x, `[[`, character(1), 2L), stringsAsFactors = FALSE)
  }
  rbind(
    s("runs",
      run_id = c("character", "Name of the run."),
      started = c("character", "When the run started (UTC, ISO 8601)."),
      finished = c("character", "When the run ended (UTC, ISO 8601)."),
      status = c("character", "polished, max_rounds, stalled, error or running."),
      rounds = c("integer", "Number of rounds done."),
      message = c("character", "The error message, for status error."),
      construct = c("character", "Name of the construct."),
      scales = c("character", "The scales and their definitions."),
      seed = c("numeric", "Random seed of the run."),
      max_rounds = c("integer", "The round cap."),
      models = c("character", "Respondent models."),
      personas = c("integer", "Number of personas (0 for none)."),
      attempts = c("integer", "Attempts per model in each round."),
      respondents = c("integer", "Respondents per persona in each attempt."),
      writer = c("character", "Label of the item writer, or given items."),
      evaluator = c("character", "Label of the evaluator."),
      checker = c("character", "Label of the checker."),
      reviser = c("character", "Label of the reviser."),
      criterion = c("character", "The stopping rule."),
      writer_reasoning = c("character", "The writer's note on the first items."),
      synthcheck_version = c("character", "synthcheck version."),
      r_version = c("character", "R version.")),
    s("rounds",
      run_id = c("character", "Name of the run."),
      round = c("integer", "Round number, from 1."),
      n_items = c("integer", "Items answered in the round."),
      n_flagged = c("integer", "Items with any flag."),
      n_failing = c("integer", "Items with a failing flag."),
      n_flags = c("integer", "Flags of any kind, including scale and respondent flags."),
      n_criteria = c("integer", "Parts of the stopping rule."),
      n_passed = c("integer", "Parts of the stopping rule that pass."),
      polished = c("logical", "Did every part of the stopping rule pass?"),
      n_respondents = c("integer", "Synthetic respondents in the round."),
      n_failed_calls = c("integer", "Respondents with failed or invalid calls."),
      respond_cost = c("numeric", "Estimated dollars for the respondents (estimate_cost())."),
      author_input_tokens = c("numeric", "Input tokens of the writer (round 1) and the reviser (after the round)."),
      author_output_tokens = c("numeric", "Output tokens of the writer and the reviser."),
      author_cost = c("numeric", "Dollars for the writer and the reviser, when they report it."),
      seconds = c("numeric", "Time the round took."),
      reasoning = c("character", "The reviser's note on the round."),
      stop = c("character", "Why the loop stopped after this round, or NA.")),
    s("items",
      run_id = c("character", "Name of the run."),
      round = c("integer", "Round number."),
      item = c("character", "Item name. It stays the same when an item is reworded."),
      version = c("integer", "Version of the wording, from 1; up by one with every reword or rekey."),
      scale = c("character", "Scale of the item."),
      reverse = c("logical", "Is the item reverse-keyed?"),
      statement = c("character", "The wording answered in this round."),
      change = c("character", "Change before this round: first, kept, reworded, rekeyed or added."),
      flagged = c("logical", "Has the item any flag?"),
      failing = c("logical", "Has the item a failing flag?"),
      checks = c("character", "The checks that flag the item, separated by commas.")),
    s("flags",
      run_id = c("character", "Name of the run."),
      round = c("integer", "Round number."),
      source = c("character", "Step that raised the flag: quality (checker) or irt (evaluator)."),
      item = c("character", "Item flagged, or NA for a scale or the whole set."),
      scale = c("character", "Scale flagged, or NA."),
      check = c("character", "Name of the check, for example weak or misfit."),
      value = c("numeric", "Value that triggered the flag."),
      threshold = c("numeric", "Threshold it was compared with."),
      severity = c("character", "fail (counts against the stopping rule) or warn."),
      message = c("character", "The flag in plain language.")),
    s("stats",
      run_id = c("character", "Name of the run."),
      round = c("integer", "Round number."),
      source = c("character", "Step that computed the value."),
      item = c("character", "Item, or NA for a scale-level or overall value."),
      scale = c("character", "Scale, or NA for an overall value."),
      stat = c("character", "Name of the statistic, for example alpha or slope."),
      value = c("numeric", "Its value.")),
    s("criteria",
      run_id = c("character", "Name of the run."),
      round = c("integer", "Round number."),
      criterion = c("character", "Part of the stopping rule."),
      value = c("numeric", "Observed value."),
      target = c("numeric", "Target."),
      pass = c("logical", "Does it pass?")),
    s("edits",
      run_id = c("character", "Name of the run."),
      round = c("integer", "Round whose checks prompted the edit; it takes effect in the next round."),
      item = c("character", "Item edited (the new name for an added item)."),
      action = c("character", paste(
        "reword, rekey, drop, add, replace (the item leaves and a new one takes its place;",
        "`note` names it) or keep.")),
      old_statement = c("character", "Wording before the edit."),
      new_statement = c("character", "Wording after the edit."),
      old_reverse = c("logical", "Key before the edit."),
      new_reverse = c("logical", "Key after the edit."),
      scale = c("character", "Scale of the item."),
      rationale = c("character", "Why the reviser made the edit."),
      cites = c("character", "Checks the edit responds to, separated by commas."),
      cites_flagged = c("logical", "Were all cited checks flagged on this item in this round? NA when nothing is cited."),
      resolved = c("logical", "Are the cited checks (or, with none cited, all failing checks) gone from the item in the next round? NA for drops, adds and the last round."),
      similarity = c("numeric", "Word overlap (Jaccard) of the old and new wording, 1 for no change."),
      applied = c("logical", "Was the edit applied? FALSE for unknown items or a second edit of the same item."),
      note = c("character", "Why an edit was not applied.")))
})

lp_empty_log <- function() {
  tabs <- unique(lp_schema$table)
  stats::setNames(lapply(tabs, function(t) lp_table(data.frame(), t)), tabs)
}

# select, order and type the columns of a log table
lp_table <- function(d, table, coerce = TRUE) {
  sch <- lp_schema[lp_schema$table == table, , drop = FALSE]
  if (is.null(d)) d <- data.frame()
  d <- as.data.frame(d, stringsAsFactors = FALSE)
  n <- nrow(d)
  out <- lapply(seq_len(nrow(sch)), function(i) {
    cl <- sch$column[i]
    v <- if (cl %in% names(d)) d[[cl]] else rep(NA, n)
    if (!coerce) return(v)
    switch(sch$type[i],
           character = as.character(v),
           integer = as.integer(v),
           numeric = as.numeric(v),
           logical = as.logical(v))
  })
  out <- stats::setNames(out, sch$column)
  as.data.frame(out, stringsAsFactors = FALSE, check.names = FALSE)
}

lp_bind <- function(parts, what) {
  parts <- Filter(function(p) !is.null(p) && nrow(p), parts)
  if (!length(parts)) return(lp_table(data.frame(), what)[, setdiff(
    lp_schema$column[lp_schema$table == what], c("run_id", "round")), drop = FALSE])
  do.call(rbind, parts)
}

# check and standardise the output of an evaluator or checker
lp_step_out <- function(x, source) {
  if (is.null(x)) return(list(flags = NULL, stats = NULL))
  if (!is.list(x) || is.data.frame(x))
    stop("A check must return a list with `flags` and `stats`.", call. = FALSE)
  fl <- x$flags; st <- x$stats
  if (!is.null(fl) && nrow(as.data.frame(fl))) {
    fl <- as.data.frame(fl, stringsAsFactors = FALSE)
    if (!"check" %in% names(fl)) stop("`flags` needs a `check` column.", call. = FALSE)
    if (!"severity" %in% names(fl)) fl$severity <- "fail"
    fl$severity[is.na(fl$severity)] <- "fail"
    if (!all(fl$severity %in% c("fail", "warn")))
      stop("Flag `severity` must be \"fail\" or \"warn\".", call. = FALSE)
    fl$source <- source
    fl <- lp_table(fl, "flags")[, -(1:2), drop = FALSE]
  } else fl <- NULL
  if (!is.null(st) && nrow(as.data.frame(st))) {
    st <- as.data.frame(st, stringsAsFactors = FALSE)
    if (!all(c("stat", "value") %in% names(st)))
      stop("`stats` needs `stat` and `value` columns.", call. = FALSE)
    st$source <- source
    st <- lp_table(st, "stats")[, -(1:2), drop = FALSE]
  } else st <- NULL
  list(flags = fl, stats = st)
}

# the item table of the loop: item, scale, reverse, statement, version
lp_items <- function(items) {
  items <- as.data.frame(items, stringsAsFactors = FALSE)
  if (!nrow(items)) stop("There are no items.", call. = FALSE)
  if (!"scale" %in% names(items) && "trait" %in% names(items)) items$scale <- items$trait
  if (!"statement" %in% names(items)) {
    alt <- intersect(c("text", "stem", "wording"), names(items))
    if (length(alt)) items$statement <- items[[alt[1]]]
  }
  need <- setdiff(c("item", "statement"), names(items))
  if (length(need)) stop("The items need ", paste(sprintf("`%s`", need), collapse = " and "),
                         " columns.", call. = FALSE)
  if (!"scale" %in% names(items)) items$scale <- "scale"
  if (!"reverse" %in% names(items)) items$reverse <- FALSE
  items$reverse <- as.logical(items$reverse)
  items$reverse[is.na(items$reverse)] <- FALSE
  if (!"version" %in% names(items)) items$version <- 1L
  items$item <- as.character(items$item)
  items$scale <- as.character(items$scale)
  items$statement <- as.character(items$statement)
  if (anyDuplicated(items$item)) stop("Item names must be unique.", call. = FALSE)
  items[, c("item", "scale", "reverse", "statement", "version")]
}

lp_item_rows <- function(items, prev, flags) {
  fl <- flags[!is.na(flags$item), , drop = FALSE]
  change <- if (is.null(prev)) rep("first", nrow(items)) else {
    j <- match(items$item, prev$item)
    ifelse(is.na(j), "added",
           ifelse(items$reverse != prev$reverse[j], "rekeyed",
                  ifelse(items$statement != prev$statement[j], "reworded", "kept")))
  }
  data.frame(items[, c("item", "version", "scale", "reverse", "statement")], change = change,
             flagged = items$item %in% fl$item,
             failing = items$item %in% fl$item[fl$severity == "fail"],
             checks = vapply(items$item, function(i)
               paste(unique(fl$check[fl$item == i]), collapse = ","), ""),
             stringsAsFactors = FALSE)
}

lp_edits <- function(e) {
  if (is.null(e)) return(lp_table(data.frame(), "edits"))
  e <- as.data.frame(e, stringsAsFactors = FALSE)
  if (!nrow(e)) return(lp_table(data.frame(), "edits"))
  if (!"action" %in% names(e)) stop("The reviser's `edits` need an `action` column.", call. = FALSE)
  if (!"new_statement" %in% names(e) && "statement" %in% names(e)) e$new_statement <- e$statement
  if (!"new_reverse" %in% names(e) && "reverse" %in% names(e)) e$new_reverse <- e$reverse
  if ("cites" %in% names(e) && is.list(e$cites))
    e$cites <- vapply(e$cites, function(v) paste(as.character(unlist(v)), collapse = ","), "")
  e$action <- tolower(trimws(as.character(e$action)))
  lp_table(e, "edits")[, -(1:2), drop = FALSE]
}

lp_apply_edits <- function(items, e, round, flags) {
  e$applied <- rep(FALSE, nrow(e))
  e$note <- rep(NA_character_, nrow(e))
  done <- character(0)
  k <- 0L
  for (i in seq_len(nrow(e))) {
    a <- e$action[i]; id <- e$item[i]
    if (!a %in% c("reword", "rekey", "drop", "add", "keep", "replace")) {
      e$note[i] <- sprintf("Unknown action \"%s\".", a); next
    }
    if (a == "add") {
      s <- e$scale[i]
      if (is.na(s) || !nzchar(s)) s <- items$scale[1]
      if (is.na(e$new_statement[i]) || !nzchar(trimws(e$new_statement[i]))) {
        e$note[i] <- "An added item needs a statement."; next
      }
      if (is.na(id) || id %in% items$item || !grepl("^[A-Za-z][A-Za-z0-9_.]*$", id)) {
        repeat {
          k <- k + 1L
          id <- sprintf("%s.r%d.%d", lp_id(s), round, k)
          if (!id %in% items$item) break
        }
      }
      rev <- e$new_reverse[i]
      items <- rbind(items, data.frame(item = id, scale = s, reverse = !is.na(rev) && rev,
                                       statement = trimws(e$new_statement[i]), version = 1L,
                                       stringsAsFactors = FALSE))
      e$item[i] <- id; e$scale[i] <- s
      e$old_statement[i] <- NA; e$old_reverse[i] <- NA
      e$new_reverse[i] <- !is.na(rev) && rev
      e$applied[i] <- TRUE; done <- c(done, id)
      next
    }
    j <- match(id, items$item)
    if (is.na(j)) { e$note[i] <- "No such item."; next }
    if (id %in% done) { e$note[i] <- "The item was already edited in this round."; next }
    e$scale[i] <- items$scale[j]
    e$old_statement[i] <- items$statement[j]
    e$old_reverse[i] <- items$reverse[j]
    if (a == "drop") {
      items <- items[-j, , drop = FALSE]
      e$new_statement[i] <- NA; e$new_reverse[i] <- NA
    } else if (a == "replace") {
      # the item leaves and a new item takes its place in the same scale
      st <- e$new_statement[i]
      if (is.na(st) || !nzchar(trimws(st))) {
        e$note[i] <- "A replacement needs a new statement."; next
      }
      repeat {
        k <- k + 1L
        nid <- sprintf("%s.r%d.%d", lp_id(items$scale[j]), round, k)
        if (!nid %in% items$item) break
      }
      rv <- e$new_reverse[i]
      rv <- !is.na(rv) && rv
      items <- rbind(items[-j, , drop = FALSE],
                     data.frame(item = nid, scale = items$scale[j], reverse = rv,
                                statement = trimws(st), version = 1L, stringsAsFactors = FALSE))
      e$new_statement[i] <- trimws(st); e$new_reverse[i] <- rv
      e$note[i] <- sprintf("Replaced by %s.", nid)
      done <- c(done, nid)
    } else if (a == "keep") {
      e$new_statement[i] <- items$statement[j]; e$new_reverse[i] <- items$reverse[j]
    } else {
      st <- e$new_statement[i]
      if (is.na(st) || !nzchar(trimws(st))) {
        if (a == "reword") { e$note[i] <- "A reword needs a new statement."; next }
        st <- items$statement[j]
      }
      rv <- e$new_reverse[i]
      if (is.na(rv)) rv <- if (a == "rekey") !items$reverse[j] else items$reverse[j]
      items$statement[j] <- trimws(st)
      items$reverse[j] <- rv
      items$version[j] <- items$version[j] + 1L
      e$new_statement[i] <- items$statement[j]; e$new_reverse[i] <- rv
    }
    e$applied[i] <- TRUE
    done <- c(done, id)
  }
  e$similarity <- vapply(seq_len(nrow(e)), function(i)
    lp_jaccard(e$old_statement[i], e$new_statement[i]), numeric(1))
  e$similarity[e$action %in% c("drop", "add", "replace")] <- NA_real_
  fl <- flags[!is.na(flags$item), , drop = FALSE]
  e$cites_flagged <- vapply(seq_len(nrow(e)), function(i) {
    ci <- lp_split(e$cites[i])
    if (!length(ci) || e$action[i] == "add") return(NA)
    all(ci %in% fl$check[fl$item == e$item[i]])
  }, NA)
  rownames(items) <- NULL
  list(items = items, edits = e)
}

# did the cited checks go away in the next round?
lp_resolve <- function(edits, flags) {
  if (!nrow(edits)) return(edits)
  last <- if (nrow(flags)) max(flags$round) else 0L
  edits$resolved <- vapply(seq_len(nrow(edits)), function(i) {
    e <- edits[i, ]
    if (!isTRUE(e$applied) || !e$action %in% c("reword", "rekey", "keep")) return(NA)
    nxt <- e$round + 1L
    if (nxt > last) return(NA)
    now <- flags[flags$round == e$round & flags$item %in% e$item, , drop = FALSE]
    ci <- lp_split(e$cites)
    if (!length(ci)) ci <- unique(now$check[now$severity == "fail"])
    if (!length(ci)) return(NA)
    later <- flags$check[flags$round == nxt & flags$item %in% e$item]
    !any(ci %in% later)
  }, NA)
  edits
}

lp_write <- function(log, responses, output, round) {
  dir.create(output, showWarnings = FALSE, recursive = TRUE)
  for (t in names(log))
    utils::write.csv(log[[t]], file.path(output, paste0(t, ".csv")), row.names = FALSE)
  if (!is.null(responses) && !is.null(round)) {
    dir.create(file.path(output, "responses"), showWarnings = FALSE)
    utils::write.csv(as.data.frame(responses),
                     file.path(output, "responses", sprintf("round-%02d.csv", round)),
                     row.names = FALSE)
  }
  invisible(output)
}

lp_usage <- function(u) {
  g <- function(n) { v <- u[[n]]; if (is.null(v) || !length(v)) NA_real_ else sum(as.numeric(v)) }
  list(input_tokens = g("input_tokens"), output_tokens = g("output_tokens"), cost = g("cost"))
}

lp_label <- function(f, default) {
  if (is.null(f)) return(default)
  attr(f, "label") %||% default
}

lp_chr1 <- function(x) if (is.null(x) || !length(x)) NA_character_ else
  paste(as.character(unlist(x)), collapse = " ")

lp_split <- function(x) {
  if (is.null(x) || is.na(x) || !nzchar(x)) return(character(0))
  v <- trimws(strsplit(x, ",", fixed = TRUE)[[1]])
  v[nzchar(v)]
}

lp_words <- function(x) unique(strsplit(tolower(gsub("[^A-Za-z0-9' ]", " ", x)), "\\s+")[[1]])

lp_jaccard <- function(a, b) {
  if (is.na(a) || is.na(b)) return(NA_real_)
  wa <- setdiff(lp_words(a), ""); wb <- setdiff(lp_words(b), "")
  if (!length(union(wa, wb))) return(1)
  length(intersect(wa, wb)) / length(union(wa, wb))
}

lp_id <- function(x) {
  x <- gsub("[^A-Za-z0-9]+", "_", x)
  x <- gsub("^_+|_+$", "", x)
  if (!nzchar(x) || !grepl("^[A-Za-z]", x)) x <- paste0("s", x)
  x
}

lp_sentence <- function(x) if (grepl("[.!?]$", x)) x else paste0(x, ".")

lp_now <- function() format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")

# change the severity of named checks
lp_check_severity <- function(severity) {
  if (!is.list(severity) || (length(severity) && is.null(names(severity))) ||
      !all(unlist(severity) %in% c("fail", "warn")))
    stop("`severity` must be a named list of \"fail\" or \"warn\".", call. = FALSE)
  invisible(severity)
}
lp_resev <- function(fl, severity) {
  if (is.null(fl) || !nrow(fl) || !length(severity)) return(fl)
  hit <- fl$check %in% names(severity)
  fl$severity[hit] <- unlist(severity)[fl$check[hit]]
  fl
}
lp_sev_label <- function(severity) if (!length(severity)) "" else
  paste0("; ", paste(sprintf("%s %s", names(severity), ifelse(unlist(severity) == "fail", "fails",
                                                               "warns")), collapse = ", "))
