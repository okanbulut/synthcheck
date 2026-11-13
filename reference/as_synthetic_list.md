# Turn a table of synthetic respondents into benchmark input

[`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md),
[`synthetic_behaviour()`](https://www.okanbulut.com/synthcheck/reference/synthetic_behaviour.md)
and
[`synthetic_coverage()`](https://www.okanbulut.com/synthcheck/reference/synthetic_coverage.md)
take a named list with one element per model, each a list of attempts.
`as_synthetic_list()` splits a long table, such as the result of
[`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md)
or
[hexaco_llm](https://www.okanbulut.com/synthcheck/reference/hexaco_llm.md),
into that list.

## Usage

``` r
as_synthetic_list(data, model = "model", attempt = "attempt", items = NULL)
```

## Arguments

- data:

  a data frame with one row per respondent.

- model, attempt:

  the columns that name the model and the attempt.

- items:

  optional item columns to keep. `NULL` keeps all columns.

## Value

A named list of lists of data frames.

## Examples

``` r
ca <- hexaco_llm[hexaco_llm$country == "Canada" & hexaco_llm$attempt <= 2, ]
syn <- as_synthetic_list(ca)
names(syn)
#> [1] "Gemma 4 26B"      "GPT-OSS-120B"     "Qwen 3.8 27B"     "Qwen 3.5 122B"   
#> [5] "Claude Haiku 5.5" "GPT-4.1 mini"    
lengths(syn)
#>      Gemma 4 26B     GPT-OSS-120B     Qwen 3.8 27B    Qwen 3.5 122B 
#>                2                2                2                2 
#> Claude Haiku 5.5     GPT-4.1 mini 
#>                2                2 
```
