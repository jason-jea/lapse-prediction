library(shiny)
source("lapse_survival_functions.R")
options(error = NULL)

variablesChosen <<- c(sort(as.character(convertNames(colnames(lapse.cleandata[,1:(length(lapse.cleandata) - 3)]))$names))[1])


shinyServer(function(input, output, session) {
  
  namesData <- parseNames(colnames(lapse.cleandata[,1:(length(lapse.cleandata) - 2)]))
  namesData <- namesData[as.character(namesData$variableVec) != "totalactions",]
  
  output$colnames <- renderUI({
    
    selectizeInput(
      'variables', 'Variables to Compare', 
      choices = sort(as.character(convertNames(colnames(lapse.cleandata[,1:(length(lapse.cleandata) - 2)]))$names)),
      multiple = TRUE, 
      selected = variableName(),
      options = list(maxItems = 6)
    )
    
  })
  

  output$actionName <- renderUI({
    
    selectizeInput(
      'action', 'Select Action Type:', 
      choices = sort(as.character(namesData$action)),
      multiple = FALSE
    )
    
  })
  
  output$pageName <- renderUI({
    
    namesData <- namesData[as.character(namesData$action) == input$action,]
    
    selectizeInput(
      'page', 'Select Page Type:', 
      choices = sort(as.character(namesData$page)),
      multiple = FALSE
    )
    
  })
  
  
  output$contentName <- renderUI({
    
    namesData <- namesData[as.character(namesData$action) == input$action & 
                             as.character(namesData$page) == input$page,]
    
    selectizeInput(
      'content', 'Select Content Type:', 
      choices = sort(as.character(namesData$content)),
      multiple = FALSE
    )
    
  })
  
  variableDict <- reactive({
    
    variables <- c(unique(input$variables))
    
    variableNames <- convertNames(colnames(lapse.cleandata[,1:(length(lapse.cleandata) - 2)]))
    
    variableNames <- variableNames[as.character(variableNames$names) %in% variables,]
    
    return(variableNames)
  })


  output$plot1 <- renderPlot ({
    
    
    variableNames <- variableDict()
    
     
    
    plot.data <- compareVarSurvData(lapse.model1, lapse.cleandata[,1:(length(lapse.cleandata) - 2)], 
                                    as.character(variableNames$variableVec), 1)
    
    plot.data <- melt(plot.data,"time")
    
    variableNames$variableVec <- factor(paste("1 ", variableNames$variableVec, sep=""))
    
    plot.data$variable <- factor(plot.data$variable, levels=levels(variableNames$variableVec)
                                 , labels = variableNames$names)
    
    p <-
    ggplot(data = filter(plot.data, time <= 60), aes(x = time, y = value, colour = variable)) + geom_line(size = .75) + theme_bw() +
      scale_y_continuous(labels = percent, name = "Survival Probability") + scale_x_continuous(name = "Days after First Launch") +
      scale_colour_manual(name = "Number actions in first 28 days",values = brewer.pal(6, "Set2")) 
    
    print(p)
  })
  
  output$plot2 <- renderPlot ({
    
    
    variableNames <- variableDict()
    
    plot.data <- compareVarSurvData(lapse.model1, lapse.cleandata[,1:(length(lapse.cleandata) - 2)], 
                                    as.character(variableNames$variableVec), 1)
    
    plot.data <- melt(plot.data,"time")
    
    variableNames$variableVec <- factor(paste("1 ", variableNames$variableVec, sep=""))
    
    plot.data$variable <- factor(plot.data$variable, levels=levels(variableNames$variableVec)
                                 , labels = variableNames$names)
    
    plot.data <- filter(plot.data, abs(value - .5) < .01) %>% group_by(variable) %>% summarise(time = mean(time))
    
    p <-
      ggplot(data = plot.data, aes(x = variable, y = time, fill = variable)) + 
      geom_bar(stat= "identity", width = .2) + 
      theme_bw() + scale_fill_manual(name = "Number actions in first 28 days",values = brewer.pal(6, "Set2")) +
      scale_y_continuous(name = "Half-Life Time") + scale_x_discrete(name = "Variables")
    
    print(p)
  })
  
  
  output$table1 <- renderTable ({
    
    variableNames <- variableDict()
    
    coefficients <- data.frame(summary(lapse.model1)$coefficients)
    
    coefficients <- cbind(variableName = row.names(coefficients), coefficients)
    
    coefficients <- coefficients[as.character(coefficients$variableName) %in% as.character(variableNames$variableVec),]
    
   
    coefficients <- merge(coefficients,variableNames, by.x = "variableName", by.y = "variableVec")
    
    row.names(coefficients) <- as.character(coefficients$names)
    
    coefficients$significant <- ifelse(coefficients[,6] <= .1, 'YES', 'NO')
    
    coefficients[,c(2:6,8)]
    
  }, digits = 4)
  
  output$description <- renderText({
    
    "This application allows you to visually 
compare the results of a Cox-Proportional Hazards Model 
run on RMN Native App user data. The coefficients 
can be interpretated as a multiplicative effect of the
    covariate on the user hazard function.  Hence, 
a positive coefficient has a negative effect 
    on a user's survival curve, and vice-versa."
    
  })

  output$variableName <- renderUI({
    
    name <- paste("ACTION: ", input$action, "  \n  PAGE TYPE: ", input$page, "  \n  CONTENT TYPE: ", 
                          input$content, "\n", sep="")
    
    result <- ifelse(as.character(name) %in% as.character(convertNames(colnames(lapse.cleandata[,1:(length(lapse.cleandata) - 3)]))$names),
                     name, "ERROR: Variable not found")
    
    return(result)
    
  })
  
  variableName <- reactive({
    
    input$goButton
    input$exitButton
    
    if (clear$clear) return(variablesChosen <<- c())
    
    name <- isolate(paste("ACTION: ", input$action, "  \n  PAGE TYPE: ", input$page, "  \n  CONTENT TYPE: ", 
                  input$content, "\n", sep=""))
    
    variablesChosen <<- c(variablesChosen,name)
    
    return(variablesChosen)
    
  })

  clear <- reactiveValues(clear = TRUE)
  
  
  observeEvent(input$exitButton, {
  
      clear$clear <- TRUE
      

  })
  

  observeEvent(input$goButton, {
    
    clear$clear <- FALSE
    
  })
  
  
})