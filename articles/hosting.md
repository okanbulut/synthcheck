# Hosting the app on Posit Connect Cloud

The synthcheck app can run on a server, so people can try it in a
browser without installing R. This article walks through publishing it
on [Posit Connect Cloud](https://connect.posit.cloud) from the GitHub
repository. The same `deploy/` folder also works on shinyapps.io with
`rsconnect::deployApp("deploy")`.

## What changes on a server

[`run_synthcheck_app()`](https://www.okanbulut.com/synthcheck/reference/run_synthcheck_app.md)
on your own computer is not affected: It always runs the full app. The
hosted app comes from `synthcheck_app(hosted = TRUE)` in `deploy/app.R`,
and hosted mode differs in four ways:

- **No Ollama:** Local models run on the visitor’s own computer, which a
  server cannot reach. The Models tab leaves Ollama out and says to
  install the package for local models. Anthropic, OpenAI and the mock
  provider work as usual.
- **Visitors bring their own keys:** A key typed on the Models tab stays
  in that browser session’s memory and goes only to the provider. It is
  never saved on the server, in the files or in the R script. Keys in
  the server’s environment are never used, so a key you set there by
  mistake cannot pay for other people’s runs.
- **Files last one session:** Each session writes its runs, interviews
  and response cache to its own temporary folder, which is deleted when
  the visitor closes the tab. Visitors download what they need from
  Export.
- **No Close button:** Closing the app would stop it for everyone, so
  the Export tab offers the R script instead.

The About tab tells visitors all of this in a card at the top.

Hosted mode switches on when `deploy/app.R` sets it, when the option
`synthcheck.hosted` is `TRUE`, when the environment variable
`SYNTHCHECK_HOSTED` is `true`, or when the app detects shinyapps.io or
Posit Connect.

## Publish on Posit Connect Cloud

Connect Cloud publishes from a public GitHub repository. It reads
`deploy/app.R` and a `manifest.json` beside it, which lists the packages
and versions to install.

1.  **Install synthcheck from GitHub** on your computer, so the manifest
    records where the server gets it:

    ``` r

    remotes::install_github("okanbulut/synthcheck")
    install.packages(c("rsconnect", "shiny", "bslib", "ellmer", "callr",
                       "jsonlite", "cicerone", "writexl", "readxl", "later",
                       "promises", "polycor"))
    ```

2.  **Write the manifest** from the root of your clone of the
    repository, and commit it:

    ``` r

    rsconnect::writeManifest("deploy")
    ```

    This creates `deploy/manifest.json`. Commit and push it to GitHub.

3.  **Publish:** Sign in at
    [connect.posit.cloud](https://connect.posit.cloud) with GitHub,
    choose *Publish*, then *Shiny*, and pick the repository
    `okanbulut/synthcheck`, the branch `main` and the primary file
    `deploy/app.R`. Do not add API keys under the settings for secrets
    or environment variables: The app does not use them.

4.  **Try it:** Open the link Connect Cloud gives you, choose the mock
    provider and run a short pretest. Then paste your own key and add
    one cheap model, such as `claude-haiku-5-5` or `gpt-4.1-nano`.

## Updating the hosted app

The manifest pins the synthcheck version from the commit you installed.
After a new release, install synthcheck from GitHub again, run
`rsconnect::writeManifest("deploy")` again, commit the new manifest and
republish (or turn on publishing on each push in Connect Cloud).

## Limits worth knowing

- **Long runs:** A free server has little memory and stops an idle app.
  Keep hosted runs small (a few attempts and respondents) and run large
  studies in R on your own computer.
- **Costs:** Every call is charged to the visitor’s own key. The app
  shows the estimated cost before a paid run and asks to confirm.
- **Privacy:** Items, personas and answers are sent to the provider the
  visitor chooses, as they are in R.

The benchmark compares models and supports decisions about them. It does
not show that synthetic data can replace a field test.
