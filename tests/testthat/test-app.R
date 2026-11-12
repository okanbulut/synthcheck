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
    session$setInputs(real_source = "hexaco", real_country = "Canada", syn_source = "run",
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
  s <- sc_app_script("my_run", "run", "hexaco", "Canada", "weakest", FALSE, TRUE, 20, c("H", "C"))
  expect_match(s, 'read_synthetic("my_run")', fixed = TRUE)
  expect_match(s, 'hexaco_items$trait %in% c("H", "C")', fixed = TRUE)
  expect_match(s, "fit_scales = NULL", fixed = TRUE)
})
