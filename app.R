# Import and Pre-processing ---------------------------------------------------
##  Execute All Scripts
script_path <- "./www/R"
file_paths <- list.files(path = script_path, pattern = "*.R", full.names = TRUE)

for (file in file_paths){
    source(file)
}

# Install Packages
shiny_install_packages()

# Import LIME Explainer
explainer <- import_lime_explainer()

# Import Patterns File
patterns_col <- c("remove","comments")
patterns_raw <- read_excel(path = "./www/data/patterns.xlsx",
                           col_names = patterns_col)
patterns <- patterns_raw %>% pull(remove)

PYTHON_DEPENDENCIES = c('numpy', 'fasttext', 'sklearn', 'joblib',
                        'tensorflow', 'tika')


# UI --------------------------------------------------------------------------
ui <- fluidPage(
    
    titlePanel("Causal Knowledge Extraction"),
    
    # SIDEBAR
    sidebarLayout(
        sidebarPanel(
            fileInput(
                inputId = "file1", 
                label = "Upload PDF File",
                multiple = FALSE,
                accept = c(".pdf"),
                width = '90%'
            )
        ),
        # MAIN
        mainPanel(
            tabsetPanel(
                tabPanel(
                    "Reference",
                    textOutput("file1_path"),
                    uiOutput(outputId = "pdf_view")
                ),
                tabPanel(
                    "Text - Raw",
                    textOutput("text_raw")
                ),
                tabPanel(
                    "Text - Processed",
                    textOutput("text_pr")
                ),
                tabPanel(
                    "Hypothesis Table",
                    DTOutput("hypothesis")
                ),
                tabPanel(
                    "LIME Explanation - Table",
                    DTOutput("lime_explanation_table")
                ), 
                tabPanel(
                    "LIME Explanation - Plot",
                    text_explanations_output("text_explanations_plot")
                )
            )
        )
    )
)

# Define server logic required to draw a histogram
# Server ----------------------------------------------------------------------
server <- function(input, output) {
    
    # --- VIRTUALENV Setup -------------------------------------------------- #
    
    virtualenv_dir = Sys.getenv('VIRTUALENV_NAME')
    python_path = Sys.getenv('PYTHON_PATH')
    
    # Create virtual env and install dependencies
    # Determine Existing Virtual Environments
    virtualenv_list <-  reticulate::virtualenv_list()
    
    # Create and Install Virtual Environment If One Doesn't Exist
    if (!(virtualenv_dir %in% virtualenv_list)){
    
        reticulate::virtualenv_create(envname = virtualenv_dir, 
                                      python = python_path)
        reticulate::virtualenv_install(virtualenv_dir, 
                                       packages = PYTHON_DEPENDENCIES, 
                                       ignore_installed=TRUE)
        
    }
    
    # Assign Virtual Environment
    reticulate::use_virtualenv(virtualenv_dir, required = TRUE)
    
    # --- Python Modules --------------------------------------------------- #
    # Numpy
    np <- import("numpy")
    
    # Tika PDF Parser
    parser <- import("tika.parser")
    
    # Tensorflow
    tf <- import("tensorflow")
    
    # --- Reactive Values --------------------------------------------------- #
    
    # Convert Uploaded PDF to Text
    pdf_txt_reactive <- reactive({
        # Wait until File is Uploaded
        req(input$file1)
        
        # Convert PDF to Raw Text
        pdf_raw <- tika_text(input$file1$datapath)
        pdf_raw
    })
    
    # Extract Path to Uploaded PDF
    pdf_path_reactive <- reactive({
        # Wait until File is Uploaded
        req(input$file1)
        
        input$file1$datapath
    })
    
    # Generate Explanations - REactive
    explanation_reactive <- reactive({
        req(hypotheses_reactive)
        
        # Define Hypotheses
        def_hypo_xtr <- hypotheses_reactive()
        
        # Extract  Hypothesis Text as Vector
        vec_hypo_xtr <- def_hypo_xtr %>% 
            select(hypothesis) %>% 
            pull()
        
        explanation <- lime::explain(
            x = vec_hypo_xtr, 
            explainer = explainer, 
            n_labels = 1, 
            n_features = 20
        )
        explanation
    })
    
    output$file1_path <- renderText({
        pdf_path_reactive()
    })
    
    # Generate Hypotheses - Reactively
    hypotheses_reactive <- reactive({
        # Wait Until Text is Processed
        req(pdf_txt_reactive)
        
        # Convert PDF to Raw Text
        pdf_txt_raw <- pdf_txt_reactive()
        
        # Process Text
        pdf_txt_pr <- process_text(input_text = pdf_txt_raw,
                                   removal_patterns = patterns)
        # Extract Hypotheses
        hypo_xtr <- extract_hypothesis(pdf_txt_pr)
        hypo_xtr
    })
    
    # --- Outputs to UI ----------------------------------------------------- #
    
    output$pdf_view <- renderUI({
        tags$iframe(style="height:800px; width:100%; scrolling=yes", 
                    src=pdf_path_reactive())
    })
    
    output$text_raw <- renderText({
        pdf_txt_reactive()
    })
    
    output$text_pr <- renderText({
        pdf_txt_raw <- pdf_txt_reactive()
        pdf_txt_pr <- process_text(input_text = pdf_txt_raw,
                                   removal_patterns = patterns)
        
        pdf_txt_pr
    })
    
    output$hypothesis <- DT::renderDT({
        hypotheses_reactive()
    })
    
    output$lime_explanation_table <- DT::renderDT({
        explanation_reactive()
    })
    
    output$text_explanations_plot <- render_text_explanations({
        explanation <- explanation_reactive()
        plot_text_explanations(explanation)
    })
}

# Run the application 
shinyApp(ui = ui, server = server)