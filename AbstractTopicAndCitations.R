library(tm)
library(topicmodels)
library(slam)
library(ggplot2)
library(tidyverse)
library(tidytext)

citation_data <- read.csv("../AMiner.csv")
head(citation_data)
str(citation_data)
summary(citation_data)

# Remove duplicates in paper authors. The original parsing of the data stored a new entry for
# every author in a paper
citation_data <- citation_data[!duplicated(citation_data$author), ]

# Now remove every entry that does not have an abstract
citation_data <- citation_data[!(is.na(citation_data$abstract) | citation_data$abstract==""), ]

# Since we are only interested in citation counts and abstracts, we will just
# keep those columns
citation_data <- citation_data[, c('citations', 'abstract')]
citation_data <-citation_data[sample(nrow(citation_data), 100000), ]

# Isolate the abstract texts and prepar them for text processing
abstracts <- Corpus(VectorSource(citation_data$abstract))

# Clean all the abstracts and create a DTM
clean_corpus <- function(corpus){
  corpus <- tm_map(corpus, stripWhitespace)
  corpus <- tm_map(corpus, removePunctuation)
  corpus <- tm_map(corpus, content_transformer(tolower))
  corpus <- tm_map(corpus, removeWords, stopwords('en'))
  corpus <- tm_map(corpus, stemDocument, language = "english")
  return(corpus)
}

clean_abstracts <- clean_corpus(abstracts)

abstracts_dtm <- DocumentTermMatrix(clean_abstracts, control = list(minWordLength = 1))
abstracts_dtm

# Next, we will use the tf-idf metric to get rid of words that will likely not be good
# distinguishing words

term_tfidf <- tapply(abstracts_dtm$v/row_sums(abstracts_dtm)[abstracts_dtm$i],
                     abstracts_dtm$j, mean) * log2(nDocs(abstracts_dtm)
                                                   /col_sums(abstracts_dtm > 0))
abstracts_dtm <- abstracts_dtm[,term_tfidf >= 0.1]

# We will next drop out any documents (i.e. rows) that no longer have any entries
ui <- unique(abstracts_dtm$i)
abstracts_dtm <- abstracts_dtm[ui, ]
citation_data <- citation_data[ui, ]

# Now, construct an LDA model for the data, for the LDA model, we will use 10 as
# the number of topics; this choice is largely arbitrary on my part
abstracts_lda <- LDA(abstracts_dtm, k=10)

abstract_top_words <- tidy(abstracts_lda, matrix='beta')
top_n(abstract_top_words, 20)

terms(abstracts_lda, 5)

# Next, we will do a regression model on topics and citation counts. We would like
# to see if topics, as described by an abstract, are a good predictor of how many
# citations a paper is likely to get

abstract_topics <- posterior(abstracts_lda, abstracts_dtm)
citation_data$topic = apply(abstract_topics$topics, 1, max)

regMod <- lm(citations ~ topic, data=citation_data)
summary(regMod)

ggplot(citation_data, aes(x=topic, y=citations))+
  geom_point(size=0.7, shape=23)+
  geom_smooth(method=lm)

abs_anova <- aov(citations ~ topic, data=citation_data)
summary(abs_anova)





