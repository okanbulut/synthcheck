# A clean ggplot2 theme for synthcheck graphics

The theme used by every synthcheck plot (the same as `theme_mirtverse()`
in mirtverse).

## Usage

``` r
theme_synthcheck(base_size = 11)
```

## Arguments

- base_size:

  base font size.

## Value

A ggplot2 theme.

## Examples

``` r
library(ggplot2)
ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_synthcheck()
```
