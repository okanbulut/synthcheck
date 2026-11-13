test_that("the app builds", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  app <- sc_app()
  expect_s3_class(app, "shiny.appobj")
})

test_that("the app generates mock data, benchmarks it and returns it", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  skip_on_cran()
  withr::local_options(synthcheck.foreground = TRUE)
  out <- withr::local_tempdir()
  shiny::testServer(sc_app_server(), {
    session$setInputs(ins_source = "hexaco", ins_traits = "H", ins_min = 1, ins_max = 7,
                      ins_labels = paste(sc_default_labels(7), collapse = "\n"),
                      ins_instructions = "Answer.", ins_name = "HEXACO H",
                      per_source = "grid", per_grid = "age: 25, 65",
                      per_template = "You are {age} years old.")
    expect_equal(nrow(instrument()$items), 40)
    expect_equal(nrow(persona_table()), 2)
    session$setInputs(mod_provider = "mock", mod_model = "mock", mod_send_temp = TRUE, mod_temp = 1,
                      mod_name = "Mock A", ollama_url = "", mod_add = 1)
    session$setInputs(mod_name = "Mock B", mod_add = 2)
    expect_length(rv$models, 2)
    session$setInputs(run_attempts = 2, run_respondents = 30, run_block = 0, run_retries = 0,
                      run_shuffle = FALSE, run_parallel = 1, run_batch = 1, run_output = file.path(out, "run"),
                      run_format = "csv", run_start = 1)
    expect_equal(nrow(rv$run_data), 2 * 2 * 2 * 30)
    expect_equal(rv$run_status$status, "done")
    expect_true(file.exists(file.path(out, "run", "Mock-A_attempt01.csv")))
    session$setInputs(real_source = "builtin", real_country = "Canada", syn_source = "run",
                      bm_score = "weakest", bm_clean = FALSE, bm_fit = FALSE, bm_splits = 3,
                      bm_run = 1)
    expect_s3_class(rv$benchmark, "sc_benchmark")
    expect_setequal(rv$benchmark$table$model, c("Mock A", "Mock B"))
    expect_match(output$exp_script, "authenticity_benchmark", fixed = TRUE)
    res <- result()
    expect_equal(nrow(res$synthetic), 240)
  })
})

test_that("keys typed in the app are set only while the code runs", {
  withr::local_envvar(OPENAI_API_KEY = NA)
  got <- sc_with_keys(c(OPENAI_API_KEY = "sk-test", ANTHROPIC_API_KEY = ""), Sys.getenv("OPENAI_API_KEY"))
  expect_equal(got, "sk-test")
  expect_equal(Sys.getenv("OPENAI_API_KEY", unset = "gone"), "gone")
})

test_that("the R script repeats the comparison", {
  s <- sc_app_script("my_run", "run", "builtin", "Canada", "weakest", FALSE, TRUE, 20,
                     list(name = "hexaco", scales = c("H", "C")))
  expect_match(s, 'read_synthetic("my_run")', fixed = TRUE)
  expect_match(s, 'hexaco_items$trait %in% c("H", "C")', fixed = TRUE)
  expect_match(s, 'hexaco_real[hexaco_real$country %in% "Canada", ]', fixed = TRUE)
  expect_match(s, "fit_scales = NULL", fixed = TRUE)
  s <- sc_app_script("my_run", "run", "builtin", "All", "weakest", FALSE, TRUE, 20,
                     list(name = "dass21", scales = c("D", "A", "S")))
  expect_match(s, "items <- dass_items\n", fixed = TRUE)
  expect_match(s, "real <- dass_real\n", fixed = TRUE)
})

test_that("the app opens on the About tab with the contact details and the tour", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  html <- as.character(sc_app_ui())
  expect_match(html, 'data-value="about"', fixed = TRUE)
  expect_match(html, "Okan Bulut", fixed = TRUE)
  expect_match(html, "mailto:bulut@ualberta.ca", fixed = TRUE)
  expect_match(html, "https://www.okanbulut.com", fixed = TRUE)
  expect_match(html, "<svg", fixed = TRUE)
  expect_true(file.exists(file.path(sc_app_www(), "logo.png")))
  expect_true(file.exists(file.path(sc_app_www(), "synthcheck.css")))
  # every element the tour points to is in the app
  skip_if_not_installed("cicerone")
  tour <- sc_app_tour()
  expect_s3_class(tour, "Cicerone")
  expect_s3_class(sc_app_tour("pretest"), "Cicerone")
  expect_match(html, 'id="about_path"', fixed = TRUE)
  expect_match(html, 'data-value="pretest"', fixed = TRUE)
  ids <- c("about_hero", "about_path", "pt_data_card", "pt_plot_card", "iv_items_card", "iv_plot_card", "ins_items_card", "ins_prompt_card", "per_card", "mod_add_card",
           "mod_run_card", "cmp_data_card", "cmp_plot_card", "exp_dl_card", "exp_script_card",
           "mod_keys_card", "exp_report_card", "pt_structure_card", "iv_settings_card", "iv_transcripts_card")
  for (id in ids) expect_match(html, paste0('id="', id, '"'), fixed = TRUE)
})

test_that("the Models tab links to the API key guide and the providers", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  html <- as.character(sc_app_ui())
  expect_match(html, 'id="mod_key_help"', fixed = TRUE)
  expect_match(html, "https://www.okanbulut.com/synthcheck/articles/api-keys.html", fixed = TRUE)
  expect_match(html, "https://openai.com/api/", fixed = TRUE)
  expect_match(html, "https://platform.claude.com/dashboard", fixed = TRUE)
})

test_that("without real data, the app pretests mock data across temperatures", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  skip_on_cran()
  withr::local_options(synthcheck.foreground = TRUE)
  out <- withr::local_tempdir()
  shiny::testServer(sc_app_server(), {
    session$setInputs(sc_path = "pretest",
                      ins_source = "hexaco", ins_traits = "H", ins_min = 1, ins_max = 7,
                      ins_labels = paste(sc_default_labels(7), collapse = "\n"),
                      ins_instructions = "Answer.", ins_name = "HEXACO H", per_source = "none")
    session$setInputs(mod_provider = "mock", mod_model = "mock", mod_send_temp = TRUE, mod_temp = 1,
                      mod_name = "", mod_temps = "0.5, 1.5", ollama_url = "", mod_add = 1)
    expect_length(rv$models, 2)
    expect_match(vapply(rv$models, `[[`, character(1), "name")[1], "temperature 0.5", fixed = TRUE)
    session$setInputs(run_attempts = 2, run_respondents = 40, run_block = 0, run_retries = 0,
                      run_shuffle = FALSE, run_parallel = 1, run_batch = 1, run_output = file.path(out, "run"),
                      run_format = "csv", run_start = 1)
    expect_equal(nrow(rv$run_data), 2 * 2 * 40)
    session$setInputs(pt_source = "run", pt_by = "temperature", pt_irt = FALSE, pt_pa = 3, pt_run = 1)
    expect_s3_class(rv$pretest, "sc_pretest")
    expect_setequal(rv$pretest$settings$conditions, c("0.5", "1.5"))
    expect_match(output$exp_script, "synthetic_pretest", fixed = TRUE)
    res <- result()
    expect_equal(res$path, "pretest")
    expect_s3_class(res$pretest, "sc_pretest")
  })
})

test_that("temperatures are parsed for the stability check", {
  expect_equal(sc_parse_temps("0.3, 0.7 1"), list(0.3, 0.7, 1))
  expect_equal(sc_parse_temps(""), list())
  expect_s3_class(sc_parse_temps("hot"), "error")
  expect_s3_class(sc_parse_temps("3"), "error")
  s <- sc_pretest_script("my_run", "run", "Canada", 3, "model", FALSE, 20,
                         list(name = "hexaco", scales = "H"))
  expect_match(s, 'synthetic_pretest(synthetic, items, by = "model", irt = FALSE, n_pa = 20)', fixed = TRUE)
})

test_that("without real data, the app runs cognitive interviews with or without a pretest", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  skip_on_cran()
  withr::local_options(synthcheck.foreground = TRUE)
  out <- withr::local_tempdir()
  shiny::testServer(sc_app_server(), {
    session$setInputs(sc_path = "pretest",
                      ins_source = "hexaco", ins_traits = "H", ins_min = 1, ins_max = 7,
                      ins_labels = paste(sc_default_labels(7), collapse = "\n"),
                      ins_instructions = "Answer.", ins_name = "HEXACO H",
                      per_source = "grid", per_grid = "age: 25, 65",
                      per_template = "You are {age} years old.")
    session$setInputs(mod_provider = "mock", mod_model = "mock", mod_send_temp = TRUE, mod_temp = 1,
                      mod_name = "Mock A", mod_temps = "", ollama_url = "", mod_add = 1)
    session$setInputs(mod_name = "Mock B", mod_add = 2)
    # no pretest yet: Items chosen by hand
    session$setInputs(iv_items_from = "choose", iv_items = c("HSinc1", "HFair1"), iv_coder = "Mock B",
                      iv_n = 1, iv_parallel = 1, iv_probes = sc_probe_text(sc_probes()),
                      iv_output = file.path(out, "iv1"), iv_run = 1)
    expect_s3_class(rv$interviews, "sc_interview")
    expect_equal(nrow(rv$interviews), 2 * 2 * 2)
    expect_equal(unique(rv$interviews$coder), "Mock B")
    expect_true(file.exists(file.path(out, "iv1", "transcripts", "HSinc1.md")))
    expect_match(as.character(output$iv_plan$html), "8 interviews")
    # after a pretest: Its flagged items
    session$setInputs(run_attempts = 1, run_respondents = 40, run_block = 0, run_retries = 0,
                      run_shuffle = FALSE, run_parallel = 1, run_batch = 1,
                      run_output = file.path(out, "run"), run_format = "csv", run_start = 1)
    session$setInputs(pt_source = "run", pt_by = "model", pt_irt = FALSE, pt_pa = 3, pt_run = 1)
    flagged <- rv$pretest$agreement$item[rv$pretest$agreement$flagged_in > 0]
    skip_if(!length(flagged), "the mock pretest flags no items")
    flagged <- utils::head(flagged, 3)
    session$setInputs(iv_items_from = "choose", iv_items = flagged, iv_coder = "self",
                      iv_probes = "comprehension: What does this mean to you?",
                      iv_output = file.path(out, "iv2"), iv_run = 2)
    expect_setequal(unique(rv$interviews$item), flagged)
    expect_true("probe_pretest" %in% names(rv$interviews))
    expect_equal(sum(grepl("^probe_", names(rv$interviews))), 2)
    expect_match(output$exp_script, "cognitive_interview(ins, models, personas", fixed = TRUE)
    expect_s3_class(result()$interviews, "sc_interview")
  })
})

test_that("probes typed in the app are parsed", {
  p <- sc_parse_probes("comprehension: What does it mean?\n\nresponse : Was it easy?")
  expect_equal(p$stage, c("comprehension", "response"))
  expect_equal(p$probe[2], "Was it easy?")
  expect_error(sc_parse_probes("no stage here"), "stage: probe")
  expect_error(sc_parse_probes("memory: What?"), "Unknown stage")
  expect_equal(sc_parse_probes(sc_probe_text(sc_probes()))$probe, sc_probes()$probe)
})

test_that("the app uses a short built-in instrument and its real data", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  shiny::testServer(sc_app_server(), {
    session$setInputs(ins_source = "dass21", ins_scales = c("D", "A"), ins_min = 1, ins_max = 4,
                      ins_labels = paste(sc_builtin$dass21$labels, collapse = "\n"),
                      ins_instructions = sc_builtin$dass21$instructions, ins_name = "DASS-21")
    expect_equal(nrow(instrument()$items), 14)
    expect_equal(instrument()$labels[1], "Did not apply to me at all")
    session$setInputs(real_source = "builtin", real_country = "All")
    expect_equal(nrow(real_data()), nrow(dass_real))
    expect_true(all(instrument()$items$item %in% names(real_data())))
    session$setInputs(ins_scales = character(0))
    expect_error(instrument(), "at least one scale")
  })
})

test_that("the app shows the estimated cost and asks before a paid run", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  skip_on_cran()
  withr::local_options(synthcheck.foreground = TRUE)
  out <- withr::local_tempdir()
  shiny::testServer(sc_app_server(), {
    session$setInputs(ins_source = "hexaco", ins_traits = "H", ins_min = 1, ins_max = 7,
                      ins_labels = paste(sc_default_labels(7), collapse = "\n"),
                      ins_instructions = "Answer.", ins_name = "HEXACO H",
                      per_source = "grid", per_grid = "age: 25, 65",
                      per_template = "You are {age} years old.")
    session$setInputs(mod_provider = "openai", mod_model = "gpt-4.1-nano", mod_send_temp = TRUE,
                      mod_temp = 1, mod_name = "Nano", ollama_url = "", mod_add = 1)
    session$setInputs(run_attempts = 2, run_respondents = 5, run_block = 0, run_retries = 0,
                      run_shuffle = FALSE, run_parallel = 1, run_batch = 1, run_cache = "reuse",
                      run_output = file.path(out, "run"), run_format = "csv")
    session$elapse(1000)
    expect_match(as.character(output$run_plan$html), "Estimated cost", fixed = TRUE)
    session$setInputs(run_start = 1)
    expect_false(is.null(rv$pending_run))
    expect_null(rv$run_data)
    expect_s3_class(rv$pending_run$cache, "sc_cache")
  })
})
