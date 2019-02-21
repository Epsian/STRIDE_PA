# Make sentiment Vis

library(sentimentr)

.data_loc = "data/parsed/PATRIOT Act/Access World News/USA/parsed_clean.csv"
news <- read.csv(.data_loc, header = TRUE, stringsAsFactors = FALSE)

news_sent = get_sentences(news$text)

test = sentiment_by(news_sent)

highlight(test, file = "highlight.html")
