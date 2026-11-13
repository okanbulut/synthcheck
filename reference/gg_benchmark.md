# Draw the synthetic authenticity benchmark

One row per model, sorted by the benchmark score (best at the top), and
one tile for each anchored column (Overlap, Structure, Behaviour). Tiles
run from red (-100 or lower, far worse than shuffled columns) through
pale (around 0, no better than shuffled columns) to blue (100, as close
as a second sample of real people). The number in each tile is the
unclamped value. The column that sets the score is outlined when
`score = "weakest"`. The score is printed at the right. Under each
number, in small print, is its interval (see
[`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md)):
Models whose score intervals overlap are not clearly apart.

## Usage

``` r
gg_benchmark(x, intervals = TRUE, title = NULL, subtitle = NULL)
```

## Arguments

- x:

  a result of
  [`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md).

- intervals:

  print the intervals under the values?

- title, subtitle:

  plot titles. `NULL` uses the defaults.

## Value

A ggplot object.

## See also

[`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md)

## Examples

``` r
# see authenticity_benchmark()
```
