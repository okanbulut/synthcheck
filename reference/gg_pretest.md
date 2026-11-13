# Draw the pretest

With `what = "items"`, one row per flagged item and one column per
condition. Red tiles are items with too little signal (they barely vary,
link weakly to their scale, run against it or sit closer to another
scale), blue tiles are near-duplicates of another item, pale tiles have
no flag. The letters name the flags, and the row label gives the number
of conditions that flag the item. With `what = "scales"`, one row per
condition and one tile per scale: Cronbach's alpha, red below 0.7, pale
around 0.8, blue at 0.95 or more (often a sign of tidy synthetic
respondents), with the number of dimensions parallel analysis finds.

## Usage

``` r
gg_pretest(
  x,
  what = c("items", "scales"),
  max_items = 30,
  title = NULL,
  subtitle = NULL
)
```

## Arguments

- x:

  a result of
  [`synthetic_pretest()`](https://www.okanbulut.com/synthcheck/reference/synthetic_pretest.md).

- what:

  `"items"` or `"scales"`.

- max_items:

  show at most this many items, those flagged most often first.

- title, subtitle:

  plot titles. `NULL` uses the defaults.

## Value

A ggplot object.

## See also

[`synthetic_pretest()`](https://www.okanbulut.com/synthcheck/reference/synthetic_pretest.md)

## Examples

``` r
# see synthetic_pretest()
```
