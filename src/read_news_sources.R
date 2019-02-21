
test2 = read.delim("/home/jnjoseph/projects/pa_text_analyses/data/raw/PATRIOT Act/Access World News/USA/News Sources", sep = "\t", header = FALSE)

test3 = paste(test2$V1, collapse = ", ")
