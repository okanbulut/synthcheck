# Draw the synthetic authenticity benchmark

**Experimental.** One row per model, sorted by the benchmark score (best
at the top), and one tile for each anchored column (Overlap, Structure,
Behaviour). Tiles run from red (-100 or lower, far worse than shuffled
columns) through pale (around 0, no better than shuffled columns) to
blue (100, as close as a second sample of real people). The number in
each tile is the unclamped value. The column that sets the score is
outlined when `score = "weakest"`. The score is printed at the right.

## Usage

``` r
gg_benchmark(x, title = NULL, subtitle = NULL)
```

## Arguments

- x:

  a result of
  [`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md).

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
