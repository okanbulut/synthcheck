# Define personas for synthetic respondents

A persona describes the person a synthetic respondent plays. It becomes
the system prompt of each call in
[`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md).
`sc_personas()` takes the descriptions directly, and `sc_persona_grid()`
builds them from every combination of a few attributes.

## Usage

``` r
sc_personas(x)

sc_persona_grid(..., template)
```

## Arguments

- x:

  a character vector of descriptions, or a data frame with a
  `description` column (and optionally `persona_id` and attribute
  columns, which are kept in the generated data).

- ...:

  named vectors of attribute values, for example `age = c(25, 45)`.
  Every combination becomes one persona.

- template:

  the description, with each attribute written as `{name}`.

## Value

A tibble of class `sc_personas` with `persona_id`, `description` and any
attribute columns.

## See also

[`sc_instrument()`](https://www.okanbulut.com/synthcheck/reference/sc_instrument.md),
[`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md)

## Examples

``` r
sc_personas(c("You are a 34-year-old nurse in Calgary.",
              "You are a 67-year-old retired farmer in rural Ontario."))
#> # A tibble: 2 × 2
#>   persona_id description                                           
#>   <chr>      <chr>                                                 
#> 1 p001       You are a 34-year-old nurse in Calgary.               
#> 2 p002       You are a 67-year-old retired farmer in rural Ontario.

sc_persona_grid(age = c(25, 45, 65), country = c("Canada", "the United States"),
                template = "You are a {age}-year-old adult living in {country}.")
#> # A tibble: 6 × 4
#>   persona_id description                                             age country
#>   <chr>      <chr>                                                 <dbl> <chr>  
#> 1 p001       You are a 25-year-old adult living in Canada.            25 Canada 
#> 2 p002       You are a 45-year-old adult living in Canada.            45 Canada 
#> 3 p003       You are a 65-year-old adult living in Canada.            65 Canada 
#> 4 p004       You are a 25-year-old adult living in the United Sta…    25 the Un…
#> 5 p005       You are a 45-year-old adult living in the United Sta…    45 the Un…
#> 6 p006       You are a 65-year-old adult living in the United Sta…    65 the Un…
```
