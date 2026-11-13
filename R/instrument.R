# Instruments, personas, model specifications and the prompts built from them.

#' Define an instrument for synthetic respondents
#'
#' `sc_instrument()` describes the survey that synthetic
#' respondents take: The items, the response scale and the instructions.
#' [generate_synthetic()] turns it into a prompt, and the item table works
#' as `items` in [authenticity_benchmark()].
#'
#' @param items a data frame with an `item` column (short names such as
#'   `"H1"`) and a `statement` column (the item text), plus optional
#'   `scale` (or `trait`), `facet` and `reverse` columns, as in
#'   [hexaco_items]. A character vector of statements also works; the items
#'   are then named `i1`, `i2`, and so on.
#' @param scale the lowest and highest response categories, for example
#'   `c(1, 5)`.
#' @param labels optional labels for the categories, one per category from
#'   lowest to highest. `NULL` uses agree-disagree labels for 5- and 7-point
#'   scales and labels the endpoints only otherwise.
#' @param instructions the instructions shown before the items.
#' @param name a short name for the instrument.
#' @return An object of class `sc_instrument`.
#' @seealso [sc_personas()], [generate_synthetic()]
#' @examples
#' hexaco <- sc_instrument(hexaco_items, scale = c(1, 7), name = "IPIP-HEXACO")
#' hexaco
#'
#' short <- sc_instrument(c("I am the life of the party.", "I sympathize with others."),
#'                        scale = c(1, 5))
#' short$items
#' @export
sc_instrument <- function(items, scale = c(1, 5), labels = NULL,
                          instructions = sc_default_instructions, name = "Instrument") {
  if (is.character(items)) {
    items <- data.frame(item = paste0("i", seq_along(items)), statement = items,
                        stringsAsFactors = FALSE)
  }
  if (!is.data.frame(items) || !"item" %in% names(items))
    stop("`items` must be a data frame with `item` and `statement` columns, or a character vector.",
         call. = FALSE)
  items <- as.data.frame(items, stringsAsFactors = FALSE)
  if (!"statement" %in% names(items)) {
    alt <- intersect(c("text", "stem", "question", "wording"), names(items))
    if (!length(alt)) stop("`items` needs a `statement` column with the item text.", call. = FALSE)
    items$statement <- items[[alt[1]]]
  }
  items$item <- as.character(items$item)
  items$statement <- as.character(items$statement)
  if (anyDuplicated(items$item)) stop("Item names must be unique.", call. = FALSE)
  if (any(is.na(items$item) | !nzchar(items$item))) stop("Every item needs a name.", call. = FALSE)
  if (!all(grepl("^[A-Za-z][A-Za-z0-9_.]*$", items$item)))
    stop("Item names must start with a letter and hold only letters, digits, `_` and `.`.",
         call. = FALSE)
  if ("reverse" %in% names(items)) {
    items$reverse <- as.logical(items$reverse)
    items$reverse[is.na(items$reverse)] <- FALSE
  }
  if (!"scale" %in% names(items) && "trait" %in% names(items)) items$scale <- items$trait
  scale <- as.integer(round(scale))
  if (length(scale) != 2L || anyNA(scale) || scale[2] <= scale[1])
    stop("`scale` must be two whole numbers, the lowest and highest category.", call. = FALSE)
  k <- scale[2] - scale[1] + 1L
  if (is.null(labels)) labels <- sc_default_labels(k)
  if (!is.null(labels) && length(labels) != k)
    stop(sprintf("`labels` must have one label per category (%d).", k), call. = FALSE)
  structure(list(items = as_tbl(items), min = scale[1], max = scale[2], labels = labels,
                 instructions = instructions, name = name),
            class = "sc_instrument")
}

#' @export
print.sc_instrument <- function(x, ...) {
  cat(sprintf("Instrument \"%s\": %d items, answers %d to %d.\n", x$name, nrow(x$items),
              x$min, x$max))
  if ("scale" %in% names(x$items))
    cat("Scales:", paste(unique(x$items$scale), collapse = ", "), "\n")
  n <- min(3L, nrow(x$items))
  for (i in seq_len(n)) cat(sprintf("  %s: %s\n", x$items$item[i], x$items$statement[i]))
  if (nrow(x$items) > n) cat(sprintf("  ... and %d more\n", nrow(x$items) - n))
  invisible(x)
}

sc_default_instructions <- paste(
  "Please read each statement and decide how much you agree or disagree with it.",
  "There are no right or wrong answers. Answer every statement.")

sc_default_labels <- function(k) {
  switch(as.character(k),
         "5" = c("Strongly disagree", "Disagree", "Neutral", "Agree", "Strongly agree"),
         "7" = c("Strongly disagree", "Disagree", "Slightly disagree", "Neither agree nor disagree",
                 "Slightly agree", "Agree", "Strongly agree"),
         NULL)
}

#' Define personas for synthetic respondents
#'
#' A persona describes the person a synthetic respondent
#' plays. It becomes the system prompt of each call in
#' [generate_synthetic()]. `sc_personas()` takes the descriptions directly,
#' and `sc_persona_grid()` builds them from every combination of a few
#' attributes.
#'
#' @param x a character vector of descriptions, or a data frame with a
#'   `description` column (and optionally `persona_id` and attribute
#'   columns, which are kept in the generated data).
#' @return A tibble of class `sc_personas` with `persona_id`, `description`
#'   and any attribute columns.
#' @seealso [sc_instrument()], [generate_synthetic()]
#' @examples
#' sc_personas(c("You are a 34-year-old nurse in Calgary.",
#'               "You are a 67-year-old retired farmer in rural Ontario."))
#'
#' sc_persona_grid(age = c(25, 45, 65), country = c("Canada", "the United States"),
#'                 template = "You are a {age}-year-old adult living in {country}.")
#' @export
sc_personas <- function(x) {
  if (inherits(x, "sc_personas")) return(x)
  if (is.character(x)) x <- data.frame(description = x, stringsAsFactors = FALSE)
  if (!is.data.frame(x) || !"description" %in% names(x))
    stop("`x` must be a character vector or a data frame with a `description` column.",
         call. = FALSE)
  x <- as.data.frame(x, stringsAsFactors = FALSE)
  x$description <- as.character(x$description)
  x <- x[!is.na(x$description) & nzchar(trimws(x$description)), , drop = FALSE]
  if (!nrow(x)) stop("No persona has a description.", call. = FALSE)
  if (!"persona_id" %in% names(x)) x$persona_id <- sprintf("p%03d", seq_len(nrow(x)))
  x$persona_id <- as.character(x$persona_id)
  if (anyDuplicated(x$persona_id)) stop("`persona_id` must be unique.", call. = FALSE)
  x <- x[c("persona_id", "description", setdiff(names(x), c("persona_id", "description")))]
  out <- as_tbl(x)
  class(out) <- c("sc_personas", class(out))
  out
}

#' @rdname sc_personas
#' @param ... named vectors of attribute values, for example
#'   `age = c(25, 45)`. Every combination becomes one persona.
#' @param template the description, with each attribute written as
#'   `{name}`.
#' @export
sc_persona_grid <- function(..., template) {
  att <- list(...)
  if (!length(att) || is.null(names(att)) || any(!nzchar(names(att))))
    stop("Give the attributes as named vectors, for example `age = c(25, 45)`.", call. = FALSE)
  g <- expand.grid(att, stringsAsFactors = FALSE, KEEP.OUT.ATTRS = FALSE)
  desc <- vapply(seq_len(nrow(g)), function(i) {
    d <- template
    for (a in names(att)) d <- gsub(paste0("{", a, "}"), as.character(g[[a]][i]), d, fixed = TRUE)
    d
  }, character(1))
  left <- regmatches(desc[1], gregexpr("\\{[A-Za-z0-9_.]+\\}", desc[1]))[[1]]
  if (length(left))
    stop("The template uses ", paste(left, collapse = ", "), " but no such attribute is given.",
         call. = FALSE)
  sc_personas(data.frame(description = desc, g, stringsAsFactors = FALSE))
}

#' Choose a language model for synthetic respondents
#'
#' `sc_model()` names a model and its settings for
#' [generate_synthetic()]. Anthropic, OpenAI and Ollama models are called
#' through the ellmer package. `provider = "mock"` gives random answers
#' without calling any model, for trying the workflow and the app.
#'
#' API keys are read from the `ANTHROPIC_API_KEY` and `OPENAI_API_KEY`
#' environment variables (set them in `.Renviron`, or with [Sys.setenv()]
#' for one session). They are never stored in the model specification or in
#' the saved data.
#'
#' @param provider `"anthropic"`, `"openai"`, `"ollama"` or `"mock"`.
#' @param model the model id, for example `"claude-haiku-5-5"`. `NULL` uses
#'   the provider's default (see [sc_default_models]).
#' @param temperature sampling temperature, or `NULL` to send none (some
#'   models do not take one).
#' @param name the label of the model in the data and the benchmark.
#'   `NULL` uses the model id.
#' @param base_url optional address of the API, for example an Ollama server
#'   on another machine.
#' @return An object of class `sc_model`.
#' @seealso [generate_synthetic()]
#' @examples
#' sc_model("anthropic", temperature = 1)
#' sc_model("ollama", "gemma3:27b", name = "Gemma 3 27B")
#' sc_model("mock")
#' @export
sc_model <- function(provider = c("anthropic", "openai", "ollama", "mock"), model = NULL,
                     temperature = 1, name = NULL, base_url = NULL) {
  provider <- match.arg(provider)
  if (is.null(model) || !nzchar(model)) model <- sc_default_models[[provider]]
  if (is.null(model) || !nzchar(model))
    stop("Give the model id for ", provider, ", for example one listed by `ollama list`.",
         call. = FALSE)
  if (!is.null(temperature) && (!is.numeric(temperature) || temperature < 0 || temperature > 2))
    stop("`temperature` must be between 0 and 2, or NULL.", call. = FALSE)
  if (is.null(name) || !nzchar(name)) name <- model
  structure(list(provider = provider, model = model, temperature = temperature, name = name,
                 base_url = base_url), class = "sc_model")
}

#' @export
print.sc_model <- function(x, ...) {
  cat(sprintf("%s (%s, model \"%s\", temperature %s)\n", x$name, x$provider, x$model,
              if (is.null(x$temperature)) "not sent" else format(x$temperature)))
  invisible(x)
}

#' Default model ids
#'
#' The model each provider uses when [sc_model()] gets no `model`: The
#' cheapest current model that takes a temperature (`claude-haiku-5-5` and
#' `gpt-4.1-nano`). OpenAI's `gpt-5-nano` costs less per input token but is
#' a reasoning model that takes no temperature. Ollama has no default: Use a
#' model installed on your machine (`ollama list`).
#'
#' @format A named list.
#' @examples
#' sc_default_models
#' @export
sc_default_models <- list(anthropic = "claude-haiku-5-5", openai = "gpt-4.1-nano",
                          ollama = NULL, mock = "mock")

#' Build the prompts for one synthetic respondent
#'
#' Shows exactly what [generate_synthetic()] sends: The
#' persona as the system prompt, and the instructions, response scale and
#' items as the user prompt.
#'
#' @param instrument an [sc_instrument()].
#' @param persona one persona description, or `NULL` for none.
#' @param items optional item names to include (a block of items).
#' @param n number of respondents asked for in one call (see `batch_size`
#'   in [generate_synthetic()]).
#' @return A list with `system` and `user`.
#' @examples
#' ins <- sc_instrument(hexaco_items[1:3, ], scale = c(1, 7))
#' cat(sc_prompt(ins, "You are a 30-year-old teacher.")$user)
#' @export
sc_prompt <- function(instrument, persona = NULL, items = NULL, n = 1L) {
  if (!inherits(instrument, "sc_instrument"))
    stop("`instrument` must be made with sc_instrument().", call. = FALSE)
  it <- instrument$items
  if (!is.null(items)) it <- it[match(items, it$item), , drop = FALSE]
  system <- if (is.null(persona) || is.na(persona) || !nzchar(trimws(persona))) {
    "You are taking part in a survey. Answer as a real person would."
  } else {
    paste0(trimws(persona), "\n\nYou are taking part in a survey. Stay in this role and answer ",
           "as this person would.")
  }
  cats <- seq(instrument$min, instrument$max)
  lab <- if (is.null(instrument$labels)) {
    sprintf("Answer with a whole number from %d (lowest) to %d (highest).", instrument$min,
            instrument$max)
  } else {
    paste0("Answer with a whole number from ", instrument$min, " to ", instrument$max, ":\n",
           paste(sprintf("%d = %s", cats, instrument$labels), collapse = "\n"))
  }
  user <- paste0(instrument$instructions, "\n\n", lab, "\n\nStatements:\n",
                 paste(sprintf("%s: %s", it$item, it$statement), collapse = "\n"),
                 "\n\nReturn one answer for every statement, keyed by its name (",
                 it$item[1], if (nrow(it) > 1) paste0(", ", it$item[2]), if (nrow(it) > 2) ", ...",
                 ").")
  if (n > 1L)
    user <- paste0(user, "\n\nAnswer as ", n, " different people who each fit the description. ",
                   "Give each person's answers as one element of `respondents`, ", n,
                   " elements in all. Each person answers independently of the others.")
  list(system = system, user = user)
}

#' Use an instrument that comes with synthcheck
#'
#' `sc_builtin_instrument()` returns one of the bundled instruments as an
#' [sc_instrument()], with its response scale, category labels and
#' instructions, ready for [generate_synthetic()], [synthetic_pretest()] or
#' [cognitive_interview()]. Each one comes with real responses for
#' [authenticity_benchmark()].
#'
#' Besides the long IPIP-HEXACO, three short instruments are included
#' because their items have well-documented problems. They let you check
#' whether the pretest, the interviews and the benchmark find what the
#' literature already knows:
#'
#' | `name` | Instrument | Items | Answers | Known problems | Real data |
#' |---|---|---|---|---|---|
#' | `"hexaco"` | IPIP-HEXACO | 240 | 1 to 7 | | [hexaco_real] |
#' | `"rses"` | Rosenberg Self-Esteem Scale | 10 | 1 to 4 | Negative-wording method factor | [rses_real] |
#' | `"dass21"` | DASS-21 | 21 | 1 to 4 | Disputed three-factor structure | [dass_real] |
#' | `"mini_ipip"` | Mini-IPIP | 20 | 1 to 5 | Poor fit, weak Intellect scale, reverse-keyed method effect | [mini_ipip_real] |
#'
#' The `issue` column of the item tables says, in one sentence, what has
#' been reported about each item; the help pages of the item tables give
#' the references.
#'
#' @param name the instrument: `"hexaco"`, `"rses"`, `"dass21"` or
#'   `"mini_ipip"`.
#' @param scales optional scale codes to keep, for example `c("H", "C")`
#'   for two HEXACO traits or `"D"` for DASS-21 Depression. `NULL` keeps all
#'   items.
#' @return An object of class `sc_instrument`.
#' @seealso [rses_items], [dass_items], [mini_ipip_items], [hexaco_items]
#' @examples
#' sc_builtin_instrument("rses")
#' dass <- sc_builtin_instrument("dass21", scales = c("A", "S"))
#' dass$labels
#' cat(sc_prompt(dass)$user)
#' @export
sc_builtin_instrument <- function(name = c("hexaco", "rses", "dass21", "mini_ipip"),
                                  scales = NULL) {
  name <- match.arg(name)
  b <- sc_builtin[[name]]
  items <- sc_builtin_items(name)
  if (!is.null(scales)) {
    bad <- setdiff(scales, items$scale)
    if (length(bad))
      stop(sprintf("Unknown scale%s for %s: %s. The scales are %s.", if (length(bad) > 1) "s" else "",
                   b$name, paste(bad, collapse = ", "), paste(unique(items$scale), collapse = ", ")),
           call. = FALSE)
    items <- items[items$scale %in% scales, , drop = FALSE]
  }
  sc_instrument(items, scale = b$range, labels = b$labels, instructions = b$instructions,
                name = b$name)
}

# The bundled instruments: Name, response range, labels, instructions and the
# names of the item table and the real data.
sc_builtin <- list(
  hexaco = list(name = "IPIP-HEXACO", range = c(1L, 7L), labels = NULL,
                instructions = sc_default_instructions, items = "hexaco_items",
                real = "hexaco_real", scale_col = "trait", default = c("H", "C")),
  rses = list(name = "Rosenberg Self-Esteem Scale", range = c(1L, 4L),
              labels = c("Strongly disagree", "Disagree", "Agree", "Strongly agree"),
              instructions = paste(
                "Below is a list of statements dealing with your general feelings about yourself.",
                "Please indicate how strongly you agree or disagree with each statement.",
                "There are no right or wrong answers. Answer every statement."),
              items = "rses_items", real = "rses_real", scale_col = "scale", default = "SE"),
  dass21 = list(name = "DASS-21", range = c(1L, 4L),
                labels = c("Did not apply to me at all",
                           "Applied to me to some degree, or some of the time",
                           "Applied to me to a considerable degree, or a good part of the time",
                           "Applied to me very much, or most of the time"),
                instructions = paste(
                  "Please read each statement and choose how much it applied to you over the past week.",
                  "There are no right or wrong answers. Do not spend too much time on any statement.",
                  "Answer every statement."),
                items = "dass_items", real = "dass_real", scale_col = "scale",
                default = c("D", "A", "S")),
  mini_ipip = list(name = "Mini-IPIP", range = c(1L, 5L), labels = NULL,
                   instructions = paste(
                     "Please read each statement and decide how much you agree or disagree that it",
                     "describes you as you generally are now. There are no right or wrong answers.",
                     "Answer every statement."),
                   items = "mini_ipip_items", real = "mini_ipip_real", scale_col = "scale",
                   default = c("E", "A", "C", "N", "I"))
)

# item table of a bundled instrument, with a `scale` column for every one
sc_builtin_items <- function(name) {
  items <- as.data.frame(switch(name,
                                hexaco = synthcheck::hexaco_items,
                                rses = synthcheck::rses_items,
                                dass21 = synthcheck::dass_items,
                                mini_ipip = synthcheck::mini_ipip_items))
  if (!"scale" %in% names(items)) items$scale <- items$trait
  items
}

sc_builtin_real <- function(name) {
  switch(name,
         hexaco = synthcheck::hexaco_real,
         rses = synthcheck::rses_real,
         dass21 = synthcheck::dass_real,
         mini_ipip = synthcheck::mini_ipip_real)
}

# named scale choices (label = code) of a bundled instrument
sc_builtin_scales <- function(name) {
  it <- sc_builtin_items(name)
  lab <- if ("trait_label" %in% names(it)) it$trait_label else it$scale_label
  u <- !duplicated(it$scale)
  out <- stats::setNames(it$scale[u], lab[u])
  ord <- sc_builtin[[name]]$default
  if (setequal(ord, out)) out[match(ord, out)] else out
}

# R code that selects the items of a bundled instrument
sc_builtin_items_code <- function(name, scales) {
  b <- sc_builtin[[name]]
  all <- sc_builtin_scales(name)
  if (is.null(scales) || setequal(scales, all)) return(sprintf("items <- %s", b$items))
  sprintf("items <- %s[%s$%s %%in%% c(%s), ]", b$items, b$items, b$scale_col,
          paste(sprintf('"%s"', scales), collapse = ", "))
}
