# Default model ids

The model each provider uses when
[`sc_model()`](https://www.okanbulut.com/synthcheck/reference/sc_model.md)
gets no `model`: The cheapest current model that takes a temperature
(`claude-haiku-5-5` and `gpt-4.1-nano`). OpenAI's `gpt-5-nano` costs
less per input token but is a reasoning model that takes no temperature.
Google's default is `gemini-4-hydrogen`, a thinking model that takes no
temperature and costs far more than the other two defaults (see
[sc_prices](https://www.okanbulut.com/synthcheck/reference/sc_prices.md)).
Ollama has no default: Use a model installed on your machine
(`ollama list`).

## Usage

``` r
sc_default_models
```

## Format

A named list.

## Examples

``` r
sc_default_models
#> $anthropic
#> [1] "claude-haiku-5-5"
#> 
#> $openai
#> [1] "gpt-4.1-nano"
#> 
#> $google
#> [1] "gemini-4-hydrogen"
#> 
#> $ollama
#> NULL
#> 
#> $mock
#> [1] "mock"
#> 
```
