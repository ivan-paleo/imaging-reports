#
#

# Load libraries
library(shiny)
library(readODS)
#library(shinyforms)

# Define UI
ui <- fluidPage(

  # Application title
  titlePanel("Create a report for your microscope images at the IMaging Platform At LeizA (IMPALA)"),

  # Sidebar with a selection box to select the instrument for which the report will be created
  sidebarLayout(
    sidebarPanel(
      textInput("name", "Your name", "Ivan Calandra"),
      selectInput("instrument", "Choose the instrument",
                  c("Axio Imager.Z2 Vario + LSM 800 MAT", "Smartzoom 5")),
      img(src = "TraCEr_Logo_black.png", height = 150)
    ),

    # Show tabs
    mainPanel(
      tabsetPanel(
        tabPanel("General", uiOutput("general")),
        tabPanel("Acquisition", uiOutput("acq")),
        tabPanel("Pre-processing", uiOutput("proc")),
        tabPanel("Abbreviations", tableOutput("abbr")),
        tabPanel("Export report", fluidRow(
          tableOutput("general_set"),
          tableOutput("acq_set"),
          tableOutput("proc_set"),
          downloadButton("download", "Download Report"))
        )
      )
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  output$general <- renderUI({
    if (input$instrument == "Smartzoom 5") {
      soft <- c("Smartzoom", "ZEN core")
      acq_modes <- c("2D", "EDF", "3D", "Stitching")
      assign("setup", "Steel table on solid concrete base", envir = .GlobalEnv)
    }
    if (input$instrument == "Axio Imager.Z2 Vario + LSM 800 MAT") {
      soft <- c("ZEN blue", "ZEN core")
      acq_modes <- c("3D Topography", "EDF", "Stitching")
      assign("setup", "Passive anti-vibration table on solid concrete base", envir = .GlobalEnv)
    }
    tagList(
      selectInput("software", "Software", soft),
      textInput("version", "Software version", "2.6 HF 12"),
      checkboxInput("sf", "Shuttle-and-Find module used", FALSE),
      checkboxGroupInput("acq_mode", "Acquisition modes", acq_modes)
    )
  })
  report_general <- reactive({
    data.frame(
      Category = c("User", "Microscope", "Microscope", "Location", "Location", "Location", "Software",
                   "Acquisition modes", "Maintenance", "Maintenance", "Maintenance"),
      Setting = c("Name", "Manufacturer", "Model", "Facility", "Floor", "Setup",
                  "Software, version and modules", "",
                  "Last yearly inspection and calibration by manufacturer",
                  "Last topography correction for used objectives",
                  "Last control for used objectives with the roughness standard (nominal Ra = 0.40 ± 0.05 µm)"),
      Value = c(input$name, "Carl Zeiss Microscopy GmbH", input$instrument, "IMPALA, MONREPOS, Germany",
                "-1 (basement)", setup,
                paste0(input$software, " ", input$version, ", Shuttle-and-Find: ",  input$sf),
                paste(input$acq_mode, collapse = ", "),
                "2022-10-11", "2022-10-11", "2021-12-22")
    )
  })
  output$general_set <- renderTable({
    report_general()
  })

  output$abbr <- renderTable({
    data.frame(Abbreviation = c("AU", "HF", "LSM", "NA", "WD", "WF"),
               Explanation = c("Airy unit", "Hot fix", "Laser-scanning confocal microscopy",
                               "Numerical aperture", "Working distance", "Wide-field")
    )
  })

  output$report <- downloadHandler(
    filename = function() {
      paste0("report_", input$name, Sys.Date(), ".ods")
    },
    content = function(file){
      readODS::write_ods(report_general(), file, sheet = "General_settings")
      #readODS::write_ods(output$abbr, file, sheet = "Abbreviations", append = TRUE)
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)
