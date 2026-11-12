# Build the prompts for one synthetic respondent

**Experimental.** Shows exactly what
[`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md)
sends: The persona as the system prompt, and the instructions, response
scale and items as the user prompt.

## Usage

``` r
sc_prompt(instrument, persona = NULL, items = NULL, n = 1L)
```

## Arguments

- instrument:

  an
  [`sc_instrument()`](https://www.okanbulut.com/synthcheck/reference/sc_instrument.md).

- persona:

  one persona description, or `NULL` for none.

- items:

  optional item names to include (a block of items).

- n:

  number of respondents asked for in one call (see `batch_size` in
  [`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md)).

## Value

A list with `system` and `user`.

## Examples

``` r
ins <- sc_instrument(hexaco_items[1:3, ], scale = c(1, 7))
cat(sc_prompt(ins, "You are a 30-year-old teacher.")$user)
#> Please read each statement and decide how much you agree or disagree with it. There are no right or wrong answers. Answer every statement.
#> 
#> Answer with a whole number from 1 to 7:
#> 1 = Strongly disagree
#> 2 = Disagree
#> 3 = Slightly disagree
#> 4 = Neither agree nor disagree
#> 5 = Slightly agree
#> 6 = Agree
#> 7 = Strongly agree
#> 
#> Statements:
#> HSinc1: I don't pretend to be more than I am.
#> HSinc2: I use flattery to get ahead.
#> HSinc3: I tell other people what they want to hear so that they will do what I want them to do.
#> 
#> Return one answer for every statement, keyed by its name (HSinc1, HSinc2, ...).
```
