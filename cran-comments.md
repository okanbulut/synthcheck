## Submission

This is the first submission of synthcheck to CRAN.

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

## Notes for the reviewer

* The package bundles real survey responses from the Open-Source
  Psychometrics Project and language model responses to the same items, so
  that the examples and articles run without an internet connection.
* Functions that call language model providers (through 'ellmer') are only
  run in `\dontrun{}` examples. Examples and tests use a built-in mock
  provider that makes no network calls.
* Slow examples (person-fit models on all 240 HEXACO items) are in
  `\donttest{}`.
