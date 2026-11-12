# A tour of the synthcheck app

**Experimental.**
[`run_synthcheck_app()`](https://www.okanbulut.com/synthcheck/reference/run_synthcheck_app.md)
opens an app that does the whole synthcheck workflow without code:
Define an instrument and personas, generate synthetic respondents with
one or more language models, benchmark them against real data and save
everything. This article walks through its five tabs. For worked
examples, see [the app
demos](https://www.okanbulut.com/synthcheck/articles/app-demo.md).

The benchmark compares models and supports decisions about them. It does
not show that synthetic data can replace a field test.

## Starting the app

The app needs a few suggested packages:

``` r

install.packages(c("shiny", "bslib", "ellmer", "callr", "jsonlite"))
# optional: readxl and writexl for Excel files, cicerone for the guided tour
```

``` r

library(synthcheck)
res <- run_synthcheck_app()
```

The app runs on your own computer and opens in your browser. You can
pass real or synthetic data to it, and they appear in the Compare tab:

``` r

res <- run_synthcheck_app(real = my_real_data, synthetic = my_earlier_run)
```

When you close the app with the button in the Export tab, `res` holds
the generated data, the benchmark, the instrument and the personas.

## About

![The About tab that opens the app.](figures/app-about.png)

The About tab that opens the app.

The app opens on the **About** tab. It explains what the app is for,
lists what it can do and what it produces, and shows an animated picture
of a language model answering survey items: A persona and the items go
in, the model answers each item on the response scale, and synthcheck
compares the answers with real people. A short guided demo lists the
five steps.

**Take the guided tour** walks through the app one control at a time and
switches the tabs for you. The tour needs the cicerone package
(`install.packages("cicerone")`).

![The guided tour pointing to the items on the Instrument
tab.](figures/app-tour-step.png)

The guided tour pointing to the items on the Instrument tab.

## 1. Instrument

![The Instrument tab with two HEXACO traits
selected.](figures/app-instrument.png)

The Instrument tab with two HEXACO traits selected.

Choose the items on the left: The built-in IPIP-HEXACO items (pick the
traits; two traits give 80 items, all six give 240), or your own item
table. Set the lowest and highest category, the category labels and the
instructions.

The right side checks the instrument and shows the **prompt sent for
each respondent**, so you see exactly what a model will read.

![Uploading an item table, with the template
button.](figures/app-instrument-upload.png)

Uploading an item table, with the template button.

To use your own questionnaire, choose **Upload an item table** and
download the template. It has the columns `item` (a short name),
`statement` (the text), and optionally `scale`, `facet` and `reverse`
(`TRUE` for reverse-keyed items). CSV and Excel both work. The same
template is in the package:

``` r

system.file("templates", "instrument_template.csv", package = "synthcheck")
```

## 2. Personas

![The Personas tab building a grid of
personas.](figures/app-personas.png)

The Personas tab building a grid of personas.

A persona is who the synthetic respondent is told to be. There are four
ways to set them:

- **No persona:** Every respondent gets the same neutral prompt.
- **Type them:** One description per line.
- **Build a grid:** List a few attributes (`age: 25, 45, 65`) and a
  description with `{age}` in it. The app makes every combination.
- **Upload a table:** A `description` column, with optional `persona_id`
  and attribute columns. The attributes are kept in the generated data.
  The template is `personas_template.csv`.

## 3. Models

![The Models tab with two models, the run plan and the time
estimate.](figures/app-models.png)

The Models tab with two models, the run plan and the time estimate.

**API keys.** Type an Anthropic or OpenAI key, or set
`ANTHROPIC_API_KEY` and `OPENAI_API_KEY` in `.Renviron`, and the app
uses them without showing them. Typed keys stay in memory for this
session only. They are never written to the saved data, the run settings
or the R script. Ollama models run on your own computer and need no key.

**Add a model.** Pick a provider and a model id (or type one), set the
temperature and an optional label, and click **Add model**. Add as many
as you want to compare. **Mock** gives random answers without an API,
which is useful for trying the app.

**Run.** Set the number of attempts (full passes over the personas) and
the respondents per persona per attempt. The plan under the settings
tells you how many respondents the run will make.

- **Calls at the same time** speeds up a run when the API allows it.
- **Respondents per call** above 1 is cheaper, but respondents in the
  same call may depend on each other. Keep 1 for independent
  respondents.
- **Items per call** splits a long instrument into blocks.
- **Estimate run time** sends one test call per model and tells you how
  long the whole run should take. It is also a quick check that the keys
  and model ids work.

![A run in progress, with the time left for each
model.](figures/app-progress.png)

A run in progress, with the time left for each model.

**Generate data** starts the run in a background R process, so the app
stays responsive. The progress bar shows the respondents done and the
time left, and **Stop** ends the run after the calls in progress. Every
attempt is saved to the output folder as soon as it is done, so a
stopped run keeps its finished attempts.

## 4. Compare

![The Compare tab after a benchmark.](figures/demo-builtin.png)

The Compare tab after a benchmark.

Choose the real data (the built-in `hexaco_real` for one country, data
you passed to
[`run_synthcheck_app()`](https://www.okanbulut.com/synthcheck/reference/run_synthcheck_app.md),
or an upload) and the synthetic data (this session’s run, the built-in
`hexaco_llm`, or files saved by an earlier run). Then click **Run the
benchmark**.

The right side shows a plain-language summary per model, the synthetic
authenticity benchmark with its table, and the behaviour strip. In the
benchmark, tiles run from red (-100 or lower) through pale (0, no better
than shuffled real answers) to blue (100, as close as a second sample of
real people). In the behaviour strip, red means lower than real people,
blue means higher, and pale means a match.

**Benchmark settings:**

- **Score:** The weakest column (the default), the mean or the geometric
  mean of the three columns.
- **Remove careless real respondents first:** Compare with real
  respondents after careless ones are flagged and removed
  (`clean_real = TRUE`).
- **Include person fit:** Fits a graded response model per trait to the
  real data. It is slower; switch it off while you explore.
- **Real splits and shuffled draws:** How many draws set the 0 and 100
  anchors. More is steadier and slower.

## 5. Export

![The Export tab with downloads and the R
script.](figures/app-export.png)

The Export tab with downloads and the R script.

Download the synthetic data (CSV, JSON, RDS or Excel), the benchmark
table, the summary and the plot. **Repeat it in R** gives a script that
reads the saved data and runs the same benchmark, so the comparison can
be checked and rerun without the app. **Close the app and return to R**
hands everything back to the R session.
