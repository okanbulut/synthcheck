# Downloadable reports of the results: One self-contained HTML or PDF file
# with the plots, tables, plain-language summaries and run settings.

#' Write a report of the results
#'
#' `write_report()` saves one file that holds the results
#' of a synthcheck analysis: The plots, the tables, the plain-language
#' summaries and the settings needed to repeat the run. It covers whichever
#' path was taken. With real data, that is the synthetic authenticity
#' benchmark ([authenticity_benchmark()]). Without real data, it is the
#' pretest ([synthetic_pretest()]) and the cognitive interviews
#' ([cognitive_interview()]).
#'
#' **HTML** (the default) is one self-contained file with the plots embedded,
#' so it can be emailed or archived as it is. **PDF** uses the PDF device
#' that comes with R, so it needs no LaTeX or pandoc. Long table cells are
#' shortened in the PDF. The HTML report shows them in full.
#'
#' The report says what the results can and cannot show. The benchmark
#' compares models and supports decisions about them. It does not show that
#' synthetic data can replace a field test. The pretest and the interviews
#' are screening: They flag items worth a second look, and they do not
#' validate the scale.
#'
#' @param x a result of [authenticity_benchmark()], [synthetic_pretest()] or
#'   [cognitive_interview()], or a list with any of `benchmark`, `pretest`
#'   and `interviews`, such as the list [run_synthcheck_app()] returns. The
#'   list can also hold `synthetic` (the synthetic data), `instrument` (from
#'   [sc_instrument()]), `personas`, `models` (a list of [sc_model()]),
#'   `run` (the settings of a [generate_synthetic()] run, as read from its
#'   `run.json`) and `path` (`"real"` or `"pretest"`). These fill the
#'   settings section of the report.
#' @param file the file to write.
#' @param format `"html"` or `"pdf"`. `NULL` (the default) takes it from the
#'   extension of `file`, and uses HTML when the extension is neither.
#' @param title the report title. `NULL` uses a title that fits the results.
#' @param script optional R code (a character vector) that repeats the
#'   analysis. It is printed at the end of the report.
#' @return `file`, invisibly.
#' @seealso [authenticity_benchmark()], [synthetic_pretest()],
#'   [cognitive_interview()], [run_synthcheck_app()]
#' @examples
#' h <- hexaco_items[hexaco_items$trait %in% c("H", "C"), ]
#' ca <- hexaco_llm[hexaco_llm$country == "Canada" & hexaco_llm$attempt <= 2, ]
#' pt <- synthetic_pretest(ca, h, irt = FALSE, n_pa = 0)
#' f <- tempfile(fileext = ".html")
#' write_report(pt, f)
#' \donttest{
#' real <- hexaco_real[hexaco_real$country == "Canada", ]
#' bm <- authenticity_benchmark(as_synthetic_list(ca), real, h, fit_scales = character(0),
#'                              n_splits = 5, n_floor = 5)
#' write_report(list(benchmark = bm, synthetic = ca), tempfile(fileext = ".pdf"))
#' }
#' @export
write_report <- function(x, file, format = NULL, title = NULL, script = NULL) {
  x <- sc_report_input(x)
  format <- sc_report_format(file, format)
  if (!is.null(script) && !is.character(script))
    stop("`script` must be a character vector of R code.", call. = FALSE)
  rep <- sc_report_blocks(x, title = title, script = script)
  if (format == "html") sc_report_html(rep, file) else sc_report_pdf(rep, file)
  invisible(file)
}

# ---- input ----------------------------------------------------------------

sc_report_input <- function(x) {
  if (inherits(x, "sc_benchmark")) return(list(benchmark = x))
  if (inherits(x, "sc_pretest")) return(list(pretest = x))
  if (inherits(x, "sc_interview")) return(list(interviews = x))
  ok <- is.list(x) && !is.data.frame(x) &&
    any(!vapply(x[intersect(c("benchmark", "pretest", "interviews"), names(x))], is.null, logical(1)))
  if (!ok) stop("`x` must be a result of authenticity_benchmark(), synthetic_pretest() or ",
                "cognitive_interview(), or a list that holds at least one of them.", call. = FALSE)
  if (!is.null(x$benchmark) && !inherits(x$benchmark, "sc_benchmark"))
    stop("`x$benchmark` must be a result of authenticity_benchmark().", call. = FALSE)
  if (!is.null(x$pretest) && !inherits(x$pretest, "sc_pretest"))
    stop("`x$pretest` must be a result of synthetic_pretest().", call. = FALSE)
  if (!is.null(x$interviews) && !inherits(x$interviews, "sc_interview"))
    stop("`x$interviews` must be a result of cognitive_interview().", call. = FALSE)
  x
}

sc_report_format <- function(file, format) {
  if (!is.character(file) || length(file) != 1L || !nzchar(file))
    stop("`file` must be one file name.", call. = FALSE)
  if (is.null(format)) {
    ext <- tolower(tools::file_ext(file))
    format <- if (ext == "pdf") "pdf" else "html"
  }
  format <- tolower(format)
  if (identical(format, "htm")) format <- "html"
  if (length(format) != 1L || !format %in% c("html", "pdf"))
    stop("`format` must be \"html\" or \"pdf\".", call. = FALSE)
  format
}

# ---- content --------------------------------------------------------------

# The report as a list of blocks that both renderers draw: h1, h2, p, note,
# table, plot and code.
sc_report_blocks <- function(x, title = NULL, script = NULL) {
  has_bm <- !is.null(x$benchmark)
  has_pt <- !is.null(x$pretest) || !is.null(x$interviews)
  if (is.null(title)) {
    title <- if (has_bm && has_pt) "synthcheck results" else if (has_bm)
      "Synthetic authenticity benchmark" else "Pretest without real data"
  }
  ins <- x$instrument
  sub <- c(if (!is.null(ins$name)) ins$name,
           sprintf("synthcheck %s", sc_pkg_version()),
           format(Sys.time(), "%Y-%m-%d %H:%M"))
  b <- list()
  add <- function(...) b[[length(b) + 1L]] <<- list(...)

  if (has_bm) {
    add(type = "note", text = paste(
      "The benchmark compares models and supports decisions about them.",
      "It does not show that synthetic data can replace a field test."))
  }
  if (has_pt) {
    add(type = "note", text = paste(
      "The pretest and the interviews are screening on synthetic respondents only. They flag items",
      "worth a second look. They do not show that the scale works in people, and they do not",
      "replace a pilot or cognitive interviews with real respondents."))
  }

  if (has_bm) b <- c(b, sc_report_benchmark(x$benchmark))
  if (!is.null(x$pretest)) b <- c(b, sc_report_pretest(x$pretest))
  if (!is.null(x$interviews)) b <- c(b, sc_report_interviews(x$interviews))
  b <- c(b, sc_report_settings(x))
  if (length(script) && any(nzchar(script))) {
    b[[length(b) + 1L]] <- list(type = "h1", text = "Repeat it in R")
    b[[length(b) + 1L]] <- list(type = "p", text = paste(
      "This script repeats the analysis. Calls to language models give different answers each time,",
      "so read the saved synthetic data rather than generating them again."))
    b[[length(b) + 1L]] <- list(type = "code", text = paste(script, collapse = "\n"))
  }
  b <- b[!vapply(b, is.null, logical(1))]
  list(title = title, subtitle = paste(sub, collapse = "  |  "), blocks = b)
}

sc_report_benchmark <- function(bm) {
  tab <- as.data.frame(bm$table)
  n <- nrow(tab)
  s <- summarise_benchmark(bm)
  cols <- intersect(c("model", "attempts", "score", "weakest", "overlap", "structure", "behaviour"),
                    names(tab))
  t <- tab[cols]
  for (k in intersect(c("score", "overlap", "structure", "behaviour"), cols))
    t[[k]] <- ifelse(is.na(t[[k]]), "-", sprintf("%.0f", t[[k]]))
  if ("weakest" %in% cols) t$weakest <- vapply(t$weakest, function(w)
    if (is.na(w)) "-" else sc_column_name(w), "")
  names(t) <- c(model = "Model", attempts = "Attempts", score = "Score", weakest = "Weakest",
                overlap = "Overlap", structure = "Structure", behaviour = "Behaviour")[cols]
  out <- list(
    list(type = "h1", text = "Synthetic authenticity benchmark"),
    list(type = "p", text = paste(
      "Each column is anchored: 100 is as close as a second sample of real people, 0 is no better",
      "than shuffling the real answers within each item, and below 0 is worse than that.",
      sprintf("The score is %s.", switch(bm$settings$score,
                                         weakest = "the weakest of the three columns",
                                         mean = "the mean of the three columns",
                                         geometric = "the geometric mean of the three columns",
                                         "a custom combination of the three columns")))),
    list(type = "plot", plot = gg_benchmark(bm), height = 1.5 + 0.5 * n),
    list(type = "table", data = t),
    list(type = "h2", text = "In plain language"))
  out <- c(out, lapply(s$summary, function(txt) list(type = "p", text = txt)))
  tl <- as.data.frame(bm$behaviour$summary)
  out <- c(out, list(
    list(type = "h2", text = "Behaviour"),
    list(type = "p", text = paste(
      "How synthetic respondents answer, feature by feature. Red means fewer or lower than real",
      "people, blue means more or higher, and pale means a match.")),
    list(type = "plot", plot = gg_behaviour(bm$behaviour), height = 1.6 + 0.45 * n)))
  if (nrow(tl) && all(c("model", "lz_low", "lz_high") %in% names(tl))) {
    out <- c(out, list(
      list(type = "p", text = paste(
        "Person fit tails: The share of synthetic respondents below the 5th percentile of real",
        "people (careless-like) and above the 95th (too coherent). Real people are 5% and 5%.")),
      list(type = "table", data = data.frame(
        Model = tl$model,
        `Careless-like` = ifelse(is.na(tl$lz_low), "-", sc_pct(tl$lz_low)),
        `Too coherent` = ifelse(is.na(tl$lz_high), "-", sc_pct(tl$lz_high)),
        check.names = FALSE))))
  }
  out
}

sc_report_pretest <- function(pt) {
  s <- as.data.frame(summarise_pretest(pt))
  s <- s[s$topic != "screening", , drop = FALSE]
  ag <- as.data.frame(pt$agreement)
  fl <- ag[ag$flagged_in > 0, , drop = FALSE]
  n_fl <- min(25, nrow(fl))
  summ <- as.data.frame(pt$summary)
  out <- list(list(type = "h1", text = "Pretest without real data"))
  out <- c(out, lapply(s$text, function(txt) list(type = "p", text = txt)))
  out <- c(out, list(
    list(type = "h2", text = "Flagged items"),
    list(type = "plot", plot = gg_pretest(pt, max_items = 25), height = 2 + 0.3 * max(n_fl, 3))))
  top <- utils::head(fl, 25)
  out[[length(out) + 1L]] <- if (nrow(fl)) {
    list(type = "table", data = data.frame(
      Item = top$item, Scale = top$scale,
      `Flagged in` = sprintf("%d of %d", top$flagged_in, top$conditions),
      Flags = top$flags, check.names = FALSE))
  } else list(type = "p", text = "No item is flagged.")
  if (nrow(fl) > 25) out[[length(out) + 1L]] <- list(type = "p", text = sprintf(
    "Showing the 25 items flagged most often, of %d flagged items. The pretest item table holds all of them.",
    nrow(fl)))
  ns <- length(unique(as.data.frame(pt$scales)$scale))
  c(out, list(
    list(type = "h2", text = "Scales and the structure you designed"),
    list(type = "plot", plot = gg_pretest(pt, "scales"), height = 1.8 + 0.3 * max(ns, 3)),
    list(type = "table", data = data.frame(
      Condition = summ$condition, Respondents = summ$n, `Flagged items` = summ$flagged,
      `Mean alpha` = sprintf("%.2f", summ$alpha),
      `Dimensions (designed)` = sprintf("%s (%d)", ifelse(is.na(summ$n_factors), "-", summ$n_factors),
                                        summ$scales),
      `Own scale` = ifelse(is.na(summ$own_scale), "-", sprintf("%.0f%%", 100 * summ$own_scale)),
      `Reverse keys` = ifelse(is.na(summ$reverse_ok), "-", sprintf("%.0f%%", 100 * summ$reverse_ok)),
      check.names = FALSE))))
}

sc_report_interviews <- function(iv) {
  out <- list(list(type = "h1", text = "Cognitive interviews"))
  if (!nrow(iv) || all(is.na(iv$comprehension)))
    return(c(out, list(list(type = "p", text = "No interview finished."))))
  s <- summarise_interviews(iv)
  d <- as.data.frame(s)
  top <- utils::head(d, 25)
  c(out, list(
    list(type = "p", text = attr(s, "text")),
    list(type = "plot", plot = gg_interview(s, max_items = 25),
         height = 2 + 0.3 * max(min(nrow(d), 25), 3)),
    list(type = "table", data = data.frame(
      Item = top$item, Statement = top$statement,
      `Any problem` = sprintf("%.0f%%", 100 * top$any),
      Mostly = ifelse(is.na(top$top_stage), "-", unname(sc_iv_stage_names[top$top_stage])),
      Flagged = ifelse(top$flagged, "yes", ""),
      `Suggested rewording` = ifelse(is.na(top$revisions), "", top$revisions),
      check.names = FALSE)),
    if (nrow(d) > 25) list(type = "p", text = sprintf(
      "Showing 25 of %d items. The interview table and the transcripts hold all of them.", nrow(d)))))
}

# Everything needed to repeat the run, as two-column tables
sc_report_settings <- function(x) {
  out <- list(list(type = "h1", text = "Run settings"),
              list(type = "p", text = "The settings behind these results, so that the analysis can be repeated."))
  kv <- function(...) {
    v <- list(...)
    v <- v[!vapply(v, is.null, logical(1))]
    data.frame(Setting = names(v), Value = vapply(v, sc_report_value, ""), stringsAsFactors = FALSE,
               row.names = NULL)
  }
  tbl <- function(head, d) list(list(type = "h2", text = head), list(type = "table", data = d))

  out <- c(out, tbl("Report", kv(
    Created = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
    synthcheck = sc_pkg_version(),
    R = paste(R.version$major, R.version$minor, sep = "."),
    Path = if (!is.null(x$path)) switch(x$path, real = "With real data (Compare)",
                                        pretest = "Without real data (Pretest and Interviews)", x$path))))

  ins <- x$instrument
  if (!is.null(ins)) {
    it <- as.data.frame(ins$items)
    out <- c(out, tbl("Instrument", kv(
      Name = ins$name, Items = nrow(it),
      Scales = if ("scale" %in% names(it)) length(unique(it$scale)),
      `Reverse-keyed items` = if ("reverse" %in% names(it)) sum(as.logical(it$reverse), na.rm = TRUE),
      `Response scale` = sprintf("%s to %s", ins$min, ins$max),
      Labels = ins$labels, Instructions = ins$instructions)))
  }
  if (!is.null(x$personas) && is.data.frame(x$personas) && nrow(x$personas)) {
    p <- as.data.frame(x$personas)
    out <- c(out, tbl("Personas", kv(
      Personas = nrow(p),
      Examples = if ("description" %in% names(p)) paste(utils::head(p$description, 3), collapse = " | "))))
  }
  mods <- x$models %||% x$run$models
  if (length(mods)) {
    g <- function(m, k) if (is.null(m[[k]])) "-" else as.character(m[[k]])
    out <- c(out, tbl("Models", data.frame(
      Label = vapply(mods, g, "", "name"), Provider = vapply(mods, g, "", "provider"),
      Model = vapply(mods, g, "", "model"),
      Temperature = vapply(mods, function(m) if (is.null(m$temperature)) "provider default" else
        format(m$temperature), ""),
      check.names = FALSE, stringsAsFactors = FALSE)))
  }
  r <- x$run
  if (!is.null(r)) {
    out <- c(out, tbl("Generation run", kv(
      Created = r$created, `synthcheck version` = r$synthcheck, Attempts = r$attempts,
      `Respondents per attempt` = r$respondents, `Respondents per call` = r$batch_size,
      `Items per call` = r$block_size, `Shuffle items` = r$shuffle, Seed = r$seed,
      `Saved as` = r$format)))
  }
  syn <- x$synthetic
  if (is.data.frame(syn) && nrow(syn) && "model" %in% names(syn)) {
    syn <- as.data.frame(syn)
    sp <- split(syn, syn$model)
    out <- c(out, tbl("Synthetic data", data.frame(
      Model = names(sp),
      Attempts = vapply(sp, function(d) if ("attempt" %in% names(d)) length(unique(d$attempt)) else 1L, 1L),
      Respondents = vapply(sp, nrow, 1L), check.names = FALSE, row.names = NULL)))
  }
  bm <- x$benchmark
  if (!is.null(bm)) {
    st <- bm$settings
    out <- c(out, tbl("Benchmark", kv(
      Score = st$score, Weights = if (!is.null(st$weights)) paste(sprintf("%s = %s", names(st$weights),
                                                                         format(st$weights)), collapse = ", "),
      `Real respondents` = st$n_real,
      `Target` = if (isTRUE(st$clean_real)) "Real respondents without careless cases (clean_real = TRUE)" else
        "All real respondents",
      `Careless real respondents removed` = if (isTRUE(st$clean_real) && !is.null(bm$careless))
        sum(as.data.frame(bm$careless)$careless, na.rm = TRUE),
      Items = length(st$items), Correlations = st$cor,
      `Ceiling splits (n_splits)` = st$n_splits, `Floor draws (n_floor)` = st$n_floor,
      `Ceiling sample size` = sprintf("%s (%s)", st$anchor_n, st$ceiling_n),
      `Person fit scales` = if (length(st$fit_scales)) st$fit_scales else "none",
      Seed = st$seed)))
  }
  pt <- x$pretest
  if (!is.null(pt)) {
    st <- pt$settings
    out <- c(out, tbl("Pretest", kv(
      Conditions = st$conditions, `Compared by` = if (length(st$by)) st$by else "none",
      Items = nrow(st$items), `Response scale` = sprintf("%s to %s", st$scale_range[1], st$scale_range[2]),
      `IRT slopes` = st$irt, `Parallel analysis draws` = st$n_pa, Seed = st$seed)))
  }
  iv <- x$interviews
  if (!is.null(iv)) {
    pr <- attr(iv, "probes")
    out <- c(out, tbl("Cognitive interviews", kv(
      Instrument = attr(iv, "instrument"), Interviews = nrow(iv),
      Items = length(unique(iv$item)), Models = unique(iv$model),
      Personas = length(unique(iv$persona_id)),
      Probes = if (!is.null(pr)) nrow(pr),
      Stopped = if (isTRUE(attr(iv, "stopped"))) "yes, before all interviews finished" else "no")))
  }
  out
}

sc_report_value <- function(v) {
  if (is.null(v) || !length(v)) return("-")
  if (is.logical(v)) v <- ifelse(is.na(v), "-", ifelse(v, "yes", "no"))
  if (is.numeric(v)) v <- format(v, big.mark = ",", trim = TRUE)
  v <- as.character(unlist(v))
  v[is.na(v)] <- "-"
  paste(v, collapse = ", ")
}

sc_pkg_version <- function() {
  tryCatch(as.character(utils::packageVersion("synthcheck")), error = function(e) "unknown")
}

# ---- HTML -----------------------------------------------------------------

sc_report_html <- function(rep, file) {
  esc <- sc_html_escape
  body <- vapply(rep$blocks, function(b) {
    switch(b$type,
           h1 = sprintf("<h2>%s</h2>", esc(b$text)),
           h2 = sprintf("<h3>%s</h3>", esc(b$text)),
           p = sprintf("<p>%s</p>", esc(b$text)),
           note = sprintf("<div class=\"note\">%s</div>", esc(b$text)),
           code = sprintf("<pre><code>%s</code></pre>", esc(b$text)),
           table = sc_html_table(b$data),
           plot = sprintf("<figure><img alt=\"\" src=\"data:image/png;base64,%s\"></figure>",
                          sc_plot_base64(b$plot, b$height)),
           "")
  }, "")
  logo <- system.file("app", "www", "logo.png", package = "synthcheck")
  logo <- if (nzchar(logo)) sprintf("<img class=\"logo\" alt=\"\" src=\"data:image/png;base64,%s\">",
                                    sc_base64(readBin(logo, "raw", file.info(logo)$size))) else ""
  html <- c(
    "<!DOCTYPE html>", "<html lang=\"en\">", "<head>", "<meta charset=\"utf-8\">",
    "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
    sprintf("<title>%s</title>", esc(rep$title)),
    "<style>", sc_report_css, "</style>", "</head>", "<body>",
    "<header><div class=\"wrap\">", logo,
    sprintf("<div><h1>%s</h1><div class=\"sub\">%s</div></div>", esc(rep$title), esc(rep$subtitle)),
    "</div><div class=\"strip\"></div></header>",
    "<main class=\"wrap\">", body, "</main>",
    "<footer class=\"wrap\">Made with the synthcheck R package. The benchmark compares models and supports",
    "decisions about them. It does not show that synthetic data can replace a field test.</footer>",
    "</body>", "</html>")
  con <- file(file, open = "w", encoding = "UTF-8")
  on.exit(close(con))
  writeLines(enc2utf8(html), con, useBytes = TRUE)
  invisible(file)
}

sc_report_css <- "
:root { --navy: #10213d; --blue: #1c5cab; --pale: #f0efec; --ink: #1d2433; --muted: #5b6475; }
* { box-sizing: border-box; }
body { margin: 0; background: #f7f6f3; color: var(--ink); line-height: 1.5;
  font-family: system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; }
.wrap { max-width: 920px; margin: 0 auto; padding: 0 16px; }
header { background: var(--navy); color: #fff; }
header .wrap { display: flex; align-items: center; gap: 16px; padding-top: 20px; padding-bottom: 20px; }
header h1 { margin: 0; font-size: 1.6rem; }
header .sub { color: #c9d3e6; font-size: .9rem; }
.logo { width: 56px; height: 56px; }
.strip { height: 6px; background: linear-gradient(90deg, #c0302b 0 20%, #f0a09a 20% 40%, #f0efec 40% 60%,
  #86b6ef 60% 80%, #1c5cab 80% 100%); }
main { background: #fff; padding-top: 8px; padding-bottom: 24px; margin-top: 24px; border-radius: 7px;
  box-shadow: 0 1px 3px rgba(16, 33, 61, .12); }
h2 { color: var(--navy); margin: 1.6em 0 .4em; padding-bottom: .2em; border-bottom: 2px solid var(--pale); }
h3 { color: var(--navy); margin: 1.2em 0 .3em; font-size: 1.1rem; }
.note { background: var(--pale); border-left: 4px solid var(--blue); padding: 10px 14px; margin: 16px 0;
  border-radius: 4px; }
figure { margin: 12px 0; }
figure img { width: 100%; height: auto; display: block; }
.table-scroll { overflow-x: auto; margin: 10px 0 16px; }
table { border-collapse: collapse; width: 100%; font-size: .9rem; }
th { text-align: left; color: var(--navy); border-bottom: 2px solid var(--navy); padding: 6px 8px; }
td { border-bottom: 1px solid #e4e2dc; padding: 5px 8px; vertical-align: top; }
td.num { text-align: right; font-variant-numeric: tabular-nums; }
tbody tr:nth-child(even) { background: #faf9f7; }
pre { background: var(--pale); padding: 12px; border-radius: 4px; overflow-x: auto; font-size: .85rem; }
footer { color: var(--muted); font-size: .85rem; padding-top: 16px; padding-bottom: 32px; }
@media print { body { background: #fff; } main { box-shadow: none; margin-top: 0; }
  figure, table { break-inside: avoid; } }
"

sc_html_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub("\"", "&quot;", x, fixed = TRUE)
}

sc_html_table <- function(d) {
  d <- as.data.frame(d, stringsAsFactors = FALSE)
  cells <- lapply(d, function(v) {
    v <- if (is.numeric(v)) format(v, big.mark = ",", trim = TRUE) else as.character(v)
    v[is.na(v) | v == "NA"] <- "-"
    sc_html_escape(v)
  })
  # numbers, and numbers kept as text (such as "-49" or "42%"), align right
  num <- vapply(cells, function(v) length(v) > 0 && all(grepl("^(-|-?[0-9][0-9.,]*%?)$", v)), logical(1))
  head <- paste(sprintf("<th>%s</th>", sc_html_escape(names(d))), collapse = "")
  rows <- vapply(seq_len(nrow(d)), function(i)
    paste0("<tr>", paste(sprintf("<td%s>%s</td>", ifelse(num, " class=\"num\"", ""),
                                 vapply(cells, `[`, "", i)), collapse = ""), "</tr>"), "")
  paste0("<div class=\"table-scroll\"><table><thead><tr>", head, "</tr></thead><tbody>",
         paste(rows, collapse = ""), "</tbody></table></div>")
}

sc_plot_base64 <- function(plot, height, width = 8, dpi = 150) {
  f <- tempfile(fileext = ".png")
  on.exit(unlink(f))
  ggplot2::ggsave(f, plot, width = width, height = height, dpi = dpi, bg = "white")
  sc_base64(readBin(f, "raw", file.info(f)$size))
}

# base64 in base R, so the HTML report needs no extra package
sc_base64 <- function(raw) {
  if (!length(raw)) return("")
  chars <- c(LETTERS, letters, 0:9, "+", "/")
  pad <- (3L - length(raw) %% 3L) %% 3L
  b <- matrix(as.integer(c(raw, as.raw(rep(0L, pad)))), nrow = 3L)
  v <- b[1L, ] * 65536 + b[2L, ] * 256 + b[3L, ]
  idx <- rbind(v %/% 262144, (v %/% 4096) %% 64, (v %/% 64) %% 64, v %% 64) + 1
  out <- chars[idx]
  if (pad) out[(length(out) - pad + 1L):length(out)] <- "="
  paste(out, collapse = "")
}

# ---- PDF ------------------------------------------------------------------

# Letter pages drawn with grid on the PDF device that ships with R. Cairo,
# where R has it, keeps accented letters; otherwise text is transliterated.
sc_report_pdf <- function(rep, file) {
  # cairo_pdf() can fail without an error where cairo is listed but cannot
  # write (as on some macOS builds); then draw again with pdf()
  if (isTRUE(capabilities("cairo"))) {
    unlink(file)
    ok <- tryCatch({
      suppressWarnings(sc_report_pdf_draw(rep, file, cairo = TRUE))
      file.exists(file) && isTRUE(file.size(file) > 0)
    }, error = function(e) FALSE)
    if (ok) return(invisible(file))
  }
  sc_report_pdf_draw(rep, file, cairo = FALSE)
}

sc_report_pdf_draw <- function(rep, file, cairo) {
  sans <- if (cairo) "sans" else "Helvetica"
  mono <- if (cairo) "mono" else "Courier"
  txt <- if (cairo) identity else function(s) {
    out <- iconv(s, "UTF-8", "ASCII//TRANSLIT", sub = "?")
    ifelse(is.na(out), s, out)
  }
  pw <- 8.5; ph <- 11; m <- 0.75
  w <- pw - 2 * m
  # open our own device and close only that one, so the caller's devices
  # are left alone even when cairo_pdf() fails to open
  before <- grDevices::dev.list()
  if (cairo) grDevices::cairo_pdf(file, width = pw, height = ph, onefile = TRUE) else
    grDevices::pdf(file, width = pw, height = ph, onefile = TRUE, title = txt(rep$title))
  dev <- grDevices::dev.cur()
  if (dev == 1L || dev %in% before) stop("Could not open the PDF device.", call. = FALSE)
  on.exit(grDevices::dev.off(dev))
  st <- new.env()
  st$page <- 0L
  navy <- "#10213d"; blue <- "#1c5cab"; pale <- "#f0efec"; ink <- "#1d2433"; muted <- "#5b6475"
  in_ <- function(v) grid::unit(v, "inches")

  new_page <- function() {
    grid::grid.newpage()
    st$page <- st$page + 1L
    st$y <- m
    grid::grid.text(txt(sprintf("%s  |  page %d", rep$title, st$page)), x = in_(pw - m), y = in_(m / 2),
                    just = c("right", "center"), gp = grid::gpar(fontfamily = sans, fontsize = 7.5, col = muted))
  }
  need <- function(h) if (st$y + h > ph - m) new_page()
  # y measured from the top of the page
  ytop <- function(y) in_(ph - y)
  text_lines <- function(s, size, family = sans, face = "plain", col = ink, indent = 0,
                         width = w - indent, lead = 1.35) {
    cw <- size / 72 * (if (family == mono) 0.6 else 0.5)
    lines <- unlist(lapply(strsplit(txt(s), "\n", fixed = TRUE)[[1]], function(l)
      if (!nzchar(l)) "" else strwrap(l, width = max(20, floor(width / cw)))))
    lh <- size / 72 * lead
    for (l in lines) {
      need(lh)
      grid::grid.text(l, x = in_(m + indent), y = ytop(st$y), just = c("left", "top"),
                      gp = grid::gpar(fontfamily = family, fontsize = size, fontface = face, col = col))
      st$y <- st$y + lh
    }
  }

  # title block
  new_page()
  grid::grid.rect(x = 0, y = ytop(0), width = in_(pw), height = in_(1.35), just = c("left", "top"),
                  gp = grid::gpar(fill = navy, col = NA))
  strip <- c("#c0302b", "#f0a09a", "#f0efec", "#86b6ef", "#1c5cab")
  for (k in 1:5) grid::grid.rect(x = in_((k - 1) * pw / 5), y = ytop(1.35), width = in_(pw / 5),
                                 height = in_(0.08), just = c("left", "top"),
                                 gp = grid::gpar(fill = strip[k], col = NA))
  grid::grid.text(txt(rep$title), x = in_(m), y = ytop(0.55), just = c("left", "center"),
                  gp = grid::gpar(fontfamily = sans, fontsize = 20, fontface = "bold", col = "white"))
  grid::grid.text(txt(rep$subtitle), x = in_(m), y = ytop(0.95), just = c("left", "center"),
                  gp = grid::gpar(fontfamily = sans, fontsize = 10, col = "#c9d3e6"))
  st$y <- 1.75

  blocks <- rep$blocks
  for (bi in seq_along(blocks)) {
    b <- blocks[[bi]]
    # a heading stays on the page of the plot that follows it (after at most one paragraph)
    nx <- blocks[seq.int(bi + 1L, length.out = min(2L, length(blocks) - bi))]
    pl <- Filter(function(z) z$type == "plot", nx)
    pl <- if (length(pl) && (nx[[1]]$type == "plot" || nx[[1]]$type == "p")) pl[[1]] else NULL
    keep <- if (!is.null(pl)) min(pl$height, ph - 2 * m - 0.2) + if (nx[[1]]$type == "p") 1 else 0.5 else 1
    switch(b$type,
           h1 = {
             if (st$y > ph - m - max(1.5, keep + 0.3)) new_page()
             st$y <- st$y + 0.15
             text_lines(b$text, 14, face = "bold", col = navy)
             grid::grid.lines(x = in_(c(m, pw - m)), y = ytop(rep(st$y, 2)),
                              gp = grid::gpar(col = pale, lwd = 2))
             st$y <- st$y + 0.1
           },
           h2 = {
             if (st$y > ph - m - keep) new_page()
             st$y <- st$y + 0.08
             text_lines(b$text, 11.5, face = "bold", col = navy)
             st$y <- st$y + 0.03
           },
           p = { text_lines(b$text, 9.5); st$y <- st$y + 0.08 },
           note = {
             cw <- 9.5 / 72 * 0.5
             n <- length(strwrap(txt(b$text), width = floor((w - 0.3) / cw)))
             h <- n * 9.5 / 72 * 1.35 + 0.16
             need(h)
             grid::grid.rect(x = in_(m), y = ytop(st$y), width = in_(w), height = in_(h),
                             just = c("left", "top"), gp = grid::gpar(fill = pale, col = NA))
             grid::grid.rect(x = in_(m), y = ytop(st$y), width = in_(0.05), height = in_(h),
                             just = c("left", "top"), gp = grid::gpar(fill = blue, col = NA))
             st$y <- st$y + 0.08
             text_lines(b$text, 9.5, indent = 0.2, width = w - 0.3)
             st$y <- st$y + 0.16
           },
           code = { text_lines(b$text, 7.5, family = mono, lead = 1.25); st$y <- st$y + 0.1 },
           table = {
             lines <- sc_text_table(txt_df(b$data, txt), width = floor(w / (7.5 / 72 * 0.6)))
             lh <- 7.5 / 72 * 1.4
             need(lh * min(length(lines), 4))
             for (j in seq_along(lines)) {
               if (st$y + lh > ph - m) {
                 new_page()
                 # repeat the header on the new page
                 if (j > 2) for (hl in lines[1:2]) {
                   grid::grid.text(hl, x = in_(m), y = ytop(st$y), just = c("left", "top"),
                                   gp = grid::gpar(fontfamily = mono, fontsize = 7.5, fontface = "bold", col = navy))
                   st$y <- st$y + lh
                 }
               }
               grid::grid.text(lines[j], x = in_(m), y = ytop(st$y), just = c("left", "top"),
                               gp = grid::gpar(fontfamily = mono, fontsize = 7.5,
                                               fontface = if (j <= 2) "bold" else "plain",
                                               col = if (j <= 2) navy else ink))
               st$y <- st$y + lh
             }
             st$y <- st$y + 0.12
           },
           plot = {
             h <- min(b$height, ph - 2 * m - 0.2)
             pw_ <- w * min(1, h / b$height)
             need(h + 0.1)
             vp <- grid::viewport(x = in_(m), y = ytop(st$y), width = in_(pw_), height = in_(h),
                                  just = c("left", "top"))
             print(b$plot, vp = vp, newpage = FALSE)
             st$y <- st$y + h + 0.12
           })
  }
  invisible(file)
}

txt_df <- function(d, txt) {
  d <- as.data.frame(d, stringsAsFactors = FALSE)
  names(d) <- txt(names(d))
  for (k in seq_along(d)) if (is.character(d[[k]])) d[[k]] <- txt(d[[k]])
  d
}

# A data frame as lines of fixed-width text: The header, a rule and one line
# per row. The widest columns are shortened (with "...") until it fits.
sc_text_table <- function(d, width = 100) {
  d <- as.data.frame(d, stringsAsFactors = FALSE)
  num <- vapply(d, is.numeric, logical(1))
  cells <- lapply(d, function(v) {
    v <- if (is.numeric(v)) format(v, big.mark = ",", trim = TRUE) else as.character(v)
    v[is.na(v) | v == "NA"] <- "-"
    gsub("[\r\n\t]+", " ", v)
  })
  hdr <- names(d)
  wd <- pmax(nchar(hdr), vapply(cells, function(v) if (length(v)) max(nchar(v)) else 0L, 1L))
  gap <- 2L
  while (sum(wd) + gap * (length(wd) - 1L) > width && max(wd) > 6L) {
    k <- which.max(wd)
    wd[k] <- wd[k] - 1L
  }
  cut <- function(v, n) ifelse(nchar(v) > n, paste0(substr(v, 1, max(1L, n - 3L)), "..."), v)
  pad <- function(v, n, right) {
    v <- cut(v, n)
    fill <- strrep(" ", pmax(0L, n - nchar(v)))
    if (right) paste0(fill, v) else paste0(v, fill)
  }
  line <- function(vals) paste(vapply(seq_along(vals), function(k) pad(vals[k], wd[k], num[k]), ""),
                               collapse = strrep(" ", gap))
  c(line(hdr), strrep("-", sum(wd) + gap * (length(wd) - 1L)),
    vapply(seq_len(nrow(d)), function(i) line(vapply(cells, `[`, "", i)), ""))
}
