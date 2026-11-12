# Builds hexaco_real, hexaco_llm and hexaco_items from the study files.
# Run from the folder that holds "Real Data" and "LLM Data"; set pkg_dir to
# the package folder.
pkg_dir <- "synthcheck"
items <- read.csv("Real Data/HEXACO Items.csv", stringsAsFactors = FALSE)
real <- read.csv("Real Data/HEXACO Responses.csv", check.names = FALSE, fileEncoding = "UTF-8-BOM")
ids <- items$item
cat(setdiff(names(real), ids), "\n")
model_id <- c("Gemma 4 26B" = "gemma-4-26b-a4b", "GPT-OSS-120B" = "gpt-oss-120b",
              "Qwen 3.8 27B" = "qwen38-27b", "Qwen 3.5 122B" = "qwen35-122b")
cslug <- c("Canada" = "canada", "Great Britain" = "great_britain", "United States" = "united_states")
out <- list()
for (m in names(model_id)) for (cn in names(cslug)) for (r in 1:10) {
  d <- read.csv(sprintf("LLM Data/%s/hexaco_%s_%d.csv", m, cslug[[cn]], r), check.names = FALSE)
  d <- d[d$model == model_id[[m]], ]
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
