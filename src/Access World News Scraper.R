
#### Setup ####
library(rvest)
library(httr)
library(XML)
library(stringr)
library(lubridate)
source("src/phan.R")

# Base Wait Time
base_wait = 5

# Start at article
.start_article = 1

# URL For Search
# Replace page=0 with page number
var_url <- 'https://infoweb.newsbank.com/apps/news/results?page=1&p=AWNB&t=collection%3AAIN%21Access%2520International%2520News/stp%3ANewspaper%21Newspaper&sort=YMD_date%3AD&fld-nav-0=YMD_date&val-nav-0=2001%20-%202017&fld-base-0=alltext&maxresults=20&val-base-0=%22PATRIOT%20ACT%22'

# Set up Session
obj_session <- html_session(
  var_url, set_cookies(
    'JServSessionIdinfoweb'='tvdr22ww71.JS61a',
    'SSESSf5a897cf3b8f2872d0e6fe6c381635b0'='2vURm_2MxWK5eiWnhOfKaDJy1a_aAQNw1ehweQVo38w', 
    'has_js'='1'
    ))

#### Prepare to Scrape ####
# How many pages of results?
pages = html_text(html_nodes(obj_session, ".nb-showing-result-count"), trim = TRUE)
pages = str_match(pages, "of (\\b.+) Results")[2]
pages = as.numeric(gsub(pattern = ",", replacement = "", x = pages))

# Divide by 10, minus 1 beccause index on site starts at page 0
pages = ceiling(pages/10) - 1
print(paste0("There are ", pages, " pages of results."))

# Go to each page, and get link to print option
all_print = vector()

for(page in 0:pages){
  # Go to the page
  page_link = str_replace(var_url, "\\?page=[\\d]", paste0("\\?page=", page))
  
  # Wait!
  this_wait = base_wait + sample(-2:2, 1)
  print(paste0("Waiting for ", this_wait, " seconds."))
  Sys.sleep(this_wait)
  
  # Go to next page
  print(paste0("Going to page ", page, " of ", pages, "."))
  obj_session = jump_to(obj_session, page_link)
  
  # Get all print links
  print_links = html_nodes(obj_session, ".first+ li .doc-action")
  print_links = html_attr(print_links, "href")
  
  all_print = c(all_print, print_links)
  
  # Long Pause
  pause_prob = sample(1:100, 1)
  if(pause_prob > 90){print(paste0("Sipping tea.")); Sys.sleep(sample(15:40, 1))}
  
}
rm(print_links, this_wait, page, page_link)

all_print = str_c("https://infoweb.newsbank.com", all_print)

meta_out = c(
  "Source = Access World News",
  paste0("var_url = ", var_url),
  paste0("base_wait = ", base_wait),
  paste0("Pages returned = ", pages),
  paste0("Articles returned = ", length(all_print)),
  "\n",
  "Links to articles:",
  all_print
)
writeLines(meta_out, con = "scrape_out/META.txt")

#### Scrape the articles ####
Sys.sleep(5)

for(article in .start_article:length(all_print)){
  # Go to article
  obj_session = jump_to(obj_session, all_print[article])
  
  # Wait!
  this_wait = base_wait + sample(3:8, 1)
  print(paste0("Waiting for ", this_wait, " seconds."))
  Sys.sleep(this_wait)
  
  # Scrape!
  print(paste0("Scraping article #", article, " of ", length(all_print), "."))
  js_scrape(all_print[article], as.character(article))
  print(paste0("        Saved!\n"))
  
  # Long Pause
  pause_prob = sample(1:100, 1)
  if(pause_prob > 90){print(paste0("Sipping tea.")); Sys.sleep(sample(10:20, 1))}
}

rm(meta_out, pages, this_wait, base_wait)

#### Parse ####

corpus_df = data.frame("title" = NA, "author.byline" = NA, "section" = NA, "date" = NA, "source.name" = NA, "source.loc" = NA, "text" = NA, "recordnum" = NA, stringsAsFactors = FALSE)

for(i in 1:article){
  
  tryCatch({
  
  print(paste0("Parsing article #", i, " of ", article, "."))
  current = read_html(paste0("scrape_out/raw/", i, ".html"))
  
  # Clean data/source
  source = html_nodes(current, ".source") %>% html_text()
  source_df = str_match(source, "^(.+)\\s+\\((.+)\\)\\s+-\\s+(.+)")
  
  date = source_df[4]
  source.name = source_df[2]
  source.loc = source_df[3]
  
  # Clean Author/byline and section
  meta = html_nodes(current, ".moredetails .metadata") %>% html_text()
  meta_df = str_match(meta, "Author\\/Byline:\\s+(.+)Section:\\s+(.+)")
  
  corpus_df[i, "title"] = html_nodes(current, "#nb-doc-print-container h2") %>% html_text()
  corpus_df[i, "author.byline"] = meta_df[2]
  corpus_df[i, "section"] = meta_df[3]
  corpus_df[i, "date"] = date
  corpus_df[i, "source.name"] = source.name
  corpus_df[i, "source.loc"] = source.loc
  corpus_df[i, "text"] = html_nodes(current, ".body") %>% html_text()
  corpus_df[i, "recordnum"] = html_nodes(current, ".record .val") %>% html_text()

  }, error = function(e) print(e))
  
}

# Convert date to lubridate
corpus_df$date = mdy(corpus_df$date)

# Save!
write.csv(corpus_df, "scrape_out/parsed/parsed.csv", row.names = FALSE)

