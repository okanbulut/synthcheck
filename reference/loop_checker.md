# Data quality checks for the item-revision loop

`loop_checker()` makes the `checker` step of
[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md).
It runs
[`synthetic_pretest()`](https://www.okanbulut.com/synthcheck/reference/synthetic_pretest.md)
on the round's responses (all respondent models pooled) and screens the
respondents for answer patterns that make the data unusable.

## Usage

``` r
loop_checker(
  thresholds = list(),
  irt = FALSE,
  n_pa = 20,
  straightline_sd = 0.5,
  inconsistency = 0.5,
  max_careless = 0.05
)
```

## Arguments

- thresholds:

  thresholds for the item flags, as in
  [`synthetic_pretest()`](https://www.okanbulut.com/synthcheck/reference/synthetic_pretest.md).

- irt:

  also fit graded response models in
  [`synthetic_pretest()`](https://www.okanbulut.com/synthcheck/reference/synthetic_pretest.md)
  for its `slope` flags? Off by default, because
  [`loop_irt()`](https://www.okanbulut.com/synthcheck/reference/loop_irt.md)
  fits them as the evaluator.

- n_pa:

  number of random data sets for parallel analysis.

- straightline_sd, inconsistency, max_careless:

  the respondent screening rules (see above).

## Value

A function for the `checker` argument of
[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md).

## Details

**Item flags** (from
[`synthetic_pretest()`](https://www.okanbulut.com/synthcheck/reference/synthetic_pretest.md),
with its thresholds): `low_variance`, `key`, `weak` and `other_scale`
with severity `"fail"`, and `redundant` with severity `"warn"`.

**Respondent screening.** A respondent is unusable when the SD of their
answers is below `straightline_sd` (straight-lining), when the mean
keyed difference between their positive and reverse-keyed items is above
`inconsistency` times the width of the scale (they ignore the keys), or
when more than half of their answers are missing. The share of unusable
respondents is the stat `careless_share`, flagged (with `item` and
`scale` `NA`) when it is above `max_careless`. These are absolute rules,
because the respondents are compared with no real people here.

**Stats:** `alpha`, `mean_r` and `n_factors` per scale; `own_scale`,
`reverse_ok`, `n_factors_all`, `scales` and `careless_share` over all
items; and per item `mean`, `sd`, `item_rest`, `max_r` and (with
`irt = TRUE`) `slope`.

## See also

[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md),
[`synthetic_pretest()`](https://www.okanbulut.com/synthcheck/reference/synthetic_pretest.md)

## Examples

``` r
ins <- sc_instrument(hexaco_items[hexaco_items$trait == "H", ], scale = c(1, 7))
syn <- generate_synthetic(ins, sc_model("mock"), respondents = 30, cache = FALSE)
chk <- loop_checker(n_pa = 5)
out <- chk(syn, ins$items, list(construct = loop_construct("H", scale = c(1, 7))))
head(out$flags)
#>          item scale check       value threshold severity
#> key.1  HSinc4     H   key -0.51763021         0     fail
#> key.2  HSinc7     H   key -0.01460503         0     fail
#> key.3 HSinc10     H   key -0.35068716         0     fail
#> key.4  HFair1     H   key -0.07363159         0     fail
#> key.5  HFair2     H   key -0.28346589         0     fail
#> key.6  HFair4     H   key -0.36642555         0     fail
#>                                                          message
#> key.1 Runs against its scale: Keyed item-rest correlation -0.52.
#> key.2 Runs against its scale: Keyed item-rest correlation -0.01.
#> key.3 Runs against its scale: Keyed item-rest correlation -0.35.
#> key.4 Runs against its scale: Keyed item-rest correlation -0.07.
#> key.5 Runs against its scale: Keyed item-rest correlation -0.28.
#> key.6 Runs against its scale: Keyed item-rest correlation -0.37.
```
