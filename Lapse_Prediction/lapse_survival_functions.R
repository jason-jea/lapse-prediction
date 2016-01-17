library(survival)
library(ggplot2)
library(plyr)
library(dplyr)
library(reshape2)
library(RODBC)
library(RJDBC)
library(RPostgreSQL)
library(tidyr)
library(lubridate)
library(rmarkdown)
library(scales)
library(RColorBrewer)
library(stringr)


filterGoodVariables <-
  function(data) {
    goodColumns <-
      data %>% 
      colwise(sum)(.) %>% 
      melt(data=.) %>%
      filter(value!=0) %>%
      select(variable)
    
    return(data[,goodColumns[,1]])
  }


oneVarSurvData <- function(model, data, metric, values) {
  avgdata <- colwise(mean)(data)
  avgdata <- avgdata[,names(avgdata) != metric]
  
  finaldata <-
    data.frame(avgdata[rep(seq_len(nrow(avgdata)),length(values)),], 
               newcol = values)
  
  names(finaldata)[names(finaldata) == "newcol"] <- metric
  
  fit <- survfit(lapse.model1, newdata = finaldata)
  
  plot.data <-
    data.frame(cbind(time = fit[[2]], survivalrate = fit[[6]]))
  
  names(plot.data)[1:length(values) + 1] <- paste(values, metric, sep = " ")
  
  plot.data <- 
    plot.data %>% melt("time") %>% dcast(time~variable)
  
  return(plot.data)
  
}

compareVarSurvData <- function(model, data, metrics, value) {
  
  data[,colwise(class)(data) == "factor"] <- colwise(as.numeric)(data[,colwise(class)(data) == "factor"]) - 1
  
  avgdata <- colwise(mean)(data)
  
  avgdata <- 
    cbind(avgdata[rep(seq_len(nrow(avgdata)),length(metrics)),], seqnum = seq(1:length(metrics))) %>% melt("seqnum")
  
  metrics <- data.frame(cbind(metrics, seqnum = seq(1:length(metrics))))
  
  avgdata[avgdata$variable %in% metrics$metrics,]$value <- 0
  
  avgdata <-
    ddply(metrics, 1, function(metrics) {
      
      avgdata[avgdata$seqnum == as.numeric(metrics$seqnum) & avgdata$variable == as.character(metrics$metrics),]$value <- 
        avgdata[avgdata$seqnum == as.numeric(metrics$seqnum) & avgdata$variable == as.character(metrics$metrics),]$value + value
      
      return(avgdata)
    })
  
  avgdata <- 
    avgdata[,2:4] %>%
    dcast(., seqnum~variable, fun = mean)
  
  fit <- survfit(model, newdata = avgdata[2:ncol(avgdata)])
  
  plot.data <-
    data.frame(cbind(time = fit[[2]], survivalrate = fit[[6]]))
  
  names(plot.data)[1:nrow(metrics) + 1] <- paste(value, metrics$metrics, sep = " ")
  
  plot.data <- 
    plot.data %>% melt("time") %>% dcast(time~variable)
  
  return(plot.data)
  
}

convertNames <- function(variableVec) {

  namesData <-  data.frame(matrix(unlist(str_split(variableVec, '_', 3)), nrow = length(variableVec), byrow = T))
  
  namesData[,2] <- str_replace(namesData[,2],'counts','')
  
  names <- paste("ACTION: ", namesData[,2], "  \n  PAGE TYPE: ", namesData[,1], "  \n  CONTENT TYPE: ", namesData[,3], "\n", sep="")
  
  variableNames <- data.frame(cbind(variableVec, names))
  
  return (variableNames)
  
}

parseNames <- function(variableVec) {
  
  namesData <-  data.frame(matrix(unlist(str_split(variableVec, '_', 3)), nrow = length(variableVec), byrow = T))
  
  namesData[,2] <- str_replace(namesData[,2],'counts','')
  
  names <- cbind(action = as.character(namesData[,2]), page = as.character(namesData[,1]), 
                 content = as.character(namesData[,3]))
  
  variableNames <- data.frame(cbind(variableVec, names))
  
  return (variableNames)
  
}


