# Short instruments with known item problems

The IPIP-HEXACO that ships with synthcheck is long and mostly well
behaved. That makes it a good benchmark, but a poor test of whether the
pretest and the cognitive interviews find bad items. For that, you want
items whose problems are already known. synthcheck includes three short
instruments of that kind, each with real responses:

| [`sc_builtin_instrument()`](https://www.okanbulut.com/synthcheck/reference/sc_builtin_instrument.md) | Instrument | Items | Answers | Known problems | Real data |
|----|----|----|----|----|----|
| `"rses"` | Rosenberg Self-Esteem Scale | 10 | 1 to 4 | Negative-wording method factor, weak item 8 | `rses_real` (47,974) |
| `"dass21"` | DASS-21 | 21 | 1 to 4 | Disputed three-factor structure, weak somatic items | `dass_real` (39,775) |
| `"mini_ipip"` | Mini-IPIP | 20 | 1 to 5 | Poor fit, weak Intellect scale, reverse-keyed method effect | `mini_ipip_real` (20,000) |

The real responses come from the Open-Source Psychometrics Project. The
help pages
([`?rses`](https://www.okanbulut.com/synthcheck/reference/rses.md),
[`?dass`](https://www.okanbulut.com/synthcheck/reference/dass.md) and
[`?mini_ipip`](https://www.okanbulut.com/synthcheck/reference/mini_ipip.md))
give the sources and the references for each problem.

The question these instruments let you ask is simple: Do language models
reproduce the known problems, hide them, or invent new ones? Language
models answer more tidily than people do (see the [benchmark
article](https://www.okanbulut.com/synthcheck/articles/benchmark.md)),
so a model that keeps the negatively worded RSES items perfectly in line
with the positive ones looks consistent but is less like people.

## The items and what is known about them

Each item table has an `issue` column with a one-line note on what has
been reported:

``` r

library(synthcheck)

rses_items[, c("item", "reverse", "statement")]
#>     item reverse
#> 1   RSE1   FALSE
#> 2   RSE2   FALSE
#> 3   RSE3    TRUE
#> 4   RSE4   FALSE
#> 5   RSE5    TRUE
#> 6   RSE6   FALSE
#> 7   RSE7   FALSE
#> 8   RSE8    TRUE
#> 9   RSE9    TRUE
#> 10 RSE10    TRUE
#>                                                                      statement
#> 1  I feel that I am a person of worth, at least on an equal plane with others.
#> 2                               I feel that I have a number of good qualities.
#> 3                       All in all, I am inclined to feel that I am a failure.
#> 4                         I am able to do things as well as most other people.
#> 5                                    I feel I do not have much to be proud of.
#> 6                                    I take a positive attitude toward myself.
#> 7                                    On the whole, I am satisfied with myself.
#> 8                                 I wish I could have more respect for myself.
#> 9                                           I certainly feel useless at times.
#> 10                                       At times I think I am no good at all.
rses_items$issue[8]
#> [1] "Negatively worded, and often the weakest item: A wish for more self-respect can be read as ambition rather than low self-esteem."
```

[`sc_builtin_instrument()`](https://www.okanbulut.com/synthcheck/reference/sc_builtin_instrument.md)
turns any of them into an instrument, with the response scale, the
category labels and the instructions of the original:

``` r

dass <- sc_builtin_instrument("dass21")
dass
#> Instrument "DASS-21": 21 items, answers 1 to 4.
#> Scales: S, A, D 
#>   DASS1: I found it hard to wind down.
#>   DASS2: I was aware of dryness of my mouth.
#>   DASS3: I couldn't seem to experience any positive feeling at all.
#>   ... and 18 more
dass$labels
#> [1] "Did not apply to me at all"                                        
#> [2] "Applied to me to some degree, or some of the time"                 
#> [3] "Applied to me to a considerable degree, or a good part of the time"
#> [4] "Applied to me very much, or most of the time"
```

## What the real data show

Before you generate anything, look at the real people. The pretest runs
on any data set, so it can describe the real respondents too. One
condition, with every respondent pooled:

``` r

real_pt <- synthetic_pretest(rses_real, rses_items, by = character(0), irt = FALSE)
items <- real_pt$items
items[order(items$item_rest), c("item", "item_rest", "alpha_drop", "flags")][1:4, ]
#> # A tibble: 4 × 4
#>   item  item_rest alpha_drop flags
#>   <chr>     <dbl>      <dbl> <chr>
#> 1 RSE8      0.543      0.913 ""   
#> 2 RSE4      0.586      0.910 ""   
#> 3 RSE2      0.665      0.907 ""   
#> 4 RSE5      0.693      0.905 ""
```

Item 8 has the lowest item-rest correlation of the ten. In real people
the problem is relative: No item falls below the pretest’s thresholds,
so look at the ranking, not only the flags. The DASS-21 shows its weak
somatic item the same way:

``` r

dass_pt <- synthetic_pretest(dass_real, dass_items, by = character(0), irt = FALSE)
d <- dass_pt$items
d[order(d$item_rest), c("item", "scale", "item_rest")][1:3, ]
#> # A tibble: 3 × 3
#>   item   scale item_rest
#>   <chr>  <chr>     <dbl>
#> 1 DASS2  A         0.456
#> 2 DASS18 S         0.531
#> 3 DASS14 S         0.584
dass_items$statement[dass_items$item == "DASS2"]
#> [1] "I was aware of dryness of my mouth."
```

## Generate and compare

Generate synthetic respondents for an instrument as for any other (see
[Generating synthetic respondents in
R](https://www.okanbulut.com/synthcheck/articles/generate.md)):

``` r

ins <- sc_builtin_instrument("rses")
models <- list(sc_model("anthropic", temperature = 1),
               sc_model("openai", temperature = 1))
syn <- generate_synthetic(ins, models, attempts = 3, respondents = 200, output = "rses_run")
```

Then ask the two questions:

- **Without the real data:** Does the pretest flag item 8, and do the
  models agree (`synthetic_pretest(syn, rses_items)`)? Do the cognitive
  interviews find the ambiguity in “I wish I could have more respect for
  myself”
  (`cognitive_interview(ins, models, personas, items = "RSE8")`)?
- **With the real data:** How close do the models come to real people
  (`authenticity_benchmark(as_synthetic_list(syn), rses_real, rses_items)`)?

In the app, choose the instrument in the first tab. On the path with
real data, the Compare tab’s built-in real data follow that instrument,
with a country filter.

## Notes on the data

- All answers are stored as given. Reverse-keyed items are not reversed:
  Use `5 - x` for the RSES and `6 - x` for the Mini-IPIP. The DASS has
  no reverse-keyed items. Its official scoring is 0 to 3, so subtract 1.
- Over half of the DASS respondents connected from Malaysia. Use
  `country` when the population matters.
- The Mini-IPIP answers were given among the 50 IPIP Big-Five markers,
  not as a stand-alone 20-item form. `mini_ipip_real` is a random sample
  of 20,000 complete answers from the 1,015,342 in the source file.
- The Open-Source Psychometrics Project gives no formal licence for its
  data. The items are public domain (DASS, IPIP) or free to use (RSES).
