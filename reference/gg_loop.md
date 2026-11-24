# Draw an item-revision loop

`gg_loop()` shows one run at a glance: One row per item (grouped by
scale), one column per round. Red tiles are items with a failing flag,
pale tiles items without one, and a dot marks an item that was reworded,
rekeyed or added before that round. Dropped items stop. The title says
whether and when the items were polished.

## Usage

``` r
gg_loop(x, run = NULL, title = NULL, subtitle = NULL)
```

## Arguments

- x:

  a result of
  [`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md)
  or
  [`read_loop()`](https://www.okanbulut.com/synthcheck/reference/read_loop.md).

- run:

  the `run_id` to draw; the first run by default.

- title, subtitle:

  plot titles. `NULL` uses the defaults.

## Value

A ggplot object.

## See also

[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md)

## Examples

``` r
# see revision_loop()
```
