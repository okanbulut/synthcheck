# Define an instrument for synthetic respondents

**Experimental.** `sc_instrument()` describes the survey that synthetic
respondents take: The items, the response scale and the instructions.
[`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md)
turns it into a prompt, and the item table works as `items` in
[`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md).

## Usage

``` r
sc_instrument(
  items,
  scale = c(1, 5),
  labels = NULL,
  instructions = sc_default_instructions,
  name = "Instrument"
)
```

## Arguments

- items:

  a data frame with an `item` column (short names such as `"H1"`) and a
  `statement` column (the item text), plus optional `scale` (or
  `trait`), `facet` and `reverse` columns, as in
  [hexaco_items](https://www.okanbulut.com/synthcheck/reference/hexaco_items.md).
  A character vector of statements also works; the items are then named
  `i1`, `i2`, and so on.

- scale:

  the lowest and highest response categories, for example `c(1, 5)`.

- labels:

  optional labels for the categories, one per category from lowest to
  highest. `NULL` uses agree-disagree labels for 5- and 7-point scales
  and labels the endpoints only otherwise.

- instructions:

  the instructions shown before the items.

- name:

  a short name for the instrument.

## Value

An object of class `sc_instrument`.

## See also

[`sc_personas()`](https://www.okanbulut.com/synthcheck/reference/sc_personas.md),
[`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md)

## Examples

``` r
hexaco <- sc_instrument(hexaco_items, scale = c(1, 7), name = "IPIP-HEXACO")
hexaco
#> Instrument "IPIP-HEXACO": 240 items, answers 1 to 7.
#> Scales: H, E, X, A, C, O 
#>   HSinc1: I don't pretend to be more than I am.
#>   HSinc2: I use flattery to get ahead.
#>   HSinc3: I tell other people what they want to hear so that they will do what I want them to do.
#>   ... and 237 more

short <- sc_instrument(c("I am the life of the party.", "I sympathize with others."),
                       scale = c(1, 5))
short$items
#> # A tibble: 2 × 2
#>   item  statement                  
#>   <chr> <chr>                      
#> 1 i1    I am the life of the party.
#> 2 i2    I sympathize with others.  
```
