# Flag careless real respondents

`flag_careless()` marks real respondents whose answers look careless,
using the eight
[`behaviour_features()`](https://www.okanbulut.com/synthcheck/reference/behaviour_features.md).
By default a respondent is careless when at least two features fall in
the real data's most extreme 2.5% on the careless side: The highest 2.5%
for `extreme`, `midpoint`, `acquiescence`, `key_inconsistency` and
`mahalanobis`, the lowest 2.5% for `even_odd` and `person_fit`, and the
lowest or highest 1.25% for `variability`. These are the flags behind
`clean_real = TRUE` in
[`synthetic_behaviour()`](https://www.okanbulut.com/synthcheck/reference/synthetic_behaviour.md)
and
[`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md).

## Usage

``` r
flag_careless(real, items, rule = NULL, fit_scales = NULL)
```

## Arguments

- real:

  a data frame of real responses.

- items:

  a data frame with one row per item: `item` (column name), `scale` (or
  `trait`, as in
  [hexaco_items](https://www.okanbulut.com/synthcheck/reference/hexaco_items.md)),
  an optional `facet` and an optional logical `reverse`.

- rule:

  optional function that takes the tibble of features (one row per
  respondent) and returns a logical vector, `TRUE` for careless
  respondents. It replaces the default rule.

- fit_scales:

  the scales used for person fit. `NULL` uses all scales; `character(0)`
  skips person fit (the `person_fit` column is then `NA`).

## Value

A tibble with one row per respondent of `real`: `row` (the row in
`real`), the eight features, `n_flags` (the number of features in the
careless 2.5%, or `NA` with a user `rule`) and `careless`.

## See also

[`behaviour_features()`](https://www.okanbulut.com/synthcheck/reference/behaviour_features.md),
[`synthetic_behaviour()`](https://www.okanbulut.com/synthcheck/reference/synthetic_behaviour.md)

## Examples

``` r
h <- hexaco_items[hexaco_items$trait == "H", ]
real <- hexaco_real[hexaco_real$country == "Canada", ]
fl <- flag_careless(real, h, fit_scales = character(0))
mean(fl$careless)
#> [1] 0.03337237
```
