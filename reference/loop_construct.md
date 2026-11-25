# Describe the construct for an item-revision loop

`loop_construct()` holds what an item writer needs to know about the
scale being built: The construct, its subscales, how many items to write
and the response scale.
[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md)
passes it to the item writer and the reviser, and uses `scale`, `labels`
and `instructions` to build the
[`sc_instrument()`](https://www.okanbulut.com/synthcheck/reference/sc_instrument.md)
that synthetic respondents answer.

## Usage

``` r
loop_construct(
  name,
  definition = NULL,
  scales = NULL,
  n_per_scale = 6,
  reverse_share = 1/3,
  population = NULL,
  scale = c(1, 5),
  labels = NULL,
  instructions = sc_default_instructions,
  notes = NULL,
  criterion = NULL,
  single_scale = FALSE
)
```

## Arguments

- name:

  a short name for the construct, for example `"Honesty-Humility"`.

- definition:

  the definition of the construct, in a sentence or two.

- scales:

  optional subscales: A named character vector, with the short names
  (used as `scale` in the item table) as names and their definitions as
  values. `NULL` makes one scale named after `name`.

- n_per_scale:

  number of items to write for each scale.

- reverse_share:

  share of reverse-keyed items to aim for.

- population:

  who will answer the items, for example `"adults in Canada"`.

- scale, labels, instructions:

  the response scale, its labels and the instructions, as in
  [`sc_instrument()`](https://www.okanbulut.com/synthcheck/reference/sc_instrument.md).

- notes:

  optional further guidance for the item writer and reviser, such as a
  style guide or a reading level.

- criterion:

  optional stopping rule, a
  [`loop_criterion()`](https://www.okanbulut.com/synthcheck/reference/loop_criterion.md),
  that
  [`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md)
  uses for this construct unless it is given another.

- single_scale:

  are the `scales` content domains of one scale? With `TRUE`, the items
  are written and revised domain by domain (and each item keeps its
  domain in `scale`), but the checks of
  [`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md)
  treat all items as one scale: One IRT model, one alpha and one
  dimension. Use
  [`loop_criterion()`](https://www.okanbulut.com/synthcheck/reference/loop_criterion.md)
  with `min_items` and `min_total` to require that every domain stays in
  the scale.

## Value

An object of class `sc_construct_spec`.

## See also

[`revision_loop()`](https://www.okanbulut.com/synthcheck/reference/revision_loop.md),
[`loop_builtin_construct()`](https://www.okanbulut.com/synthcheck/reference/loop_builtin_construct.md)

## Examples

``` r
loop_construct("Honesty-Humility",
               "Sincerity, fairness, greed avoidance and modesty.",
               scales = c(sincerity = "Not manipulating others for personal gain.",
                          fairness = "Not cheating or stealing."),
               n_per_scale = 4, scale = c(1, 5))
#> Construct "Honesty-Humility": 2 scales, 4 items each, answers 1 to 5.
#> Sincerity, fairness, greed avoidance and modesty. 
#>   sincerity: Not manipulating others for personal gain.
#>   fairness: Not cheating or stealing.
```
