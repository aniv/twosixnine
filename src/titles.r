#
# Bag of words / Naive Bayes fit for bill titles
#

##################
# Prepare data
##################

# Load DB credentials from file
library("rjson")
db.cred <- fromJSON(paste(readLines("/Users/aniv/Dev/twosixnine/src/credentials.json"), collapse=""))

# Create MySQL connnection
library("RMySQL")
conn = dbConnect(MySQL(), user=db.cred$user, password=db.cred$password, dbname=db.cred$db, host=db.cred$host)

data = dbGetQuery(conn, "select rbd.bill_id, rbd.title from raw_bill_data rbd order by rbd.bill_id asc");

# remove.stopwords = function(l) { 
#   for (i in 1:length(l)){
#     if (l[i] == "a" || l[i] == "the" || l[i] == "of" || l[i] == "to") {
#       l = l[-i]
#     }
#   }
# }

title.tokens = lapply(strsplit(data$title, " "), tolower)
title.num_words = sapply(title.tokens,length)
title.num_char = c(lapply(title.tokens,nchar),recursive=TRUE)
title.avg_word_len = title.num_char / title.num_words

title.tv = c(title.tokens,recursive=TRUE)
title.tc = table(title.tv)
title.tt = sort(title.tc[which(title.tc > 3)],decreasing=TRUE)

print(tt[1:500])
