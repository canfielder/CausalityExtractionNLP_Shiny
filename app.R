# Import, Setup, and Pre-processing --------------------------------------------

# Import Packages
path_import <- "./www/R/load_and_install_packages.R"
source(path_import)
import_packages()

# Setup Reticulate
path_reticulate <- "./www/R/reticulate_setup.R"
source(path_reticulate)
reticulate_setup()


#  Execute Remaining Scripts
executed_scripts <- c(path_import, path_reticulate)
script_path <- "./www/R"
file_paths <- list.files(path = script_path, pattern = "*.R", full.names = TRUE)

for (file in file_paths){
    # Skip Install Package
    if (!(file %in% executed_scripts)) {
        
        source(file)   
        
    }
}

# Import LIME Explainer
explainer <- import_lime_explainer()

# UI ---------------------------------------------------------------------------
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
                # tabPanel(
                #     "Text - Raw",
                #     textOutput("text_raw")
                # ),
                # tabPanel(
                #     "Text - Processed",
                #     textOutput("text_pr")
                # ),
                tabPanel(
                    "Hypothesis Table",
                    DTOutput("hypothesis")
                ),
                tabPanel(
                    "Entity Extraction",
                    DTOutput("entity")
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
# Server -----------------------------------------------------------------------
server <- function(input, output) {
    
    # --- Python Modules ----------------------------------------------------- #
    ## Tika PDF Parser
    tika.parser <- import("tika.parser")
    
    # --- Reactive Values ---------------------------------------------------- #
    
    # Convert Uploaded PDF to Text
    pdf_txt_reactive <- reactive({
        # Wait until File is Uploaded
        req(input$file1)
        
        # Convert PDF to Raw Text
        pdf_package <- tika.parser$from_file(input$file1$datapath)
        pdf_raw <- pdf_package$content
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
        pdf_txt_pr <- process_text(input_text = pdf_txt_raw)
        
        # Extract Hypotheses
        hypo_xtr <- extract_hypothesis(pdf_txt_pr)
        hypo_xtr
    })
    
    # Extract Entities From Hypothesis
    entity_reactive <- reactive({
        # Wait Until Text is Processed
        req(hypotheses_reactive)
        
        # Convert PDF to Raw Text
        hypotheses <- hypotheses_reactive()
        
        #Convert to Vector
        vec_hypotheses <- hypotheses %>% 
            select(hypothesis) %>% 
            pull()
        
        # Extract Entities
        df_entity <- entity_extraction_mult(vec_hypotheses)
        
        df_entity

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
        pdf_txt_pr <- process_text(input_text = pdf_txt_raw)
        
        pdf_txt_pr
    })
    
    output$hypothesis <- DT::renderDT({
        hypotheses_reactive()
    })
    
    output$entity <- DT::renderDT({
        entity_reactive()
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
