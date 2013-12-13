
# Subjects contains distinct topics; construct "topic ID" (e.g "t_12") for every topic
distinct.topics = dbGetQuery(conn, "select concat(\"t_\",id) as topic_id from subjects")

# Transpose them into columns; we now have a 1xT matrix
topics.t = t(distinct.topics)
topics.t.names = topics.t[1,]
names(topics.t.names) = NULL

# Add in a new column for where the bill_id will go
topics.t = cbind(rep(NA,1), topics.t)
colnames(topics.t) = c('bill_id', topics.t.names)
topics.t = as.data.frame(topics.t)
topics.t = topics.t[-1,]

# Get a list of (bill_id, topic_id) pairs for every bill we have
bill.topics = dbGetQuery(conn, "select bs.bill_id, concat(\"t_\",s.id) as topic_id \
                          from bill_subjects bs \
                          join subjects s on bs.subject = s.subject")


