###### Objective
# Find the relationshiop between the number of backlinks created and time.


###### Allowing R script file to be executable
#!/usr/bin/Rscript


###### Installing necessary packages
# install.packages('stringr')
# install.packages('ggplot2')
# install.packages('gridExtra')

###### Loading necessary packages
library(stringr)
library(ggplot2)
library(psych)
library(gridExtra)


###### Setting up
getwd()
wd_path <- '/Users/hawooksong/Desktop/programming_projects/backlink_project/backlink_analysis'
setwd(wd_path)
getwd()

###### Loading names of SEO and non-SEO backlink data files to import
backlinkData = c()

seo_backlink_data_files <- list.files(paste(wd_path, '/data/seo', sep=''))
non_seo_backlink_data_files <- list.files(paste(wd_path, '/data/non-seo', sep=''))
backlink_data_files <- append(seo_backlink_data_files, non_seo_backlink_data_files)

length(seo_backlink_data_files)
length(non_seo_backlink_data_files)

n <- length(seo_backlink_data_files)
n
m <- length(non_seo_backlink_data_files)
m

###### Loading CSV SEO backlink data to R
for (i in 1:n) {
  file_path <- paste('./data/seo/', seo_backlink_data_files[i], sep='')
  backlinkData[[i]] <- read.csv(file_path)
}


###### Loading CSV non-SEO backlink data to R
for (i in 1:m) {
  file_path <- paste('./data/non-seo/', non_seo_backlink_data_files[i], sep='')
  backlinkData[[n+i]] <- read.csv(file_path)
}


###### Changing the last three column names and merging data frames
### This is an important step to merge data frames using rbind() function!

# listing column length for each backlink data sheet 
for (i in 1:(n+m)) {
  col_length <- length(backlinkData[[i]])
  print(col_length)
}


# placing a NA-value vector for each data frame with missing category column and
# cleaning the last three column names for each data frame
for (i in 1:(n+m)) {
  colnames(backlinkData[[i]])[1] <- "Position"
  colnames(backlinkData[[i]])[18] <- "BackLinks"
  colnames(backlinkData[[i]])[19] <- "FirstLinkDate"
  colnames(backlinkData[[i]])[20] <- "LastLinkDate"
}


###### Adding a column of domain names to each data frame in backlinkData
for (i in 1:(n+m)) {
  file_name <- backlink_data_files[[i]] 
  domain <- strsplit(file_name, '_')
  j <- length(domain[[1]])
  domain <- domain[[1]][j]
  domain <- strsplit(domain, '.csv')
  domain <- domain[[1]][1]  
  nrow <- nrow(backlinkData[[i]])
  domainName <- rep(domain, nrow)
  backlinkData[[i]] <- cbind(backlinkData[[i]], domainName)
}


###### Merging data frames into a single data frame
blData <- do.call('rbind', backlinkData)


###### Un-factoring selected column variables
# This is done because randomForest cannot handle categorical predictors (factors) 
# with more than 32 categories.

# column names of backlink data frame
names(blData)


###### Converting domain names as character variable
names(blData)[2]
class(blData[ , 2])
head(blData[ , 2])
blData[ , 2] <- as.character(blData[ , 2])


###### Converting first & last crawled date from factor to date
###### Converting first % last link date from factor to date
names(blData)[10]
names(blData)[11]
class(blData[ , 10])
class(blData[ , 11])

names(blData)[19]
names(blData)[20]
class(blData[ , 19])
class(blData[ , 20])

col_index = c(10, 11, 19, 20)  # index of columns whose values need to be changed from factor to date
pattern <- '[0-9]+/[0-9]+/[0-9]+'

for (i in 1:length(col_index)) {
  temp <- blData[ , col_index[i]]
  temp <- str_extract_all(temp, pattern)
  temp <- as.character(temp)
  temp <- as.Date(temp, format='%d/%m/%Y')
  blData[ , col_index[i]] <- temp
}


###### Converting IP address as character
names(blData)[12]
class(blData[ , 12])
head(blData[ , 12])
blData[ , 12] <- as.character(blData[ , 12])


###### Converting subnet as character
names(blData)[13]
class(blData[ , 13])
head(blData[ , 13])
blData[ , 13] <- as.character(blData[ , 13])


###### Splitting the data into SEO and non-SEO
table(blData$domainName)
selectCond <- blData$domainName %in% 
  c('autoshop-com', 'cardealership-com', 'itcompany-com', 'cosmeticdental-com', 
    'sushirestaurant-com', 'pharmacycompany-com', 'printingshop-com', 
    'alsnonprofit-org', 'roofingcompany-com')

seo_data <- subset(blData, selectCond)
non_seo_data <- subset(blData, !selectCond)

# making sure number of rows add up 
nrow(blData)
nrow(seo_data)
nrow(non_seo_data)
nrow(blData) == nrow(seo_data) + nrow(non_seo_data)


###### Plotting number of linking domains vs. time for all SEO client websites 
###### From 2008 to 2013 
###### By first link date (closest approximation of link creation)
emptStart <- as.Date('2011/9/15', format='%Y/%m/%d')
emptEnd <- as.Date('2012/4/15', format='%Y/%m/%d')
penguinStart <- as.Date('2012/4/24', format='%Y/%m/%d')
dropOffStart <- as.Date('2012/8/10', format='%Y/%m/%d')  # Drop-off start
dropOffEnd <- as.Date('2013/1/30', format='%Y/%m/%d')  # Drop-off end
dataStart <- min(seo_data$FirstLinkDate)  # first date in data
dataEnd <- max(seo_data$FirstLinkDate)  # last date in data
johnLinkBldgEffectStart <- emptStart
johnLinkBldgEffectEnd <- as.Date('2012/9/30', format='%Y/%m/%d')
naturalLinkBuildUpEnd <- emptStart
newStrategyStart <- as.Date('2013/2/15', format='%Y/%m/%d')

#### For all SEO clients' websites
p <- ggplot(seo_data, aes(x=seo_data$FirstLinkDate))
p <- p + geom_histogram(binwidth=30) + xlab('Time') + ylab('Number of Sites Linking')
p
p <- p + ggtitle('New Sites Linking to All SEO Client Websites \n 2008 - 2013')
p <- p + annotate('rect', alpha=0.2, color='red', fill='red',
                  xmin=emptStart, xmax=emptEnd, ymin=0, ymax=400)
p <- p + annotate('text', x=emptStart-225, y=410, label='Duration of \n John\'s \n employment', color='red') 
p <- p + annotate('segment', color='blue',
             x=penguinStart, y=0, xend=15450, yend=500, size=1.5)
p <- p + annotate('text', x=penguinStart+150, y=540, label='Google\'s \n Penguin update', color='blue')
p <- p + annotate('rect', alpha=0.2, color='orange', fill='orange', 
                  xmin=dropOffStart, xmax=dropOffEnd, ymin=0, ymax=250)
p <- p + annotate('text', x=dropOffStart+50, y=275, label='Drop-off', color='orange')
p <- p + annotate('rect', alpha=0.4, color='#008800', fill='green',
                  xmin=johnLinkBldgEffectStart, xmax=johnLinkBldgEffectEnd, 
                  ymin=0, ymax=220)
p <- p + annotate('text', x=emptStart-250, y=240, color='#008800',
             label='John\'s \n link building \n effect')
p <- p + annotate('rect', alpha=0.2, color='purple', fill='purple',
                  xmin=newStrategyStart, xmax=dataEnd, ymin=0, ymax=350)
p <- p + annotate('text', color='purple', x=newStrategyStart, y=420,
             label='New link \n building \n strategy')
p <- p + annotate('rect', color='grey', fill='grey', alpha=0.4,
             xmin=dataStart, xmax=naturalLinkBuildUpEnd, ymin=0, ymax=80)
p <- p + annotate('text', x=dataStart+750, y=100,
             label='Natural link build-ups')
p
dev.copy(png,'linking_sites_vs_time_all_seo.png'); dev.off()

#### For all SEO clients' websites (frame zoomed)
tmp <- subset(seo_data, seo_data$FirstLinkDate >= emptStart)
q <- ggplot(tmp, aes(x=tmp$FirstLinkDate))
q <- q + geom_histogram(binwidth=15) + xlab('Time') + ylab('Number of Sites Linking') 
q <- q + ggtitle('New Sites Linking to All SEO Client Websites (Zoomed) \n April 2012 - August 2013')
q <- q + annotate('rect', xmin=emptStart, xmax=emptEnd, ymin=0, ymax=300, alpha=0.2, color='red', fill='red')
q <- q + annotate('text', x=emptStart+147, y=340, label='Duration \n of John\'s \n employment', color='red')
q <- q + annotate('segment', color='blue', size=1.5,
             x=penguinStart, y=0, xend=15450, yend=420)
q <- q + annotate('text', color='blue', x=penguinStart, y=450, 
                  label='Google\'s \n Penguin update')
q <- q + annotate('rect', alpha=0.2, color='orange', fill='orange',
                  xmin=dropOffStart, xmax=dropOffEnd, ymin=0, ymax=300)
q <- q + annotate('text', x=dropOffStart+70, y=325, label='Drop-off', color='orange')
q <- q + annotate('rect', alpha=0.4, color='#008800', fill='green',
                  xmin=johnLinkBldgEffectStart, xmax=johnLinkBldgEffectEnd, ymin=0, ymax=150)
q <- q + annotate('text', x=johnLinkBldgEffectStart+160, y=220, color='#008800',
                  label='John\'s \n linking \n building \n effect')
q <- q + annotate('rect', alpha=0.2, color='purple', fill='purple',
                  xmin=newStrategyStart, xmax=dataEnd, ymin=0, ymax=150)
q <- q + annotate('text', color='purple', x=dataEnd-60, y=180,
                  label='New link building \n strategy')
q
dev.copy(png,'linking_sites_vs_time_all_seo_zoomed.png'); dev.off()

##### Subsetting data for older clients when John was employed
cardealership <- subset(seo_data, seo_data$domainName == 'cardealership-com')
pharmacycompany <- subset(seo_data, seo_data$domainName == 'pharmacycompany-com')
printingshop <- subset(seo_data, seo_data$domainName == 'printingshop-com')
sushirestaurant <- subset(seo_data, seo_data$domainName == 'sushirestaurant-com')
autoshop <- subset(seo_data, seo_data$domainName == 'autoshop-com')
nonprofit <- subset(seo_data, seo_data$domainName == 'alsnonprofit-org')
cosmeticdental <- subset(seo_data, seo_data$domainName == 'cosmeticdental-com')
roofingcompany <- subset(seo_data, seo_data$domainName == 'roofingcompany-com')
itcompany <- subset(seo_data, seo_data$domainName == 'itcompany-com')

#### Plotting data for the Car Dealership
# SEO start date: Unknown (before June 5, 2012)
p <- ggplot(cardealership, aes(x=cardealership$FirstLinkDate))
p <- p + geom_histogram(binwidth=15) + xlab('Time') + ylab('Number of Sites Linking') 
p <- p + ggtitle('New Sites Linking to Car Dealership\'s Website \n 2008 - 2013')
p <- p + annotate('rect', color='red', fill='red', alpha=0.2,
                  xmin=emptStart, xmax=emptEnd, ymin=0, ymax=150)
p <- p + annotate('text', x=emptStart-150, y=170, color='red',
                  label='Duration \n of John\'s \n employment') 
p <- p + annotate('segment', color='blue', size=1.5,
                  x=penguinStart, y=0, xend=15450, yend=180)
p <- p + annotate('text', x=penguinStart+130, y=200, color='blue',
                  label='Google\'s \n Penguin update')
p <- p + annotate('rect', xmin=dropOffStart, xmax=dropOffEnd, ymin=0, ymax=80, 
                  alpha=0.2, color='orange', fill='orange')
p <- p + annotate('text', x=dropOffStart+100, y=90, label='Drop-off', color='orange')
p <- p + annotate('rect', color='grey', fill='grey', alpha=0.6,
             xmin=dataStart, xmax=naturalLinkBuildUpEnd, ymin=0, ymax=20)
p <- p + annotate('text', x=dataStart+500, y=30, label='Natural link build-ups')
p <- p + annotate('rect', color='purple', fill='purple', alpha=0.2,
             xmin=newStrategyStart, xmax=dataEnd, ymin=0, ymax=35)
p <- p + annotate('text', x=newStrategyStart+120, y=60, color='purple',
             label='New link \n building \n strategy')
p <- p + annotate('rect', color='#008800', fill='green', alpha=0.4,
             xmin=johnLinkBldgEffectStart, xmax=johnLinkBldgEffectEnd, 
                  ymin=0, ymax=70)
p <- p + annotate('text', x=emptStart-200, y=75, color='#008800',
             label='John\'s link \n building \n effect')
p
dev.copy(png,'linking_sites_vs_time_cardealership.png'); dev.off()

#### Plotting data for the Pharmacy Company
# SEO start date: 12/15/2011
clientRetainedDate <- as.Date('12/15/2011', format='%m/%d/%Y')
localDataStart <- min(pharmacycompany$FirstLinkDate)
p <- ggplot(pharmacycompany, aes(x=pharmacycompany$FirstLinkDate))
p <- p + geom_histogram(binwidth=15) + xlab('Time') + ylab('Number of Sites Linking') 
p <- p + ggtitle('New Sites Linking to Pharmacy Company\'s Website \n 2010 - 2013')
p <- p + annotate('rect', xmin=emptStart, xmax=emptEnd, ymin=0, ymax=15, alpha=0.2, color='red', fill='red')
p <- p + annotate('text', x=emptStart-150, y=16, color='red',
                  label='Duration of \n John\'s \n employment') 
p <- p + annotate('segment', color='blue', size=1.5,
                  x=penguinStart, y=0, xend=15450, yend=26)
p <- p + annotate('text', x=penguinStart+20, y=28, label='Google\'s\nPenguin update', color='blue')
p <- p + annotate('rect', xmin=dropOffStart, xmax=dropOffEnd, ymin=0, ymax=15, alpha=0.2, color='orange', fill='orange')
p <- p + annotate('text', x=dropOffStart+100, y=16, label='Drop-off', color='orange')
p <- p + annotate('segment', color='#009999', size=1.5,
             x=clientRetainedDate, y=0, xend=15320, yend=20)
p <- p + annotate('text', x=clientRetainedDate-60, y=21, 
                  label='Client retained', color='#009999')
p <- p + annotate('rect', color='purple', fill='purple', alpha=0.2,
             xmin=newStrategyStart, xmax=dataEnd, ymin=0, ymax=10)
p <- p + annotate('text', color='purple', x=dataEnd-50, y=13,
             label='New link \n building \n strategy')
p <- p + annotate('rect', color='grey', fill='grey', alpha=0.4,
             xmin=localDataStart, xmax=clientRetainedDate+30, ymin=0, ymax=8)
p <- p + annotate('text', x=localDataStart+200, y=9,
             label='Natural link build-ups')
p <- p + annotate('rect', color='#008800', fill='green', alpha=0.4,
             xmin=johnLinkBldgEffectStart+150, xmax=johnLinkBldgEffectEnd,
             ymin=0, ymax=11)
p <- p + annotate('text', x=johnLinkBldgEffectStart+60, y=11, color='#008800',
             label='John\'s link \n building \n effect')
p
dev.copy(png,'linking_sites_vs_time_pharmacycompany.png'); dev.off()

#### Plotting data for the Printing Shop
# SEO start date: 7/15/2011
clientRetainedDate <- as.Date('7/15/2011', format='%m/%d/%Y')
localDataStart <- min(printingshop$FirstLinkDate)
p <- ggplot(printingshop, aes(x=printingshop$FirstLinkDate))
p <- p + geom_histogram(binwidth=15) + xlab('Time') + ylab('Number of Sites Linking') 
p <- p + ggtitle('New Sites Linking to Printing Shop\'s Website \n 2009 - 2013')
p <- p + annotate('rect', alpha=0.2, color='red', fill='red',
                  xmin=emptStart, xmax=emptEnd, ymin=0, ymax=130)
p <- p + annotate('text', x=emptStart-130, y=155, color='red',
                  label='Duration \n of John\'s \n employment') 
p <- p + annotate('segment', color='blue', size=1.5,
                  x=penguinStart, y=0, xend=15450, yend=175)
p <- p + annotate('text', x=penguinStart+90, y=195, 
                  label='Google\'s \n Penguin update', color='blue')
p <- p + annotate('rect', xmin=dropOffStart, xmax=dropOffEnd, ymin=0, ymax=70, alpha=0.2, color='orange', fill='orange')
p <- p + annotate('text', x=dropOffStart+170, y=80, label='Drop-off', color='orange')
p <- p + annotate('segment', color='#009999', size=1.5,
             x=clientRetainedDate, y=0, xend=15170, yend=100)
p <- p + annotate('text', x=clientRetainedDate-150, y=105, 
                  label='Client retained', color='#009999')
p <- p + annotate('rect', color='grey', fill='grey', alpha=0.2,
             xmin=localDataStart, xmax=clientRetainedDate, ymin=0, ymax=10)
p <- p + annotate('text', x=localDataStart+300, y=20,
                  label='Natural link build-ups')
p <- p + annotate('rect', color='purple', fill='purple', alpha=0.2,
             xmin=newStrategyStart, xmax=dataEnd, ymin=0, ymax=35)
p <- p + annotate('text', x=newStrategyStart+100, y=60, color='purple',
             label='New link \n building \n strategy')
p <- p + annotate('rect', color='#008800', fill='green', alpha=0.4,
             xmin=johnLinkBldgEffectStart, xmax=johnLinkBldgEffectEnd,
             ymin=0, ymax=100)
p <- p + annotate('text', color='#008800', x=emptStart+450, y=115,
             label='John\'s link \n building effect')
p 
dev.copy(png,'linking_sites_vs_time_printingshop.png'); dev.off()

#### Plotting data for the Sushi Restaurant
# SEO start date: 11/14/2011
clientRetainedDate <- as.Date('11/14/2011', format='%m/%d/%Y')
p <- ggplot(sushirestaurant, aes(x=sushirestaurant$FirstLinkDate))
p <- p + geom_histogram(binwidth=15) + xlab('Time') + ylab('Number of Sites Linking') 
p <- p + ggtitle('New Sites Linking to Sushi Restaurant\'s Website \n 2008 - 2013')
p <- p + annotate('rect', alpha=0.2, color='red', fill='red',
                  xmin=emptStart, xmax=emptEnd, ymin=0, ymax=20)
p <- p + annotate('text', x=emptStart-30, y=23, color='red',
                  label='Duration \n of John\'s \n employment') 
p <- p + annotate('segment', color='blue', size=1.5,
                  x=penguinStart, y=0, xend=15450, yend=27)
p <- p + annotate('text', x=penguinStart+10, y=28.5, label='Google\'s\nPenguin update', color='blue')
p <- p + annotate('rect', xmin=dropOffStart, xmax=dropOffEnd, ymin=0, ymax=20, alpha=0.2, color='orange', fill='orange')
p <- p + annotate('text', x=dropOffStart+100, y=21, label='Drop-off', color='orange')
p <- p + annotate('segment', color='#009999', size=1.5,
             x=clientRetainedDate, y=0, xend=15300, yend=18)
p <- p + annotate('text', x=clientRetainedDate-200, y=19,
             label='Client retained', color='#009999')
p  # possibly no link building has been performed for the client
dev.copy(png,'linking_sites_vs_time_sushirestaurant.png'); dev.off()

#### Plotting data for the Autoshop
# SEO start date: 2/14/2012
clientRetainedDate <- as.Date('2/14/2012', format='%m/%d/%Y')
localDataStart <- min(autoshop$FirstLinkDate)
p <- ggplot(autoshop, aes(x=autoshop$FirstLinkDate))
p <- p + geom_histogram(binwidth=15) + xlab('Time') + ylab('Number of Sites Linking') 
p <- p + ggtitle('New Sites Linking to Autoshop\'s Website \n 2010 - 2013')
p <- p + annotate('rect', color='red', fill='red', alpha=0.2,
                  xmin=emptStart, xmax=emptEnd, ymin=0, ymax=20)
p <- p + annotate('text', x=emptStart+70, y=23.5, color='red',
                  label='Duration \n of John\'s \n employment') 
p <- p + annotate('segment', color='blue', size=1.5,
                  x=penguinStart, y=0, xend=15450, yend=27)
p <- p + annotate('text', x=penguinStart-50, y=30, label='Google\'s \n Penguin \n Update', color='blue')
p <- p + annotate('rect', xmin=dropOffStart, xmax=dropOffEnd, ymin=0, ymax=13, alpha=0.2, color='orange', fill='orange')
p <- p + annotate('text', x=dropOffStart+100, y=14, label='Drop-off', color='orange')
p <- p + annotate('segment', color='#009999', size=1.5,
                  x=clientRetainedDate, y=0, xend=15385, yend=15)
p <- p + annotate('text', x=clientRetainedDate-100, y=16,
                  label='Client retained', color='#009999')
p <- p + annotate('rect', color='purple', fill='purple', alpha=0.2,
             xmin=newStrategyStart, xmax=dataEnd, ymin=0, ymax=25)
p <- p + annotate('text', x=newStrategyStart+90, y=28, color='purple',
             label='New link \n building strategy')
p <- p + annotate('rect', color='grey', fill='grey', alpha=0.4, 
             xmin=localDataStart, xmax=clientRetainedDate, ymin=0, ymax=3)
p <- p + annotate('text', x=localDataStart+200, y=4.5, 
             label='Natural link build-ups')
p <- p + annotate('rect', color='#008800', fill='green', alpha=0.4,
             xmin=clientRetainedDate, xmax=johnLinkBldgEffectEnd, ymin=0, ymax=10)
p <- p + annotate('text', x=clientRetainedDate-100, y=8, color='#008800', 
             label='John\'s link \n building effect')
p
dev.copy(png,'linking_sites_vs_time_autoshop.png'); dev.off()

#### Plotting data for the ALS Nonprofit
# SEO start date: 8/8/2011
clientRetainedDate <- as.Date('8/8/2011', format='%m/%d/%Y')
p <- ggplot(nonprofit, aes(x=nonprofit$FirstLinkDate))
p <- p + geom_histogram(binwidth=15) + xlab('Time') + ylab('Number of Sites Linking') 
p <- p + ggtitle('New Sites Linking to ALS Nonprofit\'s Website \n 2008 - 2013')
p <- p + annotate('rect', color='red', fill='red', alpha=0.2,
                  xmin=emptStart, xmax=emptEnd, ymin=0, ymax=15)
p <- p + annotate('text', x=emptStart, y=17, color='red',
                  label='Duration \n of John\'s \n employment') 
p <- p + annotate('segment', color='blue', size=1.5,
                  x=penguinStart, y=0, xend=15450, yend=18)
p <- p + annotate('text', x=penguinStart-50, y=20, label='Google\'s \n Penguin \n Update', color='blue')
p <- p + annotate('rect', xmin=dropOffStart, xmax=dropOffEnd, ymin=0, ymax=13, alpha=0.2, color='orange', fill='orange')
p <- p + annotate('text', x=dropOffStart+80, y=14, label='Drop-off', color='orange')
p <- p + annotate('segment', color='#009999', size=1.5,
                  x=clientRetainedDate, y=0, xend=15190, yend=14)
p <- p + annotate('text', x=clientRetainedDate-200, y=14.5, 
             label='Client retained', color='#009999')
p  
# While we do see some evidence of John's link building work, because there is a sizeable
# previous natural link build-ups, we cannot determine just how much his work has contributed 
# to the spike shortly after his employment with the company.
# For the same reason, while we do see some evidence of new some work done under
# the new link building strategy, we cannot fully credit the increase to the SEO company
# because such increase could very well have been the cause of natural link build-ups.
dev.copy(png,'linking_sites_vs_time_nonprofit.png'); dev.off()

#### Plotting data for the Cosmetic Dental
# SEO start date: 3/12/2012
clientRetainedDate <- as.Date('3/12/2012', format='%m/%d/%Y')
p <- ggplot(cosmeticdental, aes(x=cosmeticdental$FirstLinkDate))
p <- p + geom_histogram(binwidth=15) + xlab('Time') + ylab('Number of Sites Linking') 
p <- p + ggtitle('New Sites Linking to Cosmetic Dental\'s Website \n 2008 - 2013')
p <- p + annotate('rect', color='red', fill='red', alpha=0.2,
                  xmin=emptStart, xmax=emptEnd, ymin=0, ymax=5)
p <- p + annotate('text', x=emptStart-200, y=5.5, color='red',
                  label='Duration of John\'s \n employment') 
p <- p + annotate('segment', color='blue', size=1.5,
                  x=penguinStart, y=0, xend=15450, yend=6)
p <- p + annotate('text', x=penguinStart-20, y=6.5, label='Google\'s \n Penguin update', color='blue')
p <- p + annotate('rect', xmin=dropOffStart, xmax=dropOffEnd, ymin=0, ymax=2, alpha=0.2, color='orange', fill='orange')
p <- p + annotate('text', x=dropOffStart+110, y=2.2, label='Drop-off', color='orange')
p <- p + annotate('segment', color='#009999', size=1.5,
             x=clientRetainedDate, y=0, xend=15410, yend=4)
p <- p + annotate('text', color='#009999', x=clientRetainedDate-200, y=4.2, 
              label='Client retained')
p
# It seems no link building has been done for the client by the SEO company.
dev.copy(png,'linking_sites_vs_time_cosmeticdental.png'); dev.off()

#### Plotting data for the Roofing Company
# SEO start date: 7/3/2012
clientRetainedDate <- as.Date('7/3/2012', format='%m/%d/%Y')
p <- ggplot(roofingcompany, aes(x=roofingcompany$FirstLinkDate))
p <- p + geom_histogram(binwidth=15) + xlab('Time') + ylab('Number of Sites Linking') 
p <- p + ggtitle('New Sites Linking to Roofing Company\'s Website \n 2008 - 2013')
p <- p + annotate('rect', color='red', fill='red', alpha=0.2,
                  xmin=emptStart, xmax=emptEnd, ymin=0, ymax=5)
p <- p + annotate('text', x=emptStart, y=6, color='red',
                  label='Duration \n of John\'s \n employment') 
p <- p + annotate('segment', color='blue', size=1.5,
                  x=penguinStart, y=0, xend=15450, yend=8)
p <- p + annotate('text', x=penguinStart-50, y=9, color='blue',
                  label='Google\'s \n Penguin update')
p <- p + annotate('rect', xmin=dropOffStart, xmax=dropOffEnd, ymin=0, ymax=5, alpha=0.2, color='orange', fill='orange')
p <- p + annotate('text', x=dropOffStart+130, y=5.5, label='Drop-off', color='orange')
p <- p + annotate('segment', color='#009999', size=1.5,
                  x=clientRetainedDate, y=0, xend=15520, yend=7.5)
p <- p + annotate('text', x=clientRetainedDate+220, y=7.5,
                  label='Client retained', color='#009999')
p
# It seems no link building was performed for the roofing company 
# during John's employment and only minimal linking building efforts were made
# under the new link building strategy.
dev.copy(png,'linking_sites_vs_time_roofingcompany.png'); dev.off()

#### Plotting data for the IT Company 2
# SEO start date: Unknown (before June 8, 2012)
localDataStart <- min(itcompany$FirstLinkDate)
p <- ggplot(itcompany, aes(x=itcompany$FirstLinkDate))
p <- p + geom_histogram(binwidth=15) + xlab('Time') + ylab('Number of Sites Linking') 
p <- p + ggtitle('New Sites Linking to IT Company 2\'s Website \n 2008 - 2013')
p <- p + annotate('rect', color='red', fill='red', alpha=0.2,
                  xmin=emptStart, xmax=emptEnd, ymin=0, ymax=13)
p <- p + annotate('text', x=emptStart-100, y=14, color='red',
                  label='Duration of John\'s \n employment') 
p <- p + annotate('segment', color='blue', size=1.5,
                  x=penguinStart, y=0, xend=15450, yend=16)
p <- p + annotate('text', x=penguinStart-20, y=17, color='blue',
              label='Google\'s \n Penguin update')
p <- p + annotate('rect', alpha=0.2, color='orange', fill='orange',
              xmin=dropOffStart, xmax=dropOffEnd, ymin=0, ymax=7)
p <- p + annotate('text', x=dropOffStart+110, y=8, label='Drop-off', color='orange')
p <- p + annotate('rect', color='grey', fill='grey', alpha=0.4,
             xmin=localDataStart, xmax=emptStart, ymin=0, ymax=3)
p <- p + annotate('text', x=localDataStart+500, y=4, 
             label='Natural link build-ups')
p <- p + annotate('rect', color='purple', fill='purple', alpha=0.2,
             xmin=newStrategyStart, xmax=dataEnd, ymin=0, ymax=10)
p <- p + annotate('text', x=newStrategyStart+60, y=12.5, color='purple',
             label='New link \n building \n strategy')
p <- p + annotate('rect', color='#008800', fill='green', alpha=0.4,
             xmin=johnLinkBldgEffectStart, xmax=johnLinkBldgEffectEnd,
             ymin=0, ymax=6)
p + annotate('text', x=emptStart-90, y=7.5, color='#008800',
             label='John\'s link \n building \n effect')
dev.copy(png,'linking_sites_vs_time_itcompany.png'); dev.off()


###### Combine data that have noticeable effects under John's linking building work 
###### and under the new linking build strategy
# Include Autoshop, Car Dealership, IT Company 2, Pharmacy Company, Printing Shop 
# Do not include Cosmetic Dental, Nonprofit, Roofing Company, Sushi Restaurant
selectCond <- seo_data$domainName %in% c('autoshop-com', 'cardealership-com', 'itcompany-com',
                                       'pharmacycompany-com', 'printingshop-com')
data <- seo_data[selectCond, ]
table(data$domainName)


###### Split the data into three categories:
###### 1. Natural link build-up
###### 2. Old link building method
###### 3. New link building method
newMethdSelectCond <- data$FirstLinkDate >= newStrategyStart  # selector condition for new link building strategy
naturalLinkSelectCond <- data$FirstLinkDate < johnLinkBldgEffectStart  # selector condition for natural link build-ups

oldMethodData <- subset(data, FirstLinkDate >= johnLinkBldgEffectStart & FirstLinkDate <= johnLinkBldgEffectEnd)
newMethodData <- data[newMethdSelectCond, ]
naturalLinkData <- data[naturalLinkSelectCond, ]

nrow(data)
nrow(oldMethodData)
nrow(newMethodData)
nrow(naturalLinkData)
# note that nrow(data) is roughly equal to nrow(oldMethodData) + nrow(newMethodData) + nrow(naturalLinkData)


###### Compare the average number of links per linking site among three categories
mean(oldMethodData$BackLinks)
mean(newMethodData$BackLinks)
mean(naturalLinkData$BackLinks)

Below three histograms not useful at all and hence commented out
#hist(oldMethodData$BackLinks)
#hist(newMethodData$BackLinks)
#hist(naturalLinkData$BackLinks)


###### Compare the average citation flow among three categories
# Definition of citation flow: 
meanOldMtdCF <- mean(oldMethodData$CitationFlow)
meanNewMtdCF <- mean(newMethodData$CitationFlow)
meanNaturalLkCF <- mean(naturalLinkData$CitationFlow)
meanOldMtdCF; meanNewMtdCF; meanNaturalLkCF

par(mfrow=c(3, 1))
hist(oldMethodData$CitationFlow, col='yellow', 
     main='Citation Flow under Old Link Buildling Method', xlab='Citation Flow')
abline(v=meanOldMtdCF, col='red', lwd=4)
hist(newMethodData$CitationFlow, col='pink',
     main='Citation Flow under New Link Building Strategy', xlab='Citation Flow')
abline(v=meanNewMtdCF, col='red', lwd=4)
hist(naturalLinkData$TrustFlow, col='orange',
     main='Citation Flow under Natural Link Build-Ups', xlab='Citation Flow')
abline(v=meanNaturalLkCF, col='red', lwd=4)
dev.copy(png,'citation_flow_histograms.png'); dev.off()

###### Compare the average trust flow among three categories
# Definition of trust flow:
meanOldMtdTF <- mean(oldMethodData$TrustFlow)
meanNewMtdTF <- mean(newMethodData$TrustFlow)
meanNaturalLkTF <- mean(naturalLinkData$TrustFlow)
meanOldMtdTF; meanNewMtdTF; meanNaturalLkTF

par(mfrow=c(3, 1))
hist(oldMethodData$TrustFlow, col='yellow', 
     main='Trust Flow under Old Link Building Method', xlab='Trust Flow')
abline(v=meanOldMtdTF, col='red', lwd=4)
hist(newMethodData$TrustFlow, col='pink',
     main='Trust Flow under New Link Building Strategy', xlab='Trust Flow')
abline(v=meanNewMtdTF, col='red', lwd=4)
hist(naturalLinkData$TrustFlow, col='orange', 
     main='Trust Flow under Natural Link Build-Ups', xlab='Trust Flow')
abline(v=meanNaturalLkTF, col='red', lwd=4)
dev.copy(png,'trust_flow_histograms.png'); dev.off()


###### AMBIGUOUS DATA LABELS; NOT SURE WHAT EXACTLY THEY REPRESENT
###### INQUIRY TO MAJESTIC SEO SUBMITTED ON OCTOBER 13, 2013
mean(oldMethodData$RefDomains)
mean(newMethodData$RefDomains)
mean(naturalLinkData$RefDomains)

mean(oldMethodData$ExtBackLinks)
mean(newMethodData$ExtBackLinks)
mean(naturalLinkData$ExtBackLinks)

###### SHOCKING FIND HERE
###### MISLED DATA ANALYSIS AS A RESULT OF MY CONFIRMATION BIAS
#### For all non-SEO clients' websites
p <- ggplot(non_seo_data, aes(x=non_seo_data$FirstLinkDate))
p <- p + geom_histogram(binwidth=30) + xlab('Time') + ylab('Number of Sites Linking')
p <- p + ggtitle('New Sites Linking to All non-SEO Client Websites \n 2008 - 2013')
p <- p + annotate('rect', alpha=0.2, color='red', fill='red',
                  xmin=emptStart, xmax=emptEnd, ymin=0, ymax=750)
p <- p + annotate('text', x=emptStart-225, y=770, label='Duration of \n John\'s \n employment', color='red') 
p <- p + annotate('segment', color='blue',
                  x=penguinStart, y=0, xend=15450, yend=900, size=1.5)
p <- p + annotate('text', x=penguinStart+150, y=1000, label='Google\'s \n Penguin update', color='blue')
p <- p + annotate('rect', alpha=0.2, color='orange', fill='orange', 
                  xmin=dropOffStart, xmax=dropOffEnd, ymin=0, ymax=250)
p <- p + annotate('text', x=dropOffStart+50, y=275, label='Drop-off', color='orange')
p <- p + annotate('rect', alpha=0.4, color='#008800', fill='green',
                  xmin=johnLinkBldgEffectStart, xmax=johnLinkBldgEffectEnd, 
                  ymin=0, ymax=220)
p <- p + annotate('text', x=emptStart-250, y=240, color='#008800',
                  label='John\'s \n link building \n effect')
p <- p + annotate('rect', alpha=0.2, color='purple', fill='purple',
                  xmin=newStrategyStart, xmax=dataEnd, ymin=0, ymax=550)
p <- p + annotate('text', color='purple', x=newStrategyStart, y=650,
                  label='New link \n building \n strategy')
p <- p + annotate('rect', color='grey', fill='grey', alpha=0.4,
                  xmin=dataStart, xmax=naturalLinkBuildUpEnd, ymin=0, ymax=80)
p <- p + annotate('text', x=dataStart+750, y=130,
                  label='Natural link build-ups')
p
dev.copy(png,'linking_sites_vs_time_non_seo.png'); dev.off()











############################### OLD, OUTDATED ANALYSIS ###############################

###### Preparing for time vs. backlinking domains graph
# this is an unfiltered number of sites (duplications are counted again since
# sites backlinks to different clients' sites)
nSitesUF <- length(seo_data$FirstLinkDate)

# number of recurring backlinking sites
length(unique(seo_data$Domain[duplicated(seo_data$Domain)]))

# number of non-recurring backlinking sites
length(unique(seo_data$Domain[!duplicated(seo_data$Domain)]))

# filtered number of sites (duplicates are not counted)
nSitesF <- length(unique(seo_data$Domain[duplicated(seo_data$Domain)])) + length(unique(seo_data$Domain[!duplicated(seo_data$Domain)]))
nSitesF


###### Showing number of sites and backlinks by country
table(seo_data$CountryCode)


###### Some Useful Info
# number of recurring backlinking sites
length(unique(seo_data$Domain[duplicated(seo_data$Domain)]))

# number of non-recurring backlinking sites
length(unique(seo_data$Domain[!duplicated(seo_data$Domain)]))

# list of recurring backlinking sites
unique(seo_data$Domain[duplicated(seo_data$Domain)])


###### Examining the relationship between number of backsites and trustflow of websites 
plot(seo_data$BackLinks, seo_data$TrustFlow, col="blue", pch=19)
plot(log(seo_data$BackLinks), seo_data$TrustFlow, col="blue", pch=19)
lm1 <- lm(seo_data$TrustFlow ~ seo_data$BackLinks)
abline(lm1)  # I see no clear relationship.

# plotting residuals
plot(lm1$residuals, main="Residuals")
abline(h = 0, col="red", lwd=3)


###### Examining the relationshiop between number of backlinks and trustflow
plot(seo_data$BackLinks, seo_data$TrustFlow, col="blue", pch=19)
plot(seo_data$BackLinks, seo_data$TrustFlow, col="blue", pch=19, xlim=c(0, 60))
lm2 <- lm(seo_data$TrustFlow ~ seo_data$BackLinks)
abline(lm2)

# plotting residuals
plot(lm2$residuals, main="Residuals")
abline(h = 0, col="red", lwd=3)


###### Examing the relationship between position and number of backlinks
plot(seo_data$BackLinks, seo_data$Position, col="blue", pch=19)
plot(log(seo_data$BackLinks), seo_data$Position, col="blue", pch=19)
plot(log(log(seo_data$BackLinks)), seo_data$Position, col="blue", pch=19)


