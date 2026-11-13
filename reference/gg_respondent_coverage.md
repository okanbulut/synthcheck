# Draw the respondent coverage

One point per model at its RCG (across) and OSR (up), with the second
sample of real people and the shuffled real columns as grey references.
Real-like models sit near the bottom left corner (both ratios near 1).
Far to the right and up means off-support, far to the right but low
means contraction (see
[`respondent_coverage()`](https://www.okanbulut.com/synthcheck/reference/respondent_coverage.md)).

## Usage

``` r
gg_respondent_coverage(x, title = NULL, subtitle = NULL)
```

## Arguments

- x:

  a result of
  [`respondent_coverage()`](https://www.okanbulut.com/synthcheck/reference/respondent_coverage.md).

- title, subtitle:

  plot titles. `NULL` uses the defaults.

## Value

A ggplot object.

## See also

[`respondent_coverage()`](https://www.okanbulut.com/synthcheck/reference/respondent_coverage.md)

## Examples

``` r
# see respondent_coverage()
```
