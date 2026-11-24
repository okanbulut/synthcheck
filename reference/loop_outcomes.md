# Outcomes of item-revision loops

`loop_outcomes()` turns the log of one or more runs into one row per run
with the outcomes of an experiment on the loop: How many rounds it took,
what the reviser did, whether its edits followed the evidence and
worked, how far the wording drifted, and what it cost.

## Usage

``` r
loop_outcomes(x)
```

## Arguments

- x:

  a result of
  [`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md)
  or
  [`read_loop()`](https://www.okanbulut.com/synthcheck/reference/read_loop.md).

## Value

A tibble with one row per run.

## Details

- `rounds_to_polish`: The round in which the stopping rule passed, `NA`
  if it never did.

- `cites_flagged`: Share of edits whose cited checks were flagged on the
  item (does the reasoning match the evidence?).

- `resolved`: Share of rewords and rekeys whose cited checks were gone
  in the next round (did the fix work?).

- `relapsed`: Share of resolved edits whose check came back on the same
  item in a later round (oscillation).

- `similarity`: Mean word overlap (Jaccard) between the first and the
  final wording of the items that survived, 1 for no change (drift).

- `cost`: Estimated cost of the respondents plus the reported cost of
  the writer and reviser, in dollars.

## See also

[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md),
[`read_loop()`](https://www.okanbulut.com/synthcheck/reference/read_loop.md)

## Examples

``` r
# see read_loop()
```
