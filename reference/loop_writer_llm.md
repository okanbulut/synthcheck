# A language-model item writer for the item-revision loop

`loop_writer_llm()` makes the `writer` step of
[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md):
One call asks a language model to write `n_per_scale` Likert items for
every scale of the
[`loop_construct()`](https://www.okanbulut.com/synthcheck/reference/loop_construct.md),
with about `reverse_share` of them reverse-keyed, and to explain its
choices in a short note (logged as `writer_reasoning` in the `runs`
table). Items are named after their scale (`sincerity01`, `sincerity02`,
...).

## Usage

``` r
loop_writer_llm(model, guidelines = lp_guidelines)
```

## Arguments

- model:

  an
  [`sc_model()`](https://www.okanbulut.com/synthcheck/reference/sc_model.md)
  for the item writer. Use a different model family from the respondents
  to avoid items that are only easy for one family to agree with.

- guidelines:

  item-writing guidelines added to the system prompt.

## Value

A function for the `writer` argument of
[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md).

## Details

With `sc_model("mock")`, no model is called: The items are placeholders,
which is enough to try the loop.

## See also

[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md),
[`loop_reviser_llm()`](https://www.okanbulut.com/synthcheck/reference/loop_reviser_llm.md)

## Examples

``` r
w <- loop_writer_llm(sc_model("mock"))
w(loop_construct("Grit", "Perseverance and passion for long-term goals.",
                 n_per_scale = 3), list())$items
#>     item scale reverse
#> 1 Grit01  Grit   FALSE
#> 2 Grit02  Grit   FALSE
#> 3 Grit03  Grit    TRUE
#>                                                                     statement
#> 1            Mock item 1 about Perseverance and passion for long-term goals..
#> 2            Mock item 2 about Perseverance and passion for long-term goals..
#> 3 Mock item 3 about Perseverance and passion for long-term goals. (reversed).
```
