# Get the blended respondents

`blend_data()` draws the synthetic respondents behind the best blend of
an
[`synthetic_coverage()`](https://www.okanbulut.com/synthcheck/reference/synthetic_coverage.md)
or
[`blend_llms()`](https://www.okanbulut.com/synthcheck/reference/blend_llms.md)
result: For each attempt, it takes from each model a share of its
respondents that matches the blend weights and stacks them into one data
frame. The `model` column names the model each respondent came from.
Save the result with
[`write_synthetic()`](https://www.okanbulut.com/synthcheck/reference/write_synthetic.md),
or benchmark it like any other synthetic data with
`as_synthetic_list(blended, model = "blend")`.

## Usage

``` r
blend_data(x, n = NULL, attempts = NULL, seed = 1, synthetic = NULL)
```

## Arguments

- x:

  an `sc_coverage` object with a blend, from
  [`synthetic_coverage()`](https://www.okanbulut.com/synthcheck/reference/synthetic_coverage.md)
  or
  [`blend_llms()`](https://www.okanbulut.com/synthcheck/reference/blend_llms.md).

- n:

  respondents per attempt. `NULL` (the default) takes the smallest
  attempt among the models, as the blend's Structure does.

- attempts:

  the attempts to draw from. `NULL` takes all of them.

- seed:

  random seed for the draw.

- synthetic:

  optional: The full synthetic data, as a named list in the form
  [`synthetic_coverage()`](https://www.okanbulut.com/synthcheck/reference/synthetic_coverage.md)
  takes, to draw the rows from, for example when the coverage was run on
  the item columns only and you want the persona columns too. It needs
  the same models, and each attempt the same number of rows in the same
  order. `NULL` uses the data stored in `x`.

## Value

A tibble with one row per blended respondent: `blend` (the recipe, the
same in every row), `model` (the source model), `attempt`, and the
columns of the synthetic data. The weights are in the `"weights"`
attribute.

## Details

The draw is random, so `seed` makes it repeatable. Each model's
respondents are drawn without replacement unless `n` asks for more than
a model has.

## See also

[`blend_llms()`](https://www.okanbulut.com/synthcheck/reference/blend_llms.md),
[`synthetic_coverage()`](https://www.okanbulut.com/synthcheck/reference/synthetic_coverage.md),
[`write_synthetic()`](https://www.okanbulut.com/synthcheck/reference/write_synthetic.md)

## Examples

``` r
set.seed(1)
a <- matrix(rlnorm(8, 0.2, 0.3)); d <- matrix(rnorm(8))
real <- as.data.frame(mirt::simdata(a, d, 600, itemtype = "dich"))
llm <- function(mu, s) lapply(1:4, function(i) as.data.frame(
  mirt::simdata(a, d, 150, itemtype = "dich", Theta = matrix(rnorm(150, mu, s)))))
cov <- synthetic_coverage(list(A = llm(0.8, 0.7), B = llm(-0.6, 0.9)), real)
blended <- blend_data(cov, seed = 2)
table(blended$model, blended$attempt)
#>    
#>      1  2  3  4
#>   A 75 75 75 75
#>   B 75 75 75 75
f <- tempfile(fileext = ".csv")
write_synthetic(blended, f)
```
