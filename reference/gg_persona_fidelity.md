# Draw the persona check

One panel per model, one row per persona and one tile per scale. The
tile colour is the persona's mean standardized score: Red is lower than
the reference, pale about the same, blue higher. The number is the mean;
when the persona has a target for that scale, the target follows in
brackets. Scales whose scores do not differ between personas more than
shuffled labels do are marked "n.s." under their name.

## Usage

``` r
gg_persona_fidelity(x, title = NULL, subtitle = NULL)
```

## Arguments

- x:

  a result of
  [`persona_fidelity()`](https://www.okanbulut.com/synthcheck/reference/persona_fidelity.md).

- title, subtitle:

  plot titles. `NULL` uses the defaults.

## Value

A ggplot object.

## See also

[`persona_fidelity()`](https://www.okanbulut.com/synthcheck/reference/persona_fidelity.md)

## Examples

``` r
# see persona_fidelity()
```
