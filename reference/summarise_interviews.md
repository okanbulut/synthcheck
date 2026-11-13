# Summarise cognitive interviews per item

**Experimental.** `summarise_interviews()` rolls the coded interviews of
[`cognitive_interview()`](https://www.okanbulut.com/synthcheck/reference/cognitive_interview.md)
up to one row per item: The share of interviews with a problem at each
stage and at any stage, how many personas and models raised a problem,
the coder's most common notes and the suggested rewordings.

## Usage

``` r
summarise_interviews(x, flag = 0.3, n_notes = 3)
```

## Arguments

- x:

  a result of
  [`cognitive_interview()`](https://www.okanbulut.com/synthcheck/reference/cognitive_interview.md).

- flag:

  the share of interviews with a problem at which an item is flagged.

- n_notes:

  how many notes and rewordings to keep per item.

## Value

A tibble of class `sc_interview_summary`, one row per item, with `item`,
`statement`, `n`, one share per stage, `any`, `major` (share of major
problems), `personas` and `models` (how many raised a problem),
`top_stage`, `flagged`, `pretest`, `agreement`, `notes` and `revisions`.
The attribute `text` holds the paragraph.

## Details

An item is **flagged** when the share of interviews with a problem at
any stage is at least `flag` and, when there are two or more models, at
least two of them raise a problem (one model alone is weaker evidence).
With a pretest, `agreement` says whether the item was flagged by both,
by the pretest only, by the interviews only, or by neither: Items
flagged by both are the first to revise.

Printing the result shows a short paragraph, written by fixed rules,
before the table. These are screening results: They point to items to
look at in human cognitive interviews and a field test.

## See also

[`cognitive_interview()`](https://www.okanbulut.com/synthcheck/reference/cognitive_interview.md),
[`gg_interview()`](https://www.okanbulut.com/synthcheck/reference/gg_interview.md)

## Examples

``` r
items <- data.frame(item = c("q1", "q2"),
                    statement = c("I never don't worry.", "I keep my promises."))
iv <- cognitive_interview(sc_instrument(items), sc_model("mock"),
                          c("You are 20 years old.", "You are 70 years old."),
                          interviews = 3)
#> 12 interviews (1 model x 2 personas x 2 items x 3 interviews): 36 requests.
summarise_interviews(iv)
#> 1 of 2 items is flagged: q1 (100% of interviews, mostly comprehension).
#> These are screening results from language models: Use them to choose
#> items for cognitive interviews with real people and a field test, not
#> to replace them.
#> 
#> # A tibble: 2 × 9
#>   item  comprehension retrieval judgement response sensitivity   any models
#>   <chr>         <dbl>     <dbl>     <dbl>    <dbl>       <dbl> <dbl>  <int>
#> 1 q1                1         0         0        0           0     1      1
#> 2 q2                0         0         0        0           0     0      0
#> # ℹ 1 more variable: flagged <lgl>
```
