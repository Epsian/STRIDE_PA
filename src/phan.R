# Made with help from: http://www.rladiesnyc.org/post/scraping-javascript-websites-in-r/

js_scrape <- function(url,
                      outname,
                      js_path = "scripts/scrape.js", 
                      phantompath = "/home/jnjoseph/programs/phantomjs-2.1.1-linux-x86_64/bin/phantomjs"){
  
  # this section will replace the url in scrape.js to whatever you want 
  lines <- readLines(js_path)
  lines[1] <- paste0("var url ='", url ,"';")
  lines[11] = paste0("               fs.write('scrape_out/raw/", outname, ".html', page.content, 'w');")
  writeLines(lines, js_path)
  
  command = paste(phantompath, js_path, sep = " ")
  system(command)
}
