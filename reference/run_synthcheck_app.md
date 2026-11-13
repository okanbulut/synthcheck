# Generate and benchmark synthetic data in a Shiny app

**Experimental.** `run_synthcheck_app()` opens an app that walks through
the whole workflow in five tabs. It opens on an **About** tab that
explains the purpose of the app, lists what it can do and produce, shows
an animated picture of a language model answering survey items and
starts a guided tour of the five tabs (the tour needs the cicerone
package).

## Usage

``` r
run_synthcheck_app(
  real = NULL,
  synthetic = NULL,
  host = "127.0.0.1",
  port = NULL,
  launch.browser = TRUE
)
```

## Arguments

- real:

  optional data frame of real responses, loaded into the Compare tab.

- synthetic:

  optional data frame of synthetic respondents (for example from
  [`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md)
  or
  [`read_synthetic()`](https://www.okanbulut.com/synthcheck/reference/write_synthetic.md)),
  loaded into the Compare tab.

- host, port:

  where to serve the app. The default serves it on your own computer
  only.

- launch.browser:

  open the app in a browser?

## Value

Invisibly, when the app is closed with its Close button: A list with
`synthetic` (the generated data), `benchmark` (the
[`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md)
result, if one was run), `pretest` (the
[`synthetic_pretest()`](https://www.okanbulut.com/synthcheck/reference/synthetic_pretest.md)
result, if one was run), `interviews` (the
[`cognitive_interview()`](https://www.okanbulut.com/synthcheck/reference/cognitive_interview.md)
result, if one was run), `path` (`"real"`, `"pretest"` or `NULL`),
`instrument` and `personas`.

## Details

The About tab starts with one question: **Do you already have real
responses to this instrument?** With real data, the fourth tab is
**Compare** (the benchmark below). Without real data, it is **Pretest**:
Pilot screening of the items on synthetic respondents alone, with the
agreement across models or temperatures and a check of the structure you
designed
([`synthetic_pretest()`](https://www.okanbulut.com/synthcheck/reference/synthetic_pretest.md)).
The answer can be changed at any time, so you can come back with real
data later and compare the same synthetic data.

1.  **Instrument:** Upload an item table or use the IPIP-HEXACO items,
    and set the response scale and instructions
    ([`sc_instrument()`](https://www.okanbulut.com/synthcheck/reference/sc_instrument.md)).

2.  **Personas:** Type, upload or build the personas that take the
    instrument
    ([`sc_personas()`](https://www.okanbulut.com/synthcheck/reference/sc_personas.md),
    [`sc_persona_grid()`](https://www.okanbulut.com/synthcheck/reference/sc_personas.md)).

Both upload panels offer a template to fill in. The templates are also
in the package:
`system.file("templates", "instrument_template.csv", package = "synthcheck")`
and `"personas_template.csv"`.

1.  **Models:** Add Anthropic, OpenAI or local Ollama models with their
    temperature, enter API keys, choose the number of attempts and
    respondents, and run
    [`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md)
    with a progress bar and the time left.

2.  **Compare:** Load real data and run
    [`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md),
    with
    [`gg_benchmark()`](https://www.okanbulut.com/synthcheck/reference/gg_benchmark.md),
    [`gg_behaviour()`](https://www.okanbulut.com/synthcheck/reference/gg_behaviour.md)
    and a plain-language summary per model
    ([`summarise_benchmark()`](https://www.okanbulut.com/synthcheck/reference/summarise_benchmark.md)).

3.  **Pretest** (without real data): Run
    [`synthetic_pretest()`](https://www.okanbulut.com/synthcheck/reference/synthetic_pretest.md)
    on the generated data, with
    [`gg_pretest()`](https://www.okanbulut.com/synthcheck/reference/gg_pretest.md)
    and a plain-language summary
    ([`summarise_pretest()`](https://www.okanbulut.com/synthcheck/reference/summarise_pretest.md)).
    Add the same model at several temperatures in the Models tab to
    check whether the flags hold.

4.  **Interviews** (tab 4b, without real data): Run
    [`cognitive_interview()`](https://www.okanbulut.com/synthcheck/reference/cognitive_interview.md)
    with the personas and models of tabs 2 and 3, on the items the
    pretest flagged or on items you choose (the pretest is optional),
    and read the summary
    ([`summarise_interviews()`](https://www.okanbulut.com/synthcheck/reference/summarise_interviews.md)),
    the plot
    ([`gg_interview()`](https://www.okanbulut.com/synthcheck/reference/gg_interview.md))
    and the transcripts. A screening aid, not a substitute for cognitive
    interviews with real people.

5.  **Export:** Download the data (CSV, JSON, RDS or Excel), the
    benchmark, the pretest or the interviews, and an R script that
    repeats the analysis.

**API keys** typed into the app stay in memory for that session only:
They are never written to the saved data, the run settings or the R
script. Keys set as `ANTHROPIC_API_KEY` or `OPENAI_API_KEY` (for example
in `.Renviron`) are used without being shown. The app runs on your own
computer; do not deploy it on a shared server with keys typed in.

Runs go to a background R process when callr is installed, so the app
stays responsive and the Stop button works. Every attempt is written to
the output folder as soon as it is done.

Synthetic respondents are experimental: The benchmark compares models
and supports decisions about them. It does not show that synthetic data
can replace a field test.

## See also

[`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md),
[`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md)

## Examples

``` r
if (interactive()) {
  res <- run_synthcheck_app()
  res$benchmark
}
```
