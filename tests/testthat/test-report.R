rp_items <- function() hexaco_items[hexaco_items$trait %in% c("H", "C"), ]
rp_syn <- function() hexaco_llm[hexaco_llm$country == "Canada" & hexaco_llm$attempt <= 2, ]

test_that("the base64 encoder matches the standard encoding", {
  expect_equal(sc_base64(charToRaw("")), "")
  expect_equal(sc_base64(charToRaw("f")), "Zg==")
  expect_equal(sc_base64(charToRaw("fo")), "Zm8=")
  expect_equal(sc_base64(charToRaw("foo")), "Zm9v")
  expect_equal(sc_base64(charToRaw("foobar")), "Zm9vYmFy")
  skip_if_not_installed("jsonlite")
  r <- as.raw(0:255)
  expect_equal(sc_base64(r), gsub("\\s", "", paste(jsonlite::base64_enc(r), collapse = "")))
})

test_that("write_report() checks its input and format", {
  expect_error(write_report(data.frame(a = 1), tempfile()), "must be a result")
  expect_error(write_report(list(instrument = NULL), tempfile()), "at least one")
  expect_error(write_report(list(benchmark = 1), tempfile()), "authenticity_benchmark")
  expect_equal(sc_report_format("a.PDF", NULL), "pdf")
  expect_equal(sc_report_format("a.html", NULL), "html")
  expect_equal(sc_report_format("a.txt", NULL), "html")
  expect_equal(sc_report_format("a", "htm"), "html")
  expect_error(sc_report_format("a", "docx"), "html")
})

test_that("a pretest report is one self-contained HTML file with the caveat and settings", {
  pt <- synthetic_pretest(rp_syn(), rp_items(), irt = FALSE, n_pa = 0)
  f <- withr::local_tempfile(fileext = ".html")
  ins <- sc_instrument(rp_items(), scale = c(1, 7), name = "HEXACO H and C")
  expect_identical(write_report(list(pretest = pt, instrument = ins, synthetic = rp_syn(), path = "pretest"),
                                f, script = c("library(synthcheck)", "pt <- synthetic_pretest(x)")), f)
  html <- paste(readLines(f, encoding = "UTF-8"), collapse = "\n")
  expect_match(html, "<title>Pretest without real data</title>", fixed = TRUE)
  expect_match(html, "do not show that the scale works in people", fixed = TRUE)
  expect_match(html, "data:image/png;base64,", fixed = TRUE)
  expect_false(grepl("<img[^>]+src=\"(http|file|/)", html))
  expect_match(html, "HEXACO H and C", fixed = TRUE)
  expect_match(html, "Run settings", fixed = TRUE)
  expect_match(html, "Without real data (Pretest and Interviews)", fixed = TRUE)
  expect_match(html, "pt &lt;- synthetic_pretest(x)", fixed = TRUE)
  expect_match(html, "Flagged items", fixed = TRUE)
})

test_that("a benchmark report has the table, the summary and the caveat, in HTML and PDF", {
  skip_on_cran()
  bm <- authenticity_benchmark(as_synthetic_list(rp_syn()), hexaco_real[hexaco_real$country == "Canada", ],
                               rp_items(), fit_scales = character(0), n_splits = 3, n_floor = 3)
  mods <- list(sc_model("mock", name = "Mock A"))
  f <- withr::local_tempfile(fileext = ".html")
  write_report(list(benchmark = bm, models = mods, path = "real"), f, title = "My <models>")
  html <- paste(readLines(f, encoding = "UTF-8"), collapse = "\n")
  expect_match(html, "<title>My &lt;models&gt;</title>", fixed = TRUE)
  expect_match(html, "does not show that synthetic data can replace a field test", fixed = TRUE)
  expect_match(html, summarise_benchmark(bm)$summary[1], fixed = TRUE)
  for (m in bm$table$model) expect_match(html, sprintf("<td>%s</td>", m), fixed = TRUE)
  expect_match(html, "Mock A", fixed = TRUE)
  expect_match(html, "Ceiling splits (n_splits)", fixed = TRUE)

  p <- withr::local_tempfile(fileext = ".pdf")
  write_report(list(benchmark = bm, synthetic = rp_syn()), p)
  expect_gt(file.size(p), 5000)
  expect_identical(readBin(p, "raw", 5), charToRaw("%PDF-"))
})

test_that("an interview report covers the interviews", {
  skip_on_cran()
  it <- data.frame(item = c("q1", "q2"), statement = c("I keep my promises.", "I worry a lot."),
                   scale = c("C", "N"), stringsAsFactors = FALSE)
  iv <- cognitive_interview(sc_instrument(it, scale = c(1, 5)), sc_model("mock"), progress = FALSE)
  f <- withr::local_tempfile(fileext = ".html")
  write_report(iv, f)
  html <- paste(readLines(f, encoding = "UTF-8"), collapse = "\n")
  expect_match(html, "Cognitive interviews", fixed = TRUE)
  expect_match(html, "I keep my promises.", fixed = TRUE)
  p <- withr::local_tempfile(fileext = ".pdf")
  write_report(iv, p)
  expect_identical(readBin(p, "raw", 5), charToRaw("%PDF-"))
})

test_that("long tables are shortened to fit the PDF width", {
  d <- data.frame(a = c("short", strrep("x", 200)), n = c(1, 22), stringsAsFactors = FALSE)
  l <- sc_text_table(d, width = 40)
  expect_length(l, 4)
  expect_true(all(nchar(l) <= 40))
  expect_match(l[4], "...", fixed = TRUE)
})

test_that("the app's Export tab downloads a report for the chosen path", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  skip_on_cran()
  withr::local_options(synthcheck.foreground = TRUE)
  expect_match(as.character(sc_app_ui()), "dl_report", fixed = TRUE)
  shiny::testServer(sc_app_server(), {
    session$setInputs(sc_path = "pretest", ins_source = "hexaco", ins_traits = c("H", "C"),
                      ins_min = 1, ins_max = 7, ins_labels = paste(sc_default_labels(7), collapse = "\n"),
                      ins_instructions = "Answer.", ins_name = "HEXACO", per_source = "none",
                      pt_source = "hexaco", pt_country = "Canada", pt_attempts = 2, pt_by = "model",
                      pt_irt = FALSE, pt_pa = 0, exp_report_format = "html", exp_report_title = "")
    expect_false(report_ready())
    session$setInputs(pt_run = 1)
    expect_s3_class(rv$pretest, "sc_pretest")
    expect_true(report_ready())
    f <- output$dl_report
    html <- paste(readLines(f, encoding = "UTF-8"), collapse = "\n")
    expect_match(html, "Pretest without real data", fixed = TRUE)
    expect_match(html, "Repeat it in R", fixed = TRUE)
  })
})
