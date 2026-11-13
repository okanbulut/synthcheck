# Estimate what a run will cost

`estimate_cost()` counts the calls that
[`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md)
would make with the same arguments, guesses their tokens and multiplies
them by the prices in
[sc_prices](https://www.okanbulut.com/synthcheck/reference/sc_prices.md).
`estimate_interview_cost()` does the same for
[`cognitive_interview()`](https://www.okanbulut.com/synthcheck/reference/cognitive_interview.md).
No model is called.

## Usage

``` r
estimate_cost(
  instrument,
  models,
  personas = NULL,
  attempts = 1,
  respondents = 1,
  batch_size = 1,
  block_size = NULL,
  shuffle = FALSE,
  seed = 1,
  cache = sc_cache(),
  prices = sc_prices
)

estimate_interview_cost(
  instrument,
  models,
  personas = NULL,
  items = NULL,
  probes = sc_probes(),
  coder = NULL,
  pretest = NULL,
  interviews = 1,
  seed = 1,
  cache = sc_cache(),
  prices = sc_prices
)
```

## Arguments

- instrument:

  an
  [`sc_instrument()`](https://www.okanbulut.com/synthcheck/reference/sc_instrument.md).

- models:

  one
  [`sc_model()`](https://www.okanbulut.com/synthcheck/reference/sc_model.md)
  or a list of them.

- personas:

  an
  [`sc_personas()`](https://www.okanbulut.com/synthcheck/reference/sc_personas.md)
  table, a character vector of descriptions, or `NULL` for respondents
  without a persona.

- attempts:

  number of attempts per model.

- respondents:

  number of respondents per persona in each attempt.

- batch_size:

  number of respondents per call. The default, 1, keeps every respondent
  independent. A larger batch asks one call for several respondents of
  the same persona: That is cheaper, but the respondents in a batch may
  depend on each other (the model sees its own earlier answers), which
  can make them look more alike or more deliberately different than
  independent people would.

- block_size:

  ask at most this many items per call. A respondent's blocks are asked
  one after another in the same conversation. `NULL` asks all items at
  once.

- shuffle:

  shuffle the item order for each call?

- seed:

  random seed for shuffling and for the mock provider. It is also part
  of the cache key: The same `seed` reuses saved answers, a new one asks
  the models again.

- cache:

  the response cache: An
  [`sc_cache()`](https://www.okanbulut.com/synthcheck/reference/sc_cache.md),
  a folder, `TRUE` (the default folder) or `FALSE` (no cache). By
  default, saved answers are reused, so the same run twice gives the
  same data and the second run costs nothing. Use
  `sc_cache(mode = "refresh")` to ask again.

- prices:

  the price table,
  [sc_prices](https://www.okanbulut.com/synthcheck/reference/sc_prices.md)
  or your own with the same columns.

- items:

  optional item names to interview about. `NULL` uses all items, or only
  the flagged items when `pretest` is given.

- probes:

  the probes, from
  [`sc_probes()`](https://www.okanbulut.com/synthcheck/reference/sc_probes.md).

- coder:

  an
  [`sc_model()`](https://www.okanbulut.com/synthcheck/reference/sc_model.md)
  that codes the transcripts. `NULL` uses each respondent model to code
  its own interviews. The coder's temperature is set to 0 when it takes
  one.

- pretest:

  optional result of
  [`synthetic_pretest()`](https://www.okanbulut.com/synthcheck/reference/synthetic_pretest.md),
  or a data frame with an `item` column and an optional `flag` column
  (the reason, for example `"low item-rest correlation"`), or a vector
  of item names. Flagged items come first and get one extra probe.

- interviews:

  number of interviews per model, persona and item.

## Value

A tibble of class `sc_cost` with one row per model: `model`, `provider`,
`model_id`, `calls`, `cached` (calls answered from the cache),
`input_tokens` and `output_tokens` (of the calls still to make),
`input_price` and `output_price` (dollars per million tokens), `checked`
(the date of the price) and `cost` (dollars, `NA` when the model has no
price). The attribute `total` holds the sum.

## Details

Calls whose answers are in the response cache (see
[`sc_cache()`](https://www.okanbulut.com/synthcheck/reference/sc_cache.md))
are counted as free, since the run will not make them. Ollama and the
mock provider are free too.

It is an estimate. Tokens are guessed from the length of the prompts
(about four characters a token) plus the structured-output schema, and
from the length of typical answers. Retries for invalid answers add to
it. Reasoning models (such as `gpt-5-nano`) also bill their hidden
reasoning as output, which the estimate leaves out. Treat the result as
a guide to the size of the bill, and check the providers' prices for a
large run.

## See also

[sc_prices](https://www.okanbulut.com/synthcheck/reference/sc_prices.md),
[`sc_cache()`](https://www.okanbulut.com/synthcheck/reference/sc_cache.md),
[`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md)

## Examples

``` r
ins <- sc_instrument(hexaco_items, scale = c(1, 7))
per <- sc_persona_grid(age = c(25, 45, 65), template = "You are {age} years old.")
estimate_cost(ins, list(sc_model("anthropic"), sc_model("openai")), per,
              attempts = 5, respondents = 10, cache = FALSE)
#> Estimated cost: $0.23 for 300 calls.
#>  model            calls cached tokens_in tokens_out cost  prices_of 
#>  claude-haiku-5-5 150   0      535,050   144,750    $0.13 2026-11-03
#>  gpt-4.1-nano     150   0      487,050   144,750    $0.11 2026-02-18
#> An estimate: Tokens are guessed from the prompts, and retries add to it.
```
