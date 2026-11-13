# Write a report of the results

`write_report()` saves one file that holds the results of a synthcheck
analysis: The plots, the tables, the plain-language summaries and the
settings needed to repeat the run. It covers whichever path was taken.
With real data, that is the synthetic authenticity benchmark
([`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md)).
Without real data, it is the pretest
([`synthetic_pretest()`](https://www.okanbulut.com/synthcheck/reference/synthetic_pretest.md))
and the cognitive interviews
([`cognitive_interview()`](https://www.okanbulut.com/synthcheck/reference/cognitive_interview.md)).

## Usage

``` r
write_report(x, file, format = NULL, title = NULL, script = NULL)
```

## Arguments

- x:

  a result of
  [`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md),
  [`synthetic_pretest()`](https://www.okanbulut.com/synthcheck/reference/synthetic_pretest.md)
  or
  [`cognitive_interview()`](https://www.okanbulut.com/synthcheck/reference/cognitive_interview.md),
  or a list with any of `benchmark`, `pretest` and `interviews`, such as
  the list
  [`run_synthcheck_app()`](https://www.okanbulut.com/synthcheck/reference/run_synthcheck_app.md)
  returns. The list can also hold `synthetic` (the synthetic data),
  `instrument` (from
  [`sc_instrument()`](https://www.okanbulut.com/synthcheck/reference/sc_instrument.md)),
  `personas`, `models` (a list of
  [`sc_model()`](https://www.okanbulut.com/synthcheck/reference/sc_model.md)),
  `run` (the settings of a
  [`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md)
  run, as read from its `run.json`) and `path` (`"real"` or
  `"pretest"`). These fill the settings section of the report.

- file:

  the file to write.

- format:

  `"html"` or `"pdf"`. `NULL` (the default) takes it from the extension
  of `file`, and uses HTML when the extension is neither.

- title:

  the report title. `NULL` uses a title that fits the results.

- script:

  optional R code (a character vector) that repeats the analysis. It is
  printed at the end of the report.

## Value

`file`, invisibly.

## Details

**HTML** (the default) is one self-contained file with the plots
embedded, so it can be emailed or archived as it is. **PDF** uses the
PDF device that comes with R, so it needs no LaTeX or pandoc. Long table
cells are shortened in the PDF. The HTML report shows them in full.

The report says what the results can and cannot show. The benchmark
compares models and supports decisions about them. It does not show that
synthetic data can replace a field test. The pretest and the interviews
are screening: They flag items worth a second look, and they do not
validate the scale.

## See also

[`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md),
[`synthetic_pretest()`](https://www.okanbulut.com/synthcheck/reference/synthetic_pretest.md),
[`cognitive_interview()`](https://www.okanbulut.com/synthcheck/reference/cognitive_interview.md),
[`run_synthcheck_app()`](https://www.okanbulut.com/synthcheck/reference/run_synthcheck_app.md)

## Examples

``` r
h <- hexaco_items[hexaco_items$trait %in% c("H", "C"), ]
ca <- hexaco_llm[hexaco_llm$country == "Canada" & hexaco_llm$attempt <= 2, ]
pt <- synthetic_pretest(ca, h, irt = FALSE, n_pa = 0)
f <- tempfile(fileext = ".html")
write_report(pt, f)
# \donttest{
real <- hexaco_real[hexaco_real$country == "Canada", ]
bm <- authenticity_benchmark(as_synthetic_list(ca), real, h, fit_scales = character(0),
                             n_splits = 5, n_floor = 5)
write_report(list(benchmark = bm, synthetic = ca), tempfile(fileext = ".pdf"))
# }
```
