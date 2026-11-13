# The About tab of the synthcheck app: Purpose, capabilities, outputs, the
# designer's contact details, an animated picture of a model answering survey
# items and a guided tour (with cicerone, when it is installed).

sc_app_www <- function() system.file("app", "www", package = "synthcheck")

sc_app_about <- function(has_real = FALSE) {
  li <- function(...) shiny::tags$li(...)
  card <- function(title, ..., id = NULL) {
    bslib::card(id = id, bslib::card_header(title), bslib::card_body(fillable = FALSE, ...))
  }
  tour_btn <- shiny::actionButton("tour_start", "Take the guided tour", class = "btn-light btn-lg me-2",
                                  icon = shiny::icon("route"))
  start_btn <- shiny::actionButton("about_start", "Start with the instrument", class = "btn-outline-light btn-lg",
                                   icon = shiny::icon("arrow-right"))

  bslib::nav_panel(
    "About", value = "about", icon = shiny::icon("house"),
    shiny::div(
      class = "sc-hero", id = "about_hero",
      shiny::img(src = "synthcheck-www/logo.png", alt = "synthcheck logo"),
      shiny::div(
        shiny::span(class = "sc-badge", "Experimental"),
        shiny::h1("synthcheck"),
        shiny::p(class = "sc-tagline",
                 "Do synthetic respondents look like real people? Generate survey answers with",
                 "language models and test how authentic they are with the synthetic",
                 "authenticity benchmark, or pretest a new scale before any real data exist."),
        tour_btn, start_btn)),
    card("First step: Do you already have real responses to this instrument?", id = "about_path",
         shiny::radioButtons(
           "sc_path", NULL, inline = TRUE, width = "100%",
           choiceNames = list(
             shiny::span(shiny::strong("Yes, I have real data. "),
                         "Generate synthetic respondents and benchmark them against the real ones."),
             shiny::span(shiny::strong("No, not yet. "),
                         "Pretest the scale on synthetic respondents alone: Item screening, agreement",
                         "across models, the structure you designed and cognitive interviews.")),
           choiceValues = list("real", "pretest"),
           selected = if (has_real) "real" else character(0)),
         shiny::p(class = "small text-muted mb-0",
                  "The answer sets the fourth tab: Compare with real data, or Pretest and Interviews without it.",
                  "You can change it at any time, for example to benchmark the same synthetic data",
                  "once real responses come in.")),
    bslib::layout_columns(
      col_widths = c(7, 5), fill = FALSE,
      card("How a language model answers a survey", id = "about_anim",
           shiny::div(class = "sc-anim", shiny::HTML(sc_app_animation())),
           shiny::p(class = "text-muted small mb-0 mt-2",
                    "Each synthetic respondent is one call to a model: The persona and the items go in,",
                    "and an answer on the response scale comes back for every item. synthcheck then",
                    "puts these answers next to real people's answers to the same items.")),
      card("Purpose",
           shiny::p("Survey researchers increasingly ask language models to stand in for people.",
                    "This app tests whether the synthetic respondents they produce resemble the real",
                    "respondents they are meant to replace. Three indices answer three questions:"),
           shiny::tags$ul(
             class = "sc-list",
             li(shiny::strong("Overlap: "), "Do synthetic respondents land where real people land?"),
             li(shiny::strong("Structure: "), "Do the items relate to each other as they do in real people?"),
             li(shiny::strong("Behaviour: "), "Do synthetic respondents answer the way people do?")),
           shiny::p(class = "mt-3 mb-0",
                    "Each index runs from 0 (shuffled real answers) to 100 (a second sample of real",
                    "people), and the benchmark score is the weakest of the three by default."),
           shiny::div(class = "alert alert-warning py-2 mt-3 mb-0 small",
                      shiny::strong("Experimental. "),
                      "The benchmark compares models and supports decisions about them.",
                      "It does not show that synthetic data can replace a field test."))),
    bslib::layout_columns(
      col_widths = c(4, 4, 4), fill = FALSE,
      card("What the app can do",
           shiny::tags$ul(
             class = "sc-list",
             li("Use the built-in IPIP-HEXACO items or upload your own questionnaire"),
             li("Type, upload or build a grid of personas"),
             li("Generate respondents with Anthropic, OpenAI or local Ollama models, side by side"),
             li("Show a progress bar with the time left, and stop a run at any time"),
             li("Benchmark several models against real data in one table"),
             li("Without real data, pretest a scale on synthetic respondents and see which flagged items hold across models"),
             li("Without real data, run cognitive interviews in which models play your personas and think aloud on the items"),
             li("Explain each model's result in plain language"))),
      card("What it produces",
           shiny::tags$ul(
             class = "sc-list sc-out",
             li("Synthetic data as CSV, JSON, RDS or Excel, saved as each attempt finishes"),
             li("The synthetic authenticity benchmark table and plot"),
             li("A behaviour strip of eight answer features per model"),
             li("A plain-language summary for each model"),
             li("Without real data: Flagged items, their agreement across models and a check of the designed structure"),
             li("Cognitive interview transcripts, coded problems per item and suggested rewordings"),
             li("An R script that repeats the comparison"))),
      card("Designer",
           shiny::div(
             class = "sc-contact",
             shiny::div(class = "sc-name", "Okan Bulut"),
             shiny::div("Professor, Measurement, Evaluation, and Data Science"),
             shiny::div("University of Alberta"),
             shiny::div("E-mail: ", shiny::a(href = "mailto:bulut@ualberta.ca", "bulut@ualberta.ca")),
             shiny::div("Website: ", shiny::a(href = "https://www.okanbulut.com", target = "_blank",
                                              rel = "noopener", "www.okanbulut.com"))),
           shiny::hr(),
           shiny::p(class = "small text-muted mb-0",
                    "synthcheck is an open-source R package (GPL-3). Documentation and tutorials: ",
                    shiny::a(href = "https://www.okanbulut.com/synthcheck/", target = "_blank",
                             rel = "noopener", "okanbulut.com/synthcheck"), "."))),
    card("A quick guided demo",
         shiny::tags$ol(
           class = "sc-steps",
           li(shiny::strong("Instrument: "), "Keep the IPIP-HEXACO items with two traits, or upload your own."),
           li(shiny::strong("Personas: "), "Build a small grid, for example three ages and two genders."),
           li(shiny::strong("Models: "), "Add a model. Choose ", shiny::em("Mock"),
              " to try the app without an API key, then press ", shiny::em("Generate data"), "."),
           li(shiny::strong("Compare: "), "Choose the real data and press ", shiny::em("Run the benchmark"),
              ". Or pick ", shiny::em("hexaco_llm"), " to compare six models without generating anything."),
           li(shiny::strong("Pretest "), "(no real data): Press ", shiny::em("Run the pretest"),
              " to see which items are flagged and whether the models agree."),
           li(shiny::strong("Interviews "), "(no real data): Press ", shiny::em("Run the interviews"),
              " to have each persona think aloud on the flagged items and read what tripped them up."),
           li(shiny::strong("Export: "), "Download the data, the plot and an R script, or close the app",
              " to get everything back in R.")),
         shiny::p(class = "mb-0 small text-muted",
                  if (sc_has_tour()) paste("The guided tour above points to each of these steps in the app.",
                                           "It follows the path you choose in the first step.")
                  else "Install the cicerone package for a guided tour that points to each step in the app."))
  )
}

sc_has_tour <- function() requireNamespace("cicerone", quietly = TRUE)

# the guided tour, one step per main control (cicerone switches the tabs).
# It follows the path chosen on the About tab: With real data (or no answer
# yet) it shows Compare; without real data, Pretest and Interviews.
sc_app_tour <- function(path = NULL) {
  path <- if (identical(path, "pretest")) "pretest" else "real"
  fourth <- if (path == "pretest") list(
    list("pt_data_card", "4. Pretest: The data",
         "Without real data, the pretest screens the items on the synthetic respondents alone: This session's run, the built-in hexaco_llm or saved files.",
         "pretest", "right"),
    list("pt_plot_card", "Flagged items",
         "Items that barely vary, link weakly to their scale, duplicate another item or fight their reverse key, and how many models agree on each flag.",
         "pretest", "left"),
    list("pt_structure_card", "The structure you designed",
         "Reliability per scale, the dimensions parallel analysis finds and whether the scales and reverse keys from the Instrument tab come back. Pilot screening, not validation.",
         "pretest", "left"),
    list("iv_items_card", "5. Interviews: The items",
         "Models play your personas, think aloud on each item and answer probes. Start with the items the pretest flagged, or choose your own: The pretest is optional.",
         "interviews", "right"),
    list("iv_settings_card", "Interview settings",
         "The personas and models come from tabs 2 and 3. Choose who codes the transcripts, edit the probes and run the interviews.",
         "interviews", "right"),
    list("iv_plot_card", "Problems per item",
         "Where the interviews ran into comprehension, retrieval, judgement, response or sensitivity problems. A screening aid, not a substitute for interviews with real people.",
         "interviews", "left"),
    list("iv_transcripts_card", "Transcripts",
         "Read what each persona thought aloud about an item, its answers to the probes and the coder's notes.",
         "interviews", "left")
  ) else list(
    list("cmp_data_card", "4. Compare: The data",
         "Choose the real data and the synthetic data, and the benchmark settings. The built-in hexaco_llm has six models.",
         "compare", "right"),
    list("cmp_plot_card", "The benchmark",
         "Overlap, Structure and Behaviour for every model, from 0 (shuffled real answers) to 100 (a second sample of real people). The summary above explains each model in plain language.",
         "compare", "left"))
  export_text <- if (path == "pretest") {
    "Download the synthetic data, the pretest items, summary and plot, and the interviews with their transcripts."
  } else "Download the synthetic data, the benchmark table, the summary and the plot."
  steps <- c(list(
    list("about_hero", "Welcome to synthcheck",
         paste("This tour walks through the app one step at a time.",
               if (path == "pretest") "It follows the path without real data: Pretest and Interviews."
               else "It follows the path with real data: The benchmark in the Compare tab.",
               "Use the arrow keys or the buttons to move on."),
         "about"),
    list("about_path", "First: Real data or not?",
         paste("With real data, the fourth tab is Compare: The benchmark against real people.",
               "Without it, the fourth tab is Pretest, and the fifth is Interviews.",
               "Change the answer and start the tour again to see the other path."),
         "about"),
    list("ins_items_card", "1. Instrument",
         "Choose the items: The built-in IPIP-HEXACO items or your own item table, with the response scale.",
         "instrument", "right"),
    list("ins_prompt_card", "The prompt",
         "This is exactly what a model reads for each respondent.", "instrument", "left"),
    list("per_card", "2. Personas",
         "Give each synthetic respondent a persona: Type them, build a grid or upload a table.", "personas"),
    list("mod_add_card", "3. Add a model",
         paste("Pick a provider and a model. Mock gives random answers and needs no API key.",
               if (path == "pretest") "Several temperatures add one model per temperature, for the stability check in the Pretest tab."),
         "models", "right"),
    list("mod_run_card", "Generate data",
         "Set the attempts and respondents, estimate the run time and start the run.", "models", "left")),
    fourth, list(
    list("exp_dl_card", if (path == "pretest") "6. Export" else "5. Export", export_text, "export"),
    list("exp_script_card", "Repeat it in R",
         "An R script repeats the analysis. Close the app to get everything back in R.", "export")
  ))
  tour <- cicerone::Cicerone$new(id = "sc_tour", opacity = 0.6, allow_close = TRUE,
                                 stage_background = "#ffffff")
  # cicerone's own tab and tab_id arguments fail in cicerone 1.0.4 (the
  # function that switches tabs loses its step), so switch the tab here
  switch_tab <- function(tab) sprintf(paste0(
    "function(element){var t = $('#sc_nav'); ",
    "Shiny.inputBindings.bindingNames['shiny.bootstrapTabInput'].binding.setValue(t, '%s');}"), tab)
  for (s in steps) tour$step(el = s[[1]], title = s[[2]], description = s[[3]],
                             position = if (length(s) > 4) s[[5]] else "bottom",
                             on_highlight_started = switch_tab(s[[4]]))
  tour
}

# an inline SVG: A persona and an item go to a model, the model fills in a
# 7-point scale item by item, and a coverage strip compares the answers with
# real people. Pure CSS animation, still under prefers-reduced-motion.
sc_app_animation <- function() {
  col <- c(red = "#c0302b", lightred = "#f0a09a", pale = "#f0efec", lightblue = "#86b6ef",
           blue = "#1c5cab", navy = "#10213d", ink = "#1d2433", muted = "#5b6475")
  cycle <- 9
  items <- c("I would never take a bribe.", "I plan ahead.", "I feel anxious often.",
             "I enjoy meeting people.", "I like new ideas.")
  answers <- c(6, 5, 3, 6, 7)
  appear <- round(seq(14, 62, length.out = length(items)))
  strip_at <- 74
  keyframes <- vapply(c(appear, strip_at), function(p) sprintf(
    "@keyframes sc-in-%d { 0%%, %d%% { opacity: 0; } %d%%, 92%% { opacity: 1; } 98%%, 100%% { opacity: 0; } }",
    p, p, p + 3), "")
  css <- paste(c(keyframes,
                 vapply(c(appear, strip_at), function(p) sprintf(
                   ".sc-anim .sc-in-%d { opacity: 0; animation: sc-in-%d %ds ease-out infinite; }", p, p, cycle), ""),
                 "@media (prefers-reduced-motion: reduce) { .sc-anim [class^='sc-in-'] { animation: none; opacity: 1; } }"),
               collapse = "\n")

  x0 <- 668; dx <- 28; y0 <- 92; dy <- 38
  rows <- vapply(seq_along(items), function(i) {
    y <- y0 + (i - 1) * dy
    circles <- vapply(1:7, function(k) sprintf(
      '<circle cx="%d" cy="%d" r="9" fill="#fff" stroke="#c9c6bd" stroke-width="2"/>', x0 + (k - 1) * dx, y), "")
    dot <- sprintf('<g class="sc-in-%d"><circle cx="%d" cy="%d" r="9" fill="%s"/><circle cx="%d" cy="%d" r="13" fill="none" stroke="%s" stroke-width="2" opacity=".35"/></g>',
                   appear[i], x0 + (answers[i] - 1) * dx, y, col[["blue"]],
                   x0 + (answers[i] - 1) * dx, y, col[["blue"]])
    label <- sprintf('<text x="%d" y="%d" font-size="12.5" fill="%s" text-anchor="end">%s</text>',
                     x0 - 16, y + 4, col[["ink"]], items[i])
    paste0(label, paste(circles, collapse = ""), dot)
  }, "")
  scale_lab <- sprintf('<text x="%d" y="66" font-size="11" fill="%s" text-anchor="%s">%s</text>',
                       c(x0 - 9, x0 + 6 * dx + 9), col[["muted"]], c("start", "end"),
                       c("Strongly disagree", "Strongly agree"))
  strip_cols <- col[c("pale", "lightblue", "pale", "lightred", "pale", "pale", "blue", "pale", "pale", "red")]
  strip <- sprintf('<rect x="%d" y="300" width="34" height="22" rx="4" fill="%s" stroke="#e3e1db"/>',
                   360 + (seq_along(strip_cols) - 1) * 38, strip_cols)

  paste0(
    '<svg viewBox="0 0 860 350" role="img" aria-label="A persona and survey items go to a language model, ',
    'which answers each item on a seven-point scale; the answers are then compared with real people." ',
    'font-family="system-ui, -apple-system, Segoe UI, Roboto, sans-serif">',
    '<style>', css, '</style>',
    # 1. persona card
    '<rect x="10" y="40" width="210" height="190" rx="12" fill="#fff" stroke="#e3e1db" stroke-width="1.5"/>',
    '<rect x="10" y="40" width="210" height="34" rx="12" fill="', col[["navy"]], '"/>',
    '<rect x="10" y="62" width="210" height="12" fill="', col[["navy"]], '"/>',
    '<text x="26" y="62" font-size="14" font-weight="600" fill="#fff">Prompt</text>',
    '<circle cx="42" cy="104" r="16" fill="', col[["pale"]], '"/>',
    '<circle cx="42" cy="99" r="6" fill="', col[["muted"]], '"/>',
    '<path d="M31 114 C31 106 53 106 53 114 Z" fill="', col[["muted"]], '"/>',
    '<text x="66" y="100" font-size="12.5" fill="', col[["ink"]], '">You are a 34-year-old</text>',
    '<text x="66" y="116" font-size="12.5" fill="', col[["ink"]], '">nurse in Calgary.</text>',
    '<line x1="26" y1="138" x2="204" y2="138" stroke="#ecebe6"/>',
    '<text x="26" y="160" font-size="12" fill="', col[["muted"]], '">Rate how much you agree</text>',
    '<text x="26" y="176" font-size="12" fill="', col[["muted"]], '">with each statement,</text>',
    '<text x="26" y="192" font-size="12" fill="', col[["muted"]], '">from 1 to 7.</text>',
    '<rect x="26" y="204" width="120" height="8" rx="4" fill="', col[["pale"]], '"/>',
    # flow 1
    '<line class="sc-flow" x1="228" y1="135" x2="300" y2="135" stroke="', col[["blue"]], '" stroke-width="3"/>',
    '<path d="M300 127 L312 135 L300 143 Z" fill="', col[["blue"]], '"/>',
    # 2. the model
    '<g class="sc-pulse"><polygon points="370,78 420,106 420,164 370,192 320,164 320,106" fill="', col[["navy"]],
    '" stroke="', col[["blue"]], '" stroke-width="5" stroke-linejoin="round"/></g>',
    '<text x="370" y="132" font-size="18" font-weight="700" fill="#fff" text-anchor="middle">LLM</text>',
    '<text x="370" y="152" font-size="11" fill="', col[["lightblue"]], '" text-anchor="middle">language model</text>',
    # flow 2
    '<line class="sc-flow" x1="428" y1="135" x2="452" y2="135" stroke="', col[["blue"]], '" stroke-width="3"/>',
    '<path d="M452 127 L464 135 L452 143 Z" fill="', col[["blue"]], '"/>',
    # 3. answers
    '<rect x="470" y="40" width="380" height="226" rx="12" fill="#fff" stroke="#e3e1db" stroke-width="1.5"/>',
    '<text x="486" y="62" font-size="14" font-weight="600" fill="', col[["navy"]], '">Answers</text>',
    paste(scale_lab, collapse = ""), paste(rows, collapse = ""),
    # 4. the comparison
    '<g class="sc-in-', strip_at, '">',
    '<text x="350" y="292" font-size="12.5" fill="', col[["ink"]], '" text-anchor="end">',
    'Compared with real people:</text>', paste(strip, collapse = ""),
    '<text x="360" y="342" font-size="11" fill="', col[["muted"]], '">red: lower than real</text>',
    '<text x="486" y="342" font-size="11" fill="', col[["muted"]], '">pale: a match</text>',
    '<text x="589" y="342" font-size="11" fill="', col[["muted"]], '">blue: higher than real</text>',
    '</g>',
    '<text x="115" y="250" font-size="12" fill="', col[["muted"]], '" text-anchor="middle">1. Persona and items go in</text>',
    '<text x="370" y="220" font-size="12" fill="', col[["muted"]], '" text-anchor="middle">2. The model reads them</text>',
    '</svg>')
}
