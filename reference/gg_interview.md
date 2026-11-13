# Plot cognitive interview problems per item

**Experimental.** `gg_interview()` draws one heatmap of items (rows) by
stage (columns), coloured by the share of interviews in which the coder
found a problem: Pale is none, red is most. Flagged items (see
[`summarise_interviews()`](https://www.okanbulut.com/synthcheck/reference/summarise_interviews.md))
are marked with an asterisk after their name, and the items are sorted
with the most problems at the top.

## Usage

``` r
gg_interview(x, flag = 0.3, max_items = 40)
```

## Arguments

- x:

  a result of
  [`cognitive_interview()`](https://www.okanbulut.com/synthcheck/reference/cognitive_interview.md)
  or
  [`summarise_interviews()`](https://www.okanbulut.com/synthcheck/reference/summarise_interviews.md).

- flag:

  passed to
  [`summarise_interviews()`](https://www.okanbulut.com/synthcheck/reference/summarise_interviews.md)
  when `x` is not yet a summary.

- max_items:

  show at most this many items (those with the most problems).

## Value

A ggplot.

## See also

[`cognitive_interview()`](https://www.okanbulut.com/synthcheck/reference/cognitive_interview.md),
[`summarise_interviews()`](https://www.okanbulut.com/synthcheck/reference/summarise_interviews.md)

## Examples

``` r
items <- data.frame(item = c("q1", "q2", "q3"),
                    statement = c("I never don't worry.", "I keep my promises.",
                                  "I like parties and quiet evenings."))
iv <- cognitive_interview(sc_instrument(items), sc_model("mock"),
                          c("You are 20 years old.", "You are 70 years old."),
                          interviews = 3)
#> 18 interviews (1 model x 2 personas x 3 items x 3 interviews): 54 requests.
gg_interview(iv)
```
