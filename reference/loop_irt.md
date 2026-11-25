# IRT checks for the item-revision loop

`loop_irt()` makes the `evaluator` step of
[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md).
For every scale, it fits a unidimensional IRT model with mirt to the
keyed answers of the round. By default this is the partial credit model
(Masters, 1982), a Rasch model for ordered categories with every slope
fixed at 1; `model = "gpcm"` (generalized partial credit) and
`model = "graded"` (graded response) estimate a slope per item instead.
It flags

## Usage

``` r
loop_irt(
  model = c("pcm", "gpcm", "graded"),
  thresholds = list(),
  itemfit = TRUE,
  q3 = TRUE,
  overfit = c("fail", "warn")
)
```

## Arguments

- model:

  the IRT model: `"pcm"` (partial credit, the default), `"gpcm"`
  (generalized partial credit) or `"graded"` (graded response).

- thresholds:

  a named list that changes any of the defaults
  `list(msq = c(0.6, 1.4), misfit_p = 0.01, slope = 0.65, steep = 4, q3 = 0.2, info = NULL)`.

- itemfit, q3:

  compute the item fit statistics and the Q3 residuals? They are the
  slowest parts.

- overfit:

  severity of a mean square below the range (answers more predictable
  than the model expects): `"fail"` or `"warn"`. Language models often
  answer almost deterministically for a given persona, which rewording
  cannot change, so `"warn"` lets the stopping rule rest on the other
  checks.

## Value

A function for the `evaluator` argument of
[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md).

## Details

- `msq_misfit` (fail, partial credit model): Infit or outfit mean square
  outside `thresholds$msq` (0.6 to 1.4 by default, the range Wright and
  Linacre (1994) give for rating scales). Below the range, answers are
  more predictable than the model expects (often a sign of redundant
  items or tidy synthetic respondents); above it, they are noisy. With
  `overfit = "warn"`, an item that is only too predictable is a warning,
  and only noisy items fail.

- `misfit` (fail): The S-X2 item fit test (Orlando & Thissen, 2000) has
  a p value below `thresholds$misfit_p`.

- `disordered` (warn): The item's thresholds (the points where one
  category becomes more likely than the one below) are not in increasing
  order, so some categories are never the most likely answer.

- `low_slope` (fail, `"gpcm"` and `"graded"` only): A discrimination
  below `thresholds$slope`; a negative slope means the item runs against
  its scale.

- `steep_slope` (warn, `"gpcm"` and `"graded"` only): A discrimination
  above `thresholds$steep`, which synthetic respondents that answer
  almost deterministically produce.

- `local_dependence` (warn): The item's largest Q3 residual correlation
  (Yen, 1984) exceeds the mean Q3 of its scale by more than
  `thresholds$q3`, a sign that two items share more than the trait.

- `no_variance` (fail): Every respondent gives the same answer, so the
  item cannot be fitted.

- `low_info` (fail, only with `thresholds$info`): The mean test
  information of the scale between theta -2 and 2 is below the target.

- `irt_failed` (fail): The model could not be fitted for the scale.

Stats: Per item `location` (the mean of its thresholds), `infit` and
`outfit` (partial credit model), `slope` (`"gpcm"` and `"graded"`) and
`sx2_p`, and per scale `info_mean` and `marginal_rxx` (marginal
reliability), which
[`loop_criterion()`](https://www.okanbulut.com/synthcheck/reference/loop_criterion.md)
can use as targets, for example `min = list(marginal_rxx = 0.8)`. Both
are taken over the estimated latent distribution, with the trait
standardized: `info_mean` is the mean information between 2 SD below and
2 SD above the latent mean, and `marginal_rxx` is the mean of \\\sigma^2
I / (\sigma^2 I + 1)\\. With a latent variance of 1 these equal the
usual values.

## References

Masters, G. N. (1982). A Rasch model for partial credit scoring.
*Psychometrika, 47*(2), 149-174.

Orlando, M., & Thissen, D. (2000). Likelihood-based item-fit indices for
dichotomous item response theory models. *Applied Psychological
Measurement, 24*(1), 50-64.

Wright, B. D., & Linacre, J. M. (1994). Reasonable mean-square fit
values. *Rasch Measurement Transactions, 8*(3), 370.

Yen, W. M. (1984). Effects of local item dependence on the fit and
equating performance of the three-parameter logistic model. *Applied
Psychological Measurement, 8*(2), 125-145.

## See also

[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md),
[`loop_checker()`](https://www.okanbulut.com/synthcheck/reference/loop_checker.md)

## Examples

``` r
# \donttest{
h <- hexaco_items[hexaco_items$facet %in% c("HSinc", "HFair"), ]
ca <- hexaco_real[hexaco_real$country == "Canada", ]
irt <- loop_irt()
out <- irt(ca[1:400, ], h, list(construct = loop_construct("H", scale = c(1, 7))))
out$flags
#>       item scale            check       value threshold severity
#> 1   HSinc1     H       disordered 2.000000000 0.0000000     warn
#> 2   HSinc2     H       disordered 1.000000000 0.0000000     warn
#> 3   HSinc3     H       disordered 1.000000000 0.0000000     warn
#> 4   HSinc4     H       disordered 2.000000000 0.0000000     warn
#> 5   HSinc5     H       disordered 1.000000000 0.0000000     warn
#> 6   HSinc6     H       disordered 1.000000000 0.0000000     warn
#> 7   HSinc7     H       disordered 1.000000000 0.0000000     warn
#> 8   HSinc8     H       disordered 2.000000000 0.0000000     warn
#> 9   HSinc9     H       disordered 1.000000000 0.0000000     warn
#> 10 HSinc10     H       disordered 1.000000000 0.0000000     warn
#> 11  HFair1     H       disordered 3.000000000 0.0000000     warn
#> 12  HFair2     H       disordered 3.000000000 0.0000000     warn
#> 13  HFair3     H       disordered 2.000000000 0.0000000     warn
#> 14  HFair4     H       disordered 3.000000000 0.0000000     warn
#> 15  HFair5     H       disordered 2.000000000 0.0000000     warn
#> 16  HFair6     H       disordered 4.000000000 0.0000000     warn
#> 17  HFair7     H       disordered 2.000000000 0.0000000     warn
#> 18  HFair8     H       disordered 3.000000000 0.0000000     warn
#> 19  HFair9     H       disordered 2.000000000 0.0000000     warn
#> 20 HFair10     H       disordered 1.000000000 0.0000000     warn
#> 21 HSinc10     H           misfit 0.000313283 0.0100000     fail
#> 22  HFair7     H           misfit 0.006910746 0.0100000     fail
#> 23 HSinc10     H       msq_misfit 1.428907852 1.4000000     fail
#> 24  HSinc1     H local_dependence 0.260182173 0.1579323     warn
#> 25  HSinc2     H local_dependence 0.170967543 0.1579323     warn
#> 26  HSinc3     H local_dependence 0.175065461 0.1579323     warn
#> 27  HSinc4     H local_dependence 0.429902663 0.1579323     warn
#> 28  HSinc6     H local_dependence 0.429902663 0.1579323     warn
#> 29  HSinc7     H local_dependence 0.175065461 0.1579323     warn
#> 30  HSinc8     H local_dependence 0.175554100 0.1579323     warn
#> 31  HSinc9     H local_dependence 0.318635116 0.1579323     warn
#> 32 HSinc10     H local_dependence 0.318635116 0.1579323     warn
#> 33  HFair1     H local_dependence 0.433533500 0.1579323     warn
#> 34  HFair2     H local_dependence 0.230590211 0.1579323     warn
#> 35  HFair4     H local_dependence 0.398122629 0.1579323     warn
#> 36  HFair5     H local_dependence 0.230590211 0.1579323     warn
#> 37  HFair7     H local_dependence 0.252640082 0.1579323     warn
#> 38  HFair8     H local_dependence 0.433533500 0.1579323     warn
#> 39 HFair10     H local_dependence 0.224914486 0.1579323     warn
#>                                                                                                                  message
#> 1     Thresholds out of order (-0.89, -0.90, 0.12, -0.21, 0.03, 0.77): Some categories are never the most likely answer.
#> 2    Thresholds out of order (-1.40, -1.00, 0.21, -0.31, -0.13, 0.35): Some categories are never the most likely answer.
#> 3     Thresholds out of order (-0.82, -0.61, 0.36, -0.18, 0.20, 0.83): Some categories are never the most likely answer.
#> 4      Thresholds out of order (-1.78, -0.70, 0.12, 0.09, 0.05, 0.52): Some categories are never the most likely answer.
#> 5    Thresholds out of order (-0.83, -0.65, 0.01, -0.16, -0.05, 0.30): Some categories are never the most likely answer.
#> 6     Thresholds out of order (-1.06, -0.90, 0.62, -0.10, 0.16, 0.48): Some categories are never the most likely answer.
#> 7    Thresholds out of order (-1.03, -0.98, 0.65, -0.51, -0.49, 0.03): Some categories are never the most likely answer.
#> 8      Thresholds out of order (-0.23, -0.00, 1.20, 0.55, 0.40, 0.65): Some categories are never the most likely answer.
#> 9     Thresholds out of order (-1.12, -0.43, 0.35, -0.00, 0.24, 0.64): Some categories are never the most likely answer.
#> 10   Thresholds out of order (-1.05, -0.75, 0.29, -0.32, -0.01, 0.09): Some categories are never the most likely answer.
#> 11   Thresholds out of order (-0.96, -1.00, 0.51, -0.24, -0.59, 0.08): Some categories are never the most likely answer.
#> 12  Thresholds out of order (-0.25, -0.55, -0.87, 0.47, -1.23, -0.07): Some categories are never the most likely answer.
#> 13  Thresholds out of order (-0.46, -0.22, -0.43, -0.08, -0.37, 0.11): Some categories are never the most likely answer.
#> 14  Thresholds out of order (-0.29, -0.84, 0.40, -1.05, -0.28, -0.49): Some categories are never the most likely answer.
#> 15  Thresholds out of order (-0.83, -0.92, -0.23, -1.20, -0.37, 1.13): Some categories are never the most likely answer.
#> 16   Thresholds out of order (-0.25, -0.27, 0.55, 0.26, -0.05, -0.07): Some categories are never the most likely answer.
#> 17 Thresholds out of order (-1.32, -1.02, -0.16, -0.52, -0.62, -0.16): Some categories are never the most likely answer.
#> 18  Thresholds out of order (-1.09, -1.33, 0.28, -0.60, -0.83, -0.71): Some categories are never the most likely answer.
#> 19  Thresholds out of order (-3.27, -0.55, 0.03, -1.03, -1.15, -0.41): Some categories are never the most likely answer.
#> 20 Thresholds out of order (-0.91, -0.36, -0.10, -0.68, -0.62, -0.27): Some categories are never the most likely answer.
#> 21                                                  S-X2 item fit p = 0.000313: The model does not describe the answers.
#> 22                                                   S-X2 item fit p = 0.00691: The model does not describe the answers.
#> 23                            Outfit mean square 1.43 is outside 0.6 to 1.4: Answers are noisier than the model expects.
#> 24                                                                Q3 = 0.26 with HSinc4, 0.30 above the scale's mean Q3.
#> 25                                                                Q3 = 0.17 with HSinc4, 0.21 above the scale's mean Q3.
#> 26                                                                Q3 = 0.18 with HSinc7, 0.22 above the scale's mean Q3.
#> 27                                                                Q3 = 0.43 with HSinc6, 0.47 above the scale's mean Q3.
#> 28                                                                Q3 = 0.43 with HSinc4, 0.47 above the scale's mean Q3.
#> 29                                                                Q3 = 0.18 with HSinc3, 0.22 above the scale's mean Q3.
#> 30                                                                Q3 = 0.18 with HSinc6, 0.22 above the scale's mean Q3.
#> 31                                                               Q3 = 0.32 with HSinc10, 0.36 above the scale's mean Q3.
#> 32                                                                Q3 = 0.32 with HSinc9, 0.36 above the scale's mean Q3.
#> 33                                                                Q3 = 0.43 with HFair8, 0.48 above the scale's mean Q3.
#> 34                                                                Q3 = 0.23 with HFair5, 0.27 above the scale's mean Q3.
#> 35                                                                Q3 = 0.40 with HFair1, 0.44 above the scale's mean Q3.
#> 36                                                                Q3 = 0.23 with HFair2, 0.27 above the scale's mean Q3.
#> 37                                                                Q3 = 0.25 with HFair8, 0.29 above the scale's mean Q3.
#> 38                                                                Q3 = 0.43 with HFair1, 0.48 above the scale's mean Q3.
#> 39                                                                Q3 = 0.22 with HFair4, 0.27 above the scale's mean Q3.
# }
```
