# GOAL: To create a clean text set from scraped news articles for topic modeling

#### Setup ####
library(stringr)
source("src/tree_tagger.R")

# What data do we want to clean?
.data_loc = "/home/jnjoseph/projects/pa_text_analyses/data/parsed/PATRIOT Act/Access World News/USA/parsed.csv"

# Where to save?
.out_loc = str_replace(.data_loc, "parsed\\.csv$", "parsed_clean.csv")

#### Data Load ####
parsed = read.csv(.data_loc, header = TRUE, stringsAsFactors = FALSE)

#### Clean ####
# Convert to UTF-8
parsed$clean_text <- iconv(parsed$text,"WINDOWS-1252","UTF-8")

# to lower
parsed$clean_text <- tolower(parsed$clean_text)

# Remove copies
parsed = parsed[!duplicated(parsed$text), ]

# remove 's

# Replace Patriot act
parsed$clean_text = str_replace_all(parsed$clean_text, "(?:usa)?\\s?patriot\\sact", " patriotact")

# replace national security letters
parsed$clean_text = str_replace_all(parsed$clean_text, "(?:national)?\\s?security\\sletter[s]?|NSLs?", " nationalsecurityletters")

# Remove URLs
parsed$clean_text = str_remove_all(parsed$clean_text, "(http:\\/\\/www\\.|https:\\/\\/www\\.|http:\\/\\/|https:\\/\\/)?[a-z0-9]+([\\-\\.]{1}[a-z0-9]+)*\\.[a-z]{2,5}(:[0-9]{1,5})?(\\/.*)?")

# Remove entertainment section, but leave those with section == NA
parsed = parsed[!str_detect(parsed$section, "Entertainment") | is.na(parsed$section),]

#### Lematization ####
# Start up a parallel cluster
parallelCluster <- makeCluster(detectCores() - 1, outfile = "")
print(parallelCluster)
registerDoParallel(parallelCluster)

on.exit({
  stopImplicitCluster()
  stopCluster(parallelCluster)
  rm(parallelCluster)
})

parsed$lemed = GSRLemPar(parsed$clean_text)
parsed$lemed[parsed$lemed == "na"] = NA

# Clean @card@ things
parsed$lemed = str_remove_all(parsed$lemed, "\\@card\\@")

# -------------------------------------------------------
# Should I do this? Removing negations and possessives

# Remove 's
parsed$lemed = str_remove_all(parsed$lemed, "\\'s")

# Remove n't
parsed$lemed = str_remove_all(parsed$lemed, "n\\'t")

# Remove '
parsed$lemed = str_remove_all(parsed$lemed, "\\'")

# -------------------------------------------------------

# Close Clusters
stopImplicitCluster()
stopCluster(parallelCluster)
rm(parallelCluster)

#### Save ####
write.csv(parsed, .out_loc, row.names = FALSE)
