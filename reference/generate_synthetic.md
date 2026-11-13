# Generate synthetic respondents with language models

`generate_synthetic()` asks one or more language models to take an
instrument as each persona and returns one row per synthetic respondent.
Each call makes one respondent: The persona is the system prompt, and
the instructions, the response scale and the items are the user prompt
(see
[`sc_prompt()`](https://www.okanbulut.com/synthcheck/reference/sc_prompt.md)).
The model answers in structured JSON, one whole number per item.

## Usage

``` r
generate_synthetic(
  instrument,
  models,
  personas = NULL,
  attempts = 1,
  respondents = 1,
  batch_size = 1,
  block_size = NULL,
  shuffle = FALSE,
  max_retries = 2,
  parallel = 1,
  output = NULL,
  format = c("csv", "json", "rds", "xlsx"),
  progress = interactive(),
  progress_file = NULL,
  stop_file = NULL,
  seed = 1
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

- max_retries:

  how often to retry a call that fails or gives invalid answers.

- parallel:

  number of calls to run at the same time.

- output:

  optional folder to write the data to.

- format:

  file format for `output`: `"csv"`, `"json"`, `"rds"` or `"xlsx"`
  (needs writexl).

- progress:

  show a progress bar with the time left in the console? A function also
  works: It is called after every respondent with a list (`done`,
  `total`, `failed`, `elapsed`, `eta` in seconds, and so on).

- progress_file:

  optional path of a JSON file updated after every respondent (used by
  [`run_synthcheck_app()`](https://www.okanbulut.com/synthcheck/reference/run_synthcheck_app.md)).

- stop_file:

  optional path: When this file appears, the run stops after the calls
  in progress and returns what is done.

- seed:

  random seed for shuffling and for the mock provider.

## Value

A tibble with `model`, `provider`, `model_id`, `temperature`, `attempt`,
`persona_id`, `respondent`, any persona attributes, and one column per
item. The attribute `log` holds the failed calls.

## Details

An **attempt** is one full pass over the personas, with `respondents`
respondents per persona, as in
[hexaco_llm](https://www.okanbulut.com/synthcheck/reference/hexaco_llm.md).
The number of calls is the number of models times `attempts` times the
number of personas times `respondents`. Answers outside the scale,
missing items and failed calls are retried up to `max_retries` times and
then stored as `NA`.

With `output`, each attempt is written to its own file as soon as it is
done, with `run.json` (the settings, without API keys) and
`prompts.json` (every prompt sent) beside it, so a stopped run keeps the
finished attempts. Read the folder back with
[`read_synthetic()`](https://www.okanbulut.com/synthcheck/reference/write_synthetic.md).

Use them to compare models with
[`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md),
not to replace a field test.

## See also

[`sc_instrument()`](https://www.okanbulut.com/synthcheck/reference/sc_instrument.md),
[`sc_personas()`](https://www.okanbulut.com/synthcheck/reference/sc_personas.md),
[`sc_model()`](https://www.okanbulut.com/synthcheck/reference/sc_model.md),
[`as_synthetic_list()`](https://www.okanbulut.com/synthcheck/reference/as_synthetic_list.md),
[`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md)

## Examples

``` r
ins <- sc_instrument(hexaco_items[hexaco_items$trait == "H", ], scale = c(1, 7))
per <- sc_persona_grid(age = c(25, 65), template = "You are {age} years old.")
syn <- generate_synthetic(ins, sc_model("mock"), per, attempts = 2, respondents = 3)
syn
#> # A tibble: 12 × 48
#>    model provider model_id temperature attempt persona_id respondent   age
#>    <chr> <chr>    <chr>          <dbl>   <int> <chr>           <int> <dbl>
#>  1 mock  mock     mock               1       1 p001                1    25
#>  2 mock  mock     mock               1       1 p001                2    25
#>  3 mock  mock     mock               1       1 p001                3    25
#>  4 mock  mock     mock               1       1 p002                1    65
#>  5 mock  mock     mock               1       1 p002                2    65
#>  6 mock  mock     mock               1       1 p002                3    65
#>  7 mock  mock     mock               1       2 p001                1    25
#>  8 mock  mock     mock               1       2 p001                2    25
#>  9 mock  mock     mock               1       2 p001                3    25
#> 10 mock  mock     mock               1       2 p002                1    65
#> 11 mock  mock     mock               1       2 p002                2    65
#> 12 mock  mock     mock               1       2 p002                3    65
#> # ℹ 40 more variables: HSinc1 <int>, HSinc2 <int>, HSinc3 <int>, HSinc4 <int>,
#> #   HSinc5 <int>, HSinc6 <int>, HSinc7 <int>, HSinc8 <int>, HSinc9 <int>,
#> #   HSinc10 <int>, HFair1 <int>, HFair2 <int>, HFair3 <int>, HFair4 <int>,
#> #   HFair5 <int>, HFair6 <int>, HFair7 <int>, HFair8 <int>, HFair9 <int>,
#> #   HFair10 <int>, HGree1 <int>, HGree2 <int>, HGree3 <int>, HGree4 <int>,
#> #   HGree5 <int>, HGree6 <int>, HGree7 <int>, HGree8 <int>, HGree9 <int>,
#> #   HGree10 <int>, HMode1 <int>, HMode2 <int>, HMode3 <int>, HMode4 <int>, …
if (FALSE) { # \dontrun{
# needs ANTHROPIC_API_KEY and OPENAI_API_KEY
syn <- generate_synthetic(ins, list(sc_model("anthropic"), sc_model("openai")), per,
                          attempts = 5, respondents = 10, parallel = 8,
                          output = "hexaco_run")
} # }
```
