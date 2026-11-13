# Show the prompts of a cognitive interview

**Experimental.** Shows exactly what
[`cognitive_interview()`](https://www.okanbulut.com/synthcheck/reference/cognitive_interview.md)
sends for one item and persona: The persona's system prompt, the
think-aloud request, the probes and the coder's instructions.

## Usage

``` r
sc_interview_prompts(
  instrument,
  item,
  persona = NULL,
  probes = sc_probes(),
  flag = NULL
)
```

## Arguments

- instrument:

  an
  [`sc_instrument()`](https://www.okanbulut.com/synthcheck/reference/sc_instrument.md).

- item:

  the name of one item.

- persona:

  one persona description, or `NULL` for none.

- probes:

  the probes, from
  [`sc_probes()`](https://www.okanbulut.com/synthcheck/reference/sc_probes.md).

- flag:

  optional pretest flag for the item, which adds the pretest probe.

## Value

A list with `system`, `think_aloud`, `probes` and `coder` (the coder's
system prompt).

## Examples

``` r
ins <- sc_instrument(hexaco_items[1:3, ], scale = c(1, 7))
p <- sc_interview_prompts(ins, "HSinc1", "You are a 30-year-old teacher.")
cat(p$think_aloud)
#> Here is a statement from a survey. The survey's instructions are: "Please read each statement and decide how much you agree or disagree with it. There are no right or wrong answers. Answer every statement."
#> 
#> Answer with a whole number from 1 to 7:
#> 1 = Strongly disagree
#> 2 = Disagree
#> 3 = Slightly disagree
#> 4 = Neither agree nor disagree
#> 5 = Slightly agree
#> 6 = Agree
#> 7 = Strongly agree
#> 
#> Statement: "I don't pretend to be more than I am."
#> 
#> Please think aloud: Read the statement, then tell me everything that goes through your mind as you decide how to answer it, in your own words. Then give your answer.
cat(p$probes)
#> Thank you. Now a few questions about that statement. Answer each one in your own words, in a few sentences.
#> 
#> 1. In your own words, what is this statement asking you?
#> 2. Were there any words or phrases that were unclear, or that could mean different things? What did you take them to mean?
#> 3. What did you think about, or remember, to come up with your answer?
#> 4. How sure are you of your answer? Was anything hard about deciding?
#> 5. Was it easy to pick a number on this scale? Did any of the options fit poorly, or did you want an option that was not there?
#> 6. Would you, or people like you, feel uncomfortable answering this honestly? Is any of the wording sensitive or offensive?
```
