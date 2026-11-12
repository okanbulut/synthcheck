# synthcheck 0.0.0.9000

* New: `synthetic_construct()` and `gg_construct()` check the construct
  structure of each model: The gap between the synthetic and the real
  correlations between scales, alpha per scale (above the real value means
  too coherent) and Tucker's congruence of the loadings, read against a
  permutation null (after Lukauskas & Šarkauskaitė, 2026).
* New: `respondent_coverage()` and `gg_respondent_coverage()` give the
  respondent coverage gap (RCG) and the off-support ratio (OSR) of Kumagae
  and Kaneko (2026): Whether every real person has a synthetic look-alike,
  and whether synthetic respondents sit outside the real data.
* New: `synthetic_copula()` draws respondents from a Gaussian copula of the
  real data, and `authenticity_benchmark(copula = TRUE)` adds it as a
  reference row.

* New: `behaviour_features()` gives eight behaviour features per respondent
  (variability, extreme and midpoint answers, acquiescence, key
  inconsistency, even-odd consistency, Mahalanobis distance and person fit
  lz), `synthetic_behaviour()` turns them into the Behaviour index, and
  `gg_behaviour()` draws the behaviour strip.
* New: `authenticity_benchmark()` builds the synthetic authenticity
  benchmark: Overlap, Structure and Behaviour for every model, each anchored
  between shuffled real columns (0) and a second sample of real people
  (100), with the weakest column as the default score. `gg_benchmark()`
  draws it on a scale from red (-100 or less) through pale (0) to blue
  (100), so values below the shuffled baseline stay readable.
* New: `flag_careless()` flags careless real respondents, and
  `clean_real = TRUE` compares against the remaining ones.
* Data: `hexaco_llm` now holds six models (89,597 synthetic respondents).
  Claude Haiku 5.5 and GPT-4.1 mini were added.

* First version of the package. `synthetic_coverage()`, `blend_llms()` and
  `gg_coverage()` (Overlap, Structure and the best blend of models, drawn as
  a coverage strip) are ported from mirtverse, with `theme_synthcheck()`.
* Data: `hexaco_real` (17,874 real respondents from Canada, Great Britain and
  the United States), `hexaco_llm` (59,611 synthetic respondents from four
  language models) and `hexaco_items` for the 240 IPIP-HEXACO items, also
  from mirtverse.
