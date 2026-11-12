# Changelog

## synthcheck (development version)

- New
  [`synthetic_pretest()`](https://www.okanbulut.com/synthcheck/reference/synthetic_pretest.md)
  for scales without real data: Pilot screening of the items on
  synthetic respondents alone (item-rest correlations, alpha if an item
  is dropped, items that barely vary or duplicate another item, reverse
  keys, GRM slopes with mirt, alpha and parallel analysis per scale). It
  checks whether the flags hold across models, temperatures, prompt
  wordings or persona sets (`by`), in every attempt, and whether the
  designed structure (the `scale` and `reverse` columns) comes back.
  [`gg_pretest()`](https://www.okanbulut.com/synthcheck/reference/gg_pretest.md)
  draws the flagged items and the scales, and
  [`summarise_pretest()`](https://www.okanbulut.com/synthcheck/reference/summarise_pretest.md)
  describes the result in plain language. It is screening, not
  validation.

- The app now asks first whether you have real data. With real data, the
  fourth tab is Compare (the benchmark); without it, the fourth tab is
  the new Pretest tab. The Models tab can add one model at several
  temperatures for the stability check, and Export saves the pretest and
  its R script.

- New article: “Pretesting a scale without real data”.

- The app has a new look in the logo colours, with the logo in the
  navbar and a coverage strip under it. A new About tab opens the app:
  It explains the purpose, lists what the app can do and produce, shows
  an animated picture of a language model answering survey items, gives
  the designer’s contact details and starts a guided tour of the five
  tabs (with the cicerone package, in Suggests).

- The website matches the app: A navy navbar with the coverage strip
  under it, navy headings and framed screenshots. The app articles
  describe the About tab and the guided tour.

- The README, `citation("synthcheck")` and `CITATION.cff` give the
  Zenodo DOI that covers all versions (10.5281/zenodo.24173113).

## synthcheck 0.1.0

First release, archived on Zenodo. synthcheck is experimental: The
benchmark compares models and supports decisions about them. It does not
show that synthetic respondents can replace a field test.

### The synthetic authenticity benchmark

- [`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md)
  builds the synthetic authenticity benchmark: Overlap, Structure and
  Behaviour for every model, each anchored between shuffled real
  columns (0) and a second sample of real people (100), with the weakest
  column as the default score.
  [`gg_benchmark()`](https://www.okanbulut.com/synthcheck/reference/gg_benchmark.md)
  draws it on a scale from red (-100 or less) through pale (0) to blue
  (100), so values below the shuffled baseline stay readable.
- [`summarise_benchmark()`](https://www.okanbulut.com/synthcheck/reference/summarise_benchmark.md)
  describes each model’s benchmark result in a few plain sentences.
- [`flag_careless()`](https://www.okanbulut.com/synthcheck/reference/flag_careless.md)
  flags careless real respondents, and `clean_real = TRUE` compares
  against the remaining ones.

### Overlap, Structure and Behaviour

- [`synthetic_coverage()`](https://www.okanbulut.com/synthcheck/reference/synthetic_coverage.md),
  [`blend_llms()`](https://www.okanbulut.com/synthcheck/reference/blend_llms.md)
  and
  [`gg_coverage()`](https://www.okanbulut.com/synthcheck/reference/gg_coverage.md)
  give Overlap, Structure and the best blend of models, drawn as a
  coverage strip, with
  [`theme_synthcheck()`](https://www.okanbulut.com/synthcheck/reference/theme_synthcheck.md).
  They are ported from mirtverse.
- [`behaviour_features()`](https://www.okanbulut.com/synthcheck/reference/behaviour_features.md)
  gives eight behaviour features per respondent (variability, extreme
  and midpoint answers, acquiescence, key inconsistency, even-odd
  consistency, Mahalanobis distance and person fit lz),
  [`synthetic_behaviour()`](https://www.okanbulut.com/synthcheck/reference/synthetic_behaviour.md)
  turns them into the Behaviour index, and
  [`gg_behaviour()`](https://www.okanbulut.com/synthcheck/reference/gg_behaviour.md)
  draws the behaviour strip.

### Diagnostics beside the benchmark

These do not change the benchmark score.

- [`synthetic_construct()`](https://www.okanbulut.com/synthcheck/reference/synthetic_construct.md)
  and
  [`gg_construct()`](https://www.okanbulut.com/synthcheck/reference/gg_construct.md)
  check the construct structure of each model: The gap between the
  synthetic and the real correlations between scales, alpha per scale
  (above the real value means too coherent) and Tucker’s congruence of
  the loadings, read against a permutation null (after Lukauskas &
  Šarkauskaitė, 2026).
- [`respondent_coverage()`](https://www.okanbulut.com/synthcheck/reference/respondent_coverage.md)
  and
  [`gg_respondent_coverage()`](https://www.okanbulut.com/synthcheck/reference/gg_respondent_coverage.md)
  give the respondent coverage gap (RCG) and the off-support ratio (OSR)
  of Kumagae and Kaneko (2026): Whether every real person has a
  synthetic look-alike, and whether synthetic respondents sit outside
  the real data.
- [`synthetic_copula()`](https://www.okanbulut.com/synthcheck/reference/synthetic_copula.md)
  draws respondents from a Gaussian copula of the real data, and
  `authenticity_benchmark(copula = TRUE)` adds it as a reference row.

### Generating synthetic respondents

- [`run_synthcheck_app()`](https://www.okanbulut.com/synthcheck/reference/run_synthcheck_app.md)
  opens a Shiny app that generates synthetic respondents with several
  language models and benchmarks them in five tabs: Instrument,
  Personas, Models (API keys, temperature, attempts, a progress bar with
  the time left), Compare (the benchmark with a plain-language summary
  per model) and Export. API keys stay in memory for the session. The
  Instrument and Personas tabs offer CSV templates to fill in.
- [`sc_instrument()`](https://www.okanbulut.com/synthcheck/reference/sc_instrument.md),
  [`sc_personas()`](https://www.okanbulut.com/synthcheck/reference/sc_personas.md),
  [`sc_persona_grid()`](https://www.okanbulut.com/synthcheck/reference/sc_personas.md),
  [`sc_model()`](https://www.okanbulut.com/synthcheck/reference/sc_model.md)
  and
  [`sc_prompt()`](https://www.okanbulut.com/synthcheck/reference/sc_prompt.md)
  define what synthetic respondents take and who they are, and
  [`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md)
  asks Anthropic, OpenAI or local Ollama models (through ellmer) to
  answer, one respondent per call.
- [`write_synthetic()`](https://www.okanbulut.com/synthcheck/reference/write_synthetic.md)
  and
  [`read_synthetic()`](https://www.okanbulut.com/synthcheck/reference/write_synthetic.md)
  save and load generated data as CSV, JSON, RDS or Excel, and
  [`as_synthetic_list()`](https://www.okanbulut.com/synthcheck/reference/as_synthetic_list.md)
  turns a long table into the input of
  [`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md).

### Data

- `hexaco_real` holds 17,874 real respondents from Canada, Great Britain
  and the United States, and `hexaco_items` the 240 IPIP-HEXACO items
  (both from mirtverse).
- `hexaco_llm` holds 89,597 synthetic respondents from six language
  models, including Claude Haiku 5.5 and GPT-4.1 mini.

### Documentation

- The website has a Get started article, four tutorials (Overlap and
  Structure, Behaviour, the benchmark, generating synthetic respondents
  in R), an article on the diagnostics beside the benchmark, a tour of
  the app with screenshots of each tab, and three app demos (the
  built-in models, a practice run with the mock provider, and your own
  questionnaire).
- `citation("synthcheck")`, `CITATION.cff` and `.zenodo.json` give the
  citation and the Zenodo metadata.
