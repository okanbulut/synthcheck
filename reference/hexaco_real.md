# HEXACO responses of real people, for checking synthetic respondents

Answers of 17,874 adults from Canada, Great Britain and the United
States to the 240 items of the IPIP-HEXACO, a public-domain measure of
the six HEXACO personality traits (Ashton, Lee & Goldberg, 2007). The
respondents were volunteers who took the inventory online through the
Open-Source Psychometrics Project, which posted the data in 2014. They
are the real comparison sample for the language model responses in
[hexaco_llm](https://www.okanbulut.com/synthcheck/reference/hexaco_llm.md).

## Usage

``` r
hexaco_real
```

## Format

A data frame with 17,874 rows (one per respondent) and 241 columns:
`country` (factor: `Canada` (1,708), `Great Britain` (1,149) or
`United States` (15,017)) and the 240 items, named as in
`hexaco_items$item` (for example `HSinc1`, the first Sincerity item).

## Source

Open-Source Psychometrics Project,
<http://openpsychometrics.org/_rawdata/> (HEXACO data, 2014; 22,786
respondents from all countries). The script is `data-raw/hexaco.R` in
the package's GitHub repository.

## Details

Answers are on a 7-point scale (1 = strongly disagree, 2 = disagree, 3 =
slightly disagree, 4 = neutral, 5 = slightly agree, 6 = agree, 7 =
strongly agree) and are stored as given: Reverse-keyed items are **not**
reversed. Use `hexaco_items$reverse` and `8 - x` before scoring. The 117
answers outside 1 to 7 in the original file (coded 0) are `NA`.

## References

Ashton, M. C., Lee, K., & Goldberg, L. R. (2007). The IPIP-HEXACO
scales: An alternative, public-domain measure of the personality
constructs in the HEXACO model. *Personality and Individual Differences,
42*(8), 1515-1526.
[doi:10.1016/j.paid.2006.10.027](https://doi.org/10.1016/j.paid.2006.10.027)

## See also

[hexaco_llm](https://www.okanbulut.com/synthcheck/reference/hexaco_llm.md)
for the language model answers to the same items,
[hexaco_items](https://www.okanbulut.com/synthcheck/reference/hexaco_items.md)
for the items and their keys,
[`synthetic_coverage()`](https://www.okanbulut.com/synthcheck/reference/synthetic_coverage.md)
and
[`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md).

## Examples

``` r
table(hexaco_real$country)
#> 
#>        Canada Great Britain United States 
#>          1708          1149         15017 
# Honesty-Humility scores, with reverse-keyed items reversed
h <- hexaco_items$item[hexaco_items$trait == "H"]
x <- hexaco_real[h]
rev <- intersect(h, hexaco_items$item[hexaco_items$reverse])
x[rev] <- 8 - x[rev]
tapply(rowMeans(x, na.rm = TRUE), hexaco_real$country, mean)
#>        Canada Great Britain United States 
#>      4.456342      4.357440      4.443543 
```
