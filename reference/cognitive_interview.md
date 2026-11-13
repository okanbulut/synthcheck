# Run cognitive interviews with language models playing personas

`cognitive_interview()` asks one or more language models to take part in
a cognitive interview about each survey item, as each persona. It is
meant for screening items when there are no real respondents yet, for
example after a
[`synthetic_pretest()`](https://www.okanbulut.com/synthcheck/reference/synthetic_pretest.md):
It points to wording to look at. It is not a substitute for cognitive
interviews with real people or for a field test.

## Usage

``` r
cognitive_interview(
  instrument,
  models,
  personas = NULL,
  items = NULL,
  probes = sc_probes(),
  coder = NULL,
  pretest = NULL,
  interviews = 1,
  max_retries = 2,
  parallel = 1,
  output = NULL,
  format = c("csv", "json", "rds"),
  progress = interactive(),
  progress_file = NULL,
  stop_file = NULL,
  seed = 1,
  cache = sc_cache()
)
```

## Arguments

- instrument:

  an
  [`sc_instrument()`](https://www.okanbulut.com/synthcheck/reference/sc_instrument.md).

- models:

  one
  [`sc_model()`](https://www.okanbulut.com/synthcheck/reference/sc_model.md)
  or a list of them, the respondents.

- personas:

  an
  [`sc_personas()`](https://www.okanbulut.com/synthcheck/reference/sc_personas.md)
  table, a character vector of descriptions, or `NULL` for interviews
  without a persona.

- items:

  optional item names to interview about. `NULL` uses all items, or only
  the flagged items when `pretest` is given.

- probes:

  the probes, from
  [`sc_probes()`](https://www.okanbulut.com/synthcheck/reference/sc_probes.md).

- coder:

  an
  [`sc_model()`](https://www.okanbulut.com/synthcheck/reference/sc_model.md)
  that codes the transcripts. `NULL` uses each respondent model to code
  its own interviews. The coder's temperature is set to 0 when it takes
  one.

- pretest:

  optional result of
  [`synthetic_pretest()`](https://www.okanbulut.com/synthcheck/reference/synthetic_pretest.md),
  or a data frame with an `item` column and an optional `flag` column
  (the reason, for example `"low item-rest correlation"`), or a vector
  of item names. Flagged items come first and get one extra probe.

- interviews:

  number of interviews per model, persona and item.

- max_retries:

  how often to retry an interview that fails.

- parallel:

  number of interviews to run at the same time.

- output:

  optional folder to write the results to: The table in `format`,
  `run.json`, and one readable Markdown file of transcripts per item in
  `transcripts/`.

- format:

  file format of the table in `output`: `"csv"`, `"json"` or `"rds"`.

- progress:

  show a progress bar in the console? A function also works, as in
  [`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md).

- progress_file:

  optional path of a JSON file updated after every interview (used by
  [`run_synthcheck_app()`](https://www.okanbulut.com/synthcheck/reference/run_synthcheck_app.md)).

- stop_file:

  optional path: When this file appears, the run stops after the
  interviews in progress.

- seed:

  random seed for the mock provider, also part of the cache key.

- cache:

  the response cache, as in
  [`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md):
  An
  [`sc_cache()`](https://www.okanbulut.com/synthcheck/reference/sc_cache.md),
  a folder, `TRUE` or `FALSE`. The respondent's two answers and the
  coding are saved, so the same interviews again cost nothing.

## Value

A tibble of class `sc_interview`, one row per model, persona, item and
interview, with `model`, `provider`, `model_id`, `coder`, `persona_id`,
any persona attributes, `item`, `statement`, `pretest` (the flag, if
any), `interview`, `answer`, `think_aloud`, one `probe_<probe_id>`
column per probe, one logical column per stage (`comprehension`,
`retrieval`, `judgement`, `response`, `sensitivity`) with a
`<stage>_note` beside it, `severity` (`"none"`, `"minor"` or `"major"`)
and `revision`. The attribute `log` holds failed interviews. Summarise
it with
[`summarise_interviews()`](https://www.okanbulut.com/synthcheck/reference/summarise_interviews.md)
and plot it with
[`gg_interview()`](https://www.okanbulut.com/synthcheck/reference/gg_interview.md).

## Details

Each interview is one conversation with one persona about one item,
following the standard mix of think-aloud and scripted verbal probes
(Willis, 2005; Beatty & Willis, 2007):

1.  **Think-aloud and answer.** The persona reads the statement, says
    what goes through its mind while deciding, and answers on the
    instrument's scale.

2.  **Probes.** The persona answers the probes in
    [`sc_probes()`](https://www.okanbulut.com/synthcheck/reference/sc_probes.md)
    in the same conversation. Items flagged by the pretest get one more
    probe aimed at the reason for the flag.

3.  **Coding.** A separate call, with no persona, reads the transcript
    and codes problems at the four stages of answering a survey question
    (comprehension, retrieval, judgement, response mapping;
    Tourangeau, 1984) plus sensitivity, as in the Question Appraisal
    System (Willis & Lessler, 1999). For each stage it gives a yes or
    no, a short note with a quote, an overall severity and an optional
    rewording. Use another model as `coder` so that no model grades its
    own interviews.

That is three requests per interview. The number of interviews is the
number of models times personas times items times `interviews`, and it
is printed before the run starts.

What a model can and cannot tell you: A model does not retrieve memories
or feel uncomfortable, so its retrieval and judgement reports are
guesses about what such a person might say. Comprehension and
response-mapping problems (vague or double-barrelled wording, a scale
that fits poorly) are where it helps most. Models understand items
better than many real respondents, so an item without problems here is
not shown to work.

## References

Beatty, P. C., & Willis, G. B. (2007). Research synthesis: The practice
of cognitive interviewing. *Public Opinion Quarterly, 71*(2), 287-311.

Tourangeau, R. (1984). Cognitive science and survey methods. In T.
Jabine, M. Straf, J. Tanur & R. Tourangeau (Eds.), *Cognitive aspects of
survey methodology: Building a bridge between disciplines* (pp. 73-100).
National Academy Press.

Willis, G. B. (2005). *Cognitive interviewing: A tool for improving
questionnaire design.* Sage.

Willis, G. B., & Lessler, J. T. (1999). *Question Appraisal System
QAS-99.* Research Triangle Institute.

## See also

[`sc_probes()`](https://www.okanbulut.com/synthcheck/reference/sc_probes.md),
[`summarise_interviews()`](https://www.okanbulut.com/synthcheck/reference/summarise_interviews.md),
[`gg_interview()`](https://www.okanbulut.com/synthcheck/reference/gg_interview.md),
[`sc_interview_prompts()`](https://www.okanbulut.com/synthcheck/reference/sc_interview_prompts.md),
[`estimate_interview_cost()`](https://www.okanbulut.com/synthcheck/reference/estimate_cost.md),
[`sc_cache()`](https://www.okanbulut.com/synthcheck/reference/sc_cache.md)

## Examples

``` r
items <- data.frame(
  item = c("q1", "q2", "q3"),
  statement = c("I am not someone who never worries.",
                "I enjoy meeting new people and going to parties.",
                "I keep my promises."))
ins <- sc_instrument(items, scale = c(1, 5))
per <- sc_personas(c("You are a 19-year-old student.", "You are a 70-year-old retiree."))
iv <- cognitive_interview(ins, sc_model("mock"), per)
#> 6 interviews (1 model x 2 personas x 3 items): 18 requests.
iv
#> # A tibble: 6 × 29
#>   model provider model_id coder persona_id item  statement     pretest interview
#>   <chr> <chr>    <chr>    <chr> <chr>      <chr> <chr>         <chr>       <int>
#> 1 mock  mock     mock     mock  p001       q1    I am not som… NA              1
#> 2 mock  mock     mock     mock  p001       q2    I enjoy meet… NA              1
#> 3 mock  mock     mock     mock  p001       q3    I keep my pr… NA              1
#> 4 mock  mock     mock     mock  p002       q1    I am not som… NA              1
#> 5 mock  mock     mock     mock  p002       q2    I enjoy meet… NA              1
#> 6 mock  mock     mock     mock  p002       q3    I keep my pr… NA              1
#> # ℹ 20 more variables: answer <int>, think_aloud <chr>, probe_paraphrase <chr>,
#> #   probe_terms <chr>, probe_retrieval <chr>, probe_judgement <chr>,
#> #   probe_response <chr>, probe_sensitivity <chr>, comprehension <lgl>,
#> #   comprehension_note <chr>, retrieval <lgl>, retrieval_note <chr>,
#> #   judgement <lgl>, judgement_note <chr>, response <lgl>, response_note <chr>,
#> #   sensitivity <lgl>, sensitivity_note <chr>, severity <chr>, revision <chr>
summarise_interviews(iv)
#> 3 of 3 items are flagged: q1 (100% of interviews, mostly
#> comprehension); q2 (100% of interviews, mostly comprehension); q3 (50%
#> of interviews, mostly comprehension). These are screening results from
#> language models: Use them to choose items for cognitive interviews with
#> real people and a field test, not to replace them.
#> 
#> # A tibble: 3 × 9
#>   item  comprehension retrieval judgement response sensitivity   any models
#>   <chr>         <dbl>     <dbl>     <dbl>    <dbl>       <dbl> <dbl>  <int>
#> 1 q1              1         0         0          0           0   1        1
#> 2 q2              0.5       0.5       0.5        0           0   1        1
#> 3 q3              0.5       0         0          0           0   0.5      1
#> # ℹ 1 more variable: flagged <lgl>
if (FALSE) { # \dontrun{
# needs ANTHROPIC_API_KEY and OPENAI_API_KEY
iv <- cognitive_interview(ins, list(sc_model("anthropic"), sc_model("openai")), per,
                          coder = sc_model("anthropic"), parallel = 4)
} # }
```
