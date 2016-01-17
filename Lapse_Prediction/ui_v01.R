library(shiny)

shinyUI(fluidPage(
  
  
  headerPanel("Effect of Covariates on Native App User Survival Curves"),
  
  
  sidebarPanel(
    
    uiOutput("actionName"),
    uiOutput("pageName"),
    uiOutput("contentName"),
    uiOutput("variableName"),
    p("\n"),
    actionButton("goButton", "Create Variable!"),
    br(),
    br(),
    uiOutput("colnames"),
    actionButton("exitButton", "Start Over"),
    br(),
    br(),
    strong("This application allows you to visually 
compare the results of a Cox-Proportional Hazards Model 
run on RMN Native App user data. The coefficients 
can be interpretated as a multiplicative effect of the
    covariate on the user hazard function.  Hence, 
a positive coefficient has a negative effect 
    on a user's survival curve, and vice-versa.")
    
    
  ),
  
  mainPanel(
    
    plotOutput("plot1"),
    
    br(),
    br(),
    
    tableOutput("table1"),
    
    br(),
    
    plotOutput("plot2")
    
  )
  
  
))