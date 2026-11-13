# Choose a language model for synthetic respondents

`sc_model()` names a model and its settings for
[`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md).
Anthropic, OpenAI and Ollama models are called through the ellmer
package. `provider = "mock"` gives random answers without calling any
model, for trying the workflow and the app.

## Usage

``` r
sc_model(
  provider = c("anthropic", "openai", "ollama", "mock"),
  model = NULL,
  temperature = 1,
  name = NULL,
  base_url = NULL
)
```

## Arguments

- provider:

  `"anthropic"`, `"openai"`, `"ollama"` or `"mock"`.

- model:

  the model id, for example `"claude-haiku-5-5"`. `NULL` uses the
  provider's default (see
  [sc_default_models](https://www.okanbulut.com/synthcheck/reference/sc_default_models.md)).

- temperature:

  sampling temperature, or `NULL` to send none (some models do not take
  one).

- name:

  the label of the model in the data and the benchmark. `NULL` uses the
  model id.

- base_url:

  optional address of the API, for example an Ollama server on another
  machine.

## Value

An object of class `sc_model`.

## Details

API keys are read from the `ANTHROPIC_API_KEY` and `OPENAI_API_KEY`
environment variables (set them in `.Renviron`, or with
[`Sys.setenv()`](https://rdrr.io/r/base/Sys.setenv.html) for one
session). They are never stored in the model specification or in the
saved data. To get a key, see the article [Getting an API
key](https://www.okanbulut.com/synthcheck/articles/api-keys.html).

## See also

[`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md)

## Examples

``` r
sc_model("anthropic", temperature = 1)
#> claude-haiku-5-5 (anthropic, model "claude-haiku-5-5", temperature 1)
sc_model("ollama", "gemma3:27b", name = "Gemma 3 27B")
#> Gemma 3 27B (ollama, model "gemma3:27b", temperature 1)
sc_model("mock")
#> mock (mock, model "mock", temperature 1)
```
