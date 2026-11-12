# Find the best blend of language models

Searches the blend weights for an
[`synthetic_coverage()`](https://www.okanbulut.com/synthcheck/reference/synthetic_coverage.md)
result again, for example with a finer grid or without holding out
attempts. The recipe with the highest mean overlap on the attempts it is
chosen on wins; with `holdout`, it is chosen on the first half of the
attempts and reported on the second half.

## Usage

``` r
blend_llms(x, holdout = NULL, step = 0.05, seed = 1)
```

## Arguments

- x:

  an `sc_coverage` object from
  [`synthetic_coverage()`](https://www.okanbulut.com/synthcheck/reference/synthetic_coverage.md).

- holdout:

  choose on half of the attempts and report on the other half? `NULL`
  does so when every model has four or more attempts.

- step:

  grid step for the weights (coarser steps are used for more than six
  models).

- seed:

  random seed for the pooled sample behind the blend's structure.

## Value

`x` with a `"Best Blend"` row in `summary`, its cells and attempts
added, and `blend`: A list with `weights` (a named vector), `recipe`
(text), `train` and `test` (the attempts used) and `in_sample` (the mean
overlap on the attempts the recipe was chosen on).

## See also

[`synthetic_coverage()`](https://www.okanbulut.com/synthcheck/reference/synthetic_coverage.md),
[`gg_coverage()`](https://www.okanbulut.com/synthcheck/reference/gg_coverage.md)

## Examples

``` r
set.seed(1)
a <- matrix(rlnorm(8, 0.2, 0.3)); d <- matrix(rnorm(8))
real <- as.data.frame(mirt::simdata(a, d, 600, itemtype = "dich"))
llm <- function(mu, s) lapply(1:4, function(i) as.data.frame(
  mirt::simdata(a, d, 150, itemtype = "dich", Theta = matrix(rnorm(150, mu, s)))))
cov <- synthetic_coverage(list(A = llm(0.8, 0.7), B = llm(-0.6, 0.9)), real,
                          blend = FALSE)
blend_llms(cov, holdout = FALSE)$blend$recipe
#> [1] "50% A + 50% B"
```
