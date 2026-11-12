# Server logic of the synthcheck app (see run_synthcheck_app()).

sc_app_server <- function(real = NULL, synthetic = NULL) {
  force(real); force(synthetic)
  function(input, output, session) {
    rv <- shiny::reactiveValues(models = list(), proc = NULL, run_dir = NULL, run_data = NULL,
                                run_status = NULL, timing = NULL, benchmark = NULL, log = NULL,
                                pretest = NULL)

    # ---- About ----------------------------------------------------------------
    shiny::observeEvent(input$about_start, bslib::nav_select("sc_nav", "instrument", session = session))
    shiny::observeEvent(input$tour_start, {
      if (sc_has_tour()) {
        sc_app_tour(input$sc_path)$init()$start()
      } else {
        shiny::showModal(shiny::modalDialog(
          title = "Guided tour",
          "The guided tour needs the cicerone package: install.packages(\"cicerone\").",
          easyClose = TRUE))
      }
    })

    # the first step: With real data, the fourth tab is Compare; without, Pretest
    shiny::observeEvent(input$sc_path, {
      for (p in names(sc_path_tabs)) for (tab in sc_path_tabs[[p]]) {
        if (p == input$sc_path) bslib::nav_show("sc_nav", tab, session = session) else
          bslib::nav_hide("sc_nav", tab, session = session)
      }
    })

    # ---- 1. Instrument -------------------------------------------------------
    shiny::observeEvent(input$ins_source, {
      if (input$ins_source == "hexaco") {
        shiny::updateTextInput(session, "ins_name", value = "IPIP-HEXACO")
        shiny::updateNumericInput(session, "ins_min", value = 1)
        shiny::updateNumericInput(session, "ins_max", value = 7)
      } else shiny::updateTextInput(session, "ins_name", value = "Instrument")
    })
    shiny::observeEvent(list(input$ins_min, input$ins_max), {
      if (is.numeric(input$ins_min) && is.numeric(input$ins_max) && !is.na(input$ins_min) &&
          !is.na(input$ins_max) && input$ins_max > input$ins_min) {
        lab <- sc_default_labels(input$ins_max - input$ins_min + 1)
        shiny::updateTextAreaInput(session, "ins_labels", value = paste(lab, collapse = "\n"))
      }
    }, ignoreInit = TRUE)

    instrument <- shiny::reactive({
      items <- if (input$ins_source == "hexaco") {
        shiny::validate(shiny::need(length(input$ins_traits) > 0, "Choose at least one trait."))
        h <- synthcheck::hexaco_items
        h[h$trait %in% input$ins_traits, , drop = FALSE]
      } else {
        shiny::validate(shiny::need(input$ins_file, "Upload an item table."))
        sc_read_table(input$ins_file$datapath, input$ins_file$name)
      }
      lab <- trimws(strsplit(input$ins_labels %||% "", "\n", fixed = TRUE)[[1]])
      lab <- lab[nzchar(lab)]
      if (!length(lab)) lab <- NULL
      sc_instrument(items, scale = c(input$ins_min, input$ins_max), labels = lab,
                    instructions = input$ins_instructions, name = input$ins_name)
    })
    instrument_ok <- shiny::reactive(tryCatch(instrument(), error = function(e) e))

    output$ins_status <- shiny::renderUI({
      ins <- instrument_ok()
      if (inherits(ins, "error")) return(shiny::div(class = "text-danger", conditionMessage(ins)))
      sc_ok(sprintf("%d items, answers %d to %d%s.", nrow(ins$items), ins$min, ins$max,
                    if ("reverse" %in% names(ins$items))
                      sprintf(", %d reverse-keyed", sum(ins$items$reverse)) else ""))
    })
    output$ins_preview <- shiny::renderTable({
      ins <- instrument(); d <- as.data.frame(ins$items)
      utils::head(d[intersect(c("item", "statement", "scale", "facet", "reverse"), names(d))], 8)
    })
    output$ins_prompt <- shiny::renderText({
      ins <- instrument()
      per <- personas_ok()
      p <- sc_prompt(ins, if (is.null(per) || inherits(per, "error")) NULL else per$description[1],
                     items = utils::head(ins$items$item, 4))
      paste0("SYSTEM\n", p$system, "\n\nUSER (first 4 items shown)\n", p$user)
    })

    output$tpl_instrument <- sc_template_handler("instrument_template.csv")

    # ---- 2. Personas ---------------------------------------------------------
    output$tpl_personas <- sc_template_handler("personas_template.csv")
    persona_table <- shiny::reactive({
      switch(input$per_source,
             none = NULL,
             type = {
               txt <- trimws(strsplit(input$per_text %||% "", "\n", fixed = TRUE)[[1]])
               shiny::validate(shiny::need(any(nzchar(txt)), "Type at least one persona."))
               sc_personas(txt[nzchar(txt)])
             },
             grid = {
               lines <- trimws(strsplit(input$per_grid %||% "", "\n", fixed = TRUE)[[1]])
               lines <- lines[grepl(":", lines, fixed = TRUE)]
               shiny::validate(shiny::need(length(lines) > 0, "Give at least one attribute."))
               att <- lapply(lines, function(l) trimws(strsplit(sub("^[^:]*:", "", l), ",")[[1]]))
               names(att) <- trimws(sub(":.*$", "", lines))
               do.call(sc_persona_grid, c(att, list(template = input$per_template)))
             },
             upload = {
               shiny::validate(shiny::need(input$per_file, "Upload a persona table."))
               sc_personas(sc_read_table(input$per_file$datapath, input$per_file$name))
             })
    })
    personas_ok <- shiny::reactive(tryCatch(persona_table(), error = function(e) e))
    output$per_status <- shiny::renderUI({
      p <- personas_ok()
      if (inherits(p, "error")) return(shiny::div(class = "text-danger", conditionMessage(p)))
      if (is.null(p)) return(sc_ok("No persona: Every respondent gets the same plain prompt."))
      sc_ok(sprintf("%d personas.", nrow(p)))
    })
    output$per_preview <- shiny::renderTable({
      p <- persona_table()
      if (is.null(p)) return(NULL)
      utils::head(as.data.frame(p), 12)
    })

    # ---- 3. Models -----------------------------------------------------------
    output$key_anthropic_env <- shiny::renderUI(sc_key_note("ANTHROPIC_API_KEY", input$key_anthropic))
    output$key_openai_env <- shiny::renderUI(sc_key_note("OPENAI_API_KEY", input$key_openai))

    shiny::observeEvent(input$mod_provider, {
      ch <- sc_model_choices[[input$mod_provider]]
      if (input$mod_provider == "ollama") ch <- sc_ollama_models(input$ollama_url)
      shiny::updateSelectizeInput(session, "mod_model", choices = ch, selected = ch[1],
                                  options = list(create = TRUE))
    })
    shiny::observeEvent(input$mod_refresh, {
      ch <- tryCatch(sc_with_keys(keys(), sc_list_models(input$mod_provider, input$ollama_url)),
                     error = function(e) {
                       shiny::showNotification(paste("Could not list models:", conditionMessage(e)),
                                               type = "warning")
                       NULL
                     })
      if (length(ch)) shiny::updateSelectizeInput(session, "mod_model", choices = ch, selected = ch[1],
                                                  options = list(create = TRUE))
    })
    keys <- shiny::reactive(c(ANTHROPIC_API_KEY = input$key_anthropic %||% "",
                              OPENAI_API_KEY = input$key_openai %||% ""))

    shiny::observeEvent(input$mod_add, {
      temps <- sc_parse_temps(input$mod_temps)
      if (inherits(temps, "error")) return(shiny::showNotification(conditionMessage(temps), type = "error"))
      several <- length(temps) > 0
      if (!several) temps <- list(if (isTRUE(input$mod_send_temp)) input$mod_temp else NULL)
      for (tp in temps) {
        lab <- trimws(input$mod_name %||% "")
        if (several) lab <- sprintf("%s (temperature %s)", if (nzchar(lab)) lab else input$mod_model, format(tp))
        m <- tryCatch(sc_model(input$mod_provider, input$mod_model, temperature = tp, name = lab,
                               base_url = if (input$mod_provider == "ollama") input$ollama_url else NULL),
                      error = function(e) e)
        if (inherits(m, "error")) return(shiny::showNotification(conditionMessage(m), type = "error"))
        names_now <- vapply(rv$models, `[[`, character(1), "name")
        if (m$name %in% names_now) {
          m$name <- sprintf("%s (temperature %s)", m$name,
                            if (is.null(m$temperature)) "default" else format(m$temperature))
          if (m$name %in% names_now) {
            shiny::showNotification(sprintf("%s is already in the run.", m$name), type = "warning")
            next
          }
        }
        rv$models <- c(rv$models, list(m))
      }
      shiny::updateTextInput(session, "mod_name", value = "")
      shiny::updateTextInput(session, "mod_temps", value = "")
    })
    shiny::observeEvent(input$mod_remove_last, if (length(rv$models)) rv$models <- rv$models[-length(rv$models)])
    shiny::observeEvent(input$mod_clear, rv$models <- list())
    output$mod_table <- shiny::renderTable({
      if (!length(rv$models)) return(data.frame(Note = "No models yet. Add one on the left."))
      data.frame(Label = vapply(rv$models, `[[`, character(1), "name"),
                 Provider = vapply(rv$models, `[[`, character(1), "provider"),
                 Model = vapply(rv$models, `[[`, character(1), "model"),
                 Temperature = vapply(rv$models, function(m)
                   if (is.null(m$temperature)) "not sent" else format(m$temperature), character(1)))
    })

    n_calls <- shiny::reactive({
      p <- personas_ok()
      np <- if (is.null(p) || inherits(p, "error")) 1L else nrow(p)
      length(rv$models) * max(1, input$run_attempts %||% 1) * np * max(1, input$run_respondents %||% 1)
    })
    output$run_plan <- shiny::renderUI({
      n <- n_calls()
      if (!length(rv$models)) return(shiny::p(class = "text-muted", "Add at least one model to plan a run."))
      per <- n / length(rv$models)
      est <- if (!is.null(rv$timing)) {
        secs <- sum(ceiling(per / max(1, input$run_batch %||% 1)) * rv$timing$seconds[match(vapply(rv$models, `[[`, character(1), "name"),
                                                  rv$timing$model)], na.rm = TRUE) /
          max(1, input$run_parallel %||% 1)
        sprintf(" From the test calls, the run should take about %s.", sc_duration(secs))
      } else " Click Estimate run time to send one test call per model and see how long the run should take."
      # with batches, the test call times one batch
      b <- max(1, input$run_batch %||% 1)
      calls <- if (b > 1) sprintf(" in about %s calls", format(ceiling(n / b), big.mark = ",")) else ""
      shiny::p(sprintf("%s synthetic respondents%s: %d model%s, %s per model.", format(n, big.mark = ","),
                       calls, length(rv$models), if (length(rv$models) > 1) "s" else "",
                       format(per, big.mark = ",")), est)
    })

    shiny::observeEvent(input$run_test, {
      ins <- instrument_ok()
      if (inherits(ins, "error") || !length(rv$models))
        return(shiny::showNotification("Define the instrument and add a model first.", type = "warning"))
      p <- personas_ok(); desc <- if (is.null(p) || inherits(p, "error")) NA_character_ else p$description[1]
      shiny::withProgress(message = "Sending one test call per model", value = 0, {
        tm <- lapply(seq_along(rv$models), function(i) {
          m <- rv$models[[i]]
          shiny::incProgress(1 / length(rv$models), detail = m$name)
          b <- max(1L, as.integer(input$run_batch %||% 1L))
          r <- tryCatch(sc_with_keys(keys(), sc_respondent(m, ins, desc, ins$items$item, 1L,
                                                           if (isTRUE(input$run_block > 0)) input$run_block else NULL,
                                                           0L, k = b)),
                        error = function(e) list(list(seconds = NA_real_, ok = FALSE, errors = conditionMessage(e))))
          r <- list(seconds = r[[1]]$seconds, ok = all(vapply(r, `[[`, logical(1), "ok")),
                    errors = unique(unlist(lapply(r, `[[`, "errors"))))
          data.frame(model = m$name, seconds = r$seconds, ok = r$ok,
                     error = paste(r$errors, collapse = " | "), stringsAsFactors = FALSE)
        })
      })
      rv$timing <- do.call(rbind, tm)
      bad <- rv$timing[!rv$timing$ok, , drop = FALSE]
      if (nrow(bad)) shiny::showNotification(
        paste0(bad$model, ": ", ifelse(nzchar(bad$error), bad$error, "invalid answers"), collapse = "\n"),
        type = "warning", duration = 15)
    })

    run_args <- function() {
      ins <- instrument(); p <- persona_table()
      list(instrument = ins, models = rv$models, personas = p,
           attempts = as.integer(input$run_attempts), respondents = as.integer(input$run_respondents),
           batch_size = max(1L, as.integer(input$run_batch %||% 1L)),
           block_size = if (isTRUE(input$run_block > 0)) as.integer(input$run_block) else NULL,
           shuffle = isTRUE(input$run_shuffle), max_retries = as.integer(input$run_retries),
           parallel = as.integer(input$run_parallel), output = input$run_output,
           format = input$run_format, progress = FALSE,
           progress_file = file.path(input$run_output, "progress.json"),
           stop_file = file.path(input$run_output, "STOP"))
    }

    shiny::observeEvent(input$run_start, {
      if (!is.null(rv$proc) && rv$proc$is_alive())
        return(shiny::showNotification("A run is already going.", type = "warning"))
      if (!length(rv$models)) return(shiny::showNotification("Add at least one model.", type = "warning"))
      args <- tryCatch(run_args(), error = function(e) e)
      if (inherits(args, "error"))
        return(shiny::showNotification(conditionMessage(args), type = "error"))
      if (dir.exists(args$output) && length(setdiff(list.files(args$output),
                                                    c("progress.json", "STOP"))))
        return(shiny::showNotification("The output folder already holds files. Choose a new folder.",
                                       type = "warning", duration = 10))
      dir.create(args$output, showWarnings = FALSE, recursive = TRUE)
      unlink(args$stop_file)
      rv$run_dir <- args$output; rv$run_data <- NULL; rv$run_status <- NULL; rv$log <- NULL
      if (sc_can_background()) {
        k <- keys(); k <- k[nzchar(k)]
        # keys go to the child's environment, never into the argument file callr writes
        rv$proc <- callr::r_bg(function(args) do.call(synthcheck::generate_synthetic, args),
                               args = list(args = args), env = c(callr::rcmd_safe_env(), k),
                               supervise = TRUE)
      } else {
        prog <- shiny::Progress$new(session, min = 0, max = 1)
        on.exit(prog$close())
        args$progress <- function(info) {
          prog$set(value = if (info$total) info$done / info$total else 1,
                   message = sprintf("%d of %d respondents", info$done, info$total),
                   detail = sprintf("%s, attempt %d. Time left: %s", info$model, info$attempt,
                                    sc_duration(info$eta)))
          rv$run_status <- info
        }
        res <- tryCatch(sc_with_keys(keys(), do.call(generate_synthetic, args)), error = function(e) e)
        if (inherits(res, "error")) {
          shiny::showNotification(conditionMessage(res), type = "error", duration = NULL)
        } else {
          rv$run_data <- res; rv$log <- attr(res, "log")
        }
      }
    })
    shiny::observeEvent(input$run_stop, {
      if (!is.null(rv$run_dir)) writeLines("stop", file.path(rv$run_dir, "STOP"))
      shiny::showNotification("Stopping after the calls in progress. Finished attempts are kept.")
    })

    # poll the background run
    shiny::observe({
      proc <- rv$proc
      if (is.null(proc)) return()
      shiny::invalidateLater(500)
      f <- file.path(rv$run_dir, "progress.json")
      if (file.exists(f)) {
        info <- tryCatch(jsonlite::fromJSON(f, simplifyVector = FALSE), error = function(e) NULL)
        if (!is.null(info)) rv$run_status <- info
      }
      if (!proc$is_alive()) {
        res <- tryCatch(proc$get_result(), error = function(e) e)
        rv$proc <- NULL
        if (inherits(res, "error")) {
          msg <- conditionMessage(if (!is.null(res$parent)) res$parent else res)
          shiny::showNotification(paste("The run failed:", msg), type = "error", duration = NULL)
        } else {
          rv$run_data <- res; rv$log <- attr(res, "log")
          shiny::showNotification(sprintf("Done: %d synthetic respondents in %s.", nrow(res), rv$run_dir),
                                  type = "message", duration = 10)
        }
      }
    })

    output$run_progress <- shiny::renderUI({
      s <- rv$run_status
      if (is.null(s)) return(NULL)
      bar <- function(done, total, label) {
        pct <- if (total > 0) round(100 * done / total) else 0
        shiny::div(class = "mb-2",
                   shiny::div(class = "d-flex justify-content-between small",
                              shiny::span(label), shiny::span(sprintf("%d / %d", done, total))),
                   shiny::div(class = "progress", role = "progressbar", style = "height: 1.1rem;",
                              shiny::div(class = "progress-bar", style = sprintf("width: %d%%;", pct),
                                         sprintf("%d%%", pct))))
      }
      per <- lapply(s$per_model, function(p) bar(p$done, p$total, p$model))
      head <- switch(s$status %||% "running",
                     running = sprintf("Running %s, attempt %s. Elapsed %s, about %s left.", s$model,
                                       s$attempt, sc_duration(s$elapsed), sc_duration(s$eta)),
                     stopped = sprintf("Stopped after %s. Finished attempts are saved.", sc_duration(s$elapsed)),
                     done = sprintf("Done in %s.", sc_duration(s$elapsed)))
      shiny::div(class = "mt-3",
                 shiny::p(shiny::strong(head),
                          if ((s$failed %||% 0) > 0) sprintf(" %d respondents with missing answers.", s$failed),
                          if ((s$retries %||% 0) > 0) sprintf(" %d retries.", s$retries)),
                 bar(s$done, s$total, "All models"), per)
    })
    output$run_log <- shiny::renderText({
      l <- rv$log
      if (is.null(l) || !nrow(l)) return(if (is.null(rv$run_data)) "" else "No failed calls.")
      paste(utils::head(sprintf("%s, attempt %d, %s #%d: %s", l$model, l$attempt, l$persona_id,
                                l$respondent, l$error), 20), collapse = "\n")
    })

    # ---- 4. Compare ----------------------------------------------------------
    real_data <- shiny::reactive({
      switch(input$real_source,
             arg = as.data.frame(real),
             hexaco = {
               h <- synthcheck::hexaco_real
               if (input$real_country == "All") h else h[h$country == input$real_country, ]
             },
             upload = {
               shiny::validate(shiny::need(input$real_file, "Upload the real responses."))
               sc_read_table(input$real_file$datapath, input$real_file$name)
             })
    })
    syn_from <- function(source, country, attempts, files) {
      switch(source,
             run = {
               shiny::validate(shiny::need(!is.null(rv$run_data) && nrow(rv$run_data) > 0,
                                           "Generate data in the Models tab first, or choose another source."))
               rv$run_data
             },
             arg = as.data.frame(synthetic),
             hexaco = {
               h <- synthcheck::hexaco_llm
               h[h$country == country & h$attempt <= attempts, ]
             },
             upload = {
               shiny::validate(shiny::need(files, "Upload the files saved by a run."))
               f <- files
               parts <- lapply(seq_len(nrow(f)), function(i) {
                 ext <- tolower(tools::file_ext(f$name[i]))
                 as.data.frame(read_synthetic(f$datapath[i], format = ext))
               })
               cols <- unique(unlist(lapply(parts, names)))
               do.call(rbind, lapply(parts, function(d) { d[setdiff(cols, names(d))] <- NA; d[cols] }))
             })
    }
    syn_data <- shiny::reactive(syn_from(input$syn_source, input$syn_country, input$syn_attempts,
                                         input$syn_files))
    bm_items <- shiny::reactive(as.data.frame(instrument()$items))

    output$real_status <- shiny::renderUI({
      r <- tryCatch(real_data(), error = function(e) e)
      if (inherits(r, "error")) return(shiny::div(class = "text-danger", conditionMessage(r)))
      it <- tryCatch(bm_items()$item, error = function(e) character(0))
      sc_ok(sprintf("%s real respondents; %d of %d instrument items found.",
                    format(nrow(r), big.mark = ","), length(intersect(it, names(r))), length(it)))
    })
    output$syn_status <- shiny::renderUI({
      s <- tryCatch(syn_data(), error = function(e) e)
      if (inherits(s, "error")) return(shiny::div(class = "text-muted", conditionMessage(s)))
      if (!"model" %in% names(s)) return(shiny::div(class = "text-danger", "The data need a `model` column."))
      sc_ok(sprintf("%s synthetic respondents from %d model%s.", format(nrow(s), big.mark = ","),
                    length(unique(s$model)), if (length(unique(s$model)) > 1) "s" else ""))
    })

    shiny::observeEvent(input$bm_run, {
      res <- tryCatch({
        it <- bm_items(); r <- real_data(); s <- syn_data()
        miss <- setdiff(it$item, intersect(names(r), names(s)))
        if (length(miss) == nrow(it)) stop("No instrument item is a column of both the real and the synthetic data.")
        if (length(miss)) shiny::showNotification(sprintf("%d items are missing from the data and left out.",
                                                          length(miss)), type = "warning")
        shiny::withProgress(message = "Running the benchmark", detail = "This can take a minute.", {
          authenticity_benchmark(as_synthetic_list(s), r, it, score = input$bm_score,
                                 clean_real = isTRUE(input$bm_clean),
                                 fit_scales = if (isTRUE(input$bm_fit)) NULL else character(0),
                                 n_splits = input$bm_splits, n_floor = input$bm_splits)
        })
      }, error = function(e) e)
      if (inherits(res, "error"))
        return(shiny::showNotification(conditionMessage(res), type = "error", duration = NULL))
      rv$benchmark <- res
    })
    output$bm_summary <- shiny::renderUI({
      bm <- rv$benchmark
      if (is.null(bm)) return(shiny::p(class = "text-muted", "Run the benchmark to see the summary."))
      s <- summarise_benchmark(bm)
      shiny::tagList(lapply(seq_len(nrow(s)), function(i) shiny::p(s$summary[i])),
                     shiny::p(class = "small text-muted",
                              "100 is as close as a second sample of real people; 0 is no better than",
                              "shuffled columns of the real data."))
    })
    output$bm_plot <- shiny::renderPlot({
      shiny::req(rv$benchmark); gg_benchmark(rv$benchmark)
    }, res = 96)
    output$bm_behaviour <- shiny::renderPlot({
      shiny::req(rv$benchmark); gg_behaviour(rv$benchmark$behaviour)
    }, res = 96)
    output$bm_table <- shiny::renderTable({
      shiny::req(rv$benchmark)
      t <- as.data.frame(rv$benchmark$table)
      t <- t[c("model", "attempts", "score", "weakest", "overlap", "structure", "behaviour")]
      names(t) <- c("Model", "Attempts", "Score", "Weakest", "Overlap", "Structure", "Behaviour")
      t
    }, digits = 0)

    # ---- 4. Pretest (without real data) ----------------------------------------
    pt_data <- shiny::reactive(syn_from(input$pt_source, input$pt_country, input$pt_attempts,
                                        input$pt_files))
    output$pt_status <- shiny::renderUI({
      s <- tryCatch(pt_data(), error = function(e) e)
      if (inherits(s, "error")) return(shiny::div(class = "text-muted", conditionMessage(s)))
      it <- tryCatch(bm_items()$item, error = function(e) character(0))
      sc_ok(sprintf("%s synthetic respondents%s; %d of %d instrument items found.",
                    format(nrow(s), big.mark = ","),
                    if ("model" %in% names(s)) sprintf(" from %d model%s", length(unique(s$model)),
                                                       if (length(unique(s$model)) > 1) "s" else "") else "",
                    length(intersect(it, names(s))), length(it)))
    })
    shiny::observeEvent(input$pt_run, {
      res <- tryCatch({
        it <- bm_items(); s <- pt_data()
        by <- if (identical(input$pt_by, "none")) character(0) else input$pt_by
        if (length(by) && !by %in% names(s))
          stop(sprintf("The synthetic data have no `%s` column. Choose another comparison.", by))
        ins <- instrument()
        shiny::withProgress(message = "Running the pretest", detail = "This can take a minute.", {
          synthetic_pretest(s, it, by = by, scale_range = c(ins$min, ins$max),
                            irt = isTRUE(input$pt_irt), n_pa = input$pt_pa %||% 20)
        })
      }, error = function(e) e)
      if (inherits(res, "error"))
        return(shiny::showNotification(conditionMessage(res), type = "error", duration = NULL))
      rv$pretest <- res
    })
    output$pt_summary <- shiny::renderUI({
      pt <- rv$pretest
      if (is.null(pt)) return(shiny::p(class = "text-muted", "Run the pretest to see the summary."))
      s <- summarise_pretest(pt)
      shiny::tagList(lapply(seq_len(nrow(s)), function(i) shiny::p(s$text[i])))
    })
    output$pt_plot <- shiny::renderPlot({
      shiny::req(rv$pretest); gg_pretest(rv$pretest, max_items = 25)
    }, res = 96)
    output$pt_scales <- shiny::renderPlot({
      shiny::req(rv$pretest); gg_pretest(rv$pretest, "scales")
    }, res = 96)
    output$pt_table <- shiny::renderTable({
      shiny::req(rv$pretest)
      a <- as.data.frame(rv$pretest$agreement)
      a <- a[a$flagged_in > 0, , drop = FALSE]
      if (!nrow(a)) return(data.frame(Note = "No item is flagged."))
      a <- utils::head(a, 15)
      data.frame(Item = a$item, Scale = a$scale, `Flagged in` = sprintf("%d of %d", a$flagged_in, a$conditions),
                 Flags = a$flags, check.names = FALSE)
    })
    output$pt_structure <- shiny::renderTable({
      shiny::req(rv$pretest)
      s <- as.data.frame(rv$pretest$summary)
      data.frame(Condition = s$condition, Respondents = s$n, `Flagged items` = s$flagged,
                 `Mean alpha` = sprintf("%.2f", s$alpha),
                 `Dimensions (designed)` = sprintf("%s (%d)", ifelse(is.na(s$n_factors), "-", s$n_factors), s$scales),
                 `Own scale` = ifelse(is.na(s$own_scale), "-", sprintf("%.0f%%", 100 * s$own_scale)),
                 `Reverse keys` = ifelse(is.na(s$reverse_ok), "-", sprintf("%.0f%%", 100 * s$reverse_ok)),
                 check.names = FALSE)
    })

    # ---- 5. Export -----------------------------------------------------------
    current_syn <- shiny::reactive(tryCatch(syn_data(), error = function(e) NULL))
    output$dl_synthetic <- shiny::downloadHandler(
      filename = function() paste0("synthetic.", input$exp_format),
      content = function(file) {
        d <- current_syn()
        shiny::validate(shiny::need(!is.null(d), "No synthetic data yet."))
        write_synthetic(d, file, format = input$exp_format)
      })
    output$dl_benchmark <- shiny::downloadHandler(
      filename = function() "benchmark.csv",
      content = function(file) {
        shiny::validate(shiny::need(rv$benchmark, "Run the benchmark first."))
        utils::write.csv(as.data.frame(rv$benchmark$table), file, row.names = FALSE)
      })
    output$dl_summary <- shiny::downloadHandler(
      filename = function() "benchmark-summary.txt",
      content = function(file) {
        shiny::validate(shiny::need(rv$benchmark, "Run the benchmark first."))
        writeLines(summarise_benchmark(rv$benchmark)$summary, file)
      })
    output$dl_plot <- shiny::downloadHandler(
      filename = function() "benchmark.png",
      content = function(file) {
        shiny::validate(shiny::need(rv$benchmark, "Run the benchmark first."))
        ggplot2::ggsave(file, gg_benchmark(rv$benchmark), width = 8, height = 1.5 + 0.5 * nrow(rv$benchmark$table),
                        dpi = 200, bg = "white")
      })
    output$dl_pt_items <- shiny::downloadHandler(
      filename = function() "pretest-items.csv",
      content = function(file) {
        shiny::validate(shiny::need(rv$pretest, "Run the pretest first."))
        utils::write.csv(as.data.frame(rv$pretest$items), file, row.names = FALSE)
      })
    output$dl_pt_summary <- shiny::downloadHandler(
      filename = function() "pretest-summary.txt",
      content = function(file) {
        shiny::validate(shiny::need(rv$pretest, "Run the pretest first."))
        writeLines(summarise_pretest(rv$pretest)$text, file)
      })
    output$dl_pt_plot <- shiny::downloadHandler(
      filename = function() "pretest.png",
      content = function(file) {
        shiny::validate(shiny::need(rv$pretest, "Run the pretest first."))
        n <- min(25, sum(rv$pretest$agreement$flagged_in > 0))
        ggplot2::ggsave(file, gg_pretest(rv$pretest, max_items = 25), width = 8, height = 2 + 0.3 * max(n, 3),
                        dpi = 200, bg = "white")
      })
    bm_script <- shiny::reactive(sc_app_script(
      run_dir = rv$run_dir, syn_source = input$syn_source, real_source = input$real_source,
      country = input$real_country, score = input$bm_score, clean = isTRUE(input$bm_clean),
      fit = isTRUE(input$bm_fit), splits = input$bm_splits,
      traits = if (input$ins_source == "hexaco") input$ins_traits else NULL))
    pt_script <- shiny::reactive(sc_pretest_script(
      run_dir = rv$run_dir, source = input$pt_source, country = input$pt_country,
      attempts = input$pt_attempts, by = input$pt_by, irt = isTRUE(input$pt_irt), n_pa = input$pt_pa,
      traits = if (input$ins_source == "hexaco") input$ins_traits else NULL))
    script <- shiny::reactive(if (identical(input$sc_path, "pretest")) pt_script() else bm_script())
    output$exp_script <- shiny::renderText(script())
    output$dl_script <- shiny::downloadHandler(filename = function() "synthcheck-benchmark.R",
                                               content = function(file) writeLines(script(), file))

    result <- function() list(synthetic = shiny::isolate(rv$run_data %||% current_syn()),
                              benchmark = shiny::isolate(rv$benchmark),
                              pretest = shiny::isolate(rv$pretest),
                              path = shiny::isolate(input$sc_path),
                              instrument = shiny::isolate(tryCatch(instrument(), error = function(e) NULL)),
                              personas = shiny::isolate(tryCatch(persona_table(), error = function(e) NULL)))
    shiny::observeEvent(input$app_close, shiny::stopApp(result()))
    session$onSessionEnded(function() {
      if (!is.null(shiny::isolate(rv$proc))) shiny::isolate(rv$proc)$kill()
      shiny::stopApp(result())
    })
  }
}

# ---- helpers --------------------------------------------------------------

sc_template_handler <- function(file) {
  shiny::downloadHandler(filename = function() file,
                         content = function(path)
                           file.copy(system.file("templates", file, package = "synthcheck"), path))
}

sc_ok <- function(text) shiny::div(class = "text-success", text)

sc_read_table <- function(path, name = path) {
  ext <- tolower(tools::file_ext(name))
  d <- switch(ext,
              csv = utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE),
              xlsx = { sc_need("readxl", "to read Excel files"); readxl::read_excel(path) },
              rds = readRDS(path),
              stop("Upload a .csv, .xlsx or .rds file.", call. = FALSE))
  as.data.frame(d, stringsAsFactors = FALSE)
}

sc_key_note <- function(var, typed) {
  if (nzchar(typed %||% "")) return(shiny::div(class = "small text-success mb-2", "Key entered for this session."))
  if (nzchar(Sys.getenv(var))) return(shiny::div(class = "small text-success mb-2",
                                                 sprintf("Using the key from your environment (%s).", var)))
  shiny::div(class = "small text-muted mb-2", sprintf("No key yet. Type one, or set %s in .Renviron.", var))
}

`%||%` <- function(a, b) if (is.null(a)) b else a

# set the keys typed in the app for one evaluation, then restore the environment
sc_with_keys <- function(keys, code) {
  keys <- keys[nzchar(keys)]
  if (length(keys)) {
    old <- Sys.getenv(names(keys), unset = NA, names = TRUE)
    do.call(Sys.setenv, as.list(keys))
    on.exit({
      for (k in names(old)) if (is.na(old[[k]])) Sys.unsetenv(k) else do.call(Sys.setenv, stats::setNames(list(old[[k]]), k))
    })
  }
  code
}

sc_can_background <- function() {
  requireNamespace("callr", quietly = TRUE) && nzchar(system.file(package = "synthcheck")) &&
    !isTRUE(getOption("synthcheck.foreground")) &&
    !(requireNamespace("pkgload", quietly = TRUE) && pkgload::is_dev_package("synthcheck"))
}

sc_ollama_models <- function(url) {
  tryCatch(sc_list_models("ollama", url), error = function(e) character(0))
}

sc_list_models <- function(provider, url = NULL) {
  if (provider == "mock") return("mock")
  sc_need("ellmer", "to list models")
  d <- switch(provider,
              anthropic = ellmer::models_anthropic(),
              openai = ellmer::models_openai(),
              ollama = ellmer::models_ollama(base_url = url))
  ids <- as.character(d$id)
  if (provider == "openai") ids <- ids[grepl("^(gpt|o[0-9])", ids)]
  sort(unique(ids))
}

# temperatures typed as "0.3, 0.7, 1": A list of numbers, an empty list, or an error
sc_parse_temps <- function(x) {
  x <- trimws(x %||% "")
  if (!nzchar(x)) return(list())
  v <- suppressWarnings(as.numeric(trimws(strsplit(x, "[,; ]+")[[1]])))
  if (anyNA(v) || any(v < 0 | v > 2))
    return(simpleError("Type temperatures between 0 and 2, separated by commas."))
  as.list(unique(v))
}

sc_pretest_script <- function(run_dir, source, country, attempts, by, irt, n_pa, traits) {
  syn <- switch(source %||% "run",
                run = sprintf('synthetic <- read_synthetic("%s")', run_dir %||% "path/to/run"),
                hexaco = sprintf('synthetic <- hexaco_llm[hexaco_llm$country == "%s" & hexaco_llm$attempt <= %d, ]',
                                 country %||% "Canada", as.integer(attempts %||% 3)),
                'synthetic <- read_synthetic("path/to/your/synthetic/files")')
  items <- if (!is.null(traits)) {
    sprintf("items <- hexaco_items[hexaco_items$trait %%in%% c(%s), ]",
            paste(sprintf('"%s"', traits), collapse = ", "))
  } else if (identical(source, "run") && !is.null(run_dir)) {
    sprintf('items <- jsonlite::read_json("%s", simplifyVector = TRUE)$instrument$items',
            file.path(run_dir, "run.json"))
  } else 'items <- read.csv("path/to/item_table.csv")'
  by <- if (identical(by, "none")) "character(0)" else sprintf('"%s"', by %||% "model")
  paste(c(
    "library(synthcheck)", "",
    "# Pilot screening without real data: It flags items, it does not validate the scale.",
    syn, items, "",
    sprintf("pt <- synthetic_pretest(synthetic, items, by = %s, irt = %s, n_pa = %d)", by,
            if (isTRUE(irt)) "TRUE" else "FALSE", as.integer(n_pa %||% 20)),
    "pt", "summarise_pretest(pt)", "gg_pretest(pt)", 'gg_pretest(pt, "scales")', "",
    "# Once real data are in, benchmark the same synthetic data:",
    "# real <- read.csv(\"path/to/real_data.csv\")",
    "# authenticity_benchmark(as_synthetic_list(synthetic), real, items)"),
    collapse = "\n")
}

sc_app_script <- function(run_dir, syn_source, real_source, country, score, clean, fit, splits, traits) {
  syn <- switch(syn_source,
                run = sprintf('synthetic <- read_synthetic("%s")', run_dir %||% "path/to/run"),
                hexaco = 'synthetic <- hexaco_llm[hexaco_llm$country == "Canada", ]',
                'synthetic <- read_synthetic("path/to/your/synthetic/files")')
  real <- switch(real_source,
                 hexaco = if (identical(country, "All")) "real <- hexaco_real" else
                   sprintf('real <- hexaco_real[hexaco_real$country == "%s", ]', country),
                 'real <- read.csv("path/to/real_data.csv")')
  items <- if (!is.null(traits)) {
    sprintf("items <- hexaco_items[hexaco_items$trait %%in%% c(%s), ]",
            paste(sprintf('"%s"', traits), collapse = ", "))
  } else if (syn_source == "run" && !is.null(run_dir)) {
    sprintf('items <- jsonlite::read_json("%s", simplifyVector = TRUE)$instrument$items',
            file.path(run_dir, "run.json"))
  } else 'items <- read.csv("path/to/item_table.csv")'
  paste(c(
    "library(synthcheck)", "",
    syn, real, items, "",
    sprintf("bm <- authenticity_benchmark(as_synthetic_list(synthetic), real, items,"),
    sprintf('                             score = "%s", clean_real = %s,', score, clean),
    sprintf("                             fit_scales = %s, n_splits = %d, n_floor = %d)",
            if (fit) "NULL" else "character(0)", as.integer(splits), as.integer(splits)),
    "bm", "gg_benchmark(bm)", "gg_behaviour(bm$behaviour)", "summarise_benchmark(bm)"),
    collapse = "\n")
}
