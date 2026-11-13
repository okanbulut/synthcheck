# Getting an API key for OpenAI or Claude

To generate synthetic respondents with OpenAI or Anthropic (Claude)
models, synthcheck needs an **API key**: A long secret text that tells
the provider who is calling and whose account pays for the calls. This
article walks through getting one from each provider, adding credit,
keeping the key private and capping what you can spend. It takes about
ten minutes per provider.

You do not need a key to try synthcheck. The **Mock** provider gives
random answers for free, the built-in `hexaco_llm` holds answers from
six models, and **Ollama** runs open models on your own computer at no
cost. See the [app
demos](https://www.okanbulut.com/synthcheck/articles/app-demo.md) for
runs without a key.

## Before you start

- **The API is separate from the chat apps.** A ChatGPT Plus or a Claude
  Pro or Max subscription does not include API use. The API has its own
  account page, its own billing and pay-as-you-go prices.
- **You pay per call.** Each synthetic respondent is one call (one per
  block of items when an instrument is split). The price depends on the
  model and the length of the prompt and the answer. synthcheck’s
  default models are the cheapest of each provider, and the app shows
  the estimated cost before every paid run.
- **Start with a small credit.** A few dollars are enough to try a real
  model on a short scale. Add more once you know what a full run costs.

The provider pages below change from time to time, so a button may have
a slightly different name. The steps stay the same.

## OpenAI

1.  **Sign up.** Go to [openai.com/api](https://openai.com/api/) and
    choose to sign up or log in. This opens the OpenAI platform
    (`platform.openai.com`), which is the API side of OpenAI. You can
    use the same login as ChatGPT.
2.  **Add credit.** Open **Settings**, then **Billing**, add a payment
    method and buy credit. OpenAI uses prepaid credit: Calls stop when
    the credit runs out, unless you switch on automatic recharge. Leave
    automatic recharge off at first.
3.  **Create a key.** Open the **API keys** page
    ([platform.openai.com/api-keys](https://platform.openai.com/api-keys)),
    click **Create new secret key**, give it a name such as
    *synthcheck*, and copy it. The key starts with `sk-`. OpenAI shows
    it only once: If you lose it, delete it and create a new one.
4.  **Set a limit.** Under **Settings**, the **Limits** page (and the
    budget of each project) lets you set a monthly budget and an email
    alert. A small budget is a good guard against a run that is larger
    than you meant.

## Claude (Anthropic)

1.  **Sign up.** Go to the Claude Console at
    [platform.claude.com/dashboard](https://platform.claude.com/dashboard)
    and create an account. The Console is the API side of Anthropic. It
    is separate from the Claude chat app, though you can sign in with
    the same email.
2.  **Add credit.** Open **Settings**, then **Billing**
    ([platform.claude.com/settings/billing](https://platform.claude.com/settings/billing)),
    and click **Buy credits**. Calls stop when the credit runs out,
    unless you switch on auto-reload. Leave auto-reload off at first.
3.  **Create a key.** Open **Settings**, then **API keys**, click
    **Create key**, name it *synthcheck* and copy it. The key starts
    with `sk-ant-`. The Console shows it only once.
4.  **Set a limit.** The **Limits** page under **Settings** shows the
    spend limit of your account, and lets you set a lower monthly limit
    of your own.

## Using the key in synthcheck

There are two ways to give synthcheck the key.

**In the app.** Paste the key into **Anthropic API key** or **OpenAI API
key** on the Models tab. A typed key stays in memory for that session
only. It is never written to the saved data, the run settings, the
report or the R script, so you paste it again the next time you open the
app.

**In `.Renviron` (recommended).** Save the key once, and both the app
and your R code find it without showing it. Open the file with

``` r

usethis::edit_r_environ()   # or file.edit("~/.Renviron")
```

add one line per provider, and restart R:

    OPENAI_API_KEY=sk-...
    ANTHROPIC_API_KEY=sk-ant-...

The app then says that it found the key, and `sc_model("openai")` and
`sc_model("anthropic")` use it in code. Check that R sees it with
`nzchar(Sys.getenv("OPENAI_API_KEY"))`, which should be `TRUE`.

Before the first real run, start small: One attempt and two respondents
per persona. In the app, **Estimate run time** sends one test call per
model, which checks that the key and the model id work. In code,
[`estimate_cost()`](https://www.okanbulut.com/synthcheck/reference/estimate_cost.md)
shows what a run is likely to cost:

``` r

ins <- sc_builtin_instrument("rses")
estimate_cost(ins, list(sc_model("anthropic"), sc_model("openai")),
              attempts = 1, respondents = 20)
```

Every answer is kept in synthcheck’s response cache, so running the same
settings again costs nothing (see [the response
cache](https://www.okanbulut.com/synthcheck/articles/generate.html#the-response-cache)).

## Keeping the key private

An API key works like a password that can spend your money.

- **Do not share it.** Do not paste it into emails, chats, shared
  documents or screenshots.
- **Keep it out of code and Git.** Do not write it into an R script, an
  R Markdown file or a Shiny app. `.Renviron` in your home folder is
  outside your projects. If you keep a project-level `.Renviron`, add it
  to `.gitignore`.
- **Run the app on your own computer.** Do not deploy the app with a
  typed key on a shared server.
- **One key per use.** A separate key named *synthcheck* can be deleted
  without breaking anything else.
- **If a key leaks, delete it.** Delete it on the provider’s API keys
  page straight away and create a new one. Then check the usage page for
  calls you did not make.

## If something goes wrong

- **“Invalid API key” or 401:** The key was copied with a missing
  character or a space, or it was deleted. Create a new one.
- **“Insufficient credit”, “quota” or 429 right away:** The account has
  no credit yet, or the budget is reached. Add credit or raise the
  limit. A new account can take a few minutes before the first paid call
  goes through.
- **429 during a run:** The provider is limiting how many calls you make
  at once. Lower **Calls at the same time** on the Models tab
  (`parallel` in
  [`generate_synthetic()`](https://www.okanbulut.com/synthcheck/reference/generate_synthetic.md)).
- **The app does not see the key from `.Renviron`:** Restart R after you
  edit the file, and start the app again.
