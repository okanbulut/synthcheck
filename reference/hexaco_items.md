# The 240 IPIP-HEXACO items and their keys

The items of
[hexaco_real](https://www.okanbulut.com/synthcheck/reference/hexaco_real.md)
and
[hexaco_llm](https://www.okanbulut.com/synthcheck/reference/hexaco_llm.md)
in their original order, with the trait and facet each one measures and
whether it is reverse-keyed. Each of the six traits has four facets of
10 items; 122 items are reverse-keyed.

## Usage

``` r
hexaco_items
```

## Format

A data frame with 240 rows and 7 columns: `item` (column name in the
response data), `trait` (`H`, `E`, `X`, `A`, `C` or `O`), `trait_label`
(for example `Honesty-Humility`), `facet` and `facet_label` (for example
`HSinc` and `Sincerity`), `statement` (the item text) and `reverse`
(`TRUE` for reverse-keyed items).

## Source

International Personality Item Pool (public domain),
<https://ipip.ori.org>; see Ashton, Lee & Goldberg (2007) in
[hexaco_real](https://www.okanbulut.com/synthcheck/reference/hexaco_real.md).

## See also

[hexaco_real](https://www.okanbulut.com/synthcheck/reference/hexaco_real.md),
[hexaco_llm](https://www.okanbulut.com/synthcheck/reference/hexaco_llm.md).

## Examples

``` r
table(hexaco_items$trait_label, hexaco_items$reverse)
#>                         
#>                          FALSE TRUE
#>   Agreeableness             15   25
#>   Conscientiousness         21   19
#>   Emotionality              25   15
#>   Extraversion              23   17
#>   Honesty-Humility          12   28
#>   Openness to Experience    22   18
head(hexaco_items[, c("item", "facet_label", "statement", "reverse")])
#>     item facet_label
#> 1 HSinc1   Sincerity
#> 2 HSinc2   Sincerity
#> 3 HSinc3   Sincerity
#> 4 HSinc4   Sincerity
#> 5 HSinc5   Sincerity
#> 6 HSinc6   Sincerity
#>                                                                                 statement
#> 1                                                   I don't pretend to be more than I am.
#> 2                                                            I use flattery to get ahead.
#> 3 I tell other people what they want to hear so that they will do what I want them to do.
#> 4                                                      I put on a show to impress people.
#> 5                                              I switch my loyalties when I feel like it.
#> 6                                               I play a role in order to impress people.
#>   reverse
#> 1   FALSE
#> 2    TRUE
#> 3    TRUE
#> 4    TRUE
#> 5    TRUE
#> 6    TRUE
```
