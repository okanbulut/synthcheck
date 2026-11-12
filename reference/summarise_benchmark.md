# Describe the benchmark in plain language

**Experimental.** `summarise_benchmark()` writes a few sentences per
model from a result of
[`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md):
The score and its weakest column, how close each anchored column is to
real people, the behaviour features that differ most from real people
and in which direction, and the person fit tails. The text follows fixed
rules, so it is the same every time and states only values in the table.

## Usage

``` r
summarise_benchmark(x, n_features = 2)
```

## Arguments

- x:

  a result of
  [`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md).

- n_features:

  how many behaviour features to name per model.

## Value

A tibble with `model`, `score`, `weakest` and `summary` (the text), in
the order of the benchmark table. Printing it shows the text.

## Details

The anchored values read as follows: 100 is as close as a second sample
of real people, 0 is no better than shuffling the real answers within
each item, and below 0 is worse than that.

Synthetic respondents are experimental: The benchmark compares models
and supports decisions about them. It does not show that synthetic data
can replace a field test.

## See also

[`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md)

## Examples

``` r
h <- hexaco_items[hexaco_items$trait %in% c("H", "C"), ]
real <- hexaco_real[hexaco_real$country == "Canada", ]
ca <- hexaco_llm[hexaco_llm$country == "Canada" & hexaco_llm$attempt <= 2, ]
bm <- authenticity_benchmark(as_synthetic_list(ca), real, h, fit_scales = character(0),
                             n_splits = 5, n_floor = 5)
summarise_benchmark(bm)
#> Synthetic authenticity benchmark in plain language (experimental)
#> 
#> GPT-OSS-120B scores -46 on the benchmark (1st of 6), set by its weakest
#> column, Overlap. Overlap is -46 (worse than shuffled columns);
#> Structure is -20 (worse than shuffled columns); Behaviour is -12 (worse
#> than shuffled columns). Compared with real people, they answer
#> reverse-keyed items more consistently (behaviour overlap 32) and they
#> give fewer extreme answers (behaviour overlap 35).
#> 
#> Qwen 3.8 27B scores -70 on the benchmark (2nd of 6), set by its weakest
#> column, Structure. Overlap is -40 (worse than shuffled columns);
#> Structure is -70 (worse than shuffled columns); Behaviour is 11 (barely
#> better than shuffled columns). Compared with real people, they agree
#> less overall (behaviour overlap 25) and they answer reverse-keyed items
#> more consistently (behaviour overlap 45).
#> 
#> Claude Haiku 5.5 scores -83 on the benchmark (3rd of 6), set by its
#> weakest column, Behaviour. Overlap is -50 (worse than shuffled
#> columns); Structure is 16 (barely better than shuffled columns);
#> Behaviour is -83 (worse than shuffled columns). Compared with real
#> people, they agree less overall (behaviour overlap 14) and their
#> answers vary less across items (behaviour overlap 21).
#> 
#> Qwen 3.5 122B scores -85 on the benchmark (4th of 6), set by its
#> weakest column, Overlap. Overlap is -85 (worse than shuffled columns);
#> Structure is 14 (barely better than shuffled columns); Behaviour is -1
#> (worse than shuffled columns). Compared with real people, they agree
#> less overall (behaviour overlap 14) and their profiles are more unusual
#> (behaviour overlap 50).
#> 
#> GPT-4.1 mini scores -91 on the benchmark (5th of 6), set by its weakest
#> column, Overlap. Overlap is -91 (worse than shuffled columns);
#> Structure is 46 (closer to shuffled columns than to real people);
#> Behaviour is -54 (worse than shuffled columns). Compared with real
#> people, they answer reverse-keyed items more consistently (behaviour
#> overlap 21) and they agree less overall (behaviour overlap 31).
#> 
#> Gemma 4 26B scores -148 on the benchmark (6th of 6), set by its weakest
#> column, Structure. Overlap is -46 (worse than shuffled columns);
#> Structure is -148 (worse than shuffled columns); Behaviour is -45
#> (worse than shuffled columns). Compared with real people, they answer
#> reverse-keyed items more consistently (behaviour overlap 18) and they
#> give fewer extreme answers (behaviour overlap 40).
#> 
#> 100 = as close as a second sample of real people; 0 = no better than shuffled columns.
```
