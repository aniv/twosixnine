##################
# Prepare data
##################

# Load DB credentials from file
library("rjson")
db.cred <- fromJSON(paste(readLines("/Users/aniv/Dev/twosixnine/src/credentials.json"), collapse=""))

# Create MySQL connnection
library("RMySQL")
conn = dbConnect(MySQL(), user=db.cred$user, password=db.cred$password, dbname=db.cred$db, host=db.cred$host)

data = dbGetQuery(conn,
                  "select x.*, cc.cosponsor_d, cc.cosponsor_r\
                  from\
                  (select bill.status, bill.bill_id, bill.subjects, cg.*\
                  from raw_bill_data bill\
                  join congress_global cg\
                  on bill.congress = cg.congress) x\
                  left outer join cosponsor_counts cc\
                  on x.bill_id = cc.bill_id order by x.bill_id asc")

# Create outcome variables
#   Success: passed:bill, pass_over:house, enacted:signed, VETOED:OVERRIDE_FAIL_ORIG
#   Fail: reported, referred, prov_kill:suspensionfaile, FAIL:ORIGINATING:HOUSE

success = array(1,dim=c(length(data$status)))
for (i in 1:length(success)) { 
  if (data$status[i]=="REPORTED" | data$status[i]=="REFERRED" | data$status[i]=="PROV_KILL:SUSPENSIONFAILE" | data$status[i]=="FAIL:ORIGINATING:HOUSE") {
    success[i]=0
  }
}
success = as.logical(success)
colors = rep("green",length(2))
colors[success==1] = "green"
colors[success==0] = "red"
shapes = rep(17,length(colors))
shapes[success==1] = 16
shapes[success==0] = 18

#
# Prepare bill topics/subjects
#

subjects = matrix(data=0,nrow=length(data$bill_id),ncol=1129)
#subjects[,1] = data$bill_id

bill.topics = dbGetQuery(conn, "select bs.bill_id, s.id as topic_id \
                         from bill_subjects bs \
                         join subjects s on bs.subject = s.subject \
                         order by bs.bill_id asc")

for (i in 1:nrow(bill.topics)) {
  #	b.id = bill.topics[i,1]
  s.id = bill.topics[i,2]
  subject.row = which(data$bill_id==bill.topics[i,1])
  subjects[subject.row,s.id]=1
}

colnames(subjects) = c(paste("t",seq(1,1129),sep=""))

# Run stepwise on the subject columns

subjects.df = as.data.frame(subjects)
subjects.stepwise = stepwise.lars(100, subjects.df, success)
subjects.stepwise.df = as.data.frame(subjects.stepwise)
subjects.numbers =  as.numeric(gsub("V","",rownames(subjects.stepwise.df)))
subjects.form.build = paste(paste("subjects.df[,",subjects.numbers,sep="", collapse="] + "), "]", sep="")
subjects.form = as.formula(paste("success ~", subjects.form.build ))
model.subjects = lm(subjects.form)
summary(model.subjects)

plot(main="Model Predictions - Subjects (R2=.31)",
     x=seq(1:num.bills),
     y=predict(model.subjects),
     xlab="Bill Number",
     ylab="Success (1=Pass)",
     col=colors,cex=0.4,pch=shapes)
abline(h=mean(predict(model.subjects)))


# Apply stepwise regression on the PCA componenets to find the best PCs on topics
subjects.pca = prcomp(subjects,scale.=TRUE)
library(lars)
stepwise.lars = function(size=10, X, y) {
  lmt.step = lars(as.matrix(X), y, type="step", use.Gram=F, max.steps=size)
  best.index = match(min(lmt.step$Cp), lmt.step$Cp)
  sw.lars.coeffs <<- lmt.step$beta[best.index, ]
}

pca.df = as.data.frame(subjects.pca$x)
fit.stepwise = stepwise.lars(500, pca.df, success)
fit.stepwise.df = as.data.frame(fit.stepwise)
numbers.stepwise =  as.numeric(gsub("PC","",rownames(subset(fit.stepwise.df,fit.stepwise.df$fit.stepwise!=0))))
stepwise.pca.form.build = paste(paste("subjects.pca$x[,",numbers.stepwise,sep="", collapse="] + "), "]", sep="")
stepwise.pca.form = as.formula(paste("success ~", stepwise.pca.form.build ))
model.garbage = lm(stepwise.pca.form)
summary(lm(stepwise.pca.form))
#plot(subjects.pca$x[,171],subjects.pca$x[,973],col=colors,pch=shapes)
plot(main="Model Predictions, 500 Topic PCs (R2=.2271)",seq(1:15912),predict(model.garbage),xlab="Bill Number",ylab="Success (1=Pass)",col=colors,cex=0.4,pch=shapes)
abline(h=mean(predict(model.garbage)))


#
# Bill titles tokens as predictors
#
title.data = dbGetQuery(conn, "select rbd.bill_id, rbd.title from raw_bill_data rbd order by rbd.bill_id asc");

title.tokens = lapply(strsplit(title.data$title, " "), tolower)
title.num_words = sapply(title.tokens,length)

title.tv = c(title.tokens,recursive=TRUE)
title.tc = table(title.tv)
title.tt = sort(title.tc[which(title.tc > 3)],decreasing=TRUE)

title.frequencies = matrix(data=0,nrow=length(title.data$bill_id),ncol=500)
colnames(title.frequencies) = c(paste("freq.",rownames(title.tt[1:500]),sep=""))

for (i in 1:length(title.data$title)) {
  current.table = table(title.tokens[[i]]) / title.num_words[i]
  if (i %% 100 == 0) {print(i)}
  for (j in 1:length(current.table)) {
    col.to.insert = which(colnames(title.frequencies)==paste("freq.",names(current.table[j]),sep=""))
    title.frequencies[i,col.to.insert] = current.table[j]
  }
}

# Simple fit after stepwise regression
title.freq.df = as.data.frame(title.frequencies)
ttl.fit.stepwise = stepwise.lars(100, title.freq.df, success)
ttl.fit.stepwise.df = as.data.frame(ttl.fit.stepwise)
ttl.fit.stepwise.vars = rownames(subset(ttl.fit.stepwise.df,ttl.fit.stepwise.df$ttl.fit.stepwise!=0))
ttl.fit.stepwise.form.build = paste("title.freq.df", ttl.fit.stepwise.vars, collapse=" + ", sep="$")
ttl.fit.stepwise.form = paste("success ~ ",  ttl.fit.stepwise.form.build)
model.ttl.fit.stepwise = lm(ttl.fit.stepwise.form, data=title.freq.df)
summary(model.ttl.fit.stepwise)

plot(main="Model Predictions, 100 Title tokens (R2=.1272)",
     x=seq(1:16716),
     y=predict(model.ttl.fit.stepwise),
     xlab="Bill Number",
     ylab="Success (1=Pass)",
     col=colors,cex=0.4,pch=shapes)

abline(h=mean(predict(model.ttl.fit.stepwise)))


# Run LSA on the regressors
title.pca = prcomp(title.frequencies,scale.=TRUE)
title.pca.df = as.data.frame(title.pca$x)

title.pca.stepwise = stepwise.lars(100, title.pca.df, success)
title.pca.stepwise.df = as.data.frame(title.pca.stepwise)
title.numbers.stepwise =  as.numeric(gsub("PC","",rownames(subset(title.pca.stepwise.df,title.pca.stepwise.df$title.pca.stepwise!=0))))
title.pca.stepwise.form.build = paste(paste("title.pca$x[,",title.numbers.stepwise,sep="", collapse="] + "), "]", sep="")
title.pca.stepwise.form = as.formula(paste("success ~", title.pca.stepwise.form.build ))
model.title.pca.stepwise = lm(title.pca.stepwise.form)
summary(model.title.pca.stepwise)

plot(main="Model Predictions, 100 Title PCs (R2=.1246)",
     x=seq(1:16716),
     y=predict(model.title.pca.stepwise),
     xlab="Bill Number",
     ylab="Success (1=Pass)",
     col=colors,cex=0.4,pch=shapes)

abline(h=mean(predict(model.title.pca.stepwise)))


# 
# Bill cosponsors
#

csp.data = dbGetQuery(conn, "select b.id, c.id \
                             from bill_cosponsors bc \
                             join cosponsors c on bc.cosponsor_id = c.cosponsor_id \
                             join bills b on bc.bill_id = b.bill_id \
                             order by bc.bill_id asc")

csp.data.bills = dbGetQuery(conn, "select distinct bill_id from bill_cosponsors order by bill_id asc")

num.bills = length(csp.data.bills[,1])

# We need to create a new set of success variables because the number of bills here are different
csp.data.success = dbGetQuery(conn, "select r.bill_id, r.status from raw_bill_data r where r.bill_id in (select distinct bill_id from bill_cosponsors) order by r.bill_id asc")
csp.success = array(1,dim=c(num.bills))
for (i in 1:length(csp.success)) { 
  if (csp.data.success$status[i]=="REPORTED" | csp.data.success$status[i]=="REFERRED" | csp.data.success$status[i]=="PROV_KILL:SUSPENSIONFAILE" | csp.data.success$status[i]=="FAIL:ORIGINATING:HOUSE") {
    csp.success[i]=0
  }
}
csp.success = as.logical(csp.success)

cosponsors = matrix(data=0,nrow=num.bills,ncol=634)
colnames(cosponsors) = unique(csp.data$cosponsor_id)

for (i in 1:length(csp.data[,2])) {
  c.id = csp.data[i,2]  # get the cosponsor's id from the (bill_id, cospon_id)
  b.id = csp.data[i,1]
  b.row = b.id
  c.col = c.id
#   c.col = which(c.id==colnames(cosponsors))  # find the corresponding column
#   b.row = which(b.id==csp.data.bills)
  cosponsors[b.row,c.col]=1  # b.row=bill's row, c.col=sponsor's column
  if (i %% 1000 == 0) {print(i)}
}

# Run stepwise on the cosponsor matrix to find 100 most valuable cosponsors
cosponsors.df = as.data.frame(cosponsors)
csp.fit.stepwise = stepwise.lars(100, cosponsors.df, csp.success)
csp.fit.stepwise.df = as.data.frame(csp.fit.stepwise)
colnames(csp.fit.stepwise.df) = c('x')

csp.top100 = as.data.frame(subset(csp.fit.stepwise.df,csp.fit.stepwise.df$x!=0))
csp.top100.numbers =  as.numeric(gsub("V","",rownames(csp.top100)))
csp.top100.form.build = paste(paste("cosponsors.df[,",csp.numbers.stepwise,sep="", collapse="] + "), "]", sep="")
csp.top100.form = as.formula(paste("csp.success ~", csp.top100.form.build ))
model.csp.top100 = lm(csp.top100.form)
summary(model.csp.top100)


plot(main="Model Predictions, 100 Cosponsors (R2=.053)",
     x=seq(1:num.bills),
     y=predict(model.csp.top100),
     xlab="Bill Number",
     ylab="Success (1=Pass)",
     col=colors,cex=0.4,pch=shapes)

abline(h=mean(predict(model.csp.top100)))


# Run PCA on cosponsors and then stepwise the PCs

cosponsors.pca = prcomp(cosponsors,scale.=TRUE)
cosponsors.pca.df = as.data.frame(cosponsors.pca$x)

csp.fit.stepwise = stepwise.lars(100, cosponsors.pca.df, csp.success)
csp.fit.stepwise.df = as.data.frame(csp.fit.stepwise)

csp.numbers.stepwise =  as.numeric(gsub("PC","",rownames(subset(csp.fit.stepwise.df,csp.fit.stepwise.df$csp.fit.stepwise!=0))))
csp.stepwise.pca.form.build = paste(paste("cosponsors.pca$x[,",csp.numbers.stepwise,sep="", collapse="] + "), "]", sep="")
csp.stepwise.pca.form = as.formula(paste("csp.success ~", csp.stepwise.pca.form.build ))
model.csp.stepwise = lm(csp.stepwise.pca.form)
summary(model.csp.stepwise)

plot(main="Model Predictions, 100 Cosponsor PCs (R2=.098)",
     x=seq(1:num.bills),
     y=predict(model.csp.stepwise),
     xlab="Bill Number",
     ylab="Success (1=Pass)",
     col=colors,cex=0.4,pch=shapes)

abline(h=mean(predict(model.csp.stepwise)))


## Combine all factors into uber table

# subjects = (bill_id x [topic_ids ....] )
# subjects.pca.df = (bill_id x [PCAs from subjects])
# cosponsors.df = (bill_id x [cosponsor_ids ...])
# cosponsors.pca.df = (bill_id x [634 PCAs of cosponsors])
# title.freq.df = (bill_id x [title terms... ])
# title.pca.df = (bill_id x 500 PCAs of titles)

subjects.pca = prcomp(subjects,scale.=TRUE)
subjects.pca.df = as.data.frame(subjects.pca$x)
uber.df = data.frame(subjects, subjects.pca.df)

uber.stepwise = stepwise.lars(100, uber.df, success)
uber.stepwise.df = as.data.frame(uber.stepwise)
uber.top100 = as.data.frame(subset(uber.stepwise.df,uber.stepwise.df$uber.stepwise!=0))
uber.top100.numbers = array(0,dim=100)
for (i in 1:nrow(uber.top100)) {
  uber.top100.numbers[i] = which(colnames(uber.df)==rownames(uber.top100)[i])
}
uber.top100.form.build = paste(paste("uber.df[,",uber.top100.numbers,sep="", collapse="] + "), "]", sep="")
uber.top100.form = as.formula(paste("success ~", uber.top100.form.build ))
model.uber.top100 = lm(uber.top100.form)
summary(model.uber.top100)


##
## Create a new uber matrix that uses computed stepwise results
## from cosponsors, title terms, bill subjects/topics
##

# Get stepwise columns for cosponsors
#csp.top100$rownames

# Get stepwise columns for title terms
#ttl.fit.stepwise.df$rownames
#title.pca.stepwise.df



# Get stepwise columns for bill subjects
library(lars)
uber.stepwise = stepwise.lars(300, uber.df, success)
uber.stepwise.df = as.data.frame(uber.stepwise)
uber.top300 = as.data.frame(subset(uber.stepwise.df,uber.stepwise.df$uber.stepwise!=0))
uber.top300.numbers = array(0,dim=300)
for (i in 1:nrow(uber.top300)) {
  uber.top300.numbers[i] = which(colnames(uber.df)==rownames(uber.top300)[i])
}
uber.top300.form.build = paste(paste("uber.df[,",uber.top300.numbers,sep="", collapse="] + "), "]", sep="")



#
# yeah
#
model.rhs = paste(title.pca.stepwise.form.build, ttl.fit.stepwise.form.build, uber.top300.form.build, csp.stepwise.pca.form.build, csp.top100.form.build, collapse="+", sep=" + ")
model.rhs = paste("data$cosponsor_d + data$cosponsor_r", model.rhs, sep=" + ")
model.form = as.formula(paste("success ~", model.rhs ))
model.yeah.logit = glm(model.form, family=binomial(logit))

model.yeah = lm(model.form)
#summary(model.yeah)

# Lets compare our predictions (using logistic regression) to actual success
length(which(success.logit.predict > 0.5))
length(which(success.logit.predict < 0.5))
length(which(success == 1))
length(which(success == 0))

success.pred = which(success.logit.predict > 0.5)
success.actuals = which(success==1)
success.overlap = intersect(success.actuals, success.pred)  # 642 entries

failure.pred = which(success.logit.predict < 0.5)
failure.actual = which(success == 0)
failure.overlap = intersect(failure.pred, failure.actual)   # 15152 entries

true.positive = length(intersect(which(success.logit.predict>=0.5), which(success == 1)))
false.positive = length(intersect(which(success.logit.predict>=0.5), which(success == 0)))
true.negative = length(intersect(which(success.logit.predict<0.5), which(success == 0)))
false.negative = length(intersect(which(success.logit.predict<0.5), which(success == 1)))

confusion = matrix(c(true.positive, false.negative, false.positive, true.negative), nrow=2, ncol=2)

library("ROCR")
rocr.pred = prediction(success.logit.predict, success)
rocr.perf = performance(rocr.pred, measure="tpr", x.measure="fpr")
plot(rocr.perf, col=rainbow(10), main="ROC Curve for Predictions using Log. Reg")

plot(main="Residuals - Title, Cosponsor, Subjects (R2=.31)",
     x=seq(1:num.bills),
     y=resid(model.yeah),
     xlab="Bill Number",
     ylab="Success (1=Pass)",
     col=colors,cex=0.4,pch=shapes)



plot(main="Model - Title, Cosponsor, Subjects (R2=.31)",
     x=seq(1:num.bills),
     y=predict(model.yeah),
     xlab="Bill Number",
     ylab="Success (1=Pass)",
     col=colors,cex=0.4,pch=shapes)

abline(h=mean(predict(model.yeah)))
