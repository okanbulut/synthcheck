# DASS-21: Items and real responses

The 21 items of the short Depression Anxiety Stress Scales (DASS-21;
Lovibond & Lovibond, 1995), seven per scale, and the answers of 39,775
people who took the 42-item DASS online through the Open-Source
Psychometrics Project from 2017 to 2019. The 21 items are taken from the
42 (the `dass42` column says which). The DASS is public domain. Its
structure is disputed, so it is a test case for the expected-structure
checks (see
[`sc_builtin_instrument()`](https://www.okanbulut.com/synthcheck/reference/sc_builtin_instrument.md)).

## Usage

``` r
dass_items

dass_real
```

## Format

`dass_items`: A data frame with 21 rows and 7 columns: `item` (`DASS1`
to `DASS21`, in DASS-21 order), `scale` (`D`, `A` or `S`), `scale_label`
(`Depression`, `Anxiety` or `Stress`), `statement`, `reverse` (all
`FALSE`), `dass42` (the item in the 42-item DASS, for example `Q22`) and
`issue`.

`dass_real`: A data frame with 39,775 rows and 24 columns: `country`
(two-letter code from the respondent's network address, or `NA`; the
largest groups are `MY` (21,605), `US` (8,207) and `GB` (1,180)),
`gender` (factor), `age` (13 to 99, other entries `NA`) and the 21
items.

An object of class `data.frame` with 21 rows and 7 columns.

An object of class `data.frame` with 39775 rows and 24 columns.

## Source

Open-Source Psychometrics Project,
<https://openpsychometrics.org/_rawdata/> (DASS data, 2019; only
respondents who confirmed that their answers were accurate and could be
used for research). The project gives no formal licence for the data.
The DASS items are public domain (<https://www2.psy.unsw.edu.au/dass/>).
The script is `data-raw/instruments.R` in the package's GitHub
repository.

## Details

**Known problems.** Whether the DASS-21 measures three distinct states
is disputed: A bifactor model with a general distress factor often fits
better than three correlated factors, and Stress overlaps with Anxiety
(Henry & Crawford, 2005; Osman et al., 2012). The somatic anxiety items
(dry mouth, breathing, trembling, heart rate) can reflect physical
illness and often load weakly. In `dass_real`, item 2 ("I was aware of
dryness of my mouth") has the lowest corrected item-total correlation
within its scale (0.46; the others are 0.53 to 0.77). The `issue` column
of `dass_items` gives a one-line note per item.

Answers are how much each statement applied over the past week, on a
4-point scale stored as given (1 = did not apply to me at all, 2 = to
some degree, 3 = to a considerable degree, 4 = very much). The official
DASS scoring uses 0 to 3, so subtract 1 (and double the DASS-21 sums to
compare with DASS-42 norms). No item is reverse-keyed. The items were
shown in a random order among the 42, one at a time.

Over half of the respondents connected from Malaysia, so use `country`
when the population matters.

## References

Henry, J. D., & Crawford, J. R. (2005). The short-form version of the
Depression Anxiety Stress Scales (DASS-21): Construct validity and
normative data in a large non-clinical sample. *British Journal of
Clinical Psychology, 44*(2), 227-239.
[doi:10.1348/014466505X29657](https://doi.org/10.1348/014466505X29657)

Lovibond, S. H., & Lovibond, P. F. (1995). *Manual for the Depression
Anxiety Stress Scales* (2nd ed.). Psychology Foundation.

Osman, A., Wong, J. L., Bagge, C. L., Freedenthal, S., Gutierrez, P. M.,
& Lozano, G. (2012). The Depression Anxiety Stress Scales-21 (DASS-21):
Further examination of dimensions, scale reliability, and correlates.
*Journal of Clinical Psychology, 68*(12), 1322-1338.
[doi:10.1002/jclp.21908](https://doi.org/10.1002/jclp.21908)

## See also

[`sc_builtin_instrument()`](https://www.okanbulut.com/synthcheck/reference/sc_builtin_instrument.md),
[rses_items](https://www.okanbulut.com/synthcheck/reference/rses.md),
[mini_ipip_items](https://www.okanbulut.com/synthcheck/reference/mini_ipip.md)

## Examples

``` r
table(dass_items$scale_label)
#> 
#>    Anxiety Depression     Stress 
#>          7          7          7 
# DASS-21 scale sums on the official 0 to 3 scoring
sums <- sapply(split(dass_items$item, dass_items$scale),
               function(i) rowSums(dass_real[i] - 1))
round(cor(sums), 2)
#>      A    D    S
#> A 1.00 0.62 0.75
#> D 0.62 1.00 0.71
#> S 0.75 0.71 1.00
```
