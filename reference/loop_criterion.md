# The stopping rule of the item-revision loop

`loop_criterion()` makes the `criterion` of
[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md):
The rule that says when items are polished. Decide it before the first
run, so that the number of rounds means something. Every part gives one
row in the `criteria` table, and the items are polished when every row
passes.

## Usage

``` r
loop_criterion(
  no_failing_items = TRUE,
  min = list(alpha = 0.8, own_scale = 0.9),
  max = list(careless_share = 0.05),
  min_items = 3,
  factors = FALSE,
  min_total = NULL
)
```

## Arguments

- no_failing_items:

  require that no item has a failing flag?

- min, max:

  named lists of targets for stats (see above).

- min_items:

  smallest number of items per scale.

- factors:

  require the number of dimensions to match the number of scales?

- min_total:

  smallest number of items in all, or `NULL`.

## Value

A function for the `criterion` argument of
[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md).

## Details

- `no_failing_items`: No item has a flag with severity `"fail"`, from
  any step.

- `min`: For each named stat, its lowest value (over scales or items)
  must be at least the target. The default asks for alpha of at least
  0.80 in every scale and at least 90% of items closest to their own
  scale.

- `max`: For each named stat, its highest value must be at most the
  target. The default allows at most 5% unusable respondents.

- `min_items`: Every scale keeps at least this many items. A scale of
  the construct that lost all its items counts as 0, so `min_items = 1`
  requires that every scale (or content domain) is still there.

- `min_total`: The items number at least this many in all.

- `factors`: Parallel analysis over all items finds as many dimensions
  as there are scales, or one dimension for a construct made with
  `single_scale = TRUE`.

Stats from any step can be named, for example the test information of
[`loop_irt()`](https://www.okanbulut.com/synthcheck/reference/loop_irt.md)
(`min = list(marginal_rxx = 0.8)`). A stat that no step reports fails,
so that a missing check never passes quietly.

## See also

[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md)

## Examples

``` r
loop_criterion()
#> function (flags, stats, items, context) 
#> {
#>     rows <- list()
#>     add <- function(name, value, target, pass) rows[[length(rows) + 
#>         1L]] <<- data.frame(criterion = name, value = value, 
#>         target = target, pass = pass, stringsAsFactors = FALSE)
#>     if (no_failing_items) {
#>         n <- length(unique(flags$item[flags$severity == "fail" & 
#>             !is.na(flags$item)]))
#>         add("no_failing_items", n, 0, n == 0)
#>     }
#>     for (s in names(min)) {
#>         v <- stats$value[stats$stat == s]
#>         v <- if (length(v) && any(!is.na(v))) 
#>             min(v, na.rm = TRUE)
#>         else NA_real_
#>         add(paste0("min_", s), v, min[[s]], !is.na(v) && v >= 
#>             min[[s]])
#>     }
#>     for (s in names(max)) {
#>         v <- stats$value[stats$stat == s]
#>         v <- if (length(v) && any(!is.na(v))) 
#>             max(v, na.rm = TRUE)
#>         else NA_real_
#>         add(paste0("max_", s), v, max[[s]], !is.na(v) && v <= 
#>             max[[s]])
#>     }
#>     con <- context$construct
#>     if (!is.null(min_items)) {
#>         sc <- unique(c(names(con$scales), items$scale))
#>         n <- min(table(factor(items$scale, levels = sc)))
#>         add("min_items", n, min_items, n >= min_items)
#>     }
#>     if (!is.null(min_total)) 
#>         add("min_total", nrow(items), min_total, nrow(items) >= 
#>             min_total)
#>     if (factors) {
#>         v <- stats$value[stats$stat == "n_factors_all"][1]
#>         k <- if (isTRUE(con$single_scale)) 
#>             1L
#>         else length(unique(items$scale))
#>         add("factors", v, k, !is.na(v) && v == k)
#>     }
#>     if (!length(rows)) 
#>         return(NULL)
#>     do.call(rbind, rows)
#> }
#> <bytecode: 0x64eeefb623f0>
#> <environment: 0x64eee388af48>
#> attr(,"label")
#> [1] "no failing items; alpha >= 0.8; own_scale >= 0.9; careless_share <= 0.05; at least 3 items per scale"
loop_criterion(min = list(alpha = 0.7), factors = TRUE)
#> function (flags, stats, items, context) 
#> {
#>     rows <- list()
#>     add <- function(name, value, target, pass) rows[[length(rows) + 
#>         1L]] <<- data.frame(criterion = name, value = value, 
#>         target = target, pass = pass, stringsAsFactors = FALSE)
#>     if (no_failing_items) {
#>         n <- length(unique(flags$item[flags$severity == "fail" & 
#>             !is.na(flags$item)]))
#>         add("no_failing_items", n, 0, n == 0)
#>     }
#>     for (s in names(min)) {
#>         v <- stats$value[stats$stat == s]
#>         v <- if (length(v) && any(!is.na(v))) 
#>             min(v, na.rm = TRUE)
#>         else NA_real_
#>         add(paste0("min_", s), v, min[[s]], !is.na(v) && v >= 
#>             min[[s]])
#>     }
#>     for (s in names(max)) {
#>         v <- stats$value[stats$stat == s]
#>         v <- if (length(v) && any(!is.na(v))) 
#>             max(v, na.rm = TRUE)
#>         else NA_real_
#>         add(paste0("max_", s), v, max[[s]], !is.na(v) && v <= 
#>             max[[s]])
#>     }
#>     con <- context$construct
#>     if (!is.null(min_items)) {
#>         sc <- unique(c(names(con$scales), items$scale))
#>         n <- min(table(factor(items$scale, levels = sc)))
#>         add("min_items", n, min_items, n >= min_items)
#>     }
#>     if (!is.null(min_total)) 
#>         add("min_total", nrow(items), min_total, nrow(items) >= 
#>             min_total)
#>     if (factors) {
#>         v <- stats$value[stats$stat == "n_factors_all"][1]
#>         k <- if (isTRUE(con$single_scale)) 
#>             1L
#>         else length(unique(items$scale))
#>         add("factors", v, k, !is.na(v) && v == k)
#>     }
#>     if (!length(rows)) 
#>         return(NULL)
#>     do.call(rbind, rows)
#> }
#> <bytecode: 0x64eeefb623f0>
#> <environment: 0x64eee3822aa0>
#> attr(,"label")
#> [1] "no failing items; alpha >= 0.7; careless_share <= 0.05; at least 3 items per scale; dimensions match scales"
# one scale: Every domain kept, at least 10 items, one dimension
loop_criterion(min_items = 1, min_total = 10, factors = TRUE)
#> function (flags, stats, items, context) 
#> {
#>     rows <- list()
#>     add <- function(name, value, target, pass) rows[[length(rows) + 
#>         1L]] <<- data.frame(criterion = name, value = value, 
#>         target = target, pass = pass, stringsAsFactors = FALSE)
#>     if (no_failing_items) {
#>         n <- length(unique(flags$item[flags$severity == "fail" & 
#>             !is.na(flags$item)]))
#>         add("no_failing_items", n, 0, n == 0)
#>     }
#>     for (s in names(min)) {
#>         v <- stats$value[stats$stat == s]
#>         v <- if (length(v) && any(!is.na(v))) 
#>             min(v, na.rm = TRUE)
#>         else NA_real_
#>         add(paste0("min_", s), v, min[[s]], !is.na(v) && v >= 
#>             min[[s]])
#>     }
#>     for (s in names(max)) {
#>         v <- stats$value[stats$stat == s]
#>         v <- if (length(v) && any(!is.na(v))) 
#>             max(v, na.rm = TRUE)
#>         else NA_real_
#>         add(paste0("max_", s), v, max[[s]], !is.na(v) && v <= 
#>             max[[s]])
#>     }
#>     con <- context$construct
#>     if (!is.null(min_items)) {
#>         sc <- unique(c(names(con$scales), items$scale))
#>         n <- min(table(factor(items$scale, levels = sc)))
#>         add("min_items", n, min_items, n >= min_items)
#>     }
#>     if (!is.null(min_total)) 
#>         add("min_total", nrow(items), min_total, nrow(items) >= 
#>             min_total)
#>     if (factors) {
#>         v <- stats$value[stats$stat == "n_factors_all"][1]
#>         k <- if (isTRUE(con$single_scale)) 
#>             1L
#>         else length(unique(items$scale))
#>         add("factors", v, k, !is.na(v) && v == k)
#>     }
#>     if (!length(rows)) 
#>         return(NULL)
#>     do.call(rbind, rows)
#> }
#> <bytecode: 0x64eeefb623f0>
#> <environment: 0x64eee37e1da8>
#> attr(,"label")
#> [1] "no failing items; alpha >= 0.8; own_scale >= 0.9; careless_share <= 0.05; at least 1 items per scale; at least 10 items in all; dimensions match scales"
```
