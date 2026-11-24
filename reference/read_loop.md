# Read the log of item-revision loops

`read_loop()` reads the CSV files that
[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md)
writes with `output`. Give it the folder of one run, or a folder that
holds one folder per run (for example one per replication or design
cell): The tables of all runs are then stacked, with `run_id` telling
them apart.

## Usage

``` r
read_loop(path)
```

## Arguments

- path:

  a run folder, or a folder of run folders.

## Value

An object of class `sc_loop` with the seven log tables (see
[`loop_log_schema()`](https://www.okanbulut.com/synthcheck/reference/loop_log_schema.md)).

## See also

[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md)

## Examples

``` r
h <- hexaco_items[hexaco_items$facet %in% c("HSinc", "HFair"), ]
h$scale <- h$facet
con <- loop_construct("Honesty-Humility", scale = c(1, 7))
dir <- file.path(tempdir(), "loops")
for (s in 1:2) revision_loop(con, h, respondents = 30, max_rounds = 2, seed = s,
                             evaluator = NULL, checker = loop_checker(n_pa = 5),
                             output = file.path(dir, paste0("seed", s)), cache = FALSE)
runs <- read_loop(dir)
runs$runs[, c("run_id", "status", "rounds")]
#> # A tibble: 2 × 3
#>   run_id                 status     rounds
#>   <chr>                  <chr>       <int>
#> 1 Honesty_Humility-seed1 max_rounds      2
#> 2 Honesty_Humility-seed2 max_rounds      2
loop_outcomes(runs)
#> # A tibble: 2 × 18
#>   run_id      status rounds rounds_to_polish items_start items_end failing_start
#>   <chr>       <chr>   <int>            <int>       <int>     <int>         <int>
#> 1 Honesty_Hu… max_r…      2               NA          20         6            18
#> 2 Honesty_Hu… max_r…      2               NA          20         6            20
#> # ℹ 11 more variables: failing_end <int>, edits <int>, reworded <int>,
#> #   rekeyed <int>, dropped <int>, added <int>, cites_flagged <dbl>,
#> #   resolved <dbl>, relapsed <dbl>, similarity <dbl>, cost <dbl>
```
