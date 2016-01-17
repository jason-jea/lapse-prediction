library(shiny)

shinyUI(fluidPage(
  
  titlePanel("Native App User Survival Curves"),
  
  tabsetPanel(
    tabPanel("Exploration",
      
      hr(),
      
      fluidRow (
        
        column(3, 
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
               br()
        ),
        
        column(9,plotOutput("plot1"))
        
      ),
      
      fluidRow(
        column(3,strong("This tab allows you to visually 
               compare the results of a Cox-Proportional Hazards Model 
                        run on RMN Native App user data. The coefficients 
                        can be interpretated as a multiplicative effect of the
                        covariate on the user hazard function.  Hence, 
                        a positive coefficient has a negative effect 
                        on a user's survival curve, and vice-versa."),
               br(),
               br(),
               
               p("The", span("top plot", style = "font-weight:bold"), " visualizes holding all else constant,
                 the effect of a one unit increase in a variable on 
                 the user's survival curve"),
               br(),
               
               p("The", span("bottom plot", style = "font-weight:bold"), "visualizes the half life for a hypothetical
                 user with a one unit increase above average for the respective
                 covariates of interest."),
               br(),
               
               p("The", span("table", style = "font-weight:bold"), "contains p-values and effect sizes for all covariates.
                 The effect of non significant covariates on the survival curve
                 should be ignored."),
               br()
               
               ),

        column(5,
               tableOutput("table1")
               ),
        
        column(4,
               plotOutput("plot2")
               )
        
        
        )
    ),
    tabPanel("Report")
  )
  
  
    
  
  
  
  ))