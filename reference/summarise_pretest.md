# Describe the pretest in plain language

`summarise_pretest()` writes a few sentences from a result of
[`synthetic_pretest()`](https://www.okanbulut.com/synthcheck/reference/synthetic_pretest.md):
Which items are flagged by most conditions and why, how well the
conditions agree, whether the designed structure comes back, and whether
the scales look too tidy. The text follows fixed rules, so it is the
same every time and states only values in the result. It always starts
with the reminder that this is pilot screening, not validation.

## Usage

``` r
summarise_pretest(x, n_items = 5)
```

## Arguments

- x:

  a result of
  [`synthetic_pretest()`](https://www.okanbulut.com/synthcheck/reference/synthetic_pretest.md).

- n_items:

  how many items to name.

## Value

A tibble with `topic` and `text`. Printing it shows the text.

## See also

[`synthetic_pretest()`](https://www.okanbulut.com/synthcheck/reference/synthetic_pretest.md)

## Examples

``` r
# see synthetic_pretest()
```
