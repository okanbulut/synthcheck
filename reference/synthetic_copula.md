# Respondents drawn from a Gaussian copula of the real data

`synthetic_copula()` makes synthetic respondents with no language model.
It keeps each item's answer distribution and the rank correlations
between items, and nothing else. It is a reference generator: A language
model that does no better than the copula adds nothing beyond the real
data's item distributions and correlations (Lukauskas & Šarkauskaitė,
2026; Kumagae & Kaneko, 2026).

## Usage

``` r
synthetic_copula(real, n, items = NULL, attempts = 1, seed = 1)
```

## Arguments

- real:

  a data frame of real responses.

- n:

  number of respondents per attempt.

- items:

  optional item table (see
  [`behaviour_features()`](https://www.okanbulut.com/synthcheck/reference/behaviour_features.md))
  or a character vector of item columns. `NULL` uses every numeric
  column of `real`.

- attempts:

  number of attempts (independent draws).

- seed:

  random seed.

## Value

A list of `attempts` data frames with `n` rows and the item columns,
ready to be one element of `synthetic` in
[`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md)
and the other functions.

## Details

**How it works.** Each answer is turned into a normal score at the
middle of its category, \\z = \Phi^{-1}((F(x^-) + F(x)) / 2)\\, where
\\F\\ is the item's empirical distribution in `real`. The correlation
matrix of the normal scores (pairwise complete) is made positive
definite, new normal vectors are drawn from it, and each value is mapped
back to the category whose cumulative share it falls in. The respondents
have no missing answers.

**Caution.** The copula is fitted to `real`, so it has seen the people
it is compared with. It is a strong in-sample reference, not a fair
competitor, and it says nothing about a model's value when no real data
exist.

## References

Lukauskas, M., & Šarkauskaitė, V. (2026). Plausible but not valid: A
psychometric audit of LLMs as synthetic survey respondents.
arXiv:2608.14606.

Kumagae, Y., & Kaneko, M. (2026). Silicon samples match the answers but
not the respondents. arXiv:2610.30900.

## See also

[`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md)
(`copula = TRUE`)

## Examples

``` r
h <- hexaco_items[hexaco_items$trait == "H", ]
real <- hexaco_real[hexaco_real$country == "Canada", ]
cop <- synthetic_copula(real, n = 300, items = h, attempts = 2)
# item means of the copula and of the real data
round(rbind(copula = colMeans(cop[[1]][1:5]),
            real = colMeans(real[names(cop[[1]])[1:5]], na.rm = TRUE)), 2)
#>        HSinc1 HSinc2 HSinc3 HSinc4 HSinc5
#> copula   4.53   3.18   3.73   3.48   3.44
#> real     4.49   3.19   3.85   3.60   3.40
```
