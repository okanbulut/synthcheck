## Submission

This is the first submission of synthcheck to CRAN.

## R CMD check results

0 errors | 0 warnings | 2 notes

* This is a new submission. The tarball is 6.0 MB.
* Installed size is 6.4 MB, of which data 5.4 MB. The data are the point
  of the package: Real responses to the IPIP-HEXACO (17,874 people) and
  three short scales, and the answers of six language models to the same
  240 HEXACO items (89,597 synthetic respondents), so that the benchmark,
  examples and articles can be reproduced offline. All data files are
  already compressed with xz.

## Notes for the reviewer

* The package bundles real survey responses from the Open-Source
  Psychometrics Project and language model responses to the same items, so
  that the examples and articles run without an internet connection.
* Functions that call language model providers (through 'ellmer') are only
  run in `\dontrun{}` examples. Examples and tests use a built-in mock
  provider that makes no network calls.
* Slow examples (person-fit models on all 240 HEXACO items) are in
  `\donttest{}`.
