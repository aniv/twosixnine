# Load DB credentials from file
library("rjson")
db.cred <- fromJSON(paste(readLines("/Users/aniv/Dev/twosixnine/src/credentials.json"), collapse=""))

# Create MySQL connection
library("RMySQL")
conn = dbConnect(MySQL(), user=db.cred$user, password=db.cred$password, dbname=db.cred$db, host=db.cred$host)

# Subjects contains distinct topics; construct "topic ID" (e.g "t_12") for every topic
distinct.topics = dbGetQuery(conn, "select concat(\"t_\",id) as topic_id from subjects")

# Transpose them into columns; we now have a 1xT matrix
topics.t = t(distinct.topics)
topics.t.names = topics.t[1,]
names(topics.t.names) = NULL

# Add in a new column for where the bill_id will go
topics.t = cbind(rep(NA,1), topics.t)
colnames(topics.t) = c('bill_id', topics.t.names)

# Get a list of (bill_id, topic_id) pairs for every bill we have
bill.topics = dbGetQuery(conn, "select bs.bill_id, concat(\"t_\",s.id) as topic_id \
                          from bill_subjects bs \
                          join subjects s on bs.subject = s.subject")


##### NOT WORKING - WHY!?!?
# For every bill.topic row, we need to find the corresponding topic_id (easy)
# and then add a row in topics.t with format (bill_id, 0, 0, 0, 1, 0 .... )
# where a 1 appears under the appropriate topic_id column

by(data=head(bill.topics,10), INDICES=1:10,FUN=function(row){  # TODO: Remove to head() and 1:10.. nrows(bill.topics)
  topic.col.num = which(colnames(topics.t) == row$topic_id)
  v = c(row$bill_id, rep(0,topic.col.num-1), 1, rep(0,length(topics.t)-topic.col.num-1))
  print(v)
  rbind(topics.t,v)  # My new vector isn't getting attached to topics.t -- what gives?!
})