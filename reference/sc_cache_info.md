# See or clear the response cache

`sc_cache_info()` counts the saved answers per provider and model.
`sc_cache_clear()` deletes them, all of them or those of one provider or
model.

## Usage

``` r
sc_cache_info(cache = sc_cache())

sc_cache_clear(cache = sc_cache(), provider = NULL, model = NULL)
```

## Arguments

- cache:

  an
  [`sc_cache()`](https://www.okanbulut.com/synthcheck/reference/sc_cache.md)
  or a folder.

- provider:

  optional provider to clear, for example `"openai"`.

- model:

  optional model id to clear, for example `"gpt-4.1-nano"`.

## Value

`sc_cache_info()`: A tibble with `provider`, `model`, `answers`,
`megabytes`, `oldest` and `newest`. `sc_cache_clear()`: The number of
answers deleted, invisibly.

## See also

[`sc_cache()`](https://www.okanbulut.com/synthcheck/reference/sc_cache.md)

## Examples

``` r
cache <- sc_cache(tempfile("cache"))
sc_cache_info(cache)
#> # A tibble: 0 × 6
#> # ℹ 6 variables: provider <chr>, model <chr>, answers <int>, megabytes <dbl>,
#> #   oldest <dttm>, newest <dttm>
sc_cache_clear(cache)
```
