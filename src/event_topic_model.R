
#### Setup ####

options(java.parameters = "-Xmx50000m")
library(mallet)
library(wordcloud)
library(stringr)
library(lubridate)

event_model = function(data_loc, event_date = TRUE, topics = 20, .tranining_iterations_var = 2500, .hyperparameter_var = 600, .alpha_param_var = 135){

.data_loc = data_loc
number_of_topics_var = topics

#### Options ####
# This determines how sharp the dropoff is for the crurve of what words are considered a part of a topic
# .alpha_param_var <- 135

# How optemised do you want the models to be?
# .hyperparameter_var <- 600

# Training Iterations, 10% of number of docs is good starting spot
# .tranining_iterations_var <- 2500

#### Data Load ####
# Read data
mydata <- read.csv(.data_loc, header = TRUE, stringsAsFactors = FALSE)
mydata$date = as_date(mydata$date)
mydata$month = floor_date(mydata$date, "month")
mydata = mydata[(mydata$month %within% ((as_date(event_date) - months(1)) %--% (as_date(event_date) + months(1)))),]

#### Mallet ####
# now instanciate the mallet object
mallet.instances <- mallet.import(mydata$title, mydata$lemed, stoplist.file = "data/stopwords.txt", preserve.case = FALSE, token.regexp="[\\p{L}']+")

# now setup a trainer
topic.model <- MalletLDA(num.topics = number_of_topics_var)

# now load the docs
topic.model$loadDocuments(mallet.instances)

#get entire vocab if you want it
vocabulary <- topic.model$getVocabulary()

#get word frequency info
word.freqs <- mallet.word.freqs(topic.model)

#tweak number of burn-in iterations and interations between optimizations
topic.model$setAlphaOptimization(.alpha_param_var, .hyperparameter_var)

#set number of training iterations. In theory, the higher the better
topic.model$train(.tranining_iterations_var)

#### Word Level ####
# Get a matrix of words as columns and topics as rows
topic.words.m <- mallet.topic.words(topic.model, smoothed=TRUE, normalized=TRUE)

# Get the actual words themselves
vocabulary <- topic.model$getVocabulary()

# Replace the column labels with the actual word to which each column applies
colnames(topic.words.m) <- vocabulary

# Convert the matrix to a dataframe
topic.words.df <- as.data.frame(t(topic.words.m))

#### Document Level ####
# calculate the probability that a topic appears in a each text
doc.topics.m <- mallet.doc.topics(topic.model, smoothed=TRUE, normalized=TRUE)

# get the filenames into a vector
file.ids.v <- unique(mydata$filename)

# get the topics into a data frame
doc.topics.df <- as.data.frame(doc.topics.m)

# set the rownames of the topics dataframe to Do it by doc
row.names(doc.topics.df) <- file.ids.v

#### Vis ####
#prepare matrix for visualization of top topic words
topic.top.words <- mallet.top.words(topic.model, topic.words.m[10,], 20)

#now draw a wordcloud of the top word topics
wordcloud(topic.top.words$words, topic.top.words$weights, c(4,.8), rot.per=0, random.order=F)

# Save Batch

exploreWordclouds <- function(topicWordsMatrix, topics = 1:nrow(topicWordsMatrix)){
  require(wordcloud)
  force(topicWordsMatrix)
  dir.create(paste0(getwd(), "/model_out/", event_date, "/wordclouds/"), recursive = TRUE)
  for(i in topics){
    mypath <- paste(getwd(),"/model_out/", event_date, "/wordclouds/", "topic_", i, ".jpg", sep = "")
    
    topic.top.words <- mallet.top.words(topic.model, topic.words.m[i,], 20)
    jpeg(file=mypath, width = 480, height = 480)
    wordcloud(topic.top.words$words, topic.top.words$weights, c(4,.8), rot.per=0, random.order=F)
    dev.off()
  }
}

exploreWordclouds(topic.words.m)

out = list(
  "topic.model" = topic.model,
  "doc.topics.df" = doc.topics.df,
  "topic.words.df" = topic.words.df,
  "word.freqs" = word.freqs,
  "parameters" = c("Topics" = number_of_topics_var, "Center Date" = event_date, "Data Used" = .data_loc, "Training Iterations" = .tranining_iterations_var, "Hyper-Parameter" = .hyperparameter_var, "Alpha" = .alpha_param_var)
)

saveRDS(out, paste0("model_out/", event_date, "/topic_model.rda"))

return(out)
}

test = event_model("data/parsed/PATRIOT Act/Access World News/USA/parsed_clean.csv", event_date = "2007-9-01")



