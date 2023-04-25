# Shiny app to enter the settings of acquisitions at the IMPALA
# Download the settings in an editable (XLSX) report
# Written by Ivan Calandra


#####


# 1. Load libraries
library(shiny)
library(writexl)
#library(shinyforms)


#####


# 2. Define UI
ui <- fluidPage(

  # 2.1. Application title
  titlePanel("Create a report for your microscope images acquired at the IMaging Platform At LeizA (IMPALA)"),

  sidebarLayout(

    # 2.2. Sidebar
    sidebarPanel(

      # Input text for user name
      textInput("name", "Your name", "Ivan Calandra"),

      # Selection box to select the instrument for which the report will be created
      selectInput("instrument", "Choose the instrument",
                  c("Axio Imager.Z2 Vario + LSM 800 MAT", "Smartzoom 5")),

      # TraCEr logo - will need to be replaced with IMPALA logo
      img(src = "TraCEr_Logo_black.png", height = 150)
    ),

    # 2.3. Main panel
    mainPanel(

      # Tabs
      tabsetPanel(

        # Tabs, their UIs will be rendered in the server call below
        tabPanel("General", uiOutput("general")),
        tabPanel("Objectives", uiOutput("obj")),
        tabPanel("Acquisition", uiOutput("acq")),
        tabPanel("Pre-processing", uiOutput("proc")),
        tabPanel("Abbreviations", tableOutput("abbr")),

        # Tab "Export report"
        tabPanel("Report", fluidRow(

          # Shows the result of the user input in tables
          h2("General settings"),
          tableOutput("general_set"),
          h2("Objectives"),
          tableOutput("obj_set"),
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


####


# 3. Define server logic
server <- function(input, output) {


  # 3.1. Tab General
  # 3.1.1. Render tab 'general'
  output$general <- renderUI({

    # create objects with different values depending on the instrument
    if (input$instrument == "Smartzoom 5") {
      soft <- c("Smartzoom", "ZEN core")
      acq_modes <- c("2D", "EDF", "3D", "Stitching")

      # Must be assigned to global environment so that it can be used outside of renderUI()
      # and inside 'report_general'
      assign("setup", "Steel table on solid concrete base", envir = .GlobalEnv)
      assign("maintenance", data.frame(Category = "Maintenance", Setting = "NA", Value = "NA"),
             envir = .GlobalEnv)
    }
    if (input$instrument == "Axio Imager.Z2 Vario + LSM 800 MAT") {
      soft <- c("ZEN blue", "ZEN core")
      acq_modes <- c("2D", "3D Topography", "EDF", "Stitching")
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
      selectInput("software", "Software", soft, multiple = TRUE),

      # Input text for software version
      textInput("version", "Software version", "v2.6 HF12"),

      # Check box whether Shuttle-and-Find module was used
      checkboxInput("sf", "Shuttle-and-Find module used", FALSE),

      # Check boxes to select which acquisition mode(s) was (were) used
      # Possible values come from 'acq_modes'
      checkboxGroupInput("acq_mode", "Acquisition modes", acq_modes)
    )
  })


  # 3.1.2 Create output for general settings
  # 'reactive()' is necessary to use input values from above and to export it
  report_general <- reactive({

    paste_ver <- unlist(strsplit(input$version, ";"))
    paste_sf <- paste0(", Shuttle-and-Find: ",  input$sf)
    soft_out <- paste0(paste(input$software, paste_ver, collapse = ", "), paste_sf)

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
                soft_out,
                paste(input$acq_mode, collapse = ", "))
    )
    rbind(temp, maintenance)
  })


  # 3.1.3. Render output for general settings in the tab "Report" in the table 'general_set'
  output$general_set <- renderTable({
    report_general()
  })




  # 3.2. Tab Objectives
  # 3.2.1. Render tab 'obj'
  output$obj <- renderUI({

    if (input$instrument == "Smartzoom 5") {
      assign("objectives", paste0("PlanApoD ", c(1.6, 5), "x / NA = ", c(0.1, 0.3), " / WD = ", c(36, 30), " mm"), envir = .GlobalEnv)
      obj_use <- c("Color image", "Not used")
      sel_multi <- FALSE
      sel_value <- "Not used"
    }
    if (input$instrument == "Axio Imager.Z2 Vario + LSM 800 MAT") {
      assign("objectives", paste0("C Epiplan-Apochromat ", c(5, 10, 20, 20, 50, 50, 50), "x / NA = ",
                           format(c(0.20, 0.40, 0.22, 0.70, 0.55, 0.75, 0.95), digits = 2), " / WD = ",
                           c(21, 5.4, 12, 1.3, 9, 1, 0.22)," mm"), envir = .GlobalEnv)
      obj_use <- c("Preview scan", "Coordinate system", "Color image", "3D topography", "Not used")
      sel_multi <- TRUE
      sel_value <- NULL
    }

    tagList(
      h2("Specify how you used each objective"),
      h5("Make sure to select 'Not used' for the objective(s) you have not used"),

      # loop through all objectives
      lapply(seq_along(objectives), function(i) {

        # for each objective, with labels taken from 'objectives',
        # select use from 'obj_use' and store the value into 'input[[paste0("obj",i)]]', which parses to e.g. "input$obj1"
        selectInput(paste0("obj", i), objectives[i], choices = obj_use,
                    width = "100%", multiple = sel_multi, selected = sel_value)
      })
    )
  })


  # 3.2.2. Create output for objective settings
  report_obj <- reactive({
    temp <- data.frame(
      Objective = objectives,
      Use = sapply(seq_along(objectives), function(i) paste(input[[paste0('obj', i)]], collapse = ", "))
    )

    # Exclude unused objectives from the report
    temp <- temp[temp$Use != "Not used", ]
  })


  # 3.2.3. Render output for objective settings in the tab "Report" in the table 'obj_set'
  output$obj_set <- renderTable({
    report_obj()
  })




  # 3.4. Tab Pre-processing
  # 3.4.1. Render tab 'proc'
  output$proc <- renderUI({

    if (input$instrument == "Smartzoom 5") {
      assign("edf_title", "EDF/3D (WF)", envir = .GlobalEnv)
      assign("edf_set", "Number of slices", envir = .GlobalEnv)
      assign("edf_set_val", list(edf_num_slices = "NumberSlices"), envir = .GlobalEnv)
      assign("stitch_set", c("Blending", "Stitching Options"), envir = .GlobalEnv)
      assign("stitch_set_val", list(stitch_blend = c("On", "Off"),
                                    stitch_opt = c("Pixel", "Stage")),
                                    envir = .GlobalEnv)
    }

    if (input$instrument == "Axio Imager.Z2 Vario + LSM 800 MAT") {
      assign("edf_title", "EDF (WF)", envir = .GlobalEnv)
      assign("edf_set", c("Method", "Z-Stack alignment"), envir = .GlobalEnv)
      assign("edf_set_val", list(edf_method = c("Wavelets", "Contrast", "Maximum Projection", "Variance"),
                                 edf_alignment = c("No alignment", "Normal", "High", "Highest")), envir = .GlobalEnv)
      assign("stitch_set", c("Fuse tiles", "Correct shading", "Edge Detector",
                             "Comparer", "Global Optimizer"), envir = .GlobalEnv)
      assign("stitch_set_val", list(stitch_fuse = c("Activated", "Deactived"),
                                    stitch_shading = c("Activated (Automatic)", "Activated (Reference)", "Deactivated"),
                                    stitch_edge = c("Yes", "No"),
                                    stitch_comp = c("Optimized", "Best", "Basic"),
                                    stitch_optim = c("Best", "Basic")),
                                    envir = .GlobalEnv)
    }

    tagList(
      # Only one widget can be rendered within an 'if' call (because of the comma at the end of the widget call?)
      # So 'if' statements are repeated

      # Display message in case no-processing was selected in the tab 'General'
      if (is.null(input$acq_mode) || input$acq_mode == "2D") h2("No pre-processing applied."),
      if (is.null(input$acq_mode) || input$acq_mode == "2D") h5("If you did apply some pre-processing, specify it in the tab 'General' and come back to the tab 'Pre-processing' to enter the details."),

      # If EDF/3D was applied
      if (any(input$acq_mode %in% c("EDF", "3D"))) h2(edf_title),

      # The different microscopes need different types of input (slider vs. select)
      if (input$instrument == "Axio Imager.Z2 Vario + LSM 800 MAT" & any(input$acq_mode %in% c("EDF", "3D"))) {
        lapply(seq_along(edf_set), function(i) selectInput(names(edf_set_val)[i], edf_set[i], choices = edf_set_val[[i]]))
      },
      if (input$instrument == "Smartzoom 5" & any(input$acq_mode %in% c("EDF", "3D"))) {
        lapply(seq_along(edf_set), function(i) sliderInput(names(edf_set_val)[i], edf_set[i],
                                                           min = 1, max = 200, value = c(50, 60)))
      },

      # If stitching was applied
      if (any(input$acq_mode == "Stitching")) h2("Stitching (WF)"),
      if (any(input$acq_mode == "Stitching")) {
        lapply(seq_along(stitch_set), function(i) {
          selectInput(names(stitch_set_val)[i], stitch_set[i], choices = stitch_set_val[[i]])
        })
      },
      if (input$instrument == "Axio Imager.Z2 Vario + LSM 800 MAT" & any(input$acq_mode == "Stitching")) {
        numericInput("stitch_overlap", "Minimal Overlap [%]", min = 0, max = 100, value = 5)
      },
      if (input$instrument == "Axio Imager.Z2 Vario + LSM 800 MAT" & any(input$acq_mode == "Stitching")) {
        numericInput("stitch_shift", "Maximal Shift [%]", min = 0, max = 100, value = 10)
      },
      if (input$instrument == "Axio Imager.Z2 Vario + LSM 800 MAT" & any(input$acq_mode == "3D Topography")) {
        h2("3D Topography (LSM)")
      },
      if (input$instrument == "Axio Imager.Z2 Vario + LSM 800 MAT" & any(input$acq_mode == "3D Topography")) {
        numericInput("topo_noise_low", "Data quality - Noise cut: lowest level", min = 0, max = 65335, value = 0)
      },
      if (input$instrument == "Axio Imager.Z2 Vario + LSM 800 MAT" & any(input$acq_mode == "3D Topography")) {
        numericInput("topo_noise_high", "Data quality - Noise cut: highest level", min = 0, max = 65335, value = 65335)
      }
    )
  })


  # 3.4.2. Create output for pre-processing settings
  report_proc <- reactive({

    # Create data.frame in case no pre-processing was applied.
    # Information will be rbind()ed to it in case pre-processing was applied.
    temp <- data.frame(Category = "No pre-processing applied", Setting = NA, Value = NA)

    # Not all settings are relevant for all microscopes, so output data.frames must be put together differently
    if (input$instrument == "Smartzoom 5") {

      # Add information if EDF/3D was applied
      if (any(input$acq_mode %in% c("EDF", "3D"))) {
        temp <- rbind(temp, data.frame(
                      Category = rep(edf_title, length(edf_set)),
                      Setting = edf_set,
                      Value = sapply(seq_along(edf_set_val),
                                     function(i) paste(input[[names(edf_set_val)[i]]], collapse = "-"))
        ))
      }

      # Add information if stitching was applied
      if (any(input$acq_mode == "Stitching")) {
        temp <- rbind(temp, data.frame(
                      Category = rep("Stitching (WF)", length(stitch_set)),
                      Setting = stitch_set,
                      Value = sapply(seq_along(stitch_set_val), function(i) input[[names(stitch_set_val)[i]]])
        ))
      }

    # Only one 'if' call possible within 'reactive()', so 'if... else' was chosen
    # Nested 'if... else' might be needed when more than 2 instruments are available
    } else {
      if (any(input$acq_mode %in% c("EDF", "3D"))) {
        temp <- rbind(temp, data.frame(
          Category = rep(edf_title, length(edf_set)),
          Setting = edf_set,
          Value = sapply(seq_along(edf_set_val), function(i) input[[names(edf_set_val)[i]]])
        ))
      }
      if (any(input$acq_mode == "Stitching")) {
        temp <- rbind(temp, data.frame(
          Category = rep("Stitching (WF)", length(stitch_set) + 2),
          Setting = c(stitch_set, "Minimal Overlap [%]", "Maximal Shift [%]"),
          Value = c(sapply(seq_along(stitch_set_val), function(i) input[[names(stitch_set_val)[i]]]),
                    input$stitch_overlap, input$stitch_shift)
        ))
      }
      if (any(input$acq_mode == "3D Topography")) {
        temp <- rbind(temp, data.frame(
          Category = "Topography (LSM)",
          Setting = "Data quality (Noise Cut)",
          Value = paste0(input$topo_noise_low, "-", input$topo_noise_high, " levels")
        ))
      }
      #temp <- data.frame(
      #  Category = c(rep(edf_title, length(edf_set)), rep("Stitching (WF)", length(stitch_set) + 2), "Topography (LSM)"),
      #  Setting = c(edf_set, stitch_set, "Minimal Overlap [%]", "Maximal Shift [%]", "Data quality (Noise Cut)"),
      #  Value = c(sapply(seq_along(edf_set_val), function(i) input[[names(edf_set_val)[i]]]),
      #            sapply(seq_along(stitch_set_val), function(i) input[[names(stitch_set_val)[i]]]),
      #            input$stitch_overlap, input$stitch_shift, paste0(input$topo_noise_low, "-", input$topo_noise_high, " levels"))
      #)
    }

    # If pre-processing was applied, remove first row (based on NA in 'temp$Setting')
    if (nrow(temp) > 1) temp <- temp[!is.na(temp$Setting), ]

    # Specify object to output
    return(temp)
  })


  # 3.4.3. Render output for pre-processing settings in the tab "Report" in the table 'proc_set'
  output$proc_set <- renderTable({
    report_proc()
  })




  # 3.5. Tab Abbreviations
  # 3.5.1. Create output for abbreviations
  # 'reactive()' is necessary to export it
  report_abbr <- reactive({

    # Create data.frame() with abbreviations to include in the report, pre-defined
    data.frame(Abbreviation = c("AU", "HF", "LSM", "NA", "WD", "WF"),
               Explanation = c("Airy unit", "Hot fix", "Laser-scanning confocal microscopy",
                               "Numerical aperture", "Working distance", "Wide-field")
    )
  })


  # 3.5.2. Render output for abbreviations in the tab "Abbreviations" in the table 'abbr'
  output$abbr <- renderTable({
    report_abbr()
  })




  # 3.6. Define what happens when one clicks on the download button
  output$downloadReport <- downloadHandler(

    # 3.6.1. Create file name for file to be downloaded
    filename = function() {
      paste("IMPALA-report_", gsub(" ", "-", input$name),
            format(Sys.time(), "_%Y-%m-%d_%H-%M-%S"), ".xlsx", sep = "")
    },

    # 3.6.2. Define content
    content = function(file){

      # Write to XLSX, each table in a sheet
      writexl::write_xlsx(list(General_settings = report_general(), Objectives = report_obj(), Pre_processing = report_proc(),
                               Abbreviations = report_abbr()), file)
    }
  )
}


#####


# 4. Run the application
shinyApp(ui = ui, server = server)


# END OF CODE #
