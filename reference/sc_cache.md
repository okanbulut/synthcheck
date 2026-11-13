# Keep model answers on disk

`sc_cache()` sets up the response cache that
[`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md)
and
[`cognitive_interview()`](https://www.okanbulut.com/synthcheck/reference/cognitive_interview.md)
use. Every answer a model gives is saved in a folder, under a key made
of everything that shapes the answer: The provider, the model id, the
temperature, the address of the API, the system prompt (the persona),
the prompts (the instructions, scale and items, in the order asked), and
which respondent, attempt, interview and retry it is, with the run's
`seed`. When the same call comes again, the saved answer is used instead
of a new call. That makes a run repeatable and costs nothing the second
time.

## Usage

``` r
sc_cache(dir = sc_cache_dir(), mode = c("reuse", "refresh", "off"))
```

## Arguments

- dir:

  the folder of the cache. The default is
  `tools::R_user_dir("synthcheck", "cache")`, or the option
  `synthcheck.cache_dir` when it is set.

- mode:

  `"reuse"` (use saved answers and save new ones), `"refresh"` (always
  ask the model and replace the saved answers) or `"off"` (neither read
  nor write the cache).

## Value

An object of class `sc_cache`.

## Details

Because the respondent, attempt and `seed` are part of the key, the
respondents of one run still get separate calls. Running the same
settings again gives the same data. More attempts or more respondents
add new calls for the new ones only. A new `seed`, `mode = "refresh"` or
a change to any prompt, model or setting asks the model again. Answers
from `provider = "mock"` are never saved, since they cost nothing.

Calls that fail are not saved, so a rerun tries them again. Invalid
answers (out of range or missing items) are saved like any other answer,
and the retry that followed is saved under its own key.

The cache holds answers only: No API keys. It lives in
[`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html) unless you
give another folder. See what it holds with
[`sc_cache_info()`](https://www.okanbulut.com/synthcheck/reference/sc_cache_info.md)
and delete it with
[`sc_cache_clear()`](https://www.okanbulut.com/synthcheck/reference/sc_cache_info.md).

## See also

[`sc_cache_info()`](https://www.okanbulut.com/synthcheck/reference/sc_cache_info.md),
[`sc_cache_clear()`](https://www.okanbulut.com/synthcheck/reference/sc_cache_info.md),
[`estimate_cost()`](https://www.okanbulut.com/synthcheck/reference/estimate_cost.md)

## Examples

``` r
sc_cache()
#> Response cache in /home/runner/.cache/R/synthcheck: reuses saved answers and saves new ones.
sc_cache(tempfile("cache"), mode = "refresh")
#> Response cache in /tmp/RtmpqC5hIl/cache19455416968a: asks the models again and replaces saved answers.
if (FALSE) { # \dontrun{
# needs ANTHROPIC_API_KEY
ins <- sc_instrument(hexaco_items[1:10, ], scale = c(1, 7))
a <- generate_synthetic(ins, sc_model("anthropic"), respondents = 5)
b <- generate_synthetic(ins, sc_model("anthropic"), respondents = 5) # from the cache
identical(a, b)
} # }
```
