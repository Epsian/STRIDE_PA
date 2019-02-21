
#### Setup ####

library(plotly)
library(lubridate)

parsed_loc = c(
  "US Metro Majors" = "data/parsed/PATRIOT Act/Access World News/Major Metro Titles/parsed.csv",
  "USA Papers" = "data/parsed/PATRIOT Act/Access World News/USA/parsed.csv")

#### Data Load ####

parsed = lapply(parsed_loc, FUN = function(x){
  current = read.csv(x, header = TRUE, stringsAsFactors = FALSE)
  current$date = as_date(current$date)
  current$month = floor_date(current$date, "month")
  return(current)
})

# Get counts of occurances in parsed file
month_tabs = lapply(parsed, FUN = function(x){
  current = as.data.frame(table(x$month))
  current$Var1 = as_date(current$Var1)
  return(current)
})

# Create full range of interest
plot_df = lapply(month_tabs, FUN = function(x){
  df = data.frame("month" = seq.Date(as_date("2001-9-1"), as_date("2016-1-1"), by = "month"), "Freq" = 0)
  df$Freq = x[match(df$month, x$Var1), "Freq"]
  df$Freq[is.na(df$Freq)] = 0
  return(df)
})

#### Plot! ####

USAEvents = data.frame("event.name" = NA, "event.date" = NA)
USAEvents[1,] = c("PATRIOT Act\nPassed", "2001-10-01")
USAEvents[2,] = c("President Bush Expands Powers", "2003-9-01")
USAEvents[3,] = c("Act reauthorization", "2005-12-01")
USAEvents[4,] = c("Department of Justice reveals FBI\nunderreporting of NSL, half used on US Citizens", "2007-3-01")
USAEvents[5,] = c("Oregon Judge Rules Parts of\nPATRIOT Act Unconstitutional", "2007-9-01")
USAEvents[6,] = c("Congress Extends Act Four Years", "2011-5-01")
USAEvents[7,] = c("Snowden Leaks", "2013-6-01")
USAEvents[8,] = c("Portions of PATRIOT Act\nVocally Allowed to Expire", "2015-5-01")

USAEvents$freq = apply(USAEvents, 1, function(x) month_tabs$`USA Papers`$Freq[month_tabs$`USA Papers`$Var1 == x["event.date"]])

USAEvents$lab = rep(c(10, 25, 40), length.out = nrow(USAEvents))

p <- plot_ly()

for(i in 1:length(plot_df)){
  p = add_trace(p, x = plot_df[[i]][, "month"], y = plot_df[[i]][, "Freq"], type = 'scatter', mode = 'lines', name = names(parsed_loc[i]))
}

p = layout(p,
  title = 'Mentions of PATRIOT Act',
  xaxis = list(title = 'Month', tickangle = 45),
  yaxis = list(title = '# of Mentions'),
  legend = list(x = 0.1, y = 0.9))

p = add_annotations(p,
                    x = USAEvents$event.date,
                    y = USAEvents$freq,
                    text = USAEvents$event.name,
                    xref = "x",
                    yref = "y",
                    showarrow = TRUE,
                    arrowhead = 7,
                    ax = 20,
                    ay = -40)

saveRDS(p, "data/timeline_plot.rda")


# View(parsed$`USA Papers`[parsed$`USA Papers`$month == "2015-5-01", "text"])





