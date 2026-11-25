# A language-model reviser for the item-revision loop

`loop_reviser_llm()` makes the `reviser` step of
[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md).
After each round, one call shows a language model the construct, every
item with its flags and main statistics, the parts of the stopping rule
that fail, and the earlier edits with whether they worked. It asks for
edits (reword, rekey, drop, add or keep), each with a rationale and the
names of the checks it responds to, and one note on the round. These are
logged in the `edits` and `rounds` tables, so you can see whether the
revisions follow the evidence.

## Usage

``` r
loop_reviser_llm(
  model,
  actions = c("reword", "rekey", "drop", "add", "keep"),
  min_items = 3,
  max_edits = Inf,
  guidelines = lp_guidelines,
  min_total = NULL
)
```

## Arguments

- model:

  an
  [`sc_model()`](https://www.okanbulut.com/synthcheck/reference/sc_model.md)
  for the reviser.

- actions:

  the actions the reviser may take.

- min_items:

  smallest number of items a scale should keep. The model is told, and a
  drop that would leave a scale with fewer is not applied (the round's
  `reasoning` says so).

- max_edits:

  most edits per round, or `Inf`.

- guidelines:

  item-writing guidelines added to the system prompt.

- min_total:

  smallest number of items in all, or `NULL`, enforced in the same way.

## Value

A function for the `reviser` argument of
[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md).

## Details

With `sc_model("mock")`, no model is called: The reviser rewords up to
`max_edits` failing items by adding a word, which is enough to try the
loop.

## See also

[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md),
[`loop_writer_llm()`](https://www.okanbulut.com/synthcheck/reference/loop_writer_llm.md),
[`loop_reviser_drop()`](https://www.okanbulut.com/synthcheck/reference/loop_reviser_drop.md)

## Examples

``` r
# see revision_loop()
```
