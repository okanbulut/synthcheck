# Cognitive interviews with language models playing personas.

sc_iv_stages <- c("comprehension", "retrieval", "judgement", "response", "sensitivity")

sc_iv_stage_names <- c(comprehension = "Comprehension", retrieval = "Retrieval",
                       judgement = "Judgement", response = "Response mapping",
                       sensitivity = "Sensitivity")

#' Probes for cognitive interviews
#'
#' **Experimental.** `sc_probes()` returns the scripted verbal probes that
#' [cognitive_interview()] asks after the think-aloud, one row per probe.
#' With no arguments it gives the default protocol: Two comprehension probes
#' (paraphrase and terms), then one probe each for retrieval, judgement,
#' response mapping and sensitivity, following the standard cognitive
#' interviewing approach (Willis, 2005) and Tourangeau's (1984) four stages
#' of answering a survey question.
#'
#' Give `stage` and `probe` to write your own protocol. Each probe belongs
#' to one stage, which tells the reader of the transcript what the probe is
#' for. The coding of problems does not depend on which probes were asked.
#'
#' @param stage the stage of each probe: `"comprehension"`, `"retrieval"`,
#'   `"judgement"`, `"response"` or `"sensitivity"`. `NULL` gives the
#'   default protocol.
#' @param probe the wording of each probe, as the interviewer would ask it.
#' @param probe_id optional short names, used for the columns of the
#'   result (`probe_<probe_id>`). `NULL` makes them from the stages.
#' @return A tibble of class `sc_probes` with `probe_id`, `stage` and
#'   `probe`.
#' @references Tourangeau, R. (1984). Cognitive science and survey methods.
#'   In T. Jabine, M. Straf, J. Tanur & R. Tourangeau (Eds.), *Cognitive
#'   aspects of survey methodology: Building a bridge between disciplines*
#'   (pp. 73-100). National Academy Press.
#'
#'   Willis, G. B. (2005). *Cognitive interviewing: A tool for improving
#'   questionnaire design.* Sage.
#' @seealso [cognitive_interview()]
#' @examples
#' sc_probes()
#'
#' # a shorter protocol
#' sc_probes(stage = c("comprehension", "response"),
#'           probe = c("What does this statement mean to you?",
#'                     "Was it easy to choose an answer?"))
#' @export
sc_probes <- function(stage = NULL, probe = NULL, probe_id = NULL) {
  if (is.null(stage) && is.null(probe)) {
    stage <- c("comprehension", "comprehension", "retrieval", "judgement", "response",
               "sensitivity")
    probe <- c(
      "In your own words, what is this statement asking you?",
      paste("Were there any words or phrases that were unclear, or that could mean different",
            "things? What did you take them to mean?"),
      "What did you think about, or remember, to come up with your answer?",
      "How sure are you of your answer? Was anything hard about deciding?",
      paste("Was it easy to pick a number on this scale? Did any of the options fit poorly,",
            "or did you want an option that was not there?"),
      paste("Would you, or people like you, feel uncomfortable answering this honestly?",
            "Is any of the wording sensitive or offensive?"))
    if (is.null(probe_id))
      probe_id <- c("paraphrase", "terms", "retrieval", "judgement", "response", "sensitivity")
  }
  if (is.null(stage) || is.null(probe))
    stop("Give both `stage` and `probe`, or neither for the default protocol.", call. = FALSE)
  stage <- tolower(as.character(stage))
  probe <- as.character(probe)
  if (length(stage) == 1L) stage <- rep(stage, length(probe))
  if (length(stage) != length(probe) || !length(probe))
    stop("`stage` and `probe` must have the same length.", call. = FALSE)
  bad <- setdiff(stage, sc_iv_stages)
  if (length(bad))
    stop("Unknown stage: ", paste(bad, collapse = ", "), ". Use ",
         paste(sc_iv_stages, collapse = ", "), ".", call. = FALSE)
  if (any(is.na(probe) | !nzchar(trimws(probe)))) stop("Every probe needs a wording.", call. = FALSE)
  if (is.null(probe_id)) probe_id <- make.unique(stage, sep = "_")
  probe_id <- as.character(probe_id)
  if (length(probe_id) != length(probe) || anyDuplicated(probe_id) ||
      !all(grepl("^[A-Za-z][A-Za-z0-9_]*$", probe_id)))
    stop("`probe_id` must give each probe a unique name of letters, digits and `_`.",
         call. = FALSE)
  if ("pretest" %in% probe_id) stop("`pretest` is reserved for the pretest probe.", call. = FALSE)
  out <- as_tbl(data.frame(probe_id = probe_id, stage = stage, probe = trimws(probe),
                           stringsAsFactors = FALSE))
  class(out) <- c("sc_probes", class(out))
  out
}

#' Run cognitive interviews with language models playing personas
#'
#' **Experimental.** `cognitive_interview()` asks one or more language
#' models to take part in a cognitive interview about each survey item, as
#' each persona. It is meant for screening items when there are no real
#' respondents yet, for example after a [synthetic_pretest()]: It points to
#' wording to look at. It is not a substitute for cognitive interviews with
#' real people or for a field test.
#'
#' Each interview is one conversation with one persona about one item,
#' following the standard mix of think-aloud and scripted verbal probes
#' (Willis, 2005; Beatty & Willis, 2007):
#'
#' 1. **Think-aloud and answer.** The persona reads the statement, says
#'    what goes through its mind while deciding, and answers on the
#'    instrument's scale.
#' 2. **Probes.** The persona answers the probes in [sc_probes()] in the
#'    same conversation. Items flagged by the pretest get one more probe
#'    aimed at the reason for the flag.
#' 3. **Coding.** A separate call, with no persona, reads the transcript
#'    and codes problems at the four stages of answering a survey question
#'    (comprehension, retrieval, judgement, response mapping; Tourangeau,
#'    1984) plus sensitivity, as in the Question Appraisal System (Willis &
#'    Lessler, 1999). For each stage it gives a yes or no, a short note with
#'    a quote, an overall severity and an optional rewording. Use another
#'    model as `coder` so that no model grades its own interviews.
#'
#' That is three requests per interview. The number of interviews is the
#' number of models times personas times items times `interviews`, and it
#' is printed before the run starts.
#'
#' What a model can and cannot tell you: A model does not retrieve memories
#' or feel uncomfortable, so its retrieval and judgement reports are guesses
#' about what such a person might say. Comprehension and response-mapping
#' problems (vague or double-barrelled wording, a scale that fits poorly)
#' are where it helps most. Models understand items better than many real
#' respondents, so an item without problems here is not shown to work.
#'
#' @param instrument an [sc_instrument()].
#' @param models one [sc_model()] or a list of them, the respondents.
#' @param personas an [sc_personas()] table, a character vector of
#'   descriptions, or `NULL` for interviews without a persona.
#' @param items optional item names to interview about. `NULL` uses all
#'   items, or only the flagged items when `pretest` is given.
#' @param probes the probes, from [sc_probes()].
#' @param coder an [sc_model()] that codes the transcripts. `NULL` uses each
#'   respondent model to code its own interviews. The coder's temperature is
#'   set to 0 when it takes one.
#' @param pretest optional result of [synthetic_pretest()], or a data frame
#'   with an `item` column and an optional `flag` column (the reason, for
#'   example `"low item-rest correlation"`), or a vector of item names.
#'   Flagged items come first and get one extra probe.
#' @param interviews number of interviews per model, persona and item.
#' @param max_retries how often to retry an interview that fails.
#' @param parallel number of interviews to run at the same time.
#' @param output optional folder to write the results to: The table in
#'   `format`, `run.json`, and one readable Markdown file of transcripts per
#'   item in `transcripts/`.
#' @param format file format of the table in `output`: `"csv"`, `"json"`
#'   or `"rds"`.
#' @param progress show a progress bar in the console? A function also
#'   works, as in [generate_synthetic()].
#' @param progress_file optional path of a JSON file updated after every
#'   interview (used by [run_synthcheck_app()]).
#' @param stop_file optional path: When this file appears, the run stops
#'   after the interviews in progress.
#' @param seed random seed for the mock provider.
#' @return A tibble of class `sc_interview`, one row per model, persona,
#'   item and interview, with `model`, `provider`, `model_id`, `coder`,
#'   `persona_id`, any persona attributes, `item`, `statement`, `pretest`
#'   (the flag, if any), `interview`, `answer`, `think_aloud`, one
#'   `probe_<probe_id>` column per probe, one logical column per stage
#'   (`comprehension`, `retrieval`, `judgement`, `response`, `sensitivity`)
#'   with a `<stage>_note` beside it, `severity` (`"none"`, `"minor"` or
#'   `"major"`) and `revision`. The attribute `log` holds failed
#'   interviews. Summarise it with [summarise_interviews()] and plot it with
#'   [gg_interview()].
#' @references Beatty, P. C., & Willis, G. B. (2007). Research synthesis:
#'   The practice of cognitive interviewing. *Public Opinion Quarterly,
#'   71*(2), 287-311.
#'
#'   Tourangeau, R. (1984). Cognitive science and survey methods. In T.
#'   Jabine, M. Straf, J. Tanur & R. Tourangeau (Eds.), *Cognitive aspects of
#'   survey methodology: Building a bridge between disciplines* (pp. 73-100).
#'   National Academy Press.
#'
#'   Willis, G. B. (2005). *Cognitive interviewing: A tool for improving
#'   questionnaire design.* Sage.
#'
#'   Willis, G. B., & Lessler, J. T. (1999). *Question Appraisal System
#'   QAS-99.* Research Triangle Institute.
#' @seealso [sc_probes()], [summarise_interviews()], [gg_interview()],
#'   [sc_interview_prompts()]
#' @examples
#' items <- data.frame(
#'   item = c("q1", "q2", "q3"),
#'   statement = c("I am not someone who never worries.",
#'                 "I enjoy meeting new people and going to parties.",
#'                 "I keep my promises."))
#' ins <- sc_instrument(items, scale = c(1, 5))
#' per <- sc_personas(c("You are a 19-year-old student.", "You are a 70-year-old retiree."))
#' iv <- cognitive_interview(ins, sc_model("mock"), per)
#' iv
#' summarise_interviews(iv)
#' \dontrun{
#' # needs ANTHROPIC_API_KEY and OPENAI_API_KEY
#' iv <- cognitive_interview(ins, list(sc_model("anthropic"), sc_model("openai")), per,
#'                           coder = sc_model("anthropic"), parallel = 4)
#' }
#' @export
cognitive_interview <- function(instrument, models, personas = NULL, items = NULL,
                                probes = sc_probes(), coder = NULL, pretest = NULL,
                                interviews = 1, max_retries = 2, parallel = 1, output = NULL,
                                format = c("csv", "json", "rds"), progress = interactive(),
                                progress_file = NULL, stop_file = NULL, seed = 1) {
  if (!inherits(instrument, "sc_instrument"))
    stop("`instrument` must be made with sc_instrument().", call. = FALSE)
  format <- match.arg(format)
  if (inherits(models, "sc_model")) models <- list(models)
  if (!length(models) || !all(vapply(models, inherits, logical(1), "sc_model")))
    stop("`models` must be an sc_model() or a list of them.", call. = FALSE)
  labels <- vapply(models, `[[`, character(1), "name")
  if (anyDuplicated(labels))
    stop("Every model needs its own `name`: ", paste(unique(labels[duplicated(labels)]),
                                                      collapse = ", "), ".", call. = FALSE)
  if (!is.null(coder) && !inherits(coder, "sc_model"))
    stop("`coder` must be an sc_model() or NULL.", call. = FALSE)
  if (!inherits(probes, "sc_probes")) {
    if (!is.data.frame(probes) || !all(c("stage", "probe") %in% names(probes)))
      stop("`probes` must be made with sc_probes().", call. = FALSE)
    probes <- sc_probes(probes$stage, probes$probe, probes$probe_id)
  }
  all_models <- c(models, if (!is.null(coder)) list(coder))
  if (any(vapply(all_models, function(m) m$provider != "mock", logical(1))))
    sc_need("ellmer", "to call language models")
  personas <- if (is.null(personas)) NULL else sc_personas(personas)
  interviews <- as.integer(interviews)
  if (length(interviews) != 1L || is.na(interviews) || interviews < 1L)
    stop("`interviews` must be at least 1.", call. = FALSE)
  parallel <- max(1L, as.integer(parallel))

  it <- as.data.frame(instrument$items, stringsAsFactors = FALSE)
  flags <- sc_iv_pretest(pretest, it$item)
  if (is.null(items)) {
    items <- if (nrow(flags)) flags$item else it$item
    if (nrow(flags))
      message(sprintf("Interviewing about the %d item%s flagged by the pretest.", nrow(flags),
                      if (nrow(flags) == 1L) "" else "s"))
  }
  items <- unique(as.character(items))
  bad <- setdiff(items, it$item)
  if (length(bad)) stop("Not in the instrument: ", paste(bad, collapse = ", "), ".", call. = FALSE)
  if (!length(items)) stop("No items to interview about.", call. = FALSE)
  # flagged items first, in the order of the flags, then the rest in instrument order
  items <- c(intersect(flags$item, items), setdiff(it$item[it$item %in% items], flags$item))

  pers <- if (is.null(personas)) data.frame(persona_id = "none", description = NA_character_,
                                            stringsAsFactors = FALSE) else as.data.frame(personas)
  jobs <- expand.grid(r = seq_len(interviews), i = seq_along(items), p = seq_len(nrow(pers)),
                      KEEP.OUT.ATTRS = FALSE)
  jobs <- jobs[c("p", "i", "r")]
  n_job <- nrow(jobs)
  total <- length(models) * n_job
  message(sprintf("%d interview%s (%d model%s x %d persona%s x %d item%s%s): %d requests.",
                  total, if (total == 1L) "" else "s", length(models),
                  if (length(models) == 1L) "" else "s", nrow(pers),
                  if (nrow(pers) == 1L) "" else "s", length(items),
                  if (length(items) == 1L) "" else "s",
                  if (interviews > 1L) sprintf(" x %d interviews", interviews) else "",
                  3L * total))

  if (!is.null(output) || !is.null(progress_file)) sc_need("jsonlite", "to save the run")
  if (!is.null(output)) dir.create(output, showWarnings = FALSE, recursive = TRUE)

  state <- new.env()
  state$done <- 0L; state$failed <- 0L; state$retries <- 0L; state$start <- Sys.time()
  state$total <- total; state$model <- ""; state$attempt <- 1L; state$status <- "running"
  state$per_model <- stats::setNames(integer(length(models)), labels)
  report <- sc_reporter(progress, progress_file, state, labels, n_job)
  report()

  rows <- list(); log <- list(); stopped <- FALSE
  with_seed(seed, {
    for (mi in seq_along(models)) {
      m <- models[[mi]]
      cd <- sc_iv_coder(if (is.null(coder)) m else coder)
      state$model <- m$name
      seeds <- sample.int(.Machine$integer.max, n_job)
      specs <- lapply(seq_len(n_job), function(j) {
        item <- items[jobs$i[j]]
        row <- it[it$item == item, , drop = FALSE]
        fl <- flags$flag[match(item, flags$item)]
        list(item = row, persona = pers$description[jobs$p[j]],
             probes = sc_iv_probes_for(probes, row, fl), flag = fl, seed = seeds[j])
      })
      res <- vector("list", n_job)
      for (chunk in split(seq_len(n_job), ceiling(seq_len(n_job) / parallel))) {
        if (!is.null(stop_file) && file.exists(stop_file)) { stopped <- TRUE; break }
        out <- sc_iv_run_chunk(m, cd, instrument, specs[chunk], max_retries, on_done = function(r) {
          state$done <- state$done + 1L
          state$per_model[mi] <- state$per_model[mi] + 1L
          state$retries <- state$retries + r$retries
          if (!r$ok) state$failed <- state$failed + 1L
          report()
        })
        res[chunk] <- out
      }
      keep <- which(!vapply(res, is.null, logical(1)))
      if (length(keep)) {
        rows[[length(rows) + 1L]] <- sc_iv_rows(res[keep], specs[keep], jobs[keep, , drop = FALSE],
                                                pers, m, cd, probes)
        for (k in keep) if (length(res[[k]]$errors))
          log[[length(log) + 1L]] <- data.frame(model = m$name, persona_id = pers$persona_id[jobs$p[k]],
                                                item = items[jobs$i[k]], interview = jobs$r[k],
                                                error = paste(unique(res[[k]]$errors), collapse = " | "),
                                                stringsAsFactors = FALSE)
      }
      if (stopped) break
    }
  })
  state$status <- if (stopped) "stopped" else "done"
  report(final = TRUE)
  out <- if (length(rows)) do.call(rbind, rows) else
    sc_iv_rows(list(), list(), jobs[0, , drop = FALSE], pers, models[[1]],
               sc_iv_coder(if (is.null(coder)) models[[1]] else coder), probes)
  out <- as_tbl(out)
  log <- if (length(log)) as_tbl(do.call(rbind, log)) else NULL
  attr(out, "log") <- log
  attr(out, "stopped") <- stopped
  attr(out, "probes") <- probes
  attr(out, "instrument") <- instrument$name
  class(out) <- c("sc_interview", class(out))
  if (!is.null(output)) sc_iv_write(out, output, format, instrument, models, coder, personas,
                                    probes, flags, interviews, seed)
  out
}

#' Show the prompts of a cognitive interview
#'
#' **Experimental.** Shows exactly what [cognitive_interview()] sends for one
#' item and persona: The persona's system prompt, the think-aloud request,
#' the probes and the coder's instructions.
#'
#' @inheritParams cognitive_interview
#' @param item the name of one item.
#' @param persona one persona description, or `NULL` for none.
#' @param flag optional pretest flag for the item, which adds the pretest
#'   probe.
#' @return A list with `system`, `think_aloud`, `probes` and `coder` (the
#'   coder's system prompt).
#' @examples
#' ins <- sc_instrument(hexaco_items[1:3, ], scale = c(1, 7))
#' p <- sc_interview_prompts(ins, "HSinc1", "You are a 30-year-old teacher.")
#' cat(p$think_aloud)
#' cat(p$probes)
#' @export
sc_interview_prompts <- function(instrument, item, persona = NULL, probes = sc_probes(),
                                 flag = NULL) {
  if (!inherits(instrument, "sc_instrument"))
    stop("`instrument` must be made with sc_instrument().", call. = FALSE)
  row <- as.data.frame(instrument$items)[instrument$items$item == item, , drop = FALSE]
  if (nrow(row) != 1L) stop("`item` must name one item of the instrument.", call. = FALSE)
  pr <- sc_iv_probes_for(probes, row, if (is.null(flag)) NA_character_ else flag)
  list(system = sc_iv_system(persona), think_aloud = sc_iv_think_prompt(instrument, row),
       probes = sc_iv_probe_prompt(pr), coder = sc_iv_coder_system)
}

#' Summarise cognitive interviews per item
#'
#' **Experimental.** `summarise_interviews()` rolls the coded interviews of
#' [cognitive_interview()] up to one row per item: The share of interviews
#' with a problem at each stage and at any stage, how many personas and
#' models raised a problem, the coder's most common notes and the suggested
#' rewordings.
#'
#' An item is **flagged** when the share of interviews with a problem at any
#' stage is at least `flag` and, when there are two or more models, at least
#' two of them raise a problem (one model alone is weaker evidence). With a
#' pretest, `agreement` says whether the item was flagged by both, by the
#' pretest only, by the interviews only, or by neither: Items flagged by
#' both are the first to revise.
#'
#' Printing the result shows a short paragraph, written by fixed rules,
#' before the table. These are screening results: They point to items to
#' look at in human cognitive interviews and a field test.
#'
#' @param x a result of [cognitive_interview()].
#' @param flag the share of interviews with a problem at which an item is
#'   flagged.
#' @param n_notes how many notes and rewordings to keep per item.
#' @return A tibble of class `sc_interview_summary`, one row per item, with
#'   `item`, `statement`, `n`, one share per stage, `any`, `major` (share of
#'   major problems), `personas` and `models` (how many raised a problem),
#'   `top_stage`, `flagged`, `pretest`, `agreement`, `notes` and `revisions`.
#'   The attribute `text` holds the paragraph.
#' @seealso [cognitive_interview()], [gg_interview()]
#' @examples
#' items <- data.frame(item = c("q1", "q2"),
#'                     statement = c("I never don't worry.", "I keep my promises."))
#' iv <- cognitive_interview(sc_instrument(items), sc_model("mock"),
#'                           c("You are 20 years old.", "You are 70 years old."),
#'                           interviews = 3)
#' summarise_interviews(iv)
#' @export
summarise_interviews <- function(x, flag = 0.3, n_notes = 3) {
  sc_iv_check(x)
  if (!is.numeric(flag) || length(flag) != 1L || flag <= 0 || flag > 1)
    stop("`flag` must be a share between 0 and 1.", call. = FALSE)
  d <- as.data.frame(x)
  ok <- !is.na(d$comprehension)
  d <- d[ok, , drop = FALSE]
  items <- unique(as.character(x$item))
  n_models <- length(unique(d$model))
  rows <- lapply(items, function(i) {
    s <- d[d$item == i, , drop = FALSE]
    st <- unique(as.character(x$statement[x$item == i]))[1]
    pf <- if ("pretest" %in% names(x)) unique(x$pretest[x$item == i])[1] else NA_character_
    n <- nrow(s)
    sh <- vapply(sc_iv_stages, function(k) if (n) mean(s[[k]]) else NA_real_, numeric(1))
    prob <- if (n) Reduce(`|`, lapply(sc_iv_stages, function(k) s[[k]])) else logical(0)
    any_sh <- if (n) mean(prob) else NA_real_
    mods <- length(unique(s$model[prob])); pers <- length(unique(s$persona_id[prob]))
    flagged <- n > 0 && any_sh >= flag && (n_models < 2L || mods >= 2L)
    notes <- unlist(lapply(sc_iv_stages, function(k) s[[paste0(k, "_note")]][s[[k]]]))
    data.frame(item = i, statement = st, n = n, t(sh), any = any_sh,
               major = if (n) mean(s$severity == "major", na.rm = TRUE) else NA_real_,
               personas = pers, models = mods,
               top_stage = if (n && any(sh > 0)) sc_iv_stages[which.max(sh)] else NA_character_,
               flagged = flagged, pretest = !is.na(pf),
               notes = sc_iv_top(notes, n_notes), revisions = sc_iv_top(s$revision, n_notes),
               stringsAsFactors = FALSE, check.names = FALSE)
  })
  out <- do.call(rbind, rows)
  has_pre <- "pretest" %in% names(x) && any(!is.na(x$pretest))
  out$agreement <- if (has_pre) ifelse(out$flagged & out$pretest, "both",
                                       ifelse(out$pretest, "pretest only",
                                              ifelse(out$flagged, "interviews only", "neither"))) else
    NA_character_
  if (!has_pre) out$pretest <- NA
  out <- out[order(-out$flagged, -out$any, match(out$item, items)), , drop = FALSE]
  out <- as_tbl(out)
  attr(out, "text") <- sc_iv_text(out, flag, n_models, has_pre)
  attr(out, "flag") <- flag
  class(out) <- c("sc_interview_summary", class(out))
  out
}

#' @export
print.sc_interview_summary <- function(x, ...) {
  y <- x
  class(y) <- setdiff(class(y), "sc_interview_summary")
  cols <- c("item", sc_iv_stages, "any", "models", "flagged",
            if ("agreement" %in% names(x) && any(!is.na(x$agreement))) "agreement")
  if (!all(cols %in% names(x)) || is.null(attr(x, "text"))) {
    print(y, ...)
    return(invisible(x))
  }
  cat(strwrap(attr(x, "text")), sep = "\n")
  cat("\n")
  print(y[cols], ...)
  invisible(x)
}

#' Plot cognitive interview problems per item
#'
#' **Experimental.** `gg_interview()` draws one heatmap of items (rows) by
#' stage (columns), coloured by the share of interviews in which the coder
#' found a problem: Pale is none, red is most. Flagged items (see
#' [summarise_interviews()]) are marked with an asterisk after their name, and the
#' items are sorted with the most problems at the top.
#'
#' @param x a result of [cognitive_interview()] or [summarise_interviews()].
#' @param flag passed to [summarise_interviews()] when `x` is not yet a
#'   summary.
#' @param max_items show at most this many items (those with the most
#'   problems).
#' @return A ggplot.
#' @seealso [cognitive_interview()], [summarise_interviews()]
#' @examples
#' items <- data.frame(item = c("q1", "q2", "q3"),
#'                     statement = c("I never don't worry.", "I keep my promises.",
#'                                   "I like parties and quiet evenings."))
#' iv <- cognitive_interview(sc_instrument(items), sc_model("mock"),
#'                           c("You are 20 years old.", "You are 70 years old."),
#'                           interviews = 3)
#' gg_interview(iv)
#' @export
gg_interview <- function(x, flag = 0.3, max_items = 40) {
  s <- if (inherits(x, "sc_interview_summary")) x else summarise_interviews(x, flag = flag)
  s <- as.data.frame(s)
  s <- s[order(-s$any, s$item), , drop = FALSE]
  s <- utils::head(s, max_items)
  lab <- paste0(s$item, ifelse(s$flagged, " *", ""))
  cols <- c(sc_iv_stages, "any")
  long <- data.frame(item = factor(rep(lab, length(cols)), levels = rev(lab)),
                     stage = factor(rep(c(sc_iv_stage_names, any = "Any problem")[cols], each = nrow(s)),
                                    levels = c(sc_iv_stage_names, "Any problem")),
                     share = unlist(s[cols], use.names = FALSE))
  long$text <- ifelse(is.na(long$share), "", sprintf("%.0f%%", 100 * long$share))
  long$dark <- !is.na(long$share) & long$share > 0.6
  ggplot2::ggplot(long, ggplot2::aes(.data$stage, .data$item, fill = .data$share)) +
    ggplot2::geom_tile(colour = "white", linewidth = 0.8) +
    ggplot2::geom_text(ggplot2::aes(label = .data$text, colour = .data$dark), size = 3,
                       show.legend = FALSE) +
    ggplot2::scale_colour_manual(values = c(`FALSE` = "#3a3a3a", `TRUE` = "white")) +
    ggplot2::scale_fill_gradientn(colours = c("#f0efec", "#f0a09a", "#c0302b"),
                                  limits = c(0, 1), labels = function(v) paste0(100 * v, "%"),
                                  na.value = "grey90",
                                  name = "Interviews with a problem") +
    ggplot2::scale_x_discrete(position = "top") +
    ggplot2::labs(x = NULL, y = NULL,
                  title = "Where synthetic respondents ran into problems",
                  subtitle = "Share of cognitive interviews in which the coder found a problem. * Flagged item.") +
    theme_synthcheck() +
    ggplot2::theme(panel.grid = ggplot2::element_blank(),
                   legend.key.width = ggplot2::unit(1.5, "cm"))
}

# ---- internal -------------------------------------------------------------

sc_iv_check <- function(x) {
  need <- c("model", "persona_id", "item", sc_iv_stages, paste0(sc_iv_stages, "_note"),
            "severity", "revision")
  if (!is.data.frame(x) || !all(need %in% names(x)))
    stop("`x` must be a result of cognitive_interview().", call. = FALSE)
  invisible(TRUE)
}

sc_iv_top <- function(x, n) {
  x <- trimws(as.character(x))
  x <- x[!is.na(x) & nzchar(x)]
  if (!length(x)) return(NA_character_)
  tab <- sort(table(x), decreasing = TRUE)
  paste(utils::head(names(tab), n), collapse = " | ")
}

sc_iv_text <- function(s, flag, n_models, has_pre) {
  n <- nrow(s)
  f <- s[s$flagged, , drop = FALSE]
  s1 <- if (!nrow(f)) {
    sprintf("No item of the %d was flagged: Fewer than %s of the interviews about each item found a problem%s.",
            n, sc_pct(flag), if (n_models > 1) ", or only one model raised one" else "")
  } else {
    one <- function(i) sprintf("%s (%s of interviews, mostly %s)", f$item[i], sc_pct(f$any[i]),
                               tolower(sc_iv_stage_names[[f$top_stage[i]]]))
    sprintf("%d of %d items %s flagged: %s.", nrow(f), n, if (nrow(f) == 1L) "is" else "are",
            paste(vapply(seq_len(min(nrow(f), 5L)), one, character(1)), collapse = "; "))
  }
  if (nrow(f) > 5L) s1 <- sub("\\.$", sprintf(", and %d more.", nrow(f) - 5L), s1)
  s2 <- if (has_pre) {
    b <- s$item[!is.na(s$agreement) & s$agreement == "both"]
    if (length(b)) sprintf("The pretest also flagged %s, so %s the first to revise.",
                           paste(b, collapse = ", "), if (length(b) == 1L) "it is" else "they are") else
      "None of the items flagged by the pretest was also flagged in the interviews."
  } else ""
  s3 <- paste("These are screening results from language models: Use them to choose items for",
              "cognitive interviews with real people and a field test, not to replace them.")
  paste(c(s1, if (nzchar(s2)) s2, s3), collapse = " ")
}

# pretest flags as a data frame of item and flag
sc_iv_pretest <- function(pretest, items) {
  empty <- data.frame(item = character(0), flag = character(0), stringsAsFactors = FALSE)
  if (is.null(pretest)) return(empty)
  if (is.character(pretest) || is.factor(pretest)) {
    d <- data.frame(item = as.character(pretest), flag = "flagged by the pretest",
                    stringsAsFactors = FALSE)
  } else {
    if (inherits(pretest, "sc_pretest")) pretest <- as.data.frame(pretest$agreement, stringsAsFactors = FALSE)
    d <- if (is.data.frame(pretest)) pretest else if (is.list(pretest) && is.data.frame(pretest$agreement))
      pretest$agreement else if (is.list(pretest) && is.data.frame(pretest$flags)) pretest$flags else NULL
    if (is.null(d) || !"item" %in% names(d))
      stop("`pretest` must be a synthetic_pretest() result, a data frame with an `item` column, ",
           "or item names.", call. = FALSE)
    d <- as.data.frame(d, stringsAsFactors = FALSE)
    if ("flagged" %in% names(d)) d <- d[as.logical(d$flagged) %in% TRUE, , drop = FALSE]
    if ("flagged_in" %in% names(d)) d <- d[d$flagged_in %in% seq_len(1e6), , drop = FALSE]
    fc <- intersect(c("flag", "flags", "reason", "reasons", "conditions"), names(d))
    d <- data.frame(item = as.character(d$item),
                    flag = if (length(fc)) as.character(d[[fc[1]]]) else "flagged by the pretest",
                    stringsAsFactors = FALSE)
    d$flag[is.na(d$flag) | !nzchar(d$flag)] <- "flagged by the pretest"
  }
  d <- d[!duplicated(d$item), , drop = FALSE]
  bad <- setdiff(d$item, items)
  if (length(bad)) warning("Pretest items not in the instrument are skipped: ",
                           paste(bad, collapse = ", "), ".", call. = FALSE)
  d[d$item %in% items, , drop = FALSE]
}

# the probes for one item: the protocol plus the pretest probe for a flagged item
sc_iv_probes_for <- function(probes, row, flag) {
  pr <- as.data.frame(probes, stringsAsFactors = FALSE)[c("probe_id", "stage", "probe")]
  if (length(flag) && !is.na(flag))
    pr <- rbind(pr, data.frame(probe_id = "pretest", stage = "comprehension",
                               probe = sc_iv_flag_probe(flag, row), stringsAsFactors = FALSE))
  pr
}

sc_iv_flag_probe <- function(flag, row) {
  f <- tolower(trimws(strsplit(flag, ",")[[1]][1]))
  topic <- if ("scale" %in% names(row) && !is.na(row$scale) && nzchar(row$scale))
    sprintf("statements about %s", row$scale) else "the other statements in this survey"
  if (grepl("duplicate|redundant|twin", f))
    return("Does this statement seem to ask the same thing as another statement you have seen? What, if anything, is different about it?")
  if (grepl("another scale|other scale|closer", f))
    return(sprintf("Does this statement seem to be about the same thing as %s, or about something else? What?",
                   topic))
  if (grepl("weak|rest|total|discrim|loading|belong", f))
    return(sprintf("Does this statement seem to be about the same thing as %s? If not, what is it about?",
                   topic))
  if (grepl("varies|variance|floor|ceiling|spread|extreme", f))
    return("Could you imagine someone answering this statement differently from you? Who, and why?")
  if (grepl("reverse|against|negat|key", f))
    return("Did this statement point the other way from the others, or use a negative? Did that change how you read it?")
  "Is there anything about this statement that might make people answer it differently from the other statements?"
}

sc_iv_system <- function(persona = NULL) {
  role <- paste(
    "You are taking part in a cognitive interview about a survey. An interviewer will show you",
    "one survey statement, ask you to think aloud while you answer it, and then ask a few",
    "questions about it. Speak in the first person and in your own everyday words.",
    "There are no right or wrong answers. If something is unclear, odd or hard to answer,",
    "say so: That is the most helpful thing you can do.")
  if (is.null(persona) || is.na(persona) || !nzchar(trimws(persona)))
    return(paste(role, "Answer as a real person would."))
  paste0(trimws(persona), "\n\n", role, " Stay in this role and speak as this person would.")
}

sc_iv_scale_text <- function(instrument) {
  cats <- seq(instrument$min, instrument$max)
  if (is.null(instrument$labels))
    return(sprintf("Answer with a whole number from %d (lowest) to %d (highest).", instrument$min,
                   instrument$max))
  paste0("Answer with a whole number from ", instrument$min, " to ", instrument$max, ":\n",
         paste(sprintf("%d = %s", cats, instrument$labels), collapse = "\n"))
}

sc_iv_think_prompt <- function(instrument, row) {
  paste0("Here is a statement from a survey. The survey's instructions are: \"",
         instrument$instructions, "\"\n\n", sc_iv_scale_text(instrument),
         "\n\nStatement: \"", row$statement, "\"\n\n",
         "Please think aloud: Read the statement, then tell me everything that goes through your ",
         "mind as you decide how to answer it, in your own words. Then give your answer.")
}

sc_iv_probe_prompt <- function(pr) {
  paste0("Thank you. Now a few questions about that statement. Answer each one in your own ",
         "words, in a few sentences.\n\n",
         paste(sprintf("%d. %s", seq_len(nrow(pr)), pr$probe), collapse = "\n"))
}

sc_iv_coder_system <- paste(
  "You are an expert in questionnaire design who codes transcripts of cognitive interviews.",
  "Code problems with the survey statement, not with the respondent. Use the four stages of",
  "answering a survey question (Tourangeau, 1984) plus sensitivity:",
  "Comprehension: The statement, or a word or phrase in it, is unclear, vague, ambiguous,",
  "double-barrelled (asks about two things), uses a double negative, or is understood",
  "differently from what was intended.",
  "Retrieval: The person lacks the information or experience needed, or the situation or time",
  "the statement refers to is unclear.",
  "Judgement: It is hard to decide or to combine information, or the answer depends on the",
  "situation.",
  "Response mapping: The answer does not fit the response scale, the options are unclear, or a",
  "needed option is missing.",
  "Sensitivity: The wording is sensitive, embarrassing or offensive, or invites a socially",
  "desirable answer.",
  "Mark a problem only when the transcript gives evidence for it, and quote that evidence in",
  "the note. A paraphrase that changes the meaning of the statement is a comprehension problem",
  "even when the person did not notice it. Leave the note empty when there is no problem.")

sc_iv_transcript <- function(statement, think, answer, pr, probe_answers) {
  qa <- vapply(seq_len(nrow(pr)), function(k)
    sprintf("Interviewer: %s\nRespondent: %s", pr$probe[k],
            if (is.null(probe_answers[[pr$probe_id[k]]]) || is.na(probe_answers[[pr$probe_id[k]]])) ""
            else probe_answers[[pr$probe_id[k]]]),
    character(1))
  paste0("Interviewer: Please think aloud as you answer: \"", statement, "\"\n",
         "Respondent: ", think, "\n",
         "Answer given: ", if (is.na(answer)) "none" else answer, "\n\n",
         paste(qa, collapse = "\n\n"))
}

sc_iv_coder_prompt <- function(instrument, row, transcript) {
  about <- c(if ("scale" %in% names(row) && !is.na(row$scale)) sprintf("Scale: %s", row$scale),
             if ("facet" %in% names(row) && !is.na(row$facet)) sprintf("Facet: %s", row$facet))
  paste0("Survey statement: \"", row$statement, "\"\n",
         if (length(about)) paste0(paste(about, collapse = "\n"), "\n"),
         "Response scale: ", sc_iv_scale_text(instrument), "\n\n",
         "Transcript:\n", transcript, "\n\n",
         "Code the problems with this statement at each stage.")
}

sc_iv_coder <- function(m) {
  if (m$provider != "mock" && !is.null(m$temperature)) m$temperature <- 0
  m
}

sc_iv_types <- function(instrument, pr) {
  think <- ellmer::type_object(
    .description = "Your think-aloud and your answer.",
    think_aloud = ellmer::type_string("Everything that went through your mind, in your own words."),
    answer = ellmer::type_integer(sprintf("Your answer from %d to %d.", instrument$min,
                                          instrument$max)))
  pa <- lapply(pr$probe, function(p) ellmer::type_string(p))
  names(pa) <- pr$probe_id
  probes <- do.call(ellmer::type_object, c(list(.description = "One answer per question."), pa))
  cf <- list()
  for (k in sc_iv_stages) {
    cf[[k]] <- ellmer::type_boolean(sprintf("Is there a %s problem?", sc_iv_stage_names[[k]]))
    cf[[paste0(k, "_note")]] <- ellmer::type_string(
      "A short description of the problem with a quote from the transcript, or empty.")
  }
  cf$severity <- ellmer::type_enum(c("none", "minor", "major"),
                                   "How serious the problems are overall.")
  cf$revision <- ellmer::type_string("A suggested rewording of the statement if there is a problem, or empty.")
  coder <- do.call(ellmer::type_object, c(list(.description = "The coding of the transcript."), cf))
  list(think = think, probes = probes, coder = coder)
}

# turn the three answers into one interview result, checked
sc_iv_result <- function(spec, instrument, a1, a2, a3, retries, errors) {
  pr <- spec$probes
  ans <- suppressWarnings(as.numeric(unlist(a1$answer)[1]))
  if (length(ans) != 1L || is.na(ans) || ans != round(ans) || ans < instrument$min ||
      ans > instrument$max) ans <- NA_integer_
  pa <- stats::setNames(lapply(pr$probe_id, function(k) {
    v <- a2[[k]]
    if (is.null(v) || !length(v)) NA_character_ else as.character(v[[1]])
  }), pr$probe_id)
  code <- list()
  for (k in sc_iv_stages) {
    v <- a3[[k]]
    code[[k]] <- if (is.null(v) || !length(v)) NA else as.logical(v[[1]])
    nt <- a3[[paste0(k, "_note")]]
    code[[paste0(k, "_note")]] <- if (is.null(nt) || !length(nt)) NA_character_ else as.character(nt[[1]])
  }
  sev <- a3$severity
  code$severity <- if (is.null(sev) || !length(sev) || !sev %in% c("none", "minor", "major"))
    NA_character_ else as.character(sev)
  rv <- a3$revision
  code$revision <- if (is.null(rv) || !length(rv)) NA_character_ else as.character(rv[[1]])
  think <- a1$think_aloud
  think <- if (is.null(think) || !length(think)) NA_character_ else as.character(think[[1]])
  ok <- !is.na(think) && !anyNA(unlist(code[sc_iv_stages]))
  list(answer = as.integer(ans), think = think, probes = pa, code = code, ok = ok,
       retries = retries, errors = errors)
}

sc_iv_empty <- function(spec, instrument, retries, errors) {
  sc_iv_result(spec, instrument, list(), list(), list(), retries, errors)
}

sc_iv_run_chunk <- function(m, cd, instrument, specs, max_retries, on_done) {
  n <- length(specs)
  mock <- m$provider == "mock" && cd$provider == "mock"
  if (mock || n == 1L || !requireNamespace("promises", quietly = TRUE) ||
      !requireNamespace("later", quietly = TRUE)) {
    return(lapply(specs, function(s) {
      r <- sc_iv_one(m, cd, instrument, s, max_retries)
      on_done(r)
      r
    }))
  }
  out <- vector("list", n)
  pending <- n
  for (j in seq_len(n)) local({
    jj <- j
    sc_iv_one_async(m, cd, instrument, specs[[jj]], max_retries, done = function(r) {
      out[[jj]] <<- r
      pending <<- pending - 1L
      on_done(r)
    })
  })
  while (pending > 0L) later::run_now(0.05)
  out
}

# one interview, one request after another
sc_iv_one <- function(m, cd, instrument, spec, max_retries) {
  if (m$provider == "mock" && cd$provider == "mock") return(sc_iv_mock(instrument, spec))
  errors <- character(0)
  for (try in 0:max_retries) {
    r <- tryCatch({
      a12 <- if (m$provider == "mock") sc_iv_mock_answers(instrument, spec) else {
        ty <- sc_iv_types(instrument, spec$probes)
        chat <- sc_chat(m, sc_iv_system(spec$persona))
        a1 <- chat$chat_structured(sc_iv_think_prompt(instrument, spec$item), type = ty$think)
        a2 <- chat$chat_structured(sc_iv_probe_prompt(spec$probes), type = ty$probes)
        list(a1 = a1, a2 = a2)
      }
      a3 <- if (cd$provider == "mock") sc_iv_mock_code(spec) else {
        ty <- sc_iv_types(instrument, spec$probes)
        tr <- sc_iv_transcript(spec$item$statement, a12$a1$think_aloud, a12$a1$answer,
                               spec$probes, a12$a2)
        sc_chat(cd, sc_iv_coder_system)$chat_structured(
          sc_iv_coder_prompt(instrument, spec$item, tr), type = ty$coder)
      }
      sc_iv_result(spec, instrument, a12$a1, a12$a2, a3, try, errors)
    }, error = function(e) { errors <<- c(errors, conditionMessage(e)); NULL })
    if (!is.null(r) && r$ok) return(r)
    if (!is.null(r)) errors <- c(errors, "incomplete answer or coding")
  }
  sc_iv_empty(spec, instrument, max_retries, errors)
}

# the same without blocking, for parallel interviews
sc_iv_one_async <- function(m, cd, instrument, spec, max_retries, done) {
  errors <- character(0)
  fail <- function(e, try) {
    errors <<- c(errors, conditionMessage(e))
    attempt(try + 1L)
  }
  attempt <- function(try) {
    if (try > max_retries) return(done(sc_iv_empty(spec, instrument, max_retries, errors)))
    ty <- tryCatch(sc_iv_types(instrument, spec$probes), error = function(e) e)
    if (inherits(ty, "error")) return(fail(ty, try))
    a1 <- NULL; a2 <- NULL
    p <- tryCatch({
      p0 <- if (m$provider == "mock") promises::promise_resolve(sc_iv_mock_answers(instrument, spec)) else {
        chat <- sc_chat(m, sc_iv_system(spec$persona))
        promises::then(chat$chat_structured_async(sc_iv_think_prompt(instrument, spec$item),
                                                  type = ty$think),
                       function(x) {
                         a1 <<- x
                         promises::then(chat$chat_structured_async(sc_iv_probe_prompt(spec$probes),
                                                                   type = ty$probes),
                                        function(y) list(a1 = a1, a2 = y))
                       })
      }
      promises::then(p0, function(a12) {
        a1 <<- a12$a1; a2 <<- a12$a2
        if (cd$provider == "mock") return(sc_iv_mock_code(spec))
        tr <- sc_iv_transcript(spec$item$statement, a1$think_aloud, a1$answer, spec$probes, a2)
        sc_chat(cd, sc_iv_coder_system)$chat_structured_async(
          sc_iv_coder_prompt(instrument, spec$item, tr), type = ty$coder)
      })
    }, error = function(e) e)
    if (inherits(p, "error")) return(fail(p, try))
    promises::then(p, onFulfilled = function(a3) {
      r <- sc_iv_result(spec, instrument, a1, a2, a3, try, errors)
      if (r$ok) done(r) else {
        errors <<- c(errors, "incomplete answer or coding")
        attempt(try + 1L)
      }
    }, onRejected = function(e) fail(e, try))
    invisible(NULL)
  }
  attempt(0L)
}

# ---- the mock provider ------------------------------------------------------
# Canned transcripts whose problems depend on simple features of the wording
# (negations, "and"/"or", long statements, words about money, health or
# morals), so the summary and the plot have something to show.

sc_iv_features <- function(statement) {
  s <- tolower(statement)
  c(negation = grepl("\\bnot\\b|n't\\b|\\bnever\\b|\\bno\\b", s),
    double = grepl("\\band\\b|\\bor\\b", s),
    long = nchar(s) > 70,
    sensitive = grepl("money|steal|cheat|lie|sex|drink|drug|health|weight|religio|illegal|rule",
                      s),
    vague = grepl("often|usually|sometimes|rarely|things|people", s))
}

sc_iv_mock_answers <- function(instrument, spec) {
  with_seed(spec$seed, {
    ans <- sample(seq(instrument$min, instrument$max), 1L)
    lab <- if (is.null(instrument$labels)) as.character(ans) else
      tolower(instrument$labels[ans - instrument$min + 1L])
    f <- sc_iv_features(spec$item$statement)
    think <- paste0("Okay, \"", sub("[.?!]+$", "", spec$item$statement), ".\" ",
                    if (f[["negation"]]) "Wait, there's a 'not' in there, so I have to read it twice. " else "",
                    if (f[["double"]]) "Hmm, it's really asking two things at once. " else "",
                    "I think about how I usually am, day to day. I'd go with ", lab, ".")
    canned <- c(
      paraphrase = if (f[["negation"]]) "I think it's asking whether I don't do it... or do? Not sure." else
        "It's asking how much this describes me.",
      terms = if (f[["vague"]]) "Words like that are vague. It depends on what counts." else
        "No, the words were clear enough.",
      retrieval = "I thought about the last few weeks and what I usually do.",
      judgement = if (f[["double"]]) "Not very sure, because one part fits me and the other doesn't." else
        "Fairly sure.",
      response = "The numbers were fine, though the middle option is a bit of a cop-out.",
      sensitivity = if (f[["sensitive"]]) "Some people might not want to admit this honestly." else
        "No, it's fine.",
      pretest = "It does seem a bit different from the others.")
    pa <- lapply(spec$probes$probe_id, function(k)
      if (k %in% names(canned)) canned[[k]] else "I'm not sure what to say about that.")
    names(pa) <- spec$probes$probe_id
    list(a1 = list(think_aloud = think, answer = ans), a2 = pa)
  })
}

sc_iv_mock_code <- function(spec) {
  f <- sc_iv_features(spec$item$statement)
  with_seed(spec$seed + 1L, {
    p <- c(comprehension = 0.08 + 0.5 * f[["negation"]] + 0.3 * f[["double"]] + 0.15 * f[["long"]],
           retrieval = 0.05 + 0.2 * f[["vague"]],
           judgement = 0.08 + 0.4 * f[["double"]] + 0.1 * f[["vague"]],
           response = 0.06,
           sensitivity = 0.04 + 0.45 * f[["sensitive"]])
    hit <- stats::runif(5) < pmin(p, 0.95)
    names(hit) <- sc_iv_stages
    notes <- c(
      comprehension = if (f[["negation"]]) "The negation was misread: \"I think it's asking whether I don't do it... or do?\"" else
        if (f[["double"]]) "Double-barrelled: \"it's really asking two things at once\"" else
          "The meaning of the statement was unclear to the respondent.",
      retrieval = "It is unclear which situations or time to think of: \"It depends on what counts.\"",
      judgement = "Hard to combine two parts: \"one part fits me and the other doesn't\"",
      response = "The midpoint was seen as an escape option: \"the middle option is a bit of a cop-out\"",
      sensitivity = "Invites a socially desirable answer: \"Some people might not want to admit this honestly.\"")
    out <- list()
    for (k in sc_iv_stages) {
      out[[k]] <- hit[[k]]
      out[[paste0(k, "_note")]] <- if (hit[[k]]) notes[[k]] else ""
    }
    out$severity <- if (!any(hit)) "none" else if (sum(hit) >= 2 || hit[["comprehension"]]) "major" else "minor"
    out$revision <- if (!any(hit)) "" else if (f[["negation"]]) "Reword without the negation." else
      if (f[["double"]]) "Split into two statements, one about each part." else
        "Use plainer and more specific wording."
    out
  })
}

sc_iv_mock <- function(instrument, spec) {
  a12 <- sc_iv_mock_answers(instrument, spec)
  sc_iv_result(spec, instrument, a12$a1, a12$a2, sc_iv_mock_code(spec), 0L, character(0))
}

# ---- rows and files ---------------------------------------------------------

sc_iv_rows <- function(res, specs, jobs, pers, m, cd, probes) {
  n <- length(res)
  extra <- setdiff(names(pers), c("persona_id", "description"))
  pid <- c(probes$probe_id, "pretest")
  d <- data.frame(model = rep(m$name, n), provider = rep(m$provider, n),
                  model_id = rep(m$model, n), coder = rep(cd$name, n),
                  persona_id = pers$persona_id[jobs$p], stringsAsFactors = FALSE)
  for (e in extra) d[[e]] <- pers[[e]][jobs$p]
  d$item <- vapply(specs, function(s) s$item$item, character(1))
  d$statement <- vapply(specs, function(s) s$item$statement, character(1))
  d$pretest <- vapply(specs, function(s) if (is.null(s$flag)) NA_character_ else s$flag, character(1))
  d$interview <- as.integer(jobs$r)
  d$answer <- vapply(res, function(r) r$answer, integer(1))
  d$think_aloud <- vapply(res, function(r) r$think, character(1))
  for (k in pid) d[[paste0("probe_", k)]] <- vapply(res, function(r)
    if (is.null(r$probes[[k]])) NA_character_ else r$probes[[k]], character(1))
  for (k in sc_iv_stages) {
    d[[k]] <- vapply(res, function(r) as.logical(r$code[[k]]), logical(1))
    d[[paste0(k, "_note")]] <- vapply(res, function(r) r$code[[paste0(k, "_note")]], character(1))
  }
  d$severity <- vapply(res, function(r) r$code$severity, character(1))
  d$revision <- vapply(res, function(r) r$code$revision, character(1))
  if (n && all(is.na(d$probe_pretest))) d$probe_pretest <- NULL
  if (!n) d$probe_pretest <- NULL
  d
}

sc_iv_write <- function(x, output, format, instrument, models, coder, personas, probes, flags,
                        interviews, seed) {
  d <- as.data.frame(x)
  file <- file.path(output, paste0("interviews.", format))
  switch(format,
         csv = utils::write.csv(d, file, row.names = FALSE, na = ""),
         json = jsonlite::write_json(d, file, pretty = TRUE, na = "null", digits = NA),
         rds = saveRDS(x, file))
  run <- list(
    synthcheck = as.character(utils::packageVersion("synthcheck")),
    created = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    instrument = list(name = instrument$name, min = instrument$min, max = instrument$max,
                      labels = instrument$labels, instructions = instrument$instructions),
    models = lapply(models, function(m) unclass(m)[c("name", "provider", "model", "temperature")]),
    coder = if (is.null(coder)) "each model codes its own interviews" else
      unclass(coder)[c("name", "provider", "model")],
    personas = if (is.null(personas)) NULL else as.data.frame(personas),
    probes = as.data.frame(probes), pretest = flags, interviews = interviews, seed = seed,
    coder_prompt = sc_iv_coder_system)
  jsonlite::write_json(run, file.path(output, "run.json"), auto_unbox = TRUE, pretty = TRUE,
                       null = "null", na = "null", digits = NA)
  tdir <- file.path(output, "transcripts")
  dir.create(tdir, showWarnings = FALSE)
  for (i in unique(d$item))
    writeLines(sc_iv_markdown(x, i), file.path(tdir, paste0(sc_slug(i), ".md")))
  if (!is.null(attr(x, "log")))
    utils::write.csv(attr(x, "log"), file.path(output, "log.csv"), row.names = FALSE)
  invisible(TRUE)
}

# the transcripts of the given items as Markdown lines
sc_iv_markdown <- function(x, items = unique(x$item)) {
  d <- as.data.frame(x)
  probes <- attr(x, "probes") %||% sc_probes()
  pr_all <- as.data.frame(probes)
  unlist(lapply(items, function(i) {
    s <- d[d$item == i, , drop = FALSE]
    if (!nrow(s)) return(character(0))
    md <- c(sprintf("# %s: %s", i, s$statement[1]), "",
            if ("pretest" %in% names(s) && !is.na(s$pretest[1]))
              c(sprintf("Pretest flag: %s", s$pretest[1]), ""),
            "Transcripts written by language models playing personas. A screening aid, not a",
            "substitute for cognitive interviews with real people.", "")
    for (r in seq_len(nrow(s))) {
      pr <- pr_all[c("probe_id", "probe")]
      if ("probe_pretest" %in% names(s) && !is.na(s$probe_pretest[r]))
        pr <- rbind(pr, data.frame(probe_id = "pretest",
                                   probe = sc_iv_flag_probe(s$pretest[r], s[r, , drop = FALSE])))
      pa <- stats::setNames(lapply(pr$probe_id, function(k) s[[paste0("probe_", k)]][r]), pr$probe_id)
      probs <- sc_iv_stages[vapply(sc_iv_stages, function(k) isTRUE(s[[k]][r]), logical(1))]
      md <- c(md, sprintf("## %s, persona %s, interview %d", s$model[r], s$persona_id[r],
                          s$interview[r]), "",
              gsub("\n", "  \n", sc_iv_transcript(s$statement[r], s$think_aloud[r], s$answer[r],
                                                  pr, pa)), "",
              sprintf("**Coding (%s):** %s", s$coder[r],
                      if (!length(probs)) "No problems found." else
                        paste(vapply(probs, function(k) sprintf("%s: %s", sc_iv_stage_names[[k]],
                                                                s[[paste0(k, "_note")]][r]),
                                     character(1)), collapse = "; ")),
              if (!is.na(s$revision[r]) && nzchar(s$revision[r]))
                sprintf("**Suggested rewording:** %s", s$revision[r]), "")
    }
    md
  }))
}
