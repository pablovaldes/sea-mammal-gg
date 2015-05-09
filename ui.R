## User interface R file.
library(shiny)

shinyUI(fluidPage(
    
    ## Application title
    titlePanel(h1("A Northern Fur Seal's Journey")),
    
    ## Here's the "layout" of the shiny app that I'll use.
    sidebarLayout(
        sidebarPanel(
            h3("Explore"),
            p("See what this Northern Fur Seal was doing on its trip to sea. She
            left Saint Paul Island, AK on August 26, 2011 and returned August
            31, 2011."),
            p("Full-trip data are shown in the backgrounds of the magnetometer
            and overview plot. Overlaid are data over some period of time
            specified by you below, up until the date specified by you below."),
            p("Press the 'play' button to see an animation (albeit a slow one --
            you'll have to wait ~6 seconds between each frame)."),
            sliderInput("delta_t",
                        "Time span to view (minutes)",
                        min = 1,
                        max = 120,
                        value = 30),
            sliderInput("current_t",
                        "Choose the 'current' time (day of August):",
                        min = 26.1,
                        max = 31,
                        value = 28.95,
                        animate = animationOptions(interval = 6000)),
            checkboxInput("yes_night",
                          label = "Display Night (shaded) and Day\non dive plot",
                          value = 1)
        ),
        mainPanel(
            fluidRow(
                plotOutput("magPlot")
                ),
            fluidRow(
                column(6,
                       plotOutput("mapPlot")
                       ),
                column(6,
                       plotOutput("depthPlot")
                       )
                )
            
        )
        
        
    )

))