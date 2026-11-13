# synthcheck (development version)

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
