# Draw the behaviour strip

**Experimental.** One row per model (or per attempt), one column per
behaviour feature. Each tile is coloured by the direction of the gap
(red: Synthetic respondents lower than real people, blue: Higher) with a
strength of `100 - B_f`, so a pale tile is a match. The number in the
tile is \\B_f\\, and the row label gives Behaviour.

## Usage

``` r
gg_behaviour(x, by = c("model", "attempt"), title = NULL, subtitle = NULL)
```

## Arguments

- x:

  a result of
  [`synthetic_behaviour()`](https://www.okanbulut.com/synthcheck/reference/synthetic_behaviour.md).

- by:

  draw one row per `"model"` (\\B_f\\ averaged over attempts) or per
  `"attempt"`.

- title, subtitle:

  plot titles. `NULL` uses the defaults.

## Value

A ggplot object.

## See also

[`synthetic_behaviour()`](https://www.okanbulut.com/synthcheck/reference/synthetic_behaviour.md)

## Examples

``` r
# see synthetic_behaviour()
```
