# The synthcheck app: Generate synthetic respondents with several language
# models and compare them with real data, or pretest a scale without it.

#' Generate and benchmark synthetic data in a Shiny app
#'
#' `run_synthcheck_app()` opens an app that walks through
#' the whole workflow without code. It opens on an **About** tab that
#' explains the purpose of the app, lists what it can do and produce, shows
#' an animated picture of a language model answering survey items and starts
#' a guided tour (the tour needs the cicerone package). The tour follows the
#' path chosen in the first step.
#'
#' **First step:** The About tab asks one question: **Do you already have
#' real responses to this instrument?** The answer chooses one of two paths,
#' and it can be changed at any time, so you can come back with real data
#' later and benchmark the same synthetic data.
#'
#' * **Yes, I have real data:** The fourth tab is **Compare**, the benchmark
#'   against real people.
#' * **No, not yet:** The fourth tab is **Pretest**, followed by
#'   **Interviews**, so Export becomes the sixth tab. Compare is hidden.
#'
#' The tabs, in order (with real data: 1 to 4 and 5. Export; without: 1 to
#' 3, 4. Pretest, 5. Interviews and 6. Export):
#'
#' * **1. Instrument:** Upload an item table or use a built-in instrument
#'   (the IPIP-HEXACO, or one of three short scales with well-documented
#'   item problems: The Rosenberg Self-Esteem Scale, the DASS-21 and the
#'   Mini-IPIP; see [sc_builtin_instrument()]), and set the response scale
#'   and instructions ([sc_instrument()]).
#' * **2. Personas:** Type, upload or build the personas that take the
#'   instrument ([sc_personas()], [sc_persona_grid()]). Both upload panels
#'   offer a template to fill in. The templates are also in the package:
#'   `system.file("templates", "instrument_template.csv", package =
#'   "synthcheck")` and `"personas_template.csv"`.
#' * **3. Models:** Add Anthropic, OpenAI or local Ollama models with their
#'   temperature (or several temperatures, one model each), enter API keys,
#'   choose the number of attempts and respondents, and run
#'   [generate_synthetic()] with a progress bar and the time left. Before a
#'   run with paid models, the app shows its estimated cost
#'   ([estimate_cost()]) and asks you to confirm. Answers are kept in the
#'   response cache ([sc_cache()]), so the same run again is repeatable and
#'   free; choose to reuse, refresh or skip saved answers, or clear them.
#' * **4. Compare** (with real data): Load real data and run
#'   [authenticity_benchmark()], with [gg_benchmark()], [gg_behaviour()]
#'   and a plain-language summary per model ([summarise_benchmark()]).
#' * **4. Pretest** (without real data): Run [synthetic_pretest()] on the
#'   generated data, with [gg_pretest()] and a plain-language summary
#'   ([summarise_pretest()]). Compare the flags across models,
#'   temperatures or personas to see whether they hold. It is pilot
#'   screening, not validation.
#' * **5. Interviews** (without real data): Run [cognitive_interview()]
#'   with the personas and models of tabs 2 and 3, on the items the pretest
#'   flagged or on items you choose (the pretest is optional), and read the
#'   summary ([summarise_interviews()]), the plot ([gg_interview()]) and the
#'   transcripts. A screening aid, not a substitute for cognitive
#'   interviews with real people.
#' * **Export:** Download a results report (HTML or PDF, see
#'   [write_report()]), the synthetic data (CSV, JSON, RDS or Excel), the
#'   benchmark or the pretest and interviews, and an R script that repeats
#'   the analysis.
#'
#' **API keys** typed into the app stay in memory for that session only:
#' They are never written to the saved data, the run settings or the R
#' script. Keys set as `ANTHROPIC_API_KEY` or `OPENAI_API_KEY` (for example
#' in `.Renviron`) are used without being shown. New to API keys? The article
#' [Getting an API key](https://www.okanbulut.com/synthcheck/articles/api-keys.html)
#' walks through signing up with OpenAI or Anthropic, adding credit, keeping
#' the key private and setting a spending limit, and the Models tab links to
#' it next to the key fields.
#'
#' Runs go to a background R process when callr is installed, so the app
#' stays responsive and the Stop button works. Every attempt is written to
#' the output folder as soon as it is done.
#'
#' **Hosting the app:** `run_synthcheck_app()` always runs the full app on
#' your own computer. `synthcheck_app()` returns the same app as an object
#' for a server such as Posit Connect Cloud or shinyapps.io. On a server it
#' runs in hosted mode: Ollama is not offered (local models need the package
#' on your own computer), keys from the server's environment are never used,
#' each visitor types their own keys, which stay in that browser session's
#' memory, and the generated files go to a temporary folder that is deleted
#' when the session ends. The article
#' [Hosting the app](https://www.okanbulut.com/synthcheck/articles/hosting.html)
#' walks through a deployment.
#'
#' The benchmark compares models and
#' supports decisions about them. It does not show that synthetic data can
#' replace a field test.
#'
#' @param real optional data frame of real responses, loaded into the
#'   Compare tab. With real data given, the first step starts on "Yes, I
#'   have real data".
#' @param synthetic optional data frame of synthetic respondents (for
#'   example from [generate_synthetic()] or [read_synthetic()]), loaded into
#'   the Compare and Pretest tabs.
#' @param host,port where to serve the app. The default serves it on your
#'   own computer only.
#' @param launch.browser open the app in a browser?
#' @param hosted run in hosted mode (see above)? The default is `TRUE` when
#'   the option `synthcheck.hosted` is `TRUE`, the environment variable
#'   `SYNTHCHECK_HOSTED` is `"true"`, or the app runs on shinyapps.io or
#'   Posit Connect.
#' @return Invisibly, when the app is closed with its Close button: A list
#'   with `synthetic` (the generated data), `benchmark` (the
#'   [authenticity_benchmark()] result, if one was run), `pretest` (the
#'   [synthetic_pretest()] result, if one was run), `interviews` (the
#'   [cognitive_interview()] result, if one was run), `path` (`"real"`,
#'   `"pretest"` or `NULL`), `instrument` and `personas`.
#'   `synthcheck_app()` returns a Shiny app object.
#' @seealso [generate_synthetic()], [authenticity_benchmark()]
#' @examples
#' if (interactive()) {
#'   res <- run_synthcheck_app()
#'   res$benchmark
#' }
#' # the app object for a server, as in an app.R file
#' app <- synthcheck_app(hosted = TRUE)
#' @export
run_synthcheck_app <- function(real = NULL, synthetic = NULL, host = "127.0.0.1", port = NULL,
                               launch.browser = TRUE) {
  sc_need("shiny", "to run the app")
  sc_need("bslib", "to run the app")
  app <- sc_app(real = real, synthetic = synthetic)
  res <- shiny::runApp(app, host = host, port = port, launch.browser = launch.browser)
  invisible(res)
}

#' @rdname run_synthcheck_app
#' @export
synthcheck_app <- function(real = NULL, synthetic = NULL, hosted = sc_is_hosted()) {
  sc_need("shiny", "to run the app")
  sc_need("bslib", "to run the app")
  sc_app(real = real, synthetic = synthetic, hosted = isTRUE(hosted))
}

# the app object, also used by the tests; run_synthcheck_app() never runs hosted
sc_app <- function(real = NULL, synthetic = NULL, hosted = FALSE) {
  shiny::shinyApp(sc_app_ui(has_real = !is.null(real), has_syn = !is.null(synthetic), hosted = hosted),
                  sc_app_server(real = real, synthetic = synthetic, hosted = hosted))
}

# Is the app on a server? An explicit option or environment variable wins;
# otherwise shinyapps.io (R_CONFIG_ACTIVE) and Posit Connect (RSTUDIO_PRODUCT)
# are detected.
sc_is_hosted <- function() {
  opt <- getOption("synthcheck.hosted")
  if (!is.null(opt)) return(isTRUE(opt))
  env <- tolower(Sys.getenv("SYNTHCHECK_HOSTED"))
  if (env %in% c("true", "1", "yes")) return(TRUE)
  if (env %in% c("false", "0", "no")) return(FALSE)
  identical(Sys.getenv("R_CONFIG_ACTIVE"), "shinyapps") ||
    identical(toupper(Sys.getenv("RSTUDIO_PRODUCT")), "CONNECT")
}

sc_model_choices <- list(
  anthropic = c("claude-haiku-5-5", "claude-sonnet-5-5", "claude-opus-5-5"),
  openai = c("gpt-4.1-nano", "gpt-5-nano", "gpt-4.1-mini", "gpt-4.1"),
  ollama = character(0),
  mock = "mock"
)

sc_trait_choices <- c("Honesty-Humility" = "H", "Emotionality" = "E", "Extraversion" = "X",
                      "Agreeableness" = "A", "Conscientiousness" = "C", "Openness" = "O")

sc_ins_choices <- c("IPIP-HEXACO (built in, 240 items)" = "hexaco",
                    "Rosenberg Self-Esteem Scale (built in, 10 items)" = "rses",
                    "DASS-21 (built in, 21 items)" = "dass21",
                    "Mini-IPIP (built in, 20 items)" = "mini_ipip",
                    "Upload an item table" = "upload")

sc_app_ui <- function(has_real = FALSE, has_syn = FALSE, hosted = FALSE) {
  card <- function(title, ..., id = NULL) bslib::card(id = id, bslib::card_header(title),
                                                      bslib::card_body(fillable = FALSE, ...))
  row <- function(...) {
    args <- list(...)
    w <- 12 %/% length(args)
    do.call(shiny::fluidRow, lapply(args, function(a) shiny::column(w, a)))
  }
  notice <- shiny::div(
    class = "alert alert-warning py-2 mb-3",
    "The benchmark compares models and supports decisions about them. ",
    "It does not show that synthetic data can replace a field test.")

  instrument <- bslib::nav_panel(
    "1. Instrument", value = "instrument", icon = shiny::icon("list-check"),
    notice,
    bslib::layout_columns(
      col_widths = c(5, 7), fill = FALSE,
      card("Items", id = "ins_items_card",
           shiny::selectInput("ins_source", NULL, sc_ins_choices),
           shiny::conditionalPanel(
             "input.ins_source == 'hexaco'",
             shiny::checkboxGroupInput("ins_traits", "Traits", sc_trait_choices,
                                       selected = c("H", "C"), inline = TRUE),
             shiny::helpText("All six traits give 240 items. Two traits (80 items) make faster, cheaper runs.")),
           shiny::conditionalPanel(
             "['rses', 'dass21', 'mini_ipip'].indexOf(input.ins_source) >= 0",
             shiny::checkboxGroupInput("ins_scales", "Scales", character(0), inline = TRUE),
             shiny::uiOutput("ins_about")),
           shiny::conditionalPanel(
             "input.ins_source == 'upload'",
             shiny::fileInput("ins_file", "Item table (CSV or Excel)", accept = c(".csv", ".xlsx")),
             shiny::helpText("Columns: item (short name), statement (the text), and optionally",
                             "scale, facet and reverse (TRUE for reverse-keyed items)."),
             shiny::downloadButton("tpl_instrument", "Download a template", class = "btn-sm")),
           shiny::textInput("ins_name", "Name", "IPIP-HEXACO"),
           row(
             shiny::numericInput("ins_min", "Lowest category", 1, step = 1),
             shiny::numericInput("ins_max", "Highest category", 7, step = 1)),
           shiny::textAreaInput("ins_labels", "Category labels, one per line (lowest first)",
                                paste(sc_default_labels(7), collapse = "\n"), rows = 7),
           shiny::textAreaInput("ins_instructions", "Instructions", sc_default_instructions, rows = 3)),
      bslib::layout_columns(
        col_widths = 12, row_heights = "auto", fill = FALSE,
        card("Check", shiny::uiOutput("ins_status"), shiny::tableOutput("ins_preview")),
        card("Prompt sent for each respondent", id = "ins_prompt_card",
             shiny::verbatimTextOutput("ins_prompt"))))
  )

  personas <- bslib::nav_panel(
    "2. Personas", value = "personas", icon = shiny::icon("users"),
    bslib::layout_columns(
      col_widths = c(5, 7), fill = FALSE,
      card("Personas", id = "per_card",
           shiny::radioButtons("per_source", NULL,
                               c("No persona" = "none", "Type them" = "type",
                                 "Build a grid" = "grid", "Upload a table" = "upload")),
           shiny::conditionalPanel(
             "input.per_source == 'type'",
             shiny::textAreaInput("per_text", "One persona per line",
                                  paste("You are a 34-year-old nurse living in Calgary, Canada.",
                                        "You are a 67-year-old retired farmer in rural Ontario, Canada.",
                                        "You are a 21-year-old university student in Toronto, Canada.",
                                        sep = "\n"), rows = 8)),
           shiny::conditionalPanel(
             "input.per_source == 'grid'",
             shiny::textAreaInput("per_grid", "Attributes, one per line (name: value, value, ...)",
                                  "age: 25, 45, 65\ngender: woman, man\ncountry: Canada, the United States",
                                  rows = 4),
             shiny::textAreaInput("per_template", "Description, with {name} for each attribute",
                                  "You are a {age}-year-old {gender} living in {country}.", rows = 2)),
           shiny::conditionalPanel(
             "input.per_source == 'upload'",
             shiny::fileInput("per_file", "Persona table (CSV or Excel)", accept = c(".csv", ".xlsx")),
             shiny::helpText("A description column, plus optional persona_id and attribute columns",
                             "(kept in the generated data)."),
             shiny::downloadButton("tpl_personas", "Download a template", class = "btn-sm"))),
      card("Preview", shiny::uiOutput("per_status"), shiny::tableOutput("per_preview")))
  )

  models <- bslib::nav_panel(
    "3. Models", value = "models", icon = shiny::icon("microchip"),
    bslib::layout_columns(
      col_widths = c(4, 8), fill = FALSE,
      bslib::layout_columns(
        col_widths = 12, row_heights = "auto", fill = FALSE,
        card("API keys", id = "mod_keys_card",
             shiny::passwordInput("key_anthropic", "Anthropic API key"),
             shiny::uiOutput("key_anthropic_env"),
             shiny::passwordInput("key_openai", "OpenAI API key"),
             shiny::uiOutput("key_openai_env"),
             if (hosted) NULL else shiny::textInput("ollama_url", "Ollama server", "http://localhost:11434"),
             shiny::helpText(if (hosted) paste("Keys stay in this browser session's memory and go only to the",
                                               "provider. They are never saved on the server.") else
                               "Keys stay in memory for this session only. They are never saved."),
             sc_key_help()),
        card("Add a model", id = "mod_add_card",
             shiny::selectInput("mod_provider", "Provider", sc_provider_choices(hosted)),
             if (hosted) sc_hosted_ollama_note(),
             shiny::selectizeInput("mod_model", "Model id", sc_model_choices$anthropic,
                                   options = list(create = TRUE)),
             shiny::actionButton("mod_refresh", "Refresh the model list", class = "btn-sm btn-outline-secondary mb-3"),
             shiny::checkboxInput("mod_send_temp", "Send a temperature", TRUE),
             shiny::sliderInput("mod_temp", "Temperature", min = 0, max = 2, value = 1, step = 0.1),
             shiny::textInput("mod_temps", "Or several temperatures (optional)", "",
                              placeholder = "for example 0.3, 0.7, 1.2"),
             shiny::helpText("Several temperatures add one model per temperature. Without real data,",
                             "the Pretest tab then shows whether the flagged items hold across them."),
             shiny::textInput("mod_name", "Label (optional)", ""),
             shiny::actionButton("mod_add", "Add model", class = "btn-primary"))),
      bslib::layout_columns(
        col_widths = 12, row_heights = "auto", fill = FALSE,
        card("Models in this run",
             shiny::tableOutput("mod_table"),
             shiny::div(shiny::actionButton("mod_remove_last", "Remove last", class = "btn-sm"),
                        shiny::actionButton("mod_clear", "Clear", class = "btn-sm"))),
        card("Run", id = "mod_run_card",
             row(
               shiny::numericInput("run_attempts", "Attempts", 2, min = 1, step = 1),
               shiny::numericInput("run_respondents", "Respondents per persona per attempt", 5, min = 1, step = 1),
               shiny::numericInput("run_parallel", "Calls at the same time", 4, min = 1, max = 32, step = 1)),
             row(
               shiny::numericInput("run_batch", "Respondents per call", 1, min = 1, max = 50, step = 1),
               shiny::numericInput("run_block", "Items per call (0 = all)", 0, min = 0, step = 10),
               shiny::numericInput("run_retries", "Retries for invalid answers", 2, min = 0, max = 5),
               shiny::checkboxInput("run_shuffle", "Shuffle item order per respondent", FALSE)),
             row(
               if (hosted) sc_hosted_folder_note() else
                 shiny::textInput("run_output", "Save to folder",
                                  file.path(getwd(), paste0("synthcheck-run-", format(Sys.Date())))),
               shiny::selectInput("run_format", "File format",
                                  c("CSV" = "csv", "JSON" = "json", "RDS" = "rds", "Excel" = "xlsx"))),
             shiny::conditionalPanel(
               "input.run_batch > 1",
               shiny::div(class = "alert alert-warning py-2 small",
                          "More than one respondent per call is cheaper, but respondents in the same",
                          "call may depend on each other: The model sees its own earlier answers.",
                          "Keep 1 for independent respondents.")),
             row(
               shiny::selectInput("run_cache", "Saved answers (cache)",
                                  c("Reuse saved answers" = "reuse",
                                    "Ask again and replace them" = "refresh",
                                    "Do not save or reuse" = "off")),
               shiny::div(class = "pt-4",
                          shiny::actionButton("cache_clear", "Clear the cache",
                                              class = "btn-sm btn-outline-secondary"))),
             shiny::uiOutput("cache_status"),
             shiny::uiOutput("run_plan"),
             shiny::div(
               shiny::actionButton("run_test", "Estimate run time", class = "btn-outline-primary"),
               shiny::actionButton("run_start", "Generate data", class = "btn-primary"),
               shiny::actionButton("run_stop", "Stop", class = "btn-outline-danger")),
             shiny::uiOutput("run_progress"),
             shiny::verbatimTextOutput("run_log")),
        card("Persona check", id = "mod_fid_card",
             shiny::uiOutput("fid_summary"),
             shiny::uiOutput("fid_plot_ui"))))
  )

  compare <- bslib::nav_panel(
    "4. Compare", value = "compare", icon = shiny::icon("chart-simple"),
    bslib::layout_columns(
      col_widths = c(4, 8), fill = FALSE,
      bslib::layout_columns(
        col_widths = 12, row_heights = "auto", fill = FALSE, id = "cmp_data_card",
        card("Real data",
             shiny::radioButtons("real_source", NULL,
                                 c(if (has_real) c("Data given to run_synthcheck_app()" = "arg"),
                                   "Built in, for the instrument in tab 1" = "builtin",
                                   "Upload" = "upload")),
             shiny::conditionalPanel(
               "input.real_source == 'builtin'",
               shiny::selectInput("real_country", "Country",
                                  c("Canada", "Great Britain", "United States", "All"))),
             shiny::conditionalPanel(
               "input.real_source == 'upload'",
               shiny::fileInput("real_file", "Real responses (CSV, Excel or RDS)",
                                accept = c(".csv", ".xlsx", ".rds"))),
             shiny::uiOutput("real_status")),
        card("Synthetic data",
             shiny::radioButtons("syn_source", NULL,
                                 c("This session's run" = "run",
                                   if (has_syn) c("Data given to run_synthcheck_app()" = "arg"),
                                   "hexaco_llm (built in)" = "hexaco", "Upload files" = "upload"),
                                 selected = if (has_syn) "arg" else "run"),
             shiny::conditionalPanel(
               "input.syn_source == 'hexaco'",
               shiny::selectInput("syn_country", "Country", c("Canada", "Great Britain", "United States")),
               shiny::numericInput("syn_attempts", "Attempts per model", 3, min = 1, max = 10)),
             shiny::conditionalPanel(
               "input.syn_source == 'upload'",
               shiny::fileInput("syn_files", "Files saved by a run", multiple = TRUE,
                                accept = c(".csv", ".json", ".rds", ".xlsx"))),
             shiny::uiOutput("syn_status")),
        card("Benchmark settings",
             shiny::selectInput("bm_score", "Score",
                                c("Weakest column" = "weakest", "Mean" = "mean", "Geometric mean" = "geometric")),
             shiny::checkboxInput("bm_clean", "Remove careless real respondents first", FALSE),
             shiny::checkboxInput("bm_fit", "Include person fit (slower)", TRUE),
             shiny::numericInput("bm_splits", "Real splits and shuffled draws", 20, min = 3, max = 50),
             shiny::helpText("The items come from the Instrument tab."),
             shiny::actionButton("bm_run", "Run the benchmark", class = "btn-primary"))),
      bslib::layout_columns(
        col_widths = 12, row_heights = "auto", fill = FALSE,
        card("Plain-language summary", shiny::uiOutput("bm_summary")),
        card("Synthetic authenticity benchmark", id = "cmp_plot_card", shiny::plotOutput("bm_plot", height = "auto"),
             shiny::tableOutput("bm_table")),
        card("Behaviour strip", shiny::plotOutput("bm_behaviour", height = "360px"))))
  )

  pretest <- bslib::nav_panel(
    "4. Pretest", value = "pretest", icon = shiny::icon("clipboard-check"),
    shiny::div(
      class = "alert alert-warning py-2 mb-3",
      shiny::strong("Pilot screening, not validation. "),
      "Language models answer more tidily than people. The pretest flags items worth a second look;",
      "it does not show that the scale works in people."),
    bslib::layout_columns(
      col_widths = c(4, 8), fill = FALSE,
      bslib::layout_columns(
        col_widths = 12, row_heights = "auto", fill = FALSE, id = "pt_data_card",
        card("Synthetic data",
             shiny::radioButtons("pt_source", NULL,
                                 c("This session's run" = "run",
                                   if (has_syn) c("Data given to run_synthcheck_app()" = "arg"),
                                   "hexaco_llm (built in)" = "hexaco", "Upload files" = "upload"),
                                 selected = if (has_syn) "arg" else "run"),
             shiny::conditionalPanel(
               "input.pt_source == 'hexaco'",
               shiny::selectInput("pt_country", "Country", c("Canada", "Great Britain", "United States")),
               shiny::numericInput("pt_attempts", "Attempts per model", 3, min = 1, max = 10)),
             shiny::conditionalPanel(
               "input.pt_source == 'upload'",
               shiny::fileInput("pt_files", "Files saved by a run", multiple = TRUE,
                                accept = c(".csv", ".json", ".rds", ".xlsx"))),
             shiny::uiOutput("pt_status")),
        card("Pretest settings",
             shiny::selectInput("pt_by", "Compare the flags across",
                                c("Models (each label in the Models tab)" = "model",
                                  "Temperatures" = "temperature",
                                  "Personas" = "persona_id",
                                  "Nothing: Pool all respondents" = "none")),
             shiny::checkboxInput("pt_irt", "Include IRT slopes (graded response model, slower)", FALSE),
             shiny::numericInput("pt_pa", "Random data sets for parallel analysis", 20, min = 0, max = 100),
             shiny::helpText("The items, their scales and reverse keys come from the Instrument tab:",
                             "They are the structure the pretest checks."),
             shiny::div(shiny::actionButton("pt_run", "Run the pretest", class = "btn-primary")))),
      bslib::layout_columns(
        col_widths = 12, row_heights = "auto", fill = FALSE,
        card("Plain-language summary", shiny::uiOutput("pt_summary")),
        card("Flagged items", id = "pt_plot_card", shiny::plotOutput("pt_plot", height = "640px"),
             shiny::tableOutput("pt_table")),
        card("Scales and the structure you designed", id = "pt_structure_card",
             shiny::plotOutput("pt_scales", height = "300px"),
             shiny::tableOutput("pt_structure"))))
  )

  interviews <- bslib::nav_panel(
    "5. Interviews", value = "interviews", icon = shiny::icon("comments"),
    shiny::div(
      class = "alert alert-warning py-2 mb-3",
      shiny::strong("A screening aid, not a substitute for cognitive interviews with real people. "),
      "Language models play your personas, think aloud and answer the probes. The coding points",
      "to wording worth a look; it does not show that an item works in people."),
    bslib::layout_columns(
      col_widths = c(4, 8), fill = FALSE,
      bslib::layout_columns(
        col_widths = 12, row_heights = "auto", fill = FALSE,
        card("Items", id = "iv_items_card",
             shiny::radioButtons("iv_items_from", NULL,
                                 c("Items flagged by the pretest" = "pretest",
                                   "Items I choose" = "choose")),
             shiny::conditionalPanel(
               "input.iv_items_from == 'choose'",
               shiny::selectizeInput("iv_items", "Items to interview about", NULL, multiple = TRUE,
                                     options = list(placeholder = "Pick items from the instrument"))),
             shiny::uiOutput("iv_items_status"),
             shiny::helpText("The pretest is optional. When it has run, flagged items get one more",
                             "probe aimed at the reason for the flag.")),
        card("Interview settings", id = "iv_settings_card",
             shiny::helpText("The personas come from the Personas tab and the models from the Models tab."),
             shiny::selectInput("iv_coder", "Who codes the transcripts", c("Each model codes its own" = "self")),
             shiny::helpText("Another model as coder means no model grades its own interviews."),
             row(shiny::numericInput("iv_n", "Interviews per persona and item", 1, min = 1, max = 10),
                 shiny::numericInput("iv_parallel", "Interviews at the same time", 4, min = 1, max = 32)),
             shiny::textAreaInput("iv_probes", "Probes (one per line, stage: probe)",
                                  sc_probe_text(sc_probes()), rows = 7),
             if (hosted) sc_hosted_folder_note() else
               shiny::textInput("iv_output", "Save to folder",
                                file.path(getwd(), paste0("synthcheck-interviews-", format(Sys.Date())))),
             shiny::helpText("Saved answers follow the cache setting on the Models tab."),
             shiny::uiOutput("iv_plan"),
             shiny::div(shiny::actionButton("iv_run", "Run the interviews", class = "btn-primary"),
                        shiny::actionButton("iv_stop", "Stop", class = "btn-outline-danger")),
             shiny::uiOutput("iv_progress"))),
      bslib::layout_columns(
        col_widths = 12, row_heights = "auto", fill = FALSE,
        card("Plain-language summary", shiny::uiOutput("iv_summary")),
        card("Problems per item", id = "iv_plot_card", shiny::plotOutput("iv_plot", height = "520px"),
             shiny::tableOutput("iv_table")),
        card("Transcripts", id = "iv_transcripts_card",
             shiny::selectInput("iv_view", "Item", NULL),
             shiny::uiOutput("iv_transcripts"))))
  )

  export <- bslib::nav_panel(
    shiny::tagList(shiny::textOutput("exp_num", inline = TRUE), "Export"), value = "export", icon = shiny::icon("download"),
    bslib::layout_columns(
      col_widths = c(12, 6, 6), fill = FALSE,
      card("Results report", id = "exp_report_card",
           shiny::p("One file with the plots, tables and plain-language summaries of this session,",
                    "and the settings needed to repeat the run. It covers the path you chose:",
                    "The benchmark with real data, or the pretest and the interviews without."),
           row(shiny::radioButtons("exp_report_format", "Format",
                                   c("HTML (one self-contained file)" = "html", "PDF" = "pdf"),
                                   inline = TRUE),
               shiny::textInput("exp_report_title", "Title (optional)", "")),
           shiny::uiOutput("exp_report_status"),
           shiny::downloadButton("dl_report", "Download the report", class = "btn-primary")),
      card("Download", id = "exp_dl_card",
           shiny::selectInput("exp_format", "Format for the synthetic data",
                              c("CSV" = "csv", "JSON" = "json", "RDS" = "rds", "Excel" = "xlsx")),
           shiny::downloadButton("dl_synthetic", "Synthetic data"),
           shiny::conditionalPanel(
             "input.sc_path != 'pretest'",
             shiny::downloadButton("dl_benchmark", "Benchmark table (CSV)"),
             shiny::downloadButton("dl_summary", "Summary (text)"),
             shiny::downloadButton("dl_plot", "Benchmark plot (PNG)")),
           shiny::conditionalPanel(
             "input.sc_path != 'real'",
             shiny::downloadButton("dl_pt_items", "Pretest items (CSV)"),
             shiny::downloadButton("dl_pt_summary", "Pretest summary (text)"),
             shiny::downloadButton("dl_pt_plot", "Pretest plot (PNG)"),
             shiny::downloadButton("dl_iv_table", "Interviews (CSV)"),
             shiny::downloadButton("dl_iv_transcripts", "Transcripts (Markdown)"),
             shiny::downloadButton("dl_iv_plot", "Interview plot (PNG)"))),
      card("Repeat it in R", id = "exp_script_card",
           shiny::verbatimTextOutput("exp_script"),
           shiny::downloadButton("dl_script", "R script"),
           shiny::hr(),
           if (hosted) shiny::helpText("Run the script in R with the downloaded data. In R,",
                                       "run_synthcheck_app() also returns the results when you close it.") else
             shiny::tagList(
               shiny::helpText("Close the app to get the data and the benchmark back in R:",
                               "res <- run_synthcheck_app()."),
               shiny::actionButton("app_close", "Close the app and return to R", class = "btn-outline-primary"))))
  )

  shiny::addResourcePath("synthcheck-www", sc_app_www())
  bslib::page_navbar(
    id = "sc_nav",
    title = shiny::tags$span(
      shiny::img(src = "synthcheck-www/logo.png", class = "sc-brand-logo", alt = ""),
      "synthcheck", shiny::span(class = "sc-brand-sub d-none d-lg-inline", "synthetic authenticity benchmark")),
    window_title = "synthcheck",
    fillable = FALSE,
    theme = sc_app_theme(),
    header = shiny::tags$head(
      shiny::tags$link(rel = "stylesheet", href = "synthcheck-www/synthcheck.css"),
      shiny::tags$link(rel = "icon", type = "image/png", href = "synthcheck-www/logo.png"),
      if (sc_has_tour()) cicerone::use_cicerone()),
    sc_app_about(has_real = has_real, hosted = hosted), instrument, personas, models, compare, pretest, interviews, export
  )
}

# the tabs that belong to one path only: Shown for that path, hidden for the
# other (tabs in neither list are on both paths)
sc_path_tabs <- list(real = "compare", pretest = c("pretest", "interviews"))

# probes as editable text, one per line ("stage: probe"), and back
# ---- hosted mode -------------------------------------------------------------

sc_provider_choices <- function(hosted = FALSE) {
  ch <- c("Anthropic" = "anthropic", "OpenAI" = "openai",
          "Ollama (local)" = "ollama", "Mock (random answers, no API)" = "mock")
  if (hosted) ch[ch != "ollama"] else ch
}

sc_hosted_ollama_note <- function() {
  shiny::div(class = "small text-muted mb-3", id = "mod_ollama_hosted",
             shiny::icon("laptop"), shiny::strong("Ollama (local models): "),
             "Not available in the hosted app. To use models on your own computer, install the",
             "R package and run", shiny::tags$code("synthcheck::run_synthcheck_app()", .noWS = "after"), ".")
}

sc_hosted_folder_note <- function() {
  shiny::helpText("The files stay on the server for this session only and are deleted when",
                  "you close the tab. Download what you need from the Export tab.")
}

sc_probe_text <- function(p) paste(sprintf("%s: %s", p$stage, p$probe), collapse = "\n")

sc_parse_probes <- function(x) {
  lines <- trimws(strsplit(x %||% "", "\n")[[1]])
  lines <- lines[nzchar(lines)]
  if (!length(lines)) stop("Give at least one probe.", call. = FALSE)
  m <- regmatches(lines, regexec("^([A-Za-z]+)\\s*:\\s*(.+)$", lines))
  bad <- lengths(m) != 3L
  if (any(bad)) stop("Write each probe as stage: probe, for example ",
                     "\"comprehension: What does this statement mean to you?\"", call. = FALSE)
  stage <- tolower(vapply(m, `[`, "", 2L)); probe <- trimws(vapply(m, `[`, "", 3L))
  # a default probe keeps its default name (paraphrase, terms, ...); a new probe
  # is named after its stage, numbered when the stage has several
  def <- sc_probes()
  hit <- match(paste(stage, probe), paste(def$stage, def$probe))
  id <- def$probe_id[hit]
  new <- is.na(id)
  if (any(new)) id[new] <- utils::tail(make.unique(c(id[!new], stage[new]), sep = "_"), sum(new))
  if (anyDuplicated(id)) id <- make.unique(id, sep = "_")
  sc_probes(stage, probe, probe_id = id)
}

# a Bootstrap 5 theme in the logo colours (navy, the coverage strip blues and reds)
sc_app_theme <- function() {
  bslib::bs_theme(
    version = 5,
    primary = "#1c5cab", secondary = "#5b6475", info = "#86b6ef",
    danger = "#c0302b", warning = "#f0a09a", success = "#1c5cab",
    dark = "#10213d", light = "#f0efec",
    bg = "#f7f6f3", fg = "#1d2433",
    base_font = bslib::font_collection("system-ui", "-apple-system", "Segoe UI", "Roboto",
                                       "Helvetica Neue", "Arial", "sans-serif"),
    "navbar-bg" = "#10213d",
    "card-bg" = "#ffffff",
    "border-radius" = ".45rem"
  )
}

