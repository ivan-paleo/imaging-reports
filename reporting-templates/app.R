#
#

# Load libraries
library(shiny)
library(shinyforms)

# Define UI
ui <- fluidPage(

    # Application title
    titlePanel("Create a report for your microscope images at the IMaging Platform At LeizA (IMPALA)"),

    # Sidebar with a selection box to select the instrument for which the report will be created
    sidebarLayout(
        sidebarPanel(
          img(src = "TraCEr_Logo_black.png", height = 150)
        ),

        # Show tabs
        mainPanel(
          #tabsetPanel(
          #  tabPanel("General", tableOutput("general")),
          #  tabPanel("Acquisition", tableOutput("acquisition")),
          #  tabPanel("Pre-processing", tableOutput("preprocessing")),
          #  tabPanel("Abbreviations", tableOutput("abbr"))
          div(
            id = "form",
            textInput("name", "Name", "Ivan Calandra"),
            selectInput("instrument", "Choose the instrument", c("LSM 800 MAT", "Smartzoom 5")),
            selectInput("software", "Software", c("ZEN blue", "ZEN core", "Smartzoom")),


            checkboxInput("used_shiny", "I've built a Shiny app in R before", FALSE),
            sliderInput("r_num_years", "Number of years using R", 0, 25, 2, ticks = FALSE),
            selectInput("os_type", "Operating system used most frequently",
                        c("",  "Windows", "Mac", "Linux")),
            actionButton("submit", "Submit", class = "btn-primary")
          )
        )
      )
    )

# Define server logic required to draw a histogram
server <- function(input, output) {

    output$abbr <- renderTable({
        data.frame(Abbreviation = c("AU", "HF", "LSM", "NA", "WD", "WF"),
                   Explanation = c("Airy unit", "Hot fix", "Laser-scanning confocal microscopy",
                                   "Numerical aperture", "Working distance", "Wide-field"))
    })
}

# Run the application
shinyApp(ui = ui, server = server)
