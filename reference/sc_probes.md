# Probes for cognitive interviews

`sc_probes()` returns the scripted verbal probes that
[`cognitive_interview()`](https://www.okanbulut.com/synthcheck/reference/cognitive_interview.md)
asks after the think-aloud, one row per probe. With no arguments it
gives the default protocol: Two comprehension probes (paraphrase and
terms), then one probe each for retrieval, judgement, response mapping
and sensitivity, following the standard cognitive interviewing approach
(Willis, 2005) and Tourangeau's (1984) four stages of answering a survey
question.

## Usage

``` r
sc_probes(stage = NULL, probe = NULL, probe_id = NULL)
```

## Arguments

- stage:

  the stage of each probe: `"comprehension"`, `"retrieval"`,
  `"judgement"`, `"response"` or `"sensitivity"`. `NULL` gives the
  default protocol.

- probe:

  the wording of each probe, as the interviewer would ask it.

- probe_id:

  optional short names, used for the columns of the result
  (`probe_<probe_id>`). `NULL` makes them from the stages.

## Value

A tibble of class `sc_probes` with `probe_id`, `stage` and `probe`.

## Details

Give `stage` and `probe` to write your own protocol. Each probe belongs
to one stage, which tells the reader of the transcript what the probe is
for. The coding of problems does not depend on which probes were asked.

## References

Tourangeau, R. (1984). Cognitive science and survey methods. In T.
Jabine, M. Straf, J. Tanur & R. Tourangeau (Eds.), *Cognitive aspects of
survey methodology: Building a bridge between disciplines* (pp. 73-100).
National Academy Press.

Willis, G. B. (2005). *Cognitive interviewing: A tool for improving
questionnaire design.* Sage.

## See also

[`cognitive_interview()`](https://www.okanbulut.com/synthcheck/reference/cognitive_interview.md)

## Examples

``` r
sc_probes()
#> # A tibble: 6 × 3
#>   probe_id    stage         probe                                               
#>   <chr>       <chr>         <chr>                                               
#> 1 paraphrase  comprehension In your own words, what is this statement asking yo…
#> 2 terms       comprehension Were there any words or phrases that were unclear, …
#> 3 retrieval   retrieval     What did you think about, or remember, to come up w…
#> 4 judgement   judgement     How sure are you of your answer? Was anything hard …
#> 5 response    response      Was it easy to pick a number on this scale? Did any…
#> 6 sensitivity sensitivity   Would you, or people like you, feel uncomfortable a…

# a shorter protocol
sc_probes(stage = c("comprehension", "response"),
          probe = c("What does this statement mean to you?",
                    "Was it easy to choose an answer?"))
#> # A tibble: 2 × 3
#>   probe_id      stage         probe                                
#>   <chr>         <chr>         <chr>                                
#> 1 comprehension comprehension What does this statement mean to you?
#> 2 response      response      Was it easy to choose an answer?     
```
