# Mini-IPIP: Items and real responses

The 20 items of the Mini-IPIP (Donnellan et al., 2006), four per Big
Five trait, and the answers of 20,000 people drawn at random from the
Open-Source Psychometrics Project's IPIP Big-Five Factor Markers data
(1,015,342 respondents, 2016 to 2018). The Mini-IPIP items are part of
the 50 IPIP Big-Five markers, so these people answered them among the
other 30 items. The items are public domain. Its fit problems and weak
scale make it a test case for the pretest (see
[`sc_builtin_instrument()`](https://www.okanbulut.com/synthcheck/reference/sc_builtin_instrument.md)).

## Usage

``` r
mini_ipip_items

mini_ipip_real
```

## Format

`mini_ipip_items`: A data frame with 20 rows and 6 columns: `item`,
`scale` (`E`, `A`, `C`, `N` or `I`), `scale_label`, `statement`,
`reverse` (11 items are reverse-keyed) and `issue`.

`mini_ipip_real`: A data frame with 20,000 rows and 21 columns:
`country` (two-letter code from the respondent's network address, or
`NA`; the largest groups are `US` (9,918), `GB` (1,377) and `CA`
(1,269)) and the 20 items. The sample holds only people who answered all
20 items and were the only record from their network address.

An object of class `data.frame` with 20 rows and 6 columns.

An object of class `data.frame` with 20000 rows and 21 columns.

## Source

Open-Source Psychometrics Project,
<https://openpsychometrics.org/_rawdata/> (IPIP-FFM data, November
2018). The project gives no formal licence for the data. The items are
from the International Personality Item Pool (public domain),
<https://ipip.ori.org>. The script is `data-raw/instruments.R` in the
package's GitHub repository.

## Details

**Known problems.** A five-factor model with simple structure fits
poorly unless residuals are allowed to correlate, the
Intellect/Imagination scale is often the least reliable and mixes
imagination with interest in abstract ideas, and the reverse-keyed items
share a method factor (Donnellan et al., 2006; Cooper et al., 2010;
Baldasaro et al., 2013). The `issue` column of `mini_ipip_items` gives a
one-line note per item.

Answers are on a 5-point scale (1 = disagree, 3 = neutral, 5 = agree)
and are stored as given: Reverse-keyed items are **not** reversed. Use
`mini_ipip_items$reverse` and `6 - x` before scoring. The trait the
items measure is Neuroticism (high is less stable), as in the Mini-IPIP.
The item names are those of the IPIP Big-Five markers data (`EXT`,
`AGR`, `CSN`, `EST` and `OPN` with a number), so the full file can be
used too.

## References

Baldasaro, R. E., Shanahan, M. J., & Bauer, D. J. (2013). Psychometric
properties of the Mini-IPIP in a large, nationally representative sample
of young adults. *Journal of Personality Assessment, 95*(1), 74-84.
[doi:10.1080/00223891.2012.700466](https://doi.org/10.1080/00223891.2012.700466)

Cooper, A. J., Smillie, L. D., & Corr, P. J. (2010). A confirmatory
factor analysis of the Mini-IPIP five-factor model personality scale.
*Personality and Individual Differences, 48*(5), 688-691.
[doi:10.1016/j.paid.2010.01.004](https://doi.org/10.1016/j.paid.2010.01.004)

Donnellan, M. B., Oswald, F. L., Baird, B. M., & Lucas, R. E. (2006).
The Mini-IPIP scales: Tiny-yet-effective measures of the Big Five
factors of personality. *Psychological Assessment, 18*(2), 192-203.
[doi:10.1037/1040-3590.18.2.192](https://doi.org/10.1037/1040-3590.18.2.192)

## See also

[`sc_builtin_instrument()`](https://www.okanbulut.com/synthcheck/reference/sc_builtin_instrument.md),
[rses_items](https://www.okanbulut.com/synthcheck/reference/rses.md),
[dass_items](https://www.okanbulut.com/synthcheck/reference/dass.md)

## Examples

``` r
mini_ipip_items[, c("item", "scale", "reverse", "statement")]
#>    item scale reverse                                                statement
#> 1  EXT1     E   FALSE                              I am the life of the party.
#> 2  EXT7     E   FALSE          I talk to a lot of different people at parties.
#> 3  EXT2     E    TRUE                                      I don't talk a lot.
#> 4  EXT4     E    TRUE                                I keep in the background.
#> 5  AGR4     A   FALSE                      I sympathize with others' feelings.
#> 6  AGR9     A   FALSE                                 I feel others' emotions.
#> 7  AGR5     A    TRUE          I am not interested in other people's problems.
#> 8  AGR7     A    TRUE                    I am not really interested in others.
#> 9  CSN5     C   FALSE                            I get chores done right away.
#> 10 CSN7     C   FALSE                                            I like order.
#> 11 CSN6     C    TRUE I often forget to put things back in their proper place.
#> 12 CSN4     C    TRUE                                 I make a mess of things.
#> 13 EST8     N   FALSE                             I have frequent mood swings.
#> 14 EST6     N   FALSE                                      I get upset easily.
#> 15 EST2     N    TRUE                           I am relaxed most of the time.
#> 16 EST4     N    TRUE                                      I seldom feel blue.
#> 17 OPN3     I   FALSE                              I have a vivid imagination.
#> 18 OPN4     I    TRUE                   I am not interested in abstract ideas.
#> 19 OPN2     I    TRUE          I have difficulty understanding abstract ideas.
#> 20 OPN6     I    TRUE                        I do not have a good imagination.
```
