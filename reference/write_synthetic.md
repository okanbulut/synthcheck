# Save and read synthetic respondents

`write_synthetic()` saves a data frame of synthetic respondents (for
example from
[`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md))
as CSV, JSON, RDS or Excel. `read_synthetic()` reads one file, or every
data file in a folder written by
[`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md),
back into one tibble.

## Usage

``` r
write_synthetic(data, path, format = NULL)

read_synthetic(path, format = NULL)
```

## Arguments

- data:

  a data frame with one row per respondent.

- path:

  a file name, or for `read_synthetic()` a file or a folder.

- format:

  `"csv"` (the default), `"json"`, `"rds"` or `"xlsx"` (needs writexl).
  `NULL` takes it from the file extension.

## Value

`write_synthetic()` returns `path` invisibly. `read_synthetic()` returns
a tibble.

## See also

[`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md),
[`as_synthetic_list()`](https://www.okanbulut.com/synthcheck/reference/as_synthetic_list.md)

## Examples

``` r
ins <- sc_instrument(c("I like parties.", "I keep my desk tidy."), scale = c(1, 5))
syn <- generate_synthetic(ins, sc_model("mock"), attempts = 2, respondents = 5)
f <- tempfile(fileext = ".csv")
write_synthetic(syn, f)
read_synthetic(f)
#> # A tibble: 10 × 9
#>    model provider model_id temperature attempt persona_id respondent    i1    i2
#>    <chr> <chr>    <chr>          <int>   <int> <chr>           <int> <int> <int>
#>  1 mock  mock     mock               1       1 none                1     4     4
#>  2 mock  mock     mock               1       1 none                2     2     1
#>  3 mock  mock     mock               1       1 none                3     2     2
#>  4 mock  mock     mock               1       1 none                4     4     3
#>  5 mock  mock     mock               1       1 none                5     4     4
#>  6 mock  mock     mock               1       2 none                1     2     4
#>  7 mock  mock     mock               1       2 none                2     2     5
#>  8 mock  mock     mock               1       2 none                3     3     3
#>  9 mock  mock     mock               1       2 none                4     2     5
#> 10 mock  mock     mock               1       2 none                5     3     5
```
