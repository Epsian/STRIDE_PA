
#### Setup ####
library(XML)
library(rvest)
library(httr)
target_directory = "/home/jnjoseph/projects/pa_text_analyses/scrape_out/raw"

#### Data Load ####
# Find all the files!
file_list = list.files(path = target_directory)

missing = character()
for(i in 1:length(file_list)){
  print(i)
  current = read_html(paste0(target_directory, "/", file_list[i]))
  title = html_text(html_node(current, "#nb-doc-print-container h2"))
  if(is.na(title)){c(missing, i); print(paste0(i, " was a login screen!"))}
}

#### 