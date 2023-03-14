# Shiny app to enter the settings of acquisitions at the IMPALA
# Download the settings in an editable (XLSX) report

# Load libraries
library(shiny)
library(writexl)
#library(shinyforms)

# Define UI
ui <- fluidPage(

  # Application title
  titlePanel("Create a report for your microscope images acquired at the IMaging Platform At LeizA (IMPALA)"),

  # Sidebar
  sidebarLayout(
    sidebarPanel(

      # Input text for user name
      textInput("name", "Your name", "Ivan Calandra"),

      # Selection box to select the instrument for which the report will be created
      selectInput("instrument", "Choose the instrument",
                  c("Axio Imager.Z2 Vario + LSM 800 MAT", "Smartzoom 5")),

      # TraCEr logo - will need to be replaced with IMPALA logo
      img(src = "TraCEr_Logo_black.png", height = 150)
    ),

    # Main panel
    mainPanel(

      # Tabs
      tabsetPanel(

        # Tabs, their UIs will be rendered in the server call below
        tabPanel("General", uiOutput("general")),
        tabPanel("Acquisition", uiOutput("acq")),
        tabPanel("Pre-processing", uiOutput("proc")),
        tabPanel("Abbreviations", tableOutput("abbr")),

        # Tab "Export report"
        tabPanel("Export report", fluidRow(

          # Shows the result of the user input in tables
          h2("General settings"),
          tableOutput("general_set"),
          h2("Acquisition settings"),
          tableOutput("acq_set"),
          h2("Pre-processing settings"),
          tableOutput("proc_set"),

          # Add a button to download the report
          downloadButton("downloadReport", "Download Report to XLSX"))
        )
      )
    )
  )
)

# Define server logic
server <- function(input, output) {

  # Render tab 'general'
  output$general <- renderUI({

    # create objects with different values depending on the instrument
    if (input$instrument == "Smartzoom 5") {
      soft <- c("Smartzoom", "ZEN core")
      acq_modes <- c("2D", "EDF", "3D", "Stitching")

      # Must be assigned to global environment so that it can be used outside of renderUI()
      # and inside 'report_general'
      assign("setup", "Steel table on solid concrete base", envir = .GlobalEnv)
      assign("maintenance", data.frame(Category = "Maintenance", Setting = "", Value = "NA"),
             envir = .GlobalEnv)
    }
    if (input$instrument == "Axio Imager.Z2 Vario + LSM 800 MAT") {
      soft <- c("ZEN blue", "ZEN core")
      acq_modes <- c("3D Topography", "EDF", "Stitching")
      assign("setup", "Passive anti-vibration table on solid concrete base", envir = .GlobalEnv)
      assign("maintenance", data.frame(Category = rep("Maintenance", 3),
                                       Setting = c("Last yearly inspection and calibration by manufacturer",
                                                   "Last topography correction for used objectives",
                                                   "Last control for used objectives with the roughness standard (nominal Ra = 0.40 ± 0.05 µm)"),
                                       Value = c("2022-10-11", "2022-10-11", "2021-12-22")),
             envir = .GlobalEnv
      )
    }

    # Create a list of inputs
    tagList(

      # Selection box to select the software used, possible values come from 'soft'
      selectInput("software", "Software", soft),

      # Input text for software version
      textInput("version", "Software version", "2.6 HF 12"),

      # Check box whether Shuttle-and-Find module was used
      checkboxInput("sf", "Shuttle-and-Find module used", FALSE),

      # Check boxes to select which acquisition mode(s) was (were) used
      # Possible values come from 'acq_modes'
      checkboxGroupInput("acq_mode", "Acquisition modes", acq_modes)
    )
  })

  # Create output for general settings
  # 'reactive()' is necessary to use input values from above and to export it
  report_general <- reactive({

    # Create data.frame() with information to include in the report
    # Some information is user input, other is pre-defined
    temp <- data.frame(
      Category = c("User", "Microscope", "Microscope", "Location", "Location", "Location",
                   "Software", "Acquisition modes"),
      Setting = c("Name", "Manufacturer", "Model", "Facility", "Floor", "Setup",
                  "Software, version and modules", ""),
      Value = c(input$name, "Carl Zeiss Microscopy GmbH", input$instrument,
                "IMPALA, MONREPOS, Germany",
                "-1 (basement)", setup,
                paste0(input$software, " ", input$version, ", Shuttle-and-Find: ",  input$sf),
                paste(input$acq_mode, collapse = ", "))
    )
    rbind(temp, maintenance)
  })

  # Render output for general settings in the tab "Export report" in the table 'general_set'
  output$general_set <- renderTable({
    report_general()
  })


  # Render tab 'Acquisition'
  output$acq <- renderUI({

    # create objects with different values depending on the instrument
    if (input$instrument == "Smartzoom 5") {
      objectives <- paste0("PlanApoD ", c(1.6, 5), "x / NA = ", c(0.1, 0.3), " / WD = ", c(36, 30), " mm")
      obj_use <- "Color image"

      # Must be assigned to global environment so that it can be used outside of renderUI()
      # and inside 'report_acq'
      #assign("setup", "Steel table on solid concrete base", envir = .GlobalEnv)
    }

    if (input$instrument == "Axio Imager.Z2 Vario + LSM 800 MAT") {
      objectives <- paste0("C Epiplan-Apochromat ", c(5, 10, 20, 20, 50, 50, 50), "x / NA = ",
                           format(c(0.20, 0.40, 0.22, 0.70, 0.55, 0.75, 0.95), digits = 2), " / WD = ",
                           c(21, 5.4, 12, 1.3, 9, 1, 0.22)," mm")
      obj_use <- c("Preview scan", "Coordinate system", "Color image", "3D topography")
    }

    # Create a list of inputs
    tagList(

      # Selection box to select the software used, possible values come from 'soft'
      #selectInput("software", "Software", soft),

      # Input text for software version
      #textInput("version", "Software version", "2.6 HF 12"),

      # Check box whether Shuttle-and-Find module was used
      #checkboxInput("sf", "Shuttle-and-Find module used", FALSE),

      # Check boxes to select which objective(s) was (were) used
      # Possible values come from 'objectives'
      # Does not work yet - ideally a table of checkboxes
      fluidRow(
        #for (i in objectives) {
          column(4, paste(objectives, sep = "\n", collapse = "\n")),
          column(2, checkboxGroupInput("preview", "Preview scan", rep(" ", length(objectives)))),
          column(2, checkboxGroupInput("coord", "Coordinate system", rep(" ", length(objectives)))),
          column(2, checkboxGroupInput("colo", "Color image", rep(" ", length(objectives)))),
          column(2, checkboxGroupInput("topo", "3D topography", rep(" ", length(objectives))))
        #}
        #checkboxGroupInput("objs", "Objectives", objectives, width = "100%")
      )
    )
  })


  # Create output for abbreviations
  # 'reactive()' is necessary to export it
  report_abbr <- reactive({

    # Create data.frame() with abbreviations to include in the report, pre-defined
    data.frame(Abbreviation = c("AU", "HF", "LSM", "NA", "WD", "WF"),
               Explanation = c("Airy unit", "Hot fix", "Laser-scanning confocal microscopy",
                               "Numerical aperture", "Working distance", "Wide-field")
    )
  })

  # Render output for abbreviations in the tab "Abbreviations" in the table 'abbr'
  output$abbr <- renderTable({
    report_abbr()
  })

  # Define what happens when one clicks on the download button
  output$downloadReport <- downloadHandler(

    # Create file name for file to be downloaded
    filename = function() {
      paste("report-IMPALA_", gsub(" ", "-", input$name),
            format(Sys.time(), "_%Y-%m-%d_%H-%M-%S"), ".xlsx", sep = "")
    },

    # Define content
    content = function(file){

      # Write to XLSX, each table in a sheet
      writexl::write_xlsx(list(General_settings = report_general(), Abbreviations = report_abbr()),
                          file)
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)
