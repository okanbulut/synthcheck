# Changelog

## synthcheck 0.0.0.9000

- New:
  [`behaviour_features()`](https://www.okanbulut.com/synthcheck/reference/behaviour_features.md)
  gives eight behaviour features per respondent (variability, extreme
  and midpoint answers, acquiescence, key inconsistency, even-odd
  consistency, Mahalanobis distance and person fit lz),
  [`synthetic_behaviour()`](https://www.okanbulut.com/synthcheck/reference/synthetic_behaviour.md)
  turns them into the Behaviour index, and
  [`gg_behaviour()`](https://www.okanbulut.com/synthcheck/reference/gg_behaviour.md)
  draws the behaviour strip.

- New:
  [`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md)
  builds the synthetic authenticity benchmark: Overlap, Structure and
  Behaviour for every model, each anchored between shuffled real
  columns (0) and a second sample of real people (100), with the weakest
  column as the default score.
  [`gg_benchmark()`](https://www.okanbulut.com/synthcheck/reference/gg_benchmark.md)
  draws it.

- New:
  [`flag_careless()`](https://www.okanbulut.com/synthcheck/reference/flag_careless.md)
  flags careless real respondents, and `clean_real = TRUE` compares
  against the remaining ones.

- Data: `hexaco_llm` now holds six models (89,597 synthetic
  respondents). Claude Haiku 5.5 and GPT-4.1 mini were added.

- First version of the package.
  [`synthetic_coverage()`](https://www.okanbulut.com/synthcheck/reference/synthetic_coverage.md),
  [`blend_llms()`](https://www.okanbulut.com/synthcheck/reference/blend_llms.md)
  and
  [`gg_coverage()`](https://www.okanbulut.com/synthcheck/reference/gg_coverage.md)
  (Overlap, Structure and the best blend of models, drawn as a coverage
  strip) are ported from mirtverse, with
  [`theme_synthcheck()`](https://www.okanbulut.com/synthcheck/reference/theme_synthcheck.md).

- Data: `hexaco_real` (17,874 real respondents from Canada, Great
  Britain and the United States), `hexaco_llm` (59,611 synthetic
  respondents from four language models) and `hexaco_items` for the 240
  IPIP-HEXACO items, also from mirtverse.
