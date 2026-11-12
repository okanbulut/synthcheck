# Generating synthetic respondents in R

**Experimental.** This tutorial makes synthetic respondents from your
own instrument, personas and models, in R code. The
[app](https://www.okanbulut.com/synthcheck/articles/app-tour.md) does
the same steps on screen. Synthetic respondents are for comparing models
with the benchmark, not for replacing a field test.

Everything below runs with the **mock** provider, which gives random
answers without calling an API. Swap in `sc_model("anthropic")`,
`sc_model("openai")` or `sc_model("ollama", ...)` for a real run.

``` r

library(synthcheck)
```

## 1. The instrument

[`sc_instrument()`](https://www.okanbulut.com/synthcheck/reference/sc_instrument.md)
takes an item table (`item`, `statement`, and optionally `scale`,
`facet` and `reverse`) or a plain vector of statements, plus the
response scale:

``` r

ins <- sc_instrument(hexaco_items[hexaco_items$trait == "H", ], scale = c(1, 7),
                     name = "HEXACO Honesty-Humility")
ins
#> Instrument "HEXACO Honesty-Humility": 40 items, answers 1 to 7.
#> Scales: H 
#>   HSinc1: I don't pretend to be more than I am.
#>   HSinc2: I use flattery to get ahead.
#>   HSinc3: I tell other people what they want to hear so that they will do what I want them to do.
#>   ... and 37 more
```

Labels default to agree-disagree labels for 5- and 7-point scales. Give
your own with `labels`, and your own text with `instructions`.

A template item table ships with the package:

``` r

tpl <- system.file("templates", "instrument_template.csv", package = "synthcheck")
read.csv(tpl)
#>   item                         statement             scale       facet reverse
#> 1   E1       I am the life of the party.      Extraversion Sociability   FALSE
#> 2   E2               I don't talk a lot.      Extraversion Sociability    TRUE
#> 3   E3 I feel comfortable around people.      Extraversion     Comfort   FALSE
#> 4   E4         I keep in the background.      Extraversion     Comfort    TRUE
#> 5   C1             I am always prepared. Conscientiousness       Order   FALSE
#> 6   C2     I leave my belongings around. Conscientiousness       Order    TRUE
#> 7   C3       I pay attention to details. Conscientiousness   Diligence   FALSE
#> 8   C4          I make a mess of things. Conscientiousness   Diligence    TRUE
```

## 2. The personas

A persona is the system prompt: Who the synthetic respondent is. Type
them, or build every combination of a few attributes with
[`sc_persona_grid()`](https://www.okanbulut.com/synthcheck/reference/sc_personas.md):

``` r

per <- sc_persona_grid(age = c(25, 45, 65), gender = c("woman", "man"),
                       country = c("Canada", "the United States"),
                       template = "You are a {age}-year-old {gender} living in {country}.")
per
#> # A tibble: 12 × 5
#>    persona_id description                                     age gender country
#>    <chr>      <chr>                                         <dbl> <chr>  <chr>  
#>  1 p001       You are a 25-year-old woman living in Canada.    25 woman  Canada 
#>  2 p002       You are a 45-year-old woman living in Canada.    45 woman  Canada 
#>  3 p003       You are a 65-year-old woman living in Canada.    65 woman  Canada 
#>  4 p004       You are a 25-year-old man living in Canada.      25 man    Canada 
#>  5 p005       You are a 45-year-old man living in Canada.      45 man    Canada 
#>  6 p006       You are a 65-year-old man living in Canada.      65 man    Canada 
#>  7 p007       You are a 25-year-old woman living in the Un…    25 woman  the Un…
#>  8 p008       You are a 45-year-old woman living in the Un…    45 woman  the Un…
#>  9 p009       You are a 65-year-old woman living in the Un…    65 woman  the Un…
#> 10 p010       You are a 25-year-old man living in the Unit…    25 man    the Un…
#> 11 p011       You are a 45-year-old man living in the Unit…    45 man    the Un…
#> 12 p012       You are a 65-year-old man living in the Unit…    65 man    the Un…
```

The attribute columns are kept in the generated data, so you can compare
groups later.
[`sc_personas()`](https://www.okanbulut.com/synthcheck/reference/sc_personas.md)
takes a vector of descriptions or a table with a `description` column
(see
`system.file("templates", "personas_template.csv", package = "synthcheck")`).

## 3. The prompt

[`sc_prompt()`](https://www.okanbulut.com/synthcheck/reference/sc_prompt.md)
shows exactly what is sent for one respondent:

``` r

p <- sc_prompt(ins, per$description[1], items = ins$items$item[1:3])
cat(p$system, "\n\n", p$user, sep = "")
#> You are a 25-year-old woman living in Canada.
#> 
#> You are taking part in a survey. Stay in this role and answer as this person would.
#> 
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

The model answers in structured JSON, one whole number per item. Answers
outside the scale and missing items are retried, then stored as `NA`.

## 4. The models

``` r

sc_default_models
#> $anthropic
#> [1] "claude-haiku-5-5"
#> 
#> $openai
#> [1] "gpt-4.1-nano"
#> 
#> $ollama
#> NULL
#> 
#> $mock
#> [1] "mock"
sc_model("anthropic", temperature = 1)
#> claude-haiku-5-5 (anthropic, model "claude-haiku-5-5", temperature 1)
sc_model("ollama", "gemma3:27b", name = "Gemma 3 27B")
#> Gemma 3 27B (ollama, model "gemma3:27b", temperature 1)
```

The defaults are the cheapest models of each provider that take a
temperature. `temperature = NULL` sends none, for models that do not
take one. API keys come from `ANTHROPIC_API_KEY` and `OPENAI_API_KEY`
(for example in `.Renviron`) and are never written to the saved files.

## 5. Generate

An **attempt** is one full pass over the personas, with `respondents`
respondents per persona. The number of calls is models × attempts ×
personas × respondents.

``` r

models <- list(sc_model("mock", name = "Mock A"), sc_model("mock", name = "Mock B"))
syn <- generate_synthetic(ins, models, per, attempts = 3, respondents = 10,
                          progress = FALSE, seed = 1)
dim(syn)
#> [1] 720  50
syn[1:3, 1:12]
#> # A tibble: 3 × 12
#>   model provider model_id temperature attempt persona_id respondent   age gender
#>   <chr> <chr>    <chr>          <dbl>   <int> <chr>           <int> <dbl> <chr> 
#> 1 Mock… mock     mock               1       1 p001                1    25 woman 
#> 2 Mock… mock     mock               1       1 p001                2    25 woman 
#> 3 Mock… mock     mock               1       1 p001                3    25 woman 
#> # ℹ 3 more variables: country <chr>, HSinc1 <int>, HSinc2 <int>
```

Useful settings for real runs:

- `parallel`: How many calls run at the same time.
- `batch_size`: Respondents per call. The default, 1, keeps every
  respondent independent. Larger batches are cheaper, but respondents in
  one call may depend on each other.
- `block_size`: Items per call, for long instruments.
- `shuffle`: A new item order for every respondent.
- `output`: A folder. Each attempt is written there as soon as it is
  done, with the settings (`run.json`) and every prompt (`prompts.json`)
  beside it, so a stopped run keeps its finished attempts.

``` r

syn <- generate_synthetic(ins, list(sc_model("anthropic"), sc_model("openai")), per,
                          attempts = 5, respondents = 10, parallel = 8,
                          output = "hexaco_run")
```

## 6. Save and read

``` r

f <- tempfile(fileext = ".csv")
write_synthetic(syn, f)
syn2 <- read_synthetic(f)
nrow(syn2)
#> [1] 720
```

[`read_synthetic()`](https://www.okanbulut.com/synthcheck/reference/write_synthetic.md)
also reads a whole output folder back into one table.

## 7. Benchmark

[`as_synthetic_list()`](https://www.okanbulut.com/synthcheck/reference/as_synthetic_list.md)
turns the long table into the list of models and attempts that the
benchmark takes:

``` r

real <- hexaco_real[hexaco_real$country == "Canada", ]
bm <- authenticity_benchmark(as_synthetic_list(syn, items = ins$items$item), real, ins$items,
                             fit_scales = character(0), n_splits = 5, n_floor = 5)
bm
#> Synthetic authenticity benchmark (experimental)
#> 40 items, 1708 real respondents. Score: weakest.
#> 
#>   model attempts Overlap Structure Behaviour Score   Weakest
#>  Mock B        3       2         1        -3    -3 Behaviour
#>  Mock A        3      -9        -1         8    -9   Overlap
#> 
#> Anchors (raw, floor to ceiling, samples of 120): Overlap 51.5 to 85.0, Structure 79.0 to 89.5, Behaviour 66.4 to 85.1.
#> 0 = shuffled real columns, 100 = a second sample of real people.
summarise_benchmark(bm)
#> Synthetic authenticity benchmark in plain language (experimental)
#> 
#> Mock B scores -3 on the benchmark (1st of 2), set by its weakest
#> column, Behaviour. Overlap is 2 (barely better than shuffled columns);
#> Structure is 1 (barely better than shuffled columns); Behaviour is -3
#> (worse than shuffled columns). Compared with real people, they give
#> more extreme answers (behaviour overlap 50) and their answers vary more
#> across items (behaviour overlap 54).
#> 
#> Mock A scores -9 on the benchmark (2nd of 2), set by its weakest
#> column, Overlap. Overlap is -9 (worse than shuffled columns); Structure
#> is -1 (worse than shuffled columns); Behaviour is 8 (barely better than
#> shuffled columns). Compared with real people, they give more extreme
#> answers (behaviour overlap 49) and their answers vary more across items
#> (behaviour overlap 53).
#> 
#> 100 = as close as a second sample of real people; 0 = no better than shuffled columns.
```

Random answers score close to 0 on every column, as they should: 0 is
what shuffled real answers score. Real language models are not
guaranteed to do better. On HEXACO, the six models in `hexaco_llm` often
fall below 0 because their respondents bunch together; see [the
benchmark](https://www.okanbulut.com/synthcheck/articles/benchmark.md).
