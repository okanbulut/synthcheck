# The eight behaviour features of each respondent

`behaviour_features()` describes how each respondent answers, apart from
what they answer. The eight features are the building blocks of the
Behaviour index in
[`synthetic_behaviour()`](https://www.okanbulut.com/synthcheck/reference/synthetic_behaviour.md)
and of the careless flags in
[`flag_careless()`](https://www.okanbulut.com/synthcheck/reference/flag_careless.md).

## Usage

``` r
behaviour_features(data, items, real = NULL, fit_scales = NULL)
```

## Arguments

- data:

  a data frame of responses (one row per respondent, items as columns,
  matched by name to `items$item`).

- items:

  a data frame with one row per item: `item` (column name), `scale` (or
  `trait`, as in
  [hexaco_items](https://www.okanbulut.com/synthcheck/reference/hexaco_items.md)),
  an optional `facet` and an optional logical `reverse`.

- real:

  optional data frame of real responses used as the reference (see
  Details). `NULL` uses `data`.

- fit_scales:

  the scales used for person fit. `NULL` uses all scales; `character(0)`
  skips person fit (the `person_fit` column is then `NA`).

## Value

A tibble with one row per respondent of `data` and the eight feature
columns.

## Details

|  |  |  |
|----|----|----|
| Feature | Definition | Careless side |
| `variability` | SD of the raw answers across all items | Very low or very high |
| `extreme` | Share of answers at the lowest or highest category | High |
| `midpoint` | Share of answers at the middle category (odd number of categories only) | High |
| `acquiescence` | Mean raw answer minus the scale midpoint | High |
| `key_inconsistency` | Mean over facets of the absolute difference between the keyed means of the positive and the reverse-keyed items | High |
| `even_odd` | Correlation across facets between the keyed means of the odd-numbered and the even-numbered items of each facet | Low |
| `mahalanobis` | Square root of the Mahalanobis distance of the keyed facet means, using the real data's mean and covariance | High |
| `person_fit` | Standardized log-likelihood \\l_z\\ (Drasgow) under a graded response model fitted to the real data, one model per scale, averaged over scales | Low (misfit); very high means "too coherent" |

**Keying.** Keyed answers recode reverse-keyed items as
`(min + max) - x`, where `min` and `max` are the lowest and highest
answers in the reference data (for HEXACO: `8 - x`). Variability,
Extreme, Midpoint and Acquiescence use the raw answers.

**Reference.** The facet means and covariance for `mahalanobis` and the
graded response models for `person_fit` come from `real` (from `data`
itself when `real` is `NULL`). The models are fitted once per scale with
`mirt::mirt(real_keyed[scale_items], 1, "graded")` and are never
refitted on synthetic data. Every respondent gets the MAP theta on a
grid of 81 points from -5 to 5 with a standard normal prior, and \\l_z\\
is computed at that theta. Answers in a category that the real data
never use count as missing for person fit.

**Facets.** Without a `facet` column, the scales stand in for facets in
`key_inconsistency`, `even_odd` and `mahalanobis`. `even_odd` needs at
least three facets with two or more items.

**Missing answers.** A feature is `NA` for a respondent who answered
fewer than half of the items it needs (all items, or a scale's items for
person fit).

## See also

[`synthetic_behaviour()`](https://www.okanbulut.com/synthcheck/reference/synthetic_behaviour.md),
[`flag_careless()`](https://www.okanbulut.com/synthcheck/reference/flag_careless.md)

## Examples

``` r
h <- hexaco_items[hexaco_items$trait == "H", ]
real <- hexaco_real[hexaco_real$country == "Canada", ]
syn <- hexaco_llm[hexaco_llm$country == "Canada" & hexaco_llm$attempt == 1, ]
f <- behaviour_features(syn[1:200, ], h, real = real, fit_scales = character(0))
summary(f)
#>   variability       extreme          midpoint       acquiescence    
#>  Min.   :1.163   Min.   :0.0000   Min.   :0.0500   Min.   :-0.7250  
#>  1st Qu.:1.535   1st Qu.:0.0500   1st Qu.:0.1250   1st Qu.:-0.5250  
#>  Median :1.768   Median :0.1500   Median :0.1500   Median :-0.4500  
#>  Mean   :1.690   Mean   :0.1265   Mean   :0.1444   Mean   :-0.3149  
#>  3rd Qu.:1.840   3rd Qu.:0.2000   3rd Qu.:0.1562   3rd Qu.:-0.0500  
#>  Max.   :1.987   Max.   :0.2500   Max.   :0.2750   Max.   : 0.5500  
#>                                                                     
#>  key_inconsistency    even_odd       mahalanobis      person_fit 
#>  Min.   :0.2562    Min.   :0.5915   Min.   :1.204   Min.   : NA  
#>  1st Qu.:0.3809    1st Qu.:0.9060   1st Qu.:1.600   1st Qu.: NA  
#>  Median :0.4458    Median :0.9494   Median :1.690   Median : NA  
#>  Mean   :0.5013    Mean   :0.9327   Mean   :1.691   Mean   :NaN  
#>  3rd Qu.:0.5611    3rd Qu.:0.9744   3rd Qu.:1.763   3rd Qu.: NA  
#>  Max.   :1.0479    Max.   :0.9994   Max.   :2.295   Max.   : NA  
#>                                                     NAs    :200  
# \donttest{
# with person fit (fits a graded response model to the real data)
f <- behaviour_features(syn[1:200, ], h, real = real)
summary(f$person_fit)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   0.946   1.406   1.563   1.617   1.781   2.745 
# }
```
