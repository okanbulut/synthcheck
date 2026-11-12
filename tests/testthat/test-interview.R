iv_items <- data.frame(
  item = c("q1", "q2", "q3", "q4"),
  statement = c("I am not someone who never worries.",
                "I enjoy meeting new people and going to parties.",
                "I keep my promises.",
                "I would never cheat on my taxes to save money."),
  scale = c("N", "E", "C", "H"), stringsAsFactors = FALSE)
iv_ins <- sc_instrument(iv_items, scale = c(1, 5))
iv_per <- sc_personas(data.frame(description = c("You are 19.", "You are 70."),
                                 age = c(19, 70)))

test_that("sc_probes() gives the default protocol and checks custom ones", {
  p <- sc_probes()
  expect_s3_class(p, "sc_probes")
  expect_equal(p$probe_id, c("paraphrase", "terms", "retrieval", "judgement", "response",
                             "sensitivity"))
  expect_true(all(p$stage %in% c("comprehension", "retrieval", "judgement", "response",
                                 "sensitivity")))
  q <- sc_probes(c("comprehension", "comprehension"), c("What does it mean?", "Any hard words?"))
  expect_equal(q$probe_id, c("comprehension", "comprehension_1"))
  expect_error(sc_probes("memory", "What?"), "Unknown stage")
  expect_error(sc_probes(stage = "response"), "both")
  expect_error(sc_probes("response", "x", probe_id = "pretest"), "reserved")
})

test_that("cognitive_interview() returns one coded row per interview", {
  expect_message(
    iv <- cognitive_interview(iv_ins, sc_model("mock"), iv_per, interviews = 2, progress = FALSE),
    "16 interviews .* 48 requests")
  expect_s3_class(iv, "sc_interview")
  expect_equal(nrow(iv), 2 * 4 * 2)
  expect_true(all(c("model", "coder", "persona_id", "age", "item", "statement", "answer",
                    "think_aloud", "probe_paraphrase", "probe_sensitivity", "comprehension",
                    "comprehension_note", "sensitivity", "severity", "revision") %in% names(iv)))
  expect_true(all(iv$answer %in% 1:5))
  expect_type(iv$comprehension, "logical")
  expect_false(anyNA(iv$comprehension))
  expect_true(all(iv$severity %in% c("none", "minor", "major")))
  expect_false("probe_pretest" %in% names(iv))
  # same seed, same result
  iv2 <- suppressMessages(cognitive_interview(iv_ins, sc_model("mock"), iv_per, interviews = 2,
                                              progress = FALSE))
  expect_identical(as.data.frame(iv), as.data.frame(iv2))
})

test_that("items and several models are handled", {
  iv <- suppressMessages(cognitive_interview(
    iv_ins, list(sc_model("mock", name = "A"), sc_model("mock", name = "B")), iv_per,
    items = c("q3", "q1"), coder = sc_model("mock", name = "Coder"), progress = FALSE))
  expect_equal(sort(unique(iv$item)), c("q1", "q3"))
  expect_equal(unique(iv$model), c("A", "B"))
  expect_equal(unique(iv$coder), "Coder")
  expect_error(cognitive_interview(iv_ins, sc_model("mock"), items = "zz"), "Not in the instrument")
  expect_error(cognitive_interview(iv_ins, list(sc_model("mock"), sc_model("mock"))), "own `name`")
})

test_that("pretest flags choose the items and add a probe", {
  pt <- data.frame(item = c("q4", "q2"), flag = c("Weak link to its scale", "Barely varies"))
  msgs <- capture_messages(
    iv <- cognitive_interview(iv_ins, sc_model("mock"), iv_per, pretest = pt, progress = FALSE))
  expect_match(msgs[1], "2 items flagged by the pretest")
  expect_equal(unique(iv$item), c("q4", "q2"))
  expect_true("probe_pretest" %in% names(iv))
  expect_equal(unique(iv$pretest), c("Weak link to its scale", "Barely varies"))
  p <- sc_interview_prompts(iv_ins, "q4", flag = "Weak link to its scale")
  expect_match(p$probes, "statements about H")
  expect_match(sc_interview_prompts(iv_ins, "q2", flag = "Near-duplicate of q1")$probes,
               "same thing as another statement")

  # an sc_pretest-like object: only items flagged at least once are used
  obj <- structure(list(agreement = data.frame(item = c("q1", "q3"), flagged_in = c(2, 0),
                                               flags = c("Reverse key not working", ""))),
                   class = "sc_pretest")
  iv3 <- suppressMessages(cognitive_interview(iv_ins, sc_model("mock"), pretest = obj,
                                              progress = FALSE))
  expect_equal(unique(iv3$item), "q1")
  expect_match(sc_interview_prompts(iv_ins, "q1", flag = iv3$pretest[1])$probes, "other way")

  expect_warning(suppressMessages(cognitive_interview(iv_ins, sc_model("mock"), items = "q1",
                                                      pretest = c("q1", "zz"), progress = FALSE)),
                 "not in the instrument")
})

test_that("sc_interview_prompts() shows the persona, think-aloud and coder prompts", {
  p <- sc_interview_prompts(iv_ins, "q2", "You are a 30-year-old teacher.")
  expect_match(p$system, "^You are a 30-year-old teacher")
  expect_match(p$system, "cognitive interview")
  expect_match(p$think_aloud, "think aloud")
  expect_match(p$think_aloud, "going to parties")
  expect_match(p$probes, "1\\. In your own words")
  expect_match(p$coder, "Tourangeau")
  expect_error(sc_interview_prompts(iv_ins, "zz"), "one item")
})

test_that("summarise_interviews() rolls up per item and flags by rule", {
  iv <- suppressMessages(cognitive_interview(
    iv_ins, list(sc_model("mock", name = "A"), sc_model("mock", name = "B")), iv_per,
    interviews = 5, pretest = data.frame(item = "q1", flag = "Weak link to its scale"),
    items = iv_items$item, progress = FALSE))
  s <- summarise_interviews(iv)
  expect_s3_class(s, "sc_interview_summary")
  expect_equal(sort(s$item), sort(iv_items$item))
  expect_true(all(s$n == 20))
  expect_true(all(s$any >= 0 & s$any <= 1))
  expect_equal(s$flagged, s$any >= 0.3 & s$models >= 2)
  # the double negation item has the most comprehension problems
  expect_equal(s$item[which.max(s$comprehension)], "q1")
  expect_true(all(s$agreement %in% c("both", "pretest only", "interviews only", "neither")))
  expect_equal(s$agreement[s$item == "q1"], if (s$flagged[s$item == "q1"]) "both" else "pretest only")
  expect_match(attr(s, "text"), "screening results")
  expect_output(print(s), "flagged")
  # a high threshold flags nothing
  s2 <- summarise_interviews(iv, flag = 1)
  expect_match(attr(s2, "text"), "No item of the 4 was flagged")
  expect_error(summarise_interviews(iv, flag = 2), "between 0 and 1")
  expect_error(summarise_interviews(mtcars), "cognitive_interview")
})

test_that("gg_interview() draws a heatmap", {
  iv <- suppressMessages(cognitive_interview(iv_ins, sc_model("mock"), iv_per, interviews = 2,
                                             progress = FALSE))
  g <- gg_interview(iv)
  expect_s3_class(g, "ggplot")
  expect_equal(nrow(g$data), 4 * 6)
  expect_s3_class(gg_interview(summarise_interviews(iv), max_items = 2), "ggplot")
})

test_that("output writes the table, run.json and transcripts", {
  skip_if_not_installed("jsonlite")
  dir <- withr::local_tempdir()
  iv <- suppressMessages(cognitive_interview(iv_ins, sc_model("mock"), iv_per, items = "q1",
                                             output = dir, progress = FALSE))
  expect_true(file.exists(file.path(dir, "interviews.csv")))
  expect_true(file.exists(file.path(dir, "run.json")))
  md <- readLines(file.path(dir, "transcripts", "q1.md"))
  expect_match(md[1], "^# q1: I am not someone")
  expect_true(any(grepl("Interviewer: In your own words", md)))
  expect_true(any(grepl("\\*\\*Coding", md)))
  back <- utils::read.csv(file.path(dir, "interviews.csv"))
  expect_equal(nrow(back), 2)
})

test_that("a stop file stops the run", {
  dir <- withr::local_tempdir()
  stop_file <- file.path(dir, "STOP")
  file.create(stop_file)
  iv <- suppressMessages(cognitive_interview(iv_ins, sc_model("mock"), iv_per,
                                             stop_file = stop_file, progress = FALSE))
  expect_true(attr(iv, "stopped"))
  expect_equal(nrow(iv), 0)
})

test_that("a real provider goes through think-aloud, probes and coding", {
  skip_if_not_installed("ellmer")
  sent <- character(0)
  fake_chat <- function(m, system) {
    list(chat_structured = function(prompt, type) {
      sent <<- c(sent, prompt)
      p <- names(type@properties)
      if ("think_aloud" %in% p) return(list(think_aloud = "Hmm, two things at once.", answer = 4L))
      if ("paraphrase" %in% p) return(stats::setNames(as.list(paste("Answer to", p)), p))
      out <- list()
      for (k in c("comprehension", "retrieval", "judgement", "response", "sensitivity")) {
        out[[k]] <- k == "comprehension"
        out[[paste0(k, "_note")]] <- if (k == "comprehension") "Double-barrelled: \"two things\"" else ""
      }
      c(out, list(severity = "major", revision = "Split it."))
    })
  }
  local_mocked_bindings(sc_chat = fake_chat)
  iv <- suppressMessages(cognitive_interview(iv_ins, sc_model("openai"), "You are 40.",
                                             items = "q2", progress = FALSE))
  expect_equal(nrow(iv), 1)
  expect_equal(iv$answer, 4L)
  expect_true(iv$comprehension)
  expect_false(iv$retrieval)
  expect_equal(iv$probe_terms, "Answer to terms")
  expect_equal(iv$severity, "major")
  expect_length(sent, 3)
  expect_match(sent[3], "Hmm, two things at once")
  expect_match(sent[3], "Answer to paraphrase")
})
