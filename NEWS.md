# synthcheck 0.3.0

* New `persona_fidelity()` and `gg_persona_fidelity()`: A check of whether
  the personas given to a language model change its answers. For each model
  and scale it compares the variance between personas (eta squared) with
  shuffled persona labels, and when the persona table holds `target_<scale>`
  columns, it checks that each persona's scale scores move in the intended
  direction. Scores can be standardized against real data.

* `authenticity_benchmark()` now gives an interval for every anchored value
  and for the score (`*_lower`, `*_upper`; new arguments `conf` and
  `n_boot`). It is a bootstrap over the model's attempts and over the floor
  and ceiling draws, so two models whose intervals overlap are not clearly
  apart. `gg_benchmark()` prints the intervals under the values
  (`intervals = TRUE`), `print()` adds the score interval, and
  `summarise_benchmark()` says when a model's interval overlaps with the
  next one's.

* The app's Models tab has a new **Persona check** card that runs
  `persona_fidelity()` after a run with two or more personas, and the
  Compare tab shows the intervals in the plot and the table.

* The tutorial on generating synthetic respondents has a new section on the
  persona check, the benchmark article explains the intervals, and the tour
  of the app and the app demos show both, with new screenshots.


* Three short instruments with well-documented item problems, each with
  real responses from the Open-Source Psychometrics Project: The Rosenberg
  Self-Esteem Scale (`rses_items`, `rses_real`; a negative-wording method
  factor), the DASS-21 (`dass_items`, `dass_real`; a disputed three-factor
  structure) and the Mini-IPIP (`mini_ipip_items`, `mini_ipip_real`; poor
  fit and a weak Intellect/Imagination scale). The `issue` column of each
  item table says what has been reported about each item, with references
  in the help pages.

* New `sc_builtin_instrument()` returns any bundled instrument, with its
  response scale, category labels and instructions.

* The app's Instrument tab offers all four built-in instruments, and the
  Compare tab's built-in real data follow the instrument chosen there, with
  a country filter.

* New article: "Short instruments with known item problems".

* The Designer card on the app's About tab has the full contact details,
  links to the designer's website, blog, ORCID and GitHub, and how to cite
  synthcheck with its Zenodo DOI. It no longer ends in a large blank space.

* New response cache: `generate_synthetic()` and `cognitive_interview()`
  save every answer on disk (`sc_cache()`), under a key made of the
  provider, model, temperature, prompts, respondent, attempt, retry and
  `seed`. The same run again reads the answers back: It is repeatable and
  costs nothing. More attempts or respondents call the models only for the
  new ones. `mode = "refresh"` asks again, `cache = FALSE` turns it off,
  and `sc_cache_info()` and `sc_cache_clear()` show and delete what is
  saved. Failed calls and mock answers are never saved.

* New `estimate_cost()` and `estimate_interview_cost()`: What a run is
  likely to cost before it starts, from the number of calls, guessed tokens
  and a price table (`sc_prices`, with the date of each price). Ollama
  models and cached calls are free. You can pass your own prices.

* The app shows the estimated cost under the run plan of the Models and
  Interviews tabs and asks you to confirm before a run with paid models. A
  new setting chooses whether to reuse, refresh or skip saved answers, and
  a button clears the cache.

* With one respondent per call, a retry now asks only for the items still
  missing, in both the one-at-a-time and the parallel paths.

* New `write_report()` writes the results as one report: A self-contained
  HTML file (the default) or a PDF, with the plots, tables, plain-language
  summaries and the settings needed to repeat the run. It covers the
  benchmark, the pretest and the cognitive interviews, and keeps the
  caveat that the benchmark does not show that synthetic data can replace a
  field test. The PDF uses the PDF device that comes with R, so it needs no
  LaTeX or pandoc.

* The app's Export tab has a new **Results report** card that downloads the
  report for the path you chose, in HTML or PDF.

* New article: "Getting an API key for OpenAI or Claude". It walks through
  signing up, adding credit, keeping the key private and setting a spending
  limit. The app's Models tab links to it and to the providers' sign-up
  pages next to the API key fields, and the website links to it from the app
  menu, Get started and the README.

* The guided tour in the app now shows the API keys, the estimated cost and
  the response cache. The About tab lists the cost estimate and the cache.

* The tour of the app, the app demos, Get started and the tutorial on
  generating respondents cover the built-in short instruments, the cost
  estimate, the response cache and the results report, with new
  screenshots.

# synthcheck 0.2.0

Adds a path for scales without real data (a synthetic pretest and cognitive
interviews with language models), a redesigned app and updated
documentation.

* New `synthetic_pretest()` for scales without real data: Pilot screening of
  the items on synthetic respondents alone (item-rest correlations, alpha if
  an item is dropped, items that barely vary or duplicate another item,
  reverse keys, GRM slopes with mirt, alpha and parallel analysis per
  scale). It checks whether the flags hold across models, temperatures,
  prompt wordings or persona sets (`by`), in every attempt, and whether the
  designed structure (the `scale` and `reverse` columns) comes back.
  `gg_pretest()` draws the flagged items and the scales, and
  `summarise_pretest()` describes the result in plain language. It is
  screening, not validation.

* The app now asks first whether you have real data. With real data, the
  fourth tab is Compare (the benchmark); without it, the fourth tab is the
  new Pretest tab. The Models tab can add one model at several temperatures
  for the stability check, and Export saves the pretest and its R script.

* New article: "Pretesting a scale without real data".

* New cognitive interviews for items without real data:
  `cognitive_interview()` has language models play each persona, think
  aloud while answering an item and answer scripted verbal probes
  (`sc_probes()`, after Willis, 2005), then a separate call codes each
  transcript for comprehension, retrieval, judgement, response-mapping and
  sensitivity problems. A synthetic pretest result can choose the items and
  adds a probe aimed at each flag. `summarise_interviews()` rolls the codes
  up per item, flags items by fixed rules and says how they agree with the
  pretest, and `gg_interview()` draws one heatmap. `sc_interview_prompts()`
  shows what is sent. The new article "Cognitive interviews with language
  models" walks through it. It is a screening aid, not a substitute for
  cognitive interviews with real people.

* The app has a new Interviews tab (5) on the path without real data, so
  Export is tab 6 there and tab 5 with real data. It
  runs `cognitive_interview()` with the personas and models of tabs 2 and 3,
  on the items the pretest flagged or on items you choose (the pretest is
  optional), with editable probes, a choice of coder, a progress bar and a
  Stop button. It shows the summary, the heatmap and the transcripts, and
  Export saves the interviews, the transcripts and the plot.

* The app's guided tour follows the path chosen in the first step and now
  covers every tab on both paths, including the designed structure on the
  Pretest tab and the interview settings and transcripts. The tour of the
  app, the app demos (with a new demo of the path without real data), Get
  started, the README and the help page of `run_synthcheck_app()` describe
  the final design.

* The app has a new look in the logo colours, with the logo in the navbar
  and a coverage strip under it. A new About tab opens the app: It explains
  the purpose, lists what the app can do and produce, shows an animated
  picture of a language model answering survey items, gives the designer's
  contact details and starts a guided tour of the five tabs (with the
  cicerone package, in Suggests).
* The website matches the app: A navy navbar with the coverage strip under
  it, navy headings and framed screenshots. The app articles describe the
  About tab and the guided tour.

* The README, `citation("synthcheck")` and `CITATION.cff` give the Zenodo
  DOI that covers all versions (10.5281/zenodo.24173113).

* Figure captions on the website are italic and muted, so they read apart
  from the text.

* synthcheck is no longer labelled experimental in the README, the help
  pages, the articles, the printed results or the app. The caveat stays: The
  benchmark compares models and supports decisions about them, and it does
  not show that synthetic data can replace a field test.

# synthcheck 0.1.0

First release, archived on Zenodo. The benchmark compares models and
supports decisions about them. It does not show that synthetic respondents
can replace a field test.

## The synthetic authenticity benchmark

* `authenticity_benchmark()` builds the synthetic authenticity benchmark:
  Overlap, Structure and Behaviour for every model, each anchored between
  shuffled real columns (0) and a second sample of real people (100), with
  the weakest column as the default score. `gg_benchmark()` draws it on a
  scale from red (-100 or less) through pale (0) to blue (100), so values
  below the shuffled baseline stay readable.
* `summarise_benchmark()` describes each model's benchmark result in a few
  plain sentences.
* `flag_careless()` flags careless real respondents, and `clean_real = TRUE`
  compares against the remaining ones.

## Overlap, Structure and Behaviour

* `synthetic_coverage()`, `blend_llms()` and `gg_coverage()` give Overlap,
  Structure and the best blend of models, drawn as a coverage strip, with
  `theme_synthcheck()`. They are ported from mirtverse.
* `behaviour_features()` gives eight behaviour features per respondent
  (variability, extreme and midpoint answers, acquiescence, key
  inconsistency, even-odd consistency, Mahalanobis distance and person fit
  lz), `synthetic_behaviour()` turns them into the Behaviour index, and
  `gg_behaviour()` draws the behaviour strip.

## Diagnostics beside the benchmark

These do not change the benchmark score.

* `synthetic_construct()` and `gg_construct()` check the construct structure
  of each model: The gap between the synthetic and the real correlations
  between scales, alpha per scale (above the real value means too coherent)
  and Tucker's congruence of the loadings, read against a permutation null
  (after Lukauskas & Šarkauskaitė, 2026).
* `respondent_coverage()` and `gg_respondent_coverage()` give the respondent
  coverage gap (RCG) and the off-support ratio (OSR) of Kumagae and Kaneko
  (2026): Whether every real person has a synthetic look-alike, and whether
  synthetic respondents sit outside the real data.
* `synthetic_copula()` draws respondents from a Gaussian copula of the real
  data, and `authenticity_benchmark(copula = TRUE)` adds it as a reference
  row.

## Generating synthetic respondents

* `run_synthcheck_app()` opens a Shiny app that generates synthetic
  respondents with several language models and benchmarks them in five tabs:
  Instrument, Personas, Models (API keys, temperature, attempts, a progress
  bar with the time left), Compare (the benchmark with a plain-language
  summary per model) and Export. API keys stay in memory for the session.
  The Instrument and Personas tabs offer CSV templates to fill in.
* `sc_instrument()`, `sc_personas()`, `sc_persona_grid()`, `sc_model()` and
  `sc_prompt()` define what synthetic respondents take and who they are, and
  `generate_synthetic()` asks Anthropic, OpenAI or local Ollama models
  (through ellmer) to answer, one respondent per call.
* `write_synthetic()` and `read_synthetic()` save and load generated data as
  CSV, JSON, RDS or Excel, and `as_synthetic_list()` turns a long table into
  the input of `authenticity_benchmark()`.

## Data

* `hexaco_real` holds 17,874 real respondents from Canada, Great Britain and
  the United States, and `hexaco_items` the 240 IPIP-HEXACO items (both from
  mirtverse).
* `hexaco_llm` holds 89,597 synthetic respondents from six language models,
  including Claude Haiku 5.5 and GPT-4.1 mini.

## Documentation

* The website has a Get started article, four tutorials (Overlap and
  Structure, Behaviour, the benchmark, generating synthetic respondents in
  R), an article on the diagnostics beside the benchmark, a tour of the app
  with screenshots of each tab, and three app demos (the built-in models, a
  practice run with the mock provider, and your own questionnaire).
* `citation("synthcheck")`, `CITATION.cff` and `.zenodo.json` give the
  citation and the Zenodo metadata.
