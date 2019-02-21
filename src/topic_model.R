
# Good referance http://www.historycommons.org/timeline.jsp?timeline=civilliberties&civilliberties_patriot_act=civilliberties_patriot_act

#### Setup ####

options(java.parameters = "-Xmx50000m")
library(mallet)
library(wordcloud)
library(stringr)

.data_loc = "data/parsed/PATRIOT Act/Access World News/CA Newspapers/parsed_clean.csv"

#### Options ####
# This determines how sharp the dropoff is for the crurve of what words are considered a part of a topic
.alpha_param_var <- 135

# How optemised do you want the models to be?
.hyperparameter_var <- 600

# Training Iterations, 10% of number of docs is good starting spot
.tranining_iterations_var <- 500

# Set number of topics.
number_of_topics_var <- 20

#### Data Load ####
# Read data
mydata <- read.csv(.data_loc, header = TRUE, stringsAsFactors = FALSE)

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
  for(i in topics){
    mypath <- paste(getwd(),"/wordclouds/topic_", i, ".jpg", sep = "")
    
    topic.top.words <- mallet.top.words(topic.model, topic.words.m[i,], 20)
    jpeg(file=mypath, width = 480, height = 480)
    wordcloud(topic.top.words$words, topic.top.words$weights, c(4,.8), rot.per=0, random.order=F)
    dev.off()
  }
}

exploreWordclouds(topic.words.m)




