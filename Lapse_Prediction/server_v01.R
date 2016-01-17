library(shiny)
source("lapse_survival_functions.R")
options(error = NULL)


shinyServer(function(input, output) {
  
  output$colnames1 <- renderUI({
    
    selectInput("variable1", "Variable One:", 
                as.character(convertNames(colnames(lapse.cleandata[,1:(length(lapse.cleandata) - 2)]))$names))
    
  })
  
  output$colnames2 <- renderUI({
    
    selectInput("variable2", "Variable Two:", 
                as.character(convertNames(colnames(lapse.cleandata[,1:(length(lapse.cleandata) - 2)]))$names))
    
  })
  
  output$colnames3 <- renderUI({
    
    selectInput("variable3", "Variable Three:", 
                as.character(convertNames(colnames(lapse.cleandata[,1:(length(lapse.cleandata) - 2)]))$names))
    
  })
  
  output$colnames4 <- renderUI({
    
    selectInput("variable4", "Variable Four:", 
                as.character(convertNames(colnames(lapse.cleandata[,1:(length(lapse.cleandata) - 2)]))$names))
    
  })
  
  output$colnames5 <- renderUI({
    
    selectInput("variable5", "Variable Five:", 
                as.character(convertNames(colnames(lapse.cleandata[,1:(length(lapse.cleandata) - 2)]))$names))
    
  })
  
  output$colnames6 <- renderUI({
    
    selectInput("variable6", "Variable Six:", 
                as.character(convertNames(colnames(lapse.cleandata[,1:(length(lapse.cleandata) - 2)]))$names))
    
  })
  
  
  variableDict <- reactive({
    
    variables <- c(unique(c(input$variable1,input$variable2,input$variable3,input$variable4,
                              input$variable5,input$variable6)))
    
    variableNames <- convertNames(colnames(lapse.cleandata[,1:(length(lapse.cleandata) - 2)]))
    
    variableNames <- variableNames[as.character(variableNames$names) %in% variables,]
    
    return(variableNames)
  })


  output$plot1 <- renderPlot ({
    
    
    variableNames <- variableDict()
    
     
    
    plot.data <- compareVarSurvData(lapse.model1, lapse.cleandata[,1:(length(lapse.cleandata) - 2)], as.character(variableNames$variableVec), 1)
    
    plot.data <- melt(plot.data,"time")
    
    variableNames$variableVec <- factor(paste("1 ", variableNames$variableVec, sep=""))
    
    plot.data$variable <- factor(plot.data$variable, levels=levels(variableNames$variableVec)
                                 , labels = variableNames$names)
    
    p <-
    ggplot(data = plot.data, aes(x = time, y = value, colour = variable)) + geom_line(size = 1.2) + theme_bw() +
      scale_y_continuous(labels = percent, name = "Survival Probability") + scale_x_continuous(name = "Days after First Launch") +
      scale_colour_manual(name = "Number actions in first 28 days",values = brewer.pal(6, "Set2"))
    
    print(p)
  })
  
  
  output$table1 <- renderTable ({
    
    variableNames <- variableDict()
    
    coefficients <- data.frame(summary(lapse.model1)$coefficients)
    
    coefficients <- cbind(variableName = row.names(coefficients), coefficients)
    
    coefficients <- coefficients[as.character(coefficients$variableName) %in% as.character(variableNames$variableVec),]
    
   
    coefficients <- merge(coefficients,variableNames, by.x = "variableName", by.y = "variableVec")
    
    row.names(coefficients) <- as.character(coefficients$names)
    
    coefficients[,2:6]
    
  })
  
  
})