
#######################################################
# ------------- Written by Jared Joseph ------------- #
#                                                     #
#                 Please contact me at                #
#               Jared.n.joseph@gmail.com              #
#                                                     #
#                     Find me on:                     #
# Website: https://www.jnjoseph.com                   #
# Github: https://www.github.com/Epsian               #
# BitBucket: https://www.bitbucket.org/Epsian/        #
# Twitter: https://www.twitter.com/Epsian             #
# LinkedIn: https://www.linkedin.com/in/jnjoseph/     #
#                                                     #
#######################################################

#### Data Load ####
library(doParallel)
library(koRpus)

# Start up a parallel cluster
# parallelCluster <- makeCluster(detectCores() - 1, outfile = "")
# print(parallelCluster)
# registerDoParallel(parallelCluster)

# on.exit({
#  stopImplicitCluster()
#  stopCluster(parallelCluster)
#  rm(parallelCluster)
# })

#### Function ####

GSRLemPar = function(text.col, MaxIter = 5, LemmatizerSourceDir = '/home/jnjoseph/programs/tree_tagger'){
  
  # Set the koRpus environment
  set.kRp.env(TT.cmd = "manual",
              lang = 'en',
              preset = 'en',
              treetagger = 'manual',
              format = 'obj',
              TT.tknz = TRUE,
              encoding = 'UTF-8',
              TT.options = list(path = LemmatizerSourceDir,
                                preset = 'en'))
  
  # Write a function to do the lemmatization
  lemmatize = function(txt){
    tagged.words = treetag(txt,
                           format = "obj",
                           treetagger ='manual',
                           lang = 'en',
                           TT.options = list(path = paste0(LemmatizerSourceDir),
                                             preset = 'en'))
    results = tagged.words@TT.res
    return(results)
  }
  
  # Code that will send chunks of the provided document to parallelCluster created in the 'Data Load' section
  lemlist = foreach(i = 1:length(text.col), .packages = "koRpus", .combine = c) %dopar% {
    tryCatch({
      activedf = lemmatize(text.col[i])
      activedf$lemma = as.character(activedf$lemma)
      activedf[which(activedf$lemma == "<unknown>"), "lemma"] = activedf[which(activedf$lemma == "<unknown>"), "token"]
      coltext = paste(activedf$lemma, collapse = " ")
      print(paste("Chunk #", i, " of ", length(text.col), " completed!"))
      return(coltext)
    }, error = function(e) {
      return(print(paste("SKIPPED ERROR:", conditionMessage(e), sep = " ")))
    })
    
  }
  return(lemlist)
}  