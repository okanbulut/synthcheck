# Prices of language models

The prices
[`estimate_cost()`](https://www.okanbulut.com/synthcheck/reference/estimate_cost.md)
and
[`estimate_interview_cost()`](https://www.okanbulut.com/synthcheck/reference/estimate_cost.md)
use, in US dollars per million tokens, from the providers' list prices
on the date in `checked`. Prices change: Check them before a large run,
and pass your own table as `prices` (the same columns; add rows with
[`rbind()`](https://rdrr.io/r/base/cbind.html)). Ollama models run on
your machine and cost nothing. A model that is not in the table gets no
estimate.

## Usage

``` r
sc_prices
```

## Format

A data frame with `provider`, `model` (the model id; dated snapshots
such as `gpt-4.1-nano-2025-04-14` match too), `input` and `output`
(dollars per million tokens), and `checked` (the date of the prices).

## Details

Anthropic's prices are from its price list of 2026-11-03 (Claude Haiku
5.5 costs more for prompts over 100,000 tokens, which synthcheck prompts
are not). OpenAI's are from a published comparison of its list prices of
2026-02-18.

## See also

[`estimate_cost()`](https://www.okanbulut.com/synthcheck/reference/estimate_cost.md)

## Examples

``` r
sc_prices
#>     provider             model input output    checked
#> 1  anthropic  claude-haiku-5-5  0.10    0.5 2026-11-03
#> 2  anthropic  claude-haiku-4-5  1.00    5.0 2026-11-03
#> 3  anthropic claude-sonnet-5-5  2.00   10.0 2026-11-03
#> 4  anthropic   claude-sonnet-5  2.00   10.0 2026-11-03
#> 5  anthropic claude-sonnet-4-6  3.00   15.0 2026-11-03
#> 6  anthropic   claude-opus-5-5  4.00   20.0 2026-11-03
#> 7  anthropic     claude-opus-5  5.00   25.0 2026-11-03
#> 8  anthropic   claude-opus-4-8  5.00   25.0 2026-11-03
#> 9  anthropic  claude-fable-5-2  8.00   40.0 2026-11-03
#> 10    openai      gpt-4.1-nano  0.10    0.4 2026-02-18
#> 11    openai      gpt-4.1-mini  0.40    1.6 2026-02-18
#> 12    openai           gpt-4.1  2.00    8.0 2026-02-18
#> 13    openai       gpt-4o-mini  0.15    0.6 2026-02-18
#> 14    openai            gpt-4o  2.50   10.0 2026-02-18
#> 15    openai        gpt-5-nano  0.05    0.4 2026-02-18
#> 16    openai        gpt-5-mini  0.25    2.0 2026-02-18
#> 17    openai             gpt-5  1.25   10.0 2026-02-18
#> 18    openai           gpt-5.1  1.25   10.0 2026-02-18
#> 19    openai           gpt-5.2  1.75   14.0 2026-02-18
#> 20    openai                o3  2.00    8.0 2026-02-18
#> 21    openai           o4-mini  1.10    4.4 2026-02-18
# a price of your own
my_prices <- rbind(sc_prices, data.frame(provider = "openai", model = "gpt-5.2-mini",
                                         input = 0.3, output = 2.4, checked = "2026-12-01"))
```
