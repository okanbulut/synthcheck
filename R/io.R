# Saving, reading and reshaping generated synthetic data.

#' Save and read synthetic respondents
#'
#' **Experimental.** `write_synthetic()` saves a data frame of synthetic
#' respondents (for example from [generate_synthetic()]) as CSV, JSON, RDS
#' or Excel. `read_synthetic()` reads one file, or every data file in a
#' folder written by [generate_synthetic()], back into one tibble.
#'
#' @param data a data frame with one row per respondent.
#' @param path a file name, or for `read_synthetic()` a file or a folder.
#' @param format `"csv"` (the default), `"json"`, `"rds"` or `"xlsx"`
#'   (needs writexl). `NULL` takes it from the file extension.
#' @return `write_synthetic()` returns `path` invisibly. `read_synthetic()`
#'   returns a tibble.
#' @seealso [generate_synthetic()], [as_synthetic_list()]
#' @examples
#' ins <- sc_instrument(c("I like parties.", "I keep my desk tidy."), scale = c(1, 5))
#' syn <- generate_synthetic(ins, sc_model("mock"), attempts = 2, respondents = 5)
#' f <- tempfile(fileext = ".csv")
#' write_synthetic(syn, f)
#' read_synthetic(f)
#' @export
write_synthetic <- function(data, path, format = NULL) {
  format <- sc_format(path, format)
  data <- as.data.frame(data)
  switch(format,
         csv = utils::write.csv(data, path, row.names = FALSE, na = ""),
         json = {
           sc_need("jsonlite", "to write JSON")
           jsonlite::write_json(data, path, dataframe = "rows", na = "null", digits = NA)
         },
         rds = saveRDS(data, path),
         xlsx = {
           sc_need("writexl", "to write Excel files")
           writexl::write_xlsx(data, path)
         })
  invisible(path)
}

#' @rdname write_synthetic
#' @export
read_synthetic <- function(path, format = NULL) {
  if (length(path) == 1L && dir.exists(path)) {
    files <- list.files(path, pattern = "\\.(csv|json|rds|xlsx)$", full.names = TRUE)
    files <- files[!basename(files) %in% c("run.json", "prompts.json", "log.csv", "progress.json")]
    if (!length(files)) stop("No data files in ", path, ".", call. = FALSE)
    parts <- lapply(files, read_synthetic)
    cols <- unique(unlist(lapply(parts, names)))
    parts <- lapply(parts, function(d) { d <- as.data.frame(d); d[setdiff(cols, names(d))] <- NA; d[cols] })
    out <- do.call(rbind, parts)
    if (all(c("model", "attempt") %in% names(out))) out <- out[order(out$model, out$attempt), ]
    return(as_tbl(out))
  }
  if (!file.exists(path)) stop("No file ", path, ".", call. = FALSE)
  format <- sc_format(path, format)
  d <- switch(format,
              csv = utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE),
              json = {
                sc_need("jsonlite", "to read JSON")
                jsonlite::fromJSON(path, simplifyVector = TRUE)
              },
              rds = readRDS(path),
              xlsx = {
                sc_need("readxl", "to read Excel files")
                as.data.frame(readxl::read_excel(path))
              })
  as_tbl(as.data.frame(d, stringsAsFactors = FALSE))
}

#' Turn a table of synthetic respondents into benchmark input
#'
#' **Experimental.** [authenticity_benchmark()], [synthetic_behaviour()]
#' and [synthetic_coverage()] take a named list with one element per model,
#' each a list of attempts. `as_synthetic_list()` splits a long table, such
#' as the result of [generate_synthetic()] or [hexaco_llm], into that list.
#'
#' @param data a data frame with one row per respondent.
#' @param model,attempt the columns that name the model and the attempt.
#' @param items optional item columns to keep. `NULL` keeps all columns.
#' @return A named list of lists of data frames.
#' @examples
#' ca <- hexaco_llm[hexaco_llm$country == "Canada" & hexaco_llm$attempt <= 2, ]
#' syn <- as_synthetic_list(ca)
#' names(syn)
#' lengths(syn)
#' @export
as_synthetic_list <- function(data, model = "model", attempt = "attempt", items = NULL) {
  data <- as.data.frame(data)
  if (!model %in% names(data)) stop("`data` has no column `", model, "`.", call. = FALSE)
  if (!attempt %in% names(data)) data[[attempt]] <- 1L
  if (!is.null(items)) {
    miss <- setdiff(items, names(data))
    if (length(miss)) stop("Items not in `data`: ", paste(utils::head(miss, 5), collapse = ", "),
                           ".", call. = FALSE)
  }
  out <- lapply(split(data, data[[model]], drop = TRUE), function(m) {
    a <- split(m, m[[attempt]], drop = TRUE)
    a <- a[order(suppressWarnings(as.numeric(names(a))), names(a))]
    lapply(a, function(d) { rownames(d) <- NULL; if (is.null(items)) d else d[items] })
  })
  out
}

sc_format <- function(path, format) {
  if (is.null(format)) format <- tolower(tools::file_ext(path))
  if (format == "xls") stop("Save Excel files as .xlsx.", call. = FALSE)
  if (!format %in% c("csv", "json", "rds", "xlsx"))
    stop("`format` must be \"csv\", \"json\", \"rds\" or \"xlsx\".", call. = FALSE)
  format
}
