test_that("hosted mode is detected only when asked for or on a known server", {
  withr::local_options(synthcheck.hosted = NULL)
  withr::local_envvar(SYNTHCHECK_HOSTED = NA, R_CONFIG_ACTIVE = NA, RSTUDIO_PRODUCT = NA)
  expect_false(sc_is_hosted())
  withr::with_envvar(c(SYNTHCHECK_HOSTED = "true"), expect_true(sc_is_hosted()))
  withr::with_envvar(c(R_CONFIG_ACTIVE = "shinyapps"), expect_true(sc_is_hosted()))
  withr::with_envvar(c(RSTUDIO_PRODUCT = "CONNECT"), expect_true(sc_is_hosted()))
  withr::with_envvar(c(RSTUDIO_PRODUCT = "CONNECT", SYNTHCHECK_HOSTED = "false"),
                     expect_false(sc_is_hosted()))
  withr::with_options(list(synthcheck.hosted = TRUE), expect_true(sc_is_hosted()))
  withr::with_options(list(synthcheck.hosted = FALSE),
                      withr::with_envvar(c(R_CONFIG_ACTIVE = "shinyapps"), expect_false(sc_is_hosted())))
})

test_that("the local app is unchanged and the hosted app leaves out Ollama and the Close button", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  local <- as.character(sc_app_ui())
  hosted <- as.character(sc_app_ui(hosted = TRUE))
  expect_match(local, "Ollama (local)", fixed = TRUE)
  expect_match(local, 'id="ollama_url"', fixed = TRUE)
  expect_match(local, 'id="app_close"', fixed = TRUE)
  expect_match(local, 'id="run_output"', fixed = TRUE)
  expect_no_match(local, 'id="about_hosted"', fixed = TRUE)
  expect_no_match(hosted, "Ollama (local)", fixed = TRUE)
  expect_no_match(hosted, 'id="ollama_url"', fixed = TRUE)
  expect_no_match(hosted, 'id="app_close"', fixed = TRUE)
  expect_no_match(hosted, 'id="run_output"', fixed = TRUE)
  expect_no_match(hosted, 'id="iv_output"', fixed = TRUE)
  expect_match(hosted, 'id="about_hosted"', fixed = TRUE)
  expect_match(hosted, 'id="mod_ollama_hosted"', fixed = TRUE)
  expect_match(hosted, "never saved on the server", fixed = TRUE)
  expect_s3_class(synthcheck_app(hosted = TRUE), "shiny.appobj")
})

test_that("hosted keys blank out the server's own keys while a call runs", {
  withr::local_envvar(ANTHROPIC_API_KEY = "server-key", OPENAI_API_KEY = NA)
  k <- structure(c(ANTHROPIC_API_KEY = "", OPENAI_API_KEY = "visitor-key"), keep_empty = TRUE)
  got <- sc_with_keys(k, Sys.getenv(c("ANTHROPIC_API_KEY", "OPENAI_API_KEY")))
  expect_equal(unname(got), c("", "visitor-key"))
  expect_equal(Sys.getenv("ANTHROPIC_API_KEY"), "server-key")
  expect_equal(Sys.getenv("OPENAI_API_KEY", unset = NA), NA_character_)
  # locally, empty keys leave the environment's keys in place
  local <- c(ANTHROPIC_API_KEY = "", OPENAI_API_KEY = "")
  expect_equal(sc_with_keys(local, Sys.getenv("ANTHROPIC_API_KEY")), "server-key")
  expect_match(as.character(sc_key_note("ANTHROPIC_API_KEY", "", hosted = TRUE)), "No key yet")
  expect_match(as.character(sc_key_note("ANTHROPIC_API_KEY", "")), "from your environment")
})

test_that("a hosted session writes to its own folder and deletes it at the end", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  skip_on_cran()
  withr::local_options(synthcheck.foreground = TRUE)
  withr::local_envvar(ANTHROPIC_API_KEY = "server-key")
  dir <- NULL
  shiny::testServer(sc_app_server(hosted = TRUE), {
    session$setInputs(ins_source = "rses", ins_min = 1, ins_max = 4,
                      ins_labels = paste(sc_default_labels(4), collapse = "\n"),
                      ins_instructions = "Answer.", ins_name = "RSES", ins_scales = "SE",
                      per_source = "grid", per_grid = "age: 25, 65",
                      per_template = "You are {age} years old.")
    output$key_anthropic_env
    expect_match(as.character(output$key_anthropic_env$html), "No key yet")
    session$setInputs(mod_provider = "ollama", mod_model = "llama3", mod_send_temp = FALSE,
                      mod_name = "", mod_temps = "", mod_add = 1)
    expect_length(rv$models, 0)
    session$setInputs(mod_provider = "mock", mod_model = "mock", mod_add = 2)
    expect_length(rv$models, 1)
    session$setInputs(run_attempts = 1, run_respondents = 5, run_block = 0, run_retries = 0,
                      run_shuffle = FALSE, run_parallel = 1, run_batch = 1, run_format = "csv",
                      run_start = 1)
    expect_equal(nrow(rv$run_data), 2 * 5)
    dir <<- sess_dir
    expect_true(startsWith(normalizePath(rv$run_dir), normalizePath(sess_dir)))
    expect_true(startsWith(run_cache()$dir, sess_dir))
    session$setInputs(syn_source = "run", real_source = "builtin", real_country = "All",
                      bm_score = "weakest", bm_clean = FALSE, bm_fit = FALSE, bm_splits = 20)
    expect_match(bm_script(), "path/to/run", fixed = TRUE)
    expect_no_match(bm_script(), sess_dir, fixed = TRUE)
  })
  expect_false(dir.exists(dir))
})
