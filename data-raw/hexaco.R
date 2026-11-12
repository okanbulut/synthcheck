# Builds hexaco_real, hexaco_llm and hexaco_items from the study files.
# Run from the folder that holds "Real Data", "LLM Data" (the four open-weight
# models) and "New Data" (Claude Haiku 5.5 and the GPT-4o folder, whose files
# are CSV text with an .xls ending, named like "hexaco_canada_1 (5).xls", and
# log gpt-4.1-mini as the model); set pkg_dir to the package folder.
pkg_dir <- "synthcheck"
items <- read.csv("Real Data/HEXACO Items.csv", stringsAsFactors = FALSE)
real <- read.csv("Real Data/HEXACO Responses.csv", check.names = FALSE, fileEncoding = "UTF-8-BOM")
ids <- items$item
cat(setdiff(names(real), ids), "\n")
model_id <- c("Gemma 4 26B" = "gemma-4-26b-a4b", "GPT-OSS-120B" = "gpt-oss-120b",
              "Qwen 3.8 27B" = "qwen38-27b", "Qwen 3.5 122B" = "qwen35-122b",
              "Claude Haiku 5.5" = "claude-haiku-5-5", "GPT-4.1 mini" = "gpt-4.1-mini")
llm_file <- function(m, slug, r) {
  if (m == "Claude Haiku 5.5") return(sprintf("New Data/%s/hexaco_%s_%d.csv", m, slug, r))
  if (m == "GPT-4.1 mini") {
    f <- Sys.glob(sprintf("New Data/GPT-4o/hexaco_%s_%d (*).xls", slug, r))
    stopifnot(length(f) == 1)
    return(f)
  }
  sprintf("LLM Data/%s/hexaco_%s_%d.csv", m, slug, r)
}
cslug <- c("Canada" = "canada", "Great Britain" = "great_britain", "United States" = "united_states")
out <- list()
for (m in names(model_id)) for (cn in names(cslug)) for (r in 1:10) {
  d <- read.csv(llm_file(m, cslug[[cn]], r), check.names = FALSE)
  d <- d[d$model == model_id[[m]], ]  # drops rows logged under another model
  x <- as.data.frame(lapply(d[ids], as.integer))
  out[[length(out) + 1]] <- data.frame(model = m, country = cn, attempt = r, x, check.names = FALSE)
}
llm <- do.call(rbind, out)
llm$model <- factor(llm$model, levels = names(model_id)); llm$country <- factor(llm$country)
rx <- as.data.frame(lapply(real[ids], function(v) { v <- as.integer(v); v[!v %in% 1:7] <- NA_integer_; v }))
cmap <- c(CA = "Canada", GB = "Great Britain", US = "United States")
keep <- real$country %in% names(cmap)
hexaco_real <- data.frame(country = factor(cmap[real$country[keep]]), rx[keep, ], check.names = FALSE)
rownames(hexaco_real) <- NULL; rownames(llm) <- NULL
hexaco_llm <- llm
hexaco_items <- data.frame(item = ids, trait = items$trait, trait_label = items$trait_label,
  facet = items$facet, facet_label = items$facet_label, statement = items$statement,
  reverse = items$reverse_scoring == "yes", stringsAsFactors = FALSE)
print(dim(hexaco_real)); print(dim(hexaco_llm)); print(table(hexaco_llm$model)); print(sum(is.na(hexaco_real[ids])))
for (nm in c("hexaco_real", "hexaco_llm", "hexaco_items"))
  save(list = nm, file = file.path(pkg_dir, "data", paste0(nm, ".rda")),
       compress = "xz", compression_level = 9)
