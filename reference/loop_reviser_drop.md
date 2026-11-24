# A rules-based reviser: Drop failing items

`loop_reviser_drop()` makes a `reviser` for
[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md)
that never rewrites anything: It drops the items with failing flags,
those with the most flags first, as long as each scale keeps `min_items`
items. It is the baseline to compare a language-model reviser with: How
far does deletion alone get?

## Usage

``` r
loop_reviser_drop(min_items = 3, max_drop = Inf, severity = "fail")
```

## Arguments

- min_items:

  smallest number of items a scale keeps.

- max_drop:

  most items to drop per round. `Inf` drops every failing item it can.

- severity:

  which flags count: `"fail"`, or `c("fail", "warn")`.

## Value

A function for the `reviser` argument of
[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md).

## See also

[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md)

## Examples

``` r
# see revision_loop()
```
