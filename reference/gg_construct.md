# Draw the construct structure

**Experimental.** One row per model and one tile per scale
(`what = "alpha"`) or per pair of scales (`what = "cor"`), averaged over
attempts. Red means lower than in real people, blue means higher, pale
means a match. With `"alpha"`, the tile is the synthetic minus the real
alpha and the number is the synthetic alpha (the real alpha is in the
column label). With `"cor"`, the tile and the number are the synthetic
minus the real correlation between two scales.

## Usage

``` r
gg_construct(x, what = c("alpha", "cor"), title = NULL, subtitle = NULL)
```

## Arguments

- x:

  a result of
  [`synthetic_construct()`](https://www.okanbulut.com/synthcheck/reference/synthetic_construct.md).

- what:

  `"alpha"` or `"cor"`.

- title, subtitle:

  plot titles. `NULL` uses the defaults.

## Value

A ggplot object.

## See also

[`synthetic_construct()`](https://www.okanbulut.com/synthcheck/reference/synthetic_construct.md)

## Examples

``` r
# see synthetic_construct()
```
