# Rosenberg Self-Esteem Scale: Items and real responses

The ten items of the Rosenberg Self-Esteem Scale (RSES; Rosenberg, 1965)
and the answers of 47,974 people who took it online through the
Open-Source Psychometrics Project. The RSES is short and widely used,
and its items have well-documented problems, so it is a test case for
the pretest, the cognitive interviews and the benchmark (see
[`sc_builtin_instrument()`](https://www.okanbulut.com/synthcheck/reference/sc_builtin_instrument.md)).

## Usage

``` r
rses_items

rses_real
```

## Format

`rses_items`: A data frame with 10 rows and 6 columns: `item` (`RSE1` to
`RSE10`), `scale` (`SE`), `scale_label` (`Self-esteem`), `statement`,
`reverse` (`TRUE` for the five negatively worded items) and `issue` (the
reported problem, or `NA`).

`rses_real`: A data frame with 47,974 rows and 13 columns: `country`
(two-letter code from the respondent's network address, or `NA`; the
largest groups are `US` (22,451), `GB` (6,672) and `CA` (2,941)),
`gender` (factor: `Male`, `Female` or `Other`), `age` (13 to 99, other
entries `NA`) and the ten items.

An object of class `data.frame` with 10 rows and 6 columns.

An object of class `data.frame` with 47974 rows and 13 columns.

## Source

Open-Source Psychometrics Project,
<https://openpsychometrics.org/_rawdata/> (RSE data; only respondents
who confirmed that their answers were accurate and could be used for
research). The project gives no formal licence for the data. The items
are free to use; the script is `data-raw/instruments.R` in the package's
GitHub repository.

## Details

**Known problems.** The five negatively worded items (3, 5, 8, 9 and 10)
share variance beyond self-esteem: A one-factor model fits poorly, and a
second factor or a method factor for negative wording is needed (Marsh,
1996; Tomás & Oliver, 1999; DiStefano & Motl, 2006). How the negative
items behave also differs across cultures (Schmitt & Allik, 2005). Item
8 ("I wish I could have more respect for myself") is often the weakest
item. In `rses_real` it has the lowest corrected item-total correlation
(0.54; the others are 0.59 to 0.75). The `issue` column of `rses_items`
gives a one-line note per item.

Answers are on a 4-point scale (1 = strongly disagree, 2 = disagree, 3 =
agree, 4 = strongly agree) and are stored as given: Reverse-keyed items
are **not** reversed. Use `rses_items$reverse` and `5 - x` before
scoring. Unanswered items (coded 0 in the original file) are `NA`.

## References

DiStefano, C., & Motl, R. W. (2006). Further investigating method
effects associated with negatively worded items on self-report surveys.
*Structural Equation Modeling, 13*(3), 440-464.
[doi:10.1207/s15328007sem1303_6](https://doi.org/10.1207/s15328007sem1303_6)

Marsh, H. W. (1996). Positive and negative global self-esteem: A
substantively meaningful distinction or artifactors? *Journal of
Personality and Social Psychology, 70*(4), 810-819.
[doi:10.1037/0022-3514.70.4.810](https://doi.org/10.1037/0022-3514.70.4.810)

Rosenberg, M. (1965). *Society and the adolescent self-image*. Princeton
University Press.

Schmitt, D. P., & Allik, J. (2005). Simultaneous administration of the
Rosenberg Self-Esteem Scale in 53 nations. *Journal of Personality and
Social Psychology, 89*(4), 623-642.
[doi:10.1037/0022-3514.89.4.623](https://doi.org/10.1037/0022-3514.89.4.623)

Tomás, J. M., & Oliver, A. (1999). Rosenberg's self-esteem scale: Two
factors or method effects. *Structural Equation Modeling, 6*(1), 84-98.
[doi:10.1080/10705519909540120](https://doi.org/10.1080/10705519909540120)

## See also

[`sc_builtin_instrument()`](https://www.okanbulut.com/synthcheck/reference/sc_builtin_instrument.md),
[dass_items](https://www.okanbulut.com/synthcheck/reference/dass.md),
[mini_ipip_items](https://www.okanbulut.com/synthcheck/reference/mini_ipip.md)

## Examples

``` r
rses_items[, c("item", "reverse", "statement")]
#>     item reverse
#> 1   RSE1   FALSE
#> 2   RSE2   FALSE
#> 3   RSE3    TRUE
#> 4   RSE4   FALSE
#> 5   RSE5    TRUE
#> 6   RSE6   FALSE
#> 7   RSE7   FALSE
#> 8   RSE8    TRUE
#> 9   RSE9    TRUE
#> 10 RSE10    TRUE
#>                                                                      statement
#> 1  I feel that I am a person of worth, at least on an equal plane with others.
#> 2                               I feel that I have a number of good qualities.
#> 3                       All in all, I am inclined to feel that I am a failure.
#> 4                         I am able to do things as well as most other people.
#> 5                                    I feel I do not have much to be proud of.
#> 6                                    I take a positive attitude toward myself.
#> 7                                    On the whole, I am satisfied with myself.
#> 8                                 I wish I could have more respect for myself.
#> 9                                           I certainly feel useless at times.
#> 10                                       At times I think I am no good at all.
x <- rses_real[rses_items$item]
x[rses_items$reverse] <- 5 - x[rses_items$reverse]
summary(rowMeans(x, na.rm = TRUE))
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.     NAs 
#>   1.000   2.100   2.600   2.630   3.111   4.000      45 
```
