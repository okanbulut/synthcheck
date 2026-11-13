# Use an instrument that comes with synthcheck

`sc_builtin_instrument()` returns one of the bundled instruments as an
[`sc_instrument()`](https://www.okanbulut.com/synthcheck/reference/sc_instrument.md),
with its response scale, category labels and instructions, ready for
[`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md),
[`synthetic_pretest()`](https://www.okanbulut.com/synthcheck/reference/synthetic_pretest.md)
or
[`cognitive_interview()`](https://www.okanbulut.com/synthcheck/reference/cognitive_interview.md).
Each one comes with real responses for
[`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md).

## Usage

``` r
sc_builtin_instrument(
  name = c("hexaco", "rses", "dass21", "mini_ipip"),
  scales = NULL
)
```

## Arguments

- name:

  the instrument: `"hexaco"`, `"rses"`, `"dass21"` or `"mini_ipip"`.

- scales:

  optional scale codes to keep, for example `c("H", "C")` for two HEXACO
  traits or `"D"` for DASS-21 Depression. `NULL` keeps all items.

## Value

An object of class `sc_instrument`.

## Details

Besides the long IPIP-HEXACO, three short instruments are included
because their items have well-documented problems. They let you check
whether the pretest, the interviews and the benchmark find what the
literature already knows:

|  |  |  |  |  |  |
|----|----|----|----|----|----|
| `name` | Instrument | Items | Answers | Known problems | Real data |
| `"hexaco"` | IPIP-HEXACO | 240 | 1 to 7 |  | [hexaco_real](https://www.okanbulut.com/synthcheck/reference/hexaco_real.md) |
| `"rses"` | Rosenberg Self-Esteem Scale | 10 | 1 to 4 | Negative-wording method factor | [rses_real](https://www.okanbulut.com/synthcheck/reference/rses.md) |
| `"dass21"` | DASS-21 | 21 | 1 to 4 | Disputed three-factor structure | [dass_real](https://www.okanbulut.com/synthcheck/reference/dass.md) |
| `"mini_ipip"` | Mini-IPIP | 20 | 1 to 5 | Poor fit, weak Intellect scale, reverse-keyed method effect | [mini_ipip_real](https://www.okanbulut.com/synthcheck/reference/mini_ipip.md) |

The `issue` column of the item tables says, in one sentence, what has
been reported about each item; the help pages of the item tables give
the references.

## See also

[rses_items](https://www.okanbulut.com/synthcheck/reference/rses.md),
[dass_items](https://www.okanbulut.com/synthcheck/reference/dass.md),
[mini_ipip_items](https://www.okanbulut.com/synthcheck/reference/mini_ipip.md),
[hexaco_items](https://www.okanbulut.com/synthcheck/reference/hexaco_items.md)

## Examples

``` r
sc_builtin_instrument("rses")
#> Instrument "Rosenberg Self-Esteem Scale": 10 items, answers 1 to 4.
#> Scales: SE 
#>   RSE1: I feel that I am a person of worth, at least on an equal plane with others.
#>   RSE2: I feel that I have a number of good qualities.
#>   RSE3: All in all, I am inclined to feel that I am a failure.
#>   ... and 7 more
dass <- sc_builtin_instrument("dass21", scales = c("A", "S"))
dass$labels
#> [1] "Did not apply to me at all"                                        
#> [2] "Applied to me to some degree, or some of the time"                 
#> [3] "Applied to me to a considerable degree, or a good part of the time"
#> [4] "Applied to me very much, or most of the time"                      
cat(sc_prompt(dass)$user)
#> Please read each statement and choose how much it applied to you over the past week. There are no right or wrong answers. Do not spend too much time on any statement. Answer every statement.
#> 
#> Answer with a whole number from 1 to 4:
#> 1 = Did not apply to me at all
#> 2 = Applied to me to some degree, or some of the time
#> 3 = Applied to me to a considerable degree, or a good part of the time
#> 4 = Applied to me very much, or most of the time
#> 
#> Statements:
#> DASS1: I found it hard to wind down.
#> DASS2: I was aware of dryness of my mouth.
#> DASS4: I experienced breathing difficulty (eg, excessively rapid breathing, breathlessness in the absence of physical exertion).
#> DASS6: I tended to over-react to situations.
#> DASS7: I experienced trembling (eg, in the hands).
#> DASS8: I felt that I was using a lot of nervous energy.
#> DASS9: I was worried about situations in which I might panic and make a fool of myself.
#> DASS11: I found myself getting agitated.
#> DASS12: I found it difficult to relax.
#> DASS14: I was intolerant of anything that kept me from getting on with what I was doing.
#> DASS15: I felt I was close to panic.
#> DASS18: I felt that I was rather touchy.
#> DASS19: I was aware of the action of my heart in the absence of physical exertion (eg, sense of heart rate increase, heart missing a beat).
#> DASS20: I felt scared without any good reason.
#> 
#> Return one answer for every statement, keyed by its name (DASS1, DASS2, ...).
```
