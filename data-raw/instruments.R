# Builds the three short instruments with well-documented item problems:
# rses_items/rses_real, dass_items/dass_real and mini_ipip_items/mini_ipip_real.
# Download the raw files from the Open-Source Psychometrics Project,
# <https://openpsychometrics.org/_rawdata/>, unzip them into one folder and run
# this script from that folder; set pkg_dir to the package folder:
#   RSE.zip                     -> RSE/data.csv (Rosenberg Self-Esteem Scale)
#   DASS_data_21.02.19.zip      -> DASS_data_21.02.19/data.csv (DASS-42)
#   IPIP-FFM-data-8Nov2018.zip  -> IPIP-FFM-data-8Nov2018/data-final.csv
pkg_dir <- "synthcheck"
set.seed(20261113)

clean_age <- function(a) { a <- suppressWarnings(as.integer(a)); a[!a %in% 13:99] <- NA_integer_; a }
clean_country <- function(x) {
  x <- toupper(trimws(as.character(x)))
  x[!grepl("^[A-Z]{2}$", x)] <- NA_character_
  x
}
items_in <- function(d, cols, k) {
  as.data.frame(lapply(d[cols], function(v) {
    v <- suppressWarnings(as.integer(v)); v[!v %in% seq_len(k)] <- NA_integer_; v
  }))
}
gender_lab <- function(g) factor(c("Male", "Female", "Other")[match(as.integer(g), 1:3)],
                                 levels = c("Male", "Female", "Other"))

# ---- Rosenberg Self-Esteem Scale -------------------------------------------
rses_items <- data.frame(
  item = paste0("RSE", 1:10),
  scale = "SE", scale_label = "Self-esteem",
  statement = c(
    "I feel that I am a person of worth, at least on an equal plane with others.",
    "I feel that I have a number of good qualities.",
    "All in all, I am inclined to feel that I am a failure.",
    "I am able to do things as well as most other people.",
    "I feel I do not have much to be proud of.",
    "I take a positive attitude toward myself.",
    "On the whole, I am satisfied with myself.",
    "I wish I could have more respect for myself.",
    "I certainly feel useless at times.",
    "At times I think I am no good at all."),
  reverse = 1:10 %in% c(3, 5, 8, 9, 10),
  stringsAsFactors = FALSE)
rses_items$issue <- ifelse(rses_items$reverse,
  "Negatively worded: Part of the negative-wording method factor.", NA_character_)
rses_items$issue[8] <- paste("Negatively worded, and often the weakest item: A wish for more",
                             "self-respect can be read as ambition rather than low self-esteem.")
r <- read.delim("RSE/data.csv", check.names = FALSE)
rx <- items_in(r, paste0("Q", 1:10), 4); names(rx) <- rses_items$item
rses_real <- data.frame(country = clean_country(r$country), gender = gender_lab(r$gender),
                        age = clean_age(r$age), rx, check.names = FALSE)

# ---- DASS-21 (from the 42-item DASS) ---------------------------------------
# DASS-21 item k is DASS-42 item q42[k] (Lovibond & Lovibond, 1995).
q42 <- c(22, 2, 3, 4, 42, 6, 41, 12, 40, 10, 39, 8, 26, 35, 28, 31, 17, 18, 25, 20, 38)
sub <- c("S", "A", "D", "A", "D", "S", "A", "S", "A", "D", "S", "S", "D", "S", "A", "D", "D",
         "S", "A", "A", "D")
dass_items <- data.frame(
  item = paste0("DASS", 1:21), scale = sub,
  scale_label = c(D = "Depression", A = "Anxiety", S = "Stress")[sub],
  statement = c(
    "I found it hard to wind down.",
    "I was aware of dryness of my mouth.",
    "I couldn't seem to experience any positive feeling at all.",
    "I experienced breathing difficulty (eg, excessively rapid breathing, breathlessness in the absence of physical exertion).",
    "I found it difficult to work up the initiative to do things.",
    "I tended to over-react to situations.",
    "I experienced trembling (eg, in the hands).",
    "I felt that I was using a lot of nervous energy.",
    "I was worried about situations in which I might panic and make a fool of myself.",
    "I felt that I had nothing to look forward to.",
    "I found myself getting agitated.",
    "I found it difficult to relax.",
    "I felt down-hearted and blue.",
    "I was intolerant of anything that kept me from getting on with what I was doing.",
    "I felt I was close to panic.",
    "I was unable to become enthusiastic about anything.",
    "I felt I wasn't worth much as a person.",
    "I felt that I was rather touchy.",
    "I was aware of the action of my heart in the absence of physical exertion (eg, sense of heart rate increase, heart missing a beat).",
    "I felt scared without any good reason.",
    "I felt that life was meaningless."),
  reverse = FALSE, dass42 = paste0("Q", q42), stringsAsFactors = FALSE)
rownames(dass_items) <- NULL
dass_items$issue <- NA_character_
dass_items$issue[dass_items$item %in% c("DASS2", "DASS4", "DASS7", "DASS19")] <-
  "Somatic anxiety item: Often loads weakly and can reflect physical illness."
dass_items$issue[dass_items$item %in% c("DASS4", "DASS19")] <- paste(
  "Somatic anxiety item with a long stem and examples in brackets: Often loads weakly.")
dass_items$issue[dass_items$scale == "S"] <-
  "Stress item: Stress and Anxiety overlap, so it may load on a general distress factor."
d <- read.delim("DASS_data_21.02.19/data.csv", check.names = FALSE)
dx <- items_in(d, paste0(dass_items$dass42, "A"), 4); names(dx) <- dass_items$item
dass_real <- data.frame(country = clean_country(d$country), gender = gender_lab(d$gender),
                        age = clean_age(d$age), dx, check.names = FALSE)

# ---- Mini-IPIP (from the 50 IPIP Big-Five Factor Markers) -------------------
# Donnellan, Oswald, Baird & Lucas (2006); item codes as in the IPIP-FFM file.
mini_ipip_items <- data.frame(
  item = c("EXT1", "EXT7", "EXT2", "EXT4", "AGR4", "AGR9", "AGR5", "AGR7",
           "CSN5", "CSN7", "CSN6", "CSN4", "EST8", "EST6", "EST2", "EST4",
           "OPN3", "OPN4", "OPN2", "OPN6"),
  scale = rep(c("E", "A", "C", "N", "I"), each = 4),
  scale_label = rep(c("Extraversion", "Agreeableness", "Conscientiousness", "Neuroticism",
                      "Intellect/Imagination"), each = 4),
  statement = c(
    "I am the life of the party.", "I talk to a lot of different people at parties.",
    "I don't talk a lot.", "I keep in the background.",
    "I sympathize with others' feelings.", "I feel others' emotions.",
    "I am not interested in other people's problems.", "I am not really interested in others.",
    "I get chores done right away.", "I like order.",
    "I often forget to put things back in their proper place.", "I make a mess of things.",
    "I have frequent mood swings.", "I get upset easily.",
    "I am relaxed most of the time.", "I seldom feel blue.",
    "I have a vivid imagination.", "I am not interested in abstract ideas.",
    "I have difficulty understanding abstract ideas.", "I do not have a good imagination."),
  reverse = rep(c(FALSE, FALSE, TRUE, TRUE), 5), stringsAsFactors = FALSE)
mini_ipip_items$reverse[mini_ipip_items$item %in% c("OPN3", "OPN4", "OPN2", "OPN6")] <-
  c(FALSE, TRUE, TRUE, TRUE)
mini_ipip_items$issue <- ifelse(mini_ipip_items$reverse,
  "Reverse-keyed: Shares a method factor with the other reverse-keyed items.", NA_character_)
mini_ipip_items$issue[mini_ipip_items$scale == "I"] <- paste(
  "Intellect/Imagination item: The scale is often the least reliable and mixes",
  "imagination with interest in abstract ideas.")
mini_ipip_items$issue[mini_ipip_items$item %in% c("OPN2", "OPN4")] <- paste(
  "Intellect/Imagination item about abstract ideas: Near-duplicate wording of",
  "the other abstract-ideas item, so their residuals correlate.")
f <- read.delim("IPIP-FFM-data-8Nov2018/data-final.csv", check.names = FALSE)
f <- f[f$IPC == 1, ]  # one record per network address, as the codebook advises
fx <- items_in(f, mini_ipip_items$item, 5)
ok <- rowSums(is.na(fx)) == 0
keep <- sample(which(ok), 20000)
mini_ipip_real <- data.frame(country = clean_country(f$country[keep]), fx[keep, ],
                             check.names = FALSE)

for (nm in c("rses_real", "dass_real", "mini_ipip_real")) {
  x <- get(nm); rownames(x) <- NULL; assign(nm, x)
}
print(sapply(list(rses = rses_real, dass = dass_real, mini = mini_ipip_real), dim))
for (nm in c("rses_items", "rses_real", "dass_items", "dass_real", "mini_ipip_items", "mini_ipip_real"))
  save(list = nm, file = file.path(pkg_dir, "data", paste0(nm, ".rda")),
       compress = "xz", compression_level = 9)
