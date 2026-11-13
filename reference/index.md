# Package index

## Overlap and Structure

Where synthetic respondents land and how their items relate.

- [`synthetic_coverage()`](https://www.okanbulut.com/synthcheck/reference/synthetic_coverage.md)
  : How well do synthetic respondents cover the real population?
- [`gg_coverage()`](https://www.okanbulut.com/synthcheck/reference/gg_coverage.md)
  : Draw the coverage strip
- [`blend_llms()`](https://www.okanbulut.com/synthcheck/reference/blend_llms.md)
  : Find the best blend of language models

## Behaviour

How synthetic respondents answer.

- [`synthetic_behaviour()`](https://www.okanbulut.com/synthcheck/reference/synthetic_behaviour.md)
  : Behaviour: Do synthetic respondents answer the way real people do?
- [`gg_behaviour()`](https://www.okanbulut.com/synthcheck/reference/gg_behaviour.md)
  : Draw the behaviour strip
- [`behaviour_features()`](https://www.okanbulut.com/synthcheck/reference/behaviour_features.md)
  : The eight behaviour features of each respondent
- [`flag_careless()`](https://www.okanbulut.com/synthcheck/reference/flag_careless.md)
  : Flag careless real respondents

## The synthetic authenticity benchmark

- [`authenticity_benchmark()`](https://www.okanbulut.com/synthcheck/reference/authenticity_benchmark.md)
  : The synthetic authenticity benchmark
- [`gg_benchmark()`](https://www.okanbulut.com/synthcheck/reference/gg_benchmark.md)
  : Draw the synthetic authenticity benchmark
- [`summarise_benchmark()`](https://www.okanbulut.com/synthcheck/reference/summarise_benchmark.md)
  : Describe the benchmark in plain language

## Diagnostics

Checks beside the benchmark that do not change its score.

- [`synthetic_construct()`](https://www.okanbulut.com/synthcheck/reference/synthetic_construct.md)
  : Construct structure of synthetic respondents
- [`gg_construct()`](https://www.okanbulut.com/synthcheck/reference/gg_construct.md)
  : Draw the construct structure
- [`respondent_coverage()`](https://www.okanbulut.com/synthcheck/reference/respondent_coverage.md)
  : Respondent coverage of synthetic respondents
- [`gg_respondent_coverage()`](https://www.okanbulut.com/synthcheck/reference/gg_respondent_coverage.md)
  : Draw the respondent coverage
- [`synthetic_copula()`](https://www.okanbulut.com/synthcheck/reference/synthetic_copula.md)
  : Respondents drawn from a Gaussian copula of the real data

## Pretest without real data

Pilot screening of a scale on synthetic respondents alone, with
agreement across conditions.

- [`synthetic_pretest()`](https://www.okanbulut.com/synthcheck/reference/synthetic_pretest.md)
  : Pretest a scale on synthetic respondents, without real data
- [`gg_pretest()`](https://www.okanbulut.com/synthcheck/reference/gg_pretest.md)
  : Draw the pretest
- [`summarise_pretest()`](https://www.okanbulut.com/synthcheck/reference/summarise_pretest.md)
  : Describe the pretest in plain language

## Generating synthetic respondents

Define an instrument and personas, call language models, save the data.

- [`run_synthcheck_app()`](https://www.okanbulut.com/synthcheck/reference/run_synthcheck_app.md)
  : Generate and benchmark synthetic data in a Shiny app
- [`sc_instrument()`](https://www.okanbulut.com/synthcheck/reference/sc_instrument.md)
  : Define an instrument for synthetic respondents
- [`sc_builtin_instrument()`](https://www.okanbulut.com/synthcheck/reference/sc_builtin_instrument.md)
  : Use an instrument that comes with synthcheck
- [`sc_personas()`](https://www.okanbulut.com/synthcheck/reference/sc_personas.md)
  [`sc_persona_grid()`](https://www.okanbulut.com/synthcheck/reference/sc_personas.md)
  : Define personas for synthetic respondents
- [`sc_model()`](https://www.okanbulut.com/synthcheck/reference/sc_model.md)
  : Choose a language model for synthetic respondents
- [`sc_default_models`](https://www.okanbulut.com/synthcheck/reference/sc_default_models.md)
  : Default model ids
- [`sc_prompt()`](https://www.okanbulut.com/synthcheck/reference/sc_prompt.md)
  : Build the prompts for one synthetic respondent
- [`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md)
  : Generate synthetic respondents with language models
- [`estimate_cost()`](https://www.okanbulut.com/synthcheck/reference/estimate_cost.md)
  [`estimate_interview_cost()`](https://www.okanbulut.com/synthcheck/reference/estimate_cost.md)
  : Estimate what a run will cost
- [`sc_prices`](https://www.okanbulut.com/synthcheck/reference/sc_prices.md)
  : Prices of language models
- [`sc_cache()`](https://www.okanbulut.com/synthcheck/reference/sc_cache.md)
  : Keep model answers on disk
- [`sc_cache_info()`](https://www.okanbulut.com/synthcheck/reference/sc_cache_info.md)
  [`sc_cache_clear()`](https://www.okanbulut.com/synthcheck/reference/sc_cache_info.md)
  : See or clear the response cache
- [`write_synthetic()`](https://www.okanbulut.com/synthcheck/reference/write_synthetic.md)
  [`read_synthetic()`](https://www.okanbulut.com/synthcheck/reference/write_synthetic.md)
  : Save and read synthetic respondents
- [`as_synthetic_list()`](https://www.okanbulut.com/synthcheck/reference/as_synthetic_list.md)
  : Turn a table of synthetic respondents into benchmark input

## Reports

All results of a session in one HTML or PDF file.

- [`write_report()`](https://www.okanbulut.com/synthcheck/reference/write_report.md)
  : Write a report of the results

## Cognitive interviews

Screen item wording with language models playing personas, when there
are no real respondents yet.

- [`cognitive_interview()`](https://www.okanbulut.com/synthcheck/reference/cognitive_interview.md)
  : Run cognitive interviews with language models playing personas
- [`sc_probes()`](https://www.okanbulut.com/synthcheck/reference/sc_probes.md)
  : Probes for cognitive interviews
- [`sc_interview_prompts()`](https://www.okanbulut.com/synthcheck/reference/sc_interview_prompts.md)
  : Show the prompts of a cognitive interview
- [`summarise_interviews()`](https://www.okanbulut.com/synthcheck/reference/summarise_interviews.md)
  : Summarise cognitive interviews per item
- [`gg_interview()`](https://www.okanbulut.com/synthcheck/reference/gg_interview.md)
  : Plot cognitive interview problems per item

## Data

- [`hexaco_real`](https://www.okanbulut.com/synthcheck/reference/hexaco_real.md)
  : HEXACO responses of real people, for checking synthetic respondents
- [`hexaco_llm`](https://www.okanbulut.com/synthcheck/reference/hexaco_llm.md)
  : HEXACO responses generated by six language models
- [`hexaco_items`](https://www.okanbulut.com/synthcheck/reference/hexaco_items.md)
  : The 240 IPIP-HEXACO items and their keys
- [`rses_items`](https://www.okanbulut.com/synthcheck/reference/rses.md)
  [`rses_real`](https://www.okanbulut.com/synthcheck/reference/rses.md)
  : Rosenberg Self-Esteem Scale: Items and real responses
- [`dass_items`](https://www.okanbulut.com/synthcheck/reference/dass.md)
  [`dass_real`](https://www.okanbulut.com/synthcheck/reference/dass.md)
  : DASS-21: Items and real responses
- [`mini_ipip_items`](https://www.okanbulut.com/synthcheck/reference/mini_ipip.md)
  [`mini_ipip_real`](https://www.okanbulut.com/synthcheck/reference/mini_ipip.md)
  : Mini-IPIP: Items and real responses

## Helpers

- [`theme_synthcheck()`](https://www.okanbulut.com/synthcheck/reference/theme_synthcheck.md)
  : A clean ggplot2 theme for synthcheck graphics
- [`synthcheck`](https://www.okanbulut.com/synthcheck/reference/synthcheck-package.md)
  [`synthcheck-package`](https://www.okanbulut.com/synthcheck/reference/synthcheck-package.md)
  : synthcheck: Check how authentic synthetic survey respondents are
