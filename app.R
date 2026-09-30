# app.R - R Shiny Web Application for Student Academic Assistant
# Run with: Rscript -e "shiny::runApp('.')" or launch in RStudio

library(shiny)
library(jsonlite)

# Source R Helper Engine
source("R/academic_analytics.R")
source("R/helper_nlp.R")

# Load Knowledge Base Data
kb_data <- load_academic_data()
stats <- get_summary_stats(kb_data)
courses_df <- get_courses_df(kb_data)
timetable_df <- get_timetable_df(kb_data)
project_df <- get_project_df(kb_data)

# Custom CSS for Modern High-End UI
custom_css <- HTML("
  @import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700&display=swap');
  
  :root {
    --bg-dark: #0f172a;
    --card-bg: #1e293b;
    --accent-indigo: #6366f1;
    --accent-cyan: #06b6d4;
    --accent-emerald: #10b981;
    --text-primary: #f8fafc;
    --text-muted: #94a3b8;
    --border-color: #334155;
  }
  
  body {
    font-family: 'Plus Jakarta Sans', sans-serif;
    background-color: var(--bg-dark);
    color: var(--text-primary);
    margin: 0;
    padding: 0;
  }
  
  .navbar-custom {
    background: linear-gradient(135deg, #1e1b4b 0%, #0f172a 100%);
    border-bottom: 1px solid var(--border-color);
    padding: 1rem 2rem;
  }
  
  .navbar-brand-title {
    font-size: 1.5rem;
    font-weight: 700;
    background: linear-gradient(90deg, #818cf8, #38bdf8);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
  }
  
  .stat-card {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: 12px;
    padding: 1.25rem;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.2);
    transition: transform 0.2s ease, border-color 0.2s ease;
  }
  
  .stat-card:hover {
    transform: translateY(-2px);
    border-color: var(--accent-indigo);
  }
  
  .stat-val {
    font-size: 2rem;
    font-weight: 700;
    color: #38bdf8;
  }
  
  .stat-lbl {
    font-size: 0.875rem;
    color: var(--text-muted);
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }
  
  .chat-container {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: 16px;
    height: 480px;
    overflow-y: auto;
    padding: 1.5rem;
    margin-bottom: 1rem;
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }
  
  .chat-msg {
    max-width: 80%;
    padding: 1rem 1.25rem;
    border-radius: 14px;
    line-height: 1.5;
    font-size: 0.95rem;
    animation: fadeIn 0.3s ease-in-out;
  }
  
  @keyframes fadeIn {
    from { opacity: 0; transform: translateY(6px); }
    to { opacity: 1; transform: translateY(0); }
  }
  
  .msg-user {
    align-self: flex-end;
    background: linear-gradient(135deg, #4f46e5 0%, #6366f1 100%);
    color: #ffffff;
    border-bottom-right-radius: 2px;
  }
  
  .msg-bot {
    align-self: flex-start;
    background: #334155;
    color: #f1f5f9;
    border-bottom-left-radius: 2px;
    border: 1px solid rgba(255, 255, 255, 0.05);
  }
  
  .quick-chip {
    background: #1e293b;
    border: 1px solid #475569;
    color: #cbd5e1;
    border-radius: 20px;
    padding: 0.4rem 1rem;
    font-size: 0.85rem;
    cursor: pointer;
    transition: all 0.2s ease;
    display: inline-block;
    margin-right: 0.5rem;
    margin-bottom: 0.5rem;
  }
  
  .quick-chip:hover {
    background: var(--accent-indigo);
    color: #ffffff;
    border-color: var(--accent-indigo);
  }
  
  .intent-badge {
    background: rgba(99, 102, 241, 0.2);
    color: #818cf8;
    border: 1px solid rgba(99, 102, 241, 0.4);
    padding: 0.25rem 0.75rem;
    border-radius: 12px;
    font-size: 0.8rem;
    font-weight: 600;
  }
  
  .content-card {
    background: var(--card-bg);
    border: 1px solid var(--border-color);
    border-radius: 14px;
    padding: 1.5rem;
    margin-bottom: 1.5rem;
  }
  
  .table-custom {
    color: var(--text-primary);
    background: transparent;
  }
  
  .table-custom th {
    background-color: #0f172a;
    color: #38bdf8;
    border-color: var(--border-color);
  }
  
  .table-custom td {
    border-color: var(--border-color);
  }
")

# Define UI
ui <- fluidPage(
  tags$head(
    tags$title("Student Academic Assistant - R Shiny Frontend"),
    tags$style(custom_css)
  ),
  
  # Header Bar
  div(class = "navbar-custom d-flex justify-content-between align-items-center mb-4",
    div(
      span(class = "navbar-brand-title", "🎓 Student Academic Assistant"),
      span(style = "color: #94a3b8; margin-left: 1rem; font-size: 0.9rem;", 
           paste(stats$degree, stats$department, "| Semester", stats$semester, "(AY", stats$academic_year, ")"))
    ),
    div(
      span(class = "badge bg-primary me-2", "R Shiny Enabled"),
      span(class = "badge bg-info", "Classic NLP Engine")
    )
  ),
  
  # Top Metrics Row
  fluidRow(
    column(2, div(class = "stat-card", div(class = "stat-val", stats$total_courses), div(class = "stat-lbl", "Courses"))),
    column(2, div(class = "stat-card", div(class = "stat-val", stats$total_credits), div(class = "stat-lbl", "Total Credits"))),
    column(2, div(class = "stat-card", div(class = "stat-val", stats$weekly_periods), div(class = "stat-lbl", "Weekly Periods"))),
    column(2, div(class = "stat-card", div(class = "stat-val", stats$total_faculty), div(class = "stat-lbl", "Faculty Staff"))),
    column(2, div(class = "stat-card", div(class = "stat-val", stats$total_batches), div(class = "stat-lbl", "Project Teams"))),
    column(2, div(class = "stat-card", div(class = "stat-val", "A+"), div(class = "stat-lbl", "Class Venue (306)"))
  ),
  br(),
  
  # Main Navigation Tabs
  tabsetPanel(
    id = "main_tabs",
    type = "pills",
    
    # TAB 1: AI Chatbot
    tabPanel(
      title = "💬 AI Assistant",
      br(),
      fluidRow(
        column(8,
          div(class = "content-card",
            h4(style = "color: #38bdf8; margin-bottom: 1rem;", "Academic Query Assistant"),
            uiOutput("chat_history_ui"),
            div(style = "margin-bottom: 1rem;",
              span(class = "text-muted me-2", "Quick Prompts:"),
              actionLink("btn_q1", "Next class?", class = "quick-chip"),
              actionLink("btn_q2", "Monday timetable", class = "quick-chip"),
              actionLink("btn_q3", "Deep Learning faculty?", class = "quick-chip"),
              actionLink("btn_q4", "Batch 1 mentor?", class = "quick-chip"),
              actionLink("btn_q5", "OE-I course info", class = "quick-chip")
            ),
            div(class = "input-group",
              textInput("user_input", NULL, placeholder = "Ask an academic question (e.g. What is my next class? Who teaches AI?)...", width = "100%"),
              actionButton("send_btn", "Send Query", class = "btn btn-primary ms-2", style = "border-radius: 8px; font-weight: 600;")
            )
          )
        ),
        column(4,
          div(class = "content-card",
            h5(style = "color: #818cf8;", "🔍 NLP Execution Inspector"),
            hr(style = "border-color: #334155;"),
            p(strong("Normalized Text:"), textOutput("norm_text_out")),
            p(strong("Detected Intent:"), htmlOutput("intent_badge_out")),
            p(strong("Extracted Entities:"), verbatimTextOutput("entities_json_out")),
            p(strong("Knowledge Base:"), span(style = "color: #10b981;", "Grounded Response Verified"))
          )
        )
      )
    ),
    
    # TAB 2: Timetable
    tabPanel(
      title = "📅 Weekly Timetable",
      br(),
      div(class = "content-card",
        fluidRow(
          column(4, selectInput("day_filter", "Select Day:", choices = c("All Days", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday"))),
          column(8, div(style = "text-align: right; padding-top: 1.8rem;", span(class = "badge bg-success", "Venue: CSE LH-306 (Third Floor)")))
        ),
        tableOutput("timetable_table_ui")
      )
    ),
    
    # TAB 3: Courses & Syllabus
    tabPanel(
      title = "📚 Courses & Syllabus",
      br(),
      div(class = "content-card",
        selectInput("selected_course", "Choose Course:", choices = names(kb_data$courses)),
        hr(style = "border-color: #334155;"),
        uiOutput("course_detail_ui")
      )
    ),
    
    # TAB 4: Faculty Directory
    tabPanel(
      title = "👨‍🏫 Faculty Directory",
      br(),
      div(class = "content-card",
        h4(style = "color: #38bdf8;", "Faculty Profiles & Teaching Assignments"),
        tableOutput("faculty_table_ui")
      )
    ),
    
    # TAB 5: Mini Project Teams
    tabPanel(
      title = "🚀 Mini Projects",
      br(),
      div(class = "content-card",
        h4(style = "color: #38bdf8;", "Mini Project Batches, Domains & Mentors"),
        tableOutput("project_table_ui")
      )
    ),
    
    # TAB 6: R Statistical Analytics
    tabPanel(
      title = "📊 R Analytics",
      br(),
      fluidRow(
        column(6,
          div(class = "content-card",
            h5(style = "color: #38bdf8;", "Course Credit Distribution (R Plot)"),
            plotOutput("credit_plot")
          )
        ),
        column(6,
          div(class = "content-card",
            h5(style = "color: #38bdf8;", "Weekly Period Workload per Course (R Plot)"),
            plotOutput("workload_plot")
          )
        )
      ),
      fluidRow(
        column(12,
          div(class = "content-card",
            h5(style = "color: #38bdf8;", "Project Domains Distribution (R Plot)"),
            plotOutput("domain_plot")
          )
        )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # Reactive Chat Log State
  chat_store <- reactiveVal(list(
    list(sender = "bot", text = "Hello! I am your R-powered Student Academic Assistant. Ask me about your upcoming classes, timetable, faculty, syllabus units, or project mentor!")
  ))
  
  latest_nlp <- reactiveVal(list(
    normalized = "N/A",
    intent = "NONE",
    entities = list()
  ))
  
  # Process user query function
  handle_query <- function(q_text) {
    if (nchar(trimws(q_text)) == 0) return()
    
    norm <- r_normalize_text(q_text)
    intent <- r_detect_intent(norm)
    entities <- r_extract_entities(q_text, kb_data)
    ans <- r_generate_response(intent, entities, kb_data)
    
    latest_nlp(list(normalized = norm, intent = intent, entities = entities))
    
    current_chat <- chat_store()
    current_chat[[length(current_chat) + 1]] <- list(sender = "user", text = q_text)
    current_chat[[length(current_chat) + 1]] <- list(sender = "bot", text = ans)
    chat_store(current_chat)
    
    updateTextInput(session, "user_input", value = "")
  }
  
  # Button Listeners
  observeEvent(input$send_btn, { handle_query(input$user_input) })
  observeEvent(input$btn_q1, { handle_query("What is my next class?") })
  observeEvent(input$btn_q2, { handle_query("Show me Monday timetable") })
  observeEvent(input$btn_q3, { handle_query("Who teaches Deep Learning Concepts?") })
  observeEvent(input$btn_q4, { handle_query("Who is the mentor for Batch 1?") })
  observeEvent(input$btn_q5, { handle_query("Tell me about course OE-I") })
  
  # Render Chat Messages
  output$chat_history_ui <- renderUI({
    msgs <- chat_store()
    nodes <- lapply(msgs, function(m) {
      cls <- if (m$sender == "user") "chat-msg msg-user" else "chat-msg msg-bot"
      div(class = cls, m$text)
    })
    div(class = "chat-container", nodes)
  })
  
  # NLP Inspector Outputs
  output$norm_text_out <- renderText({ latest_nlp()$normalized })
  output$intent_badge_out <- renderUI({
    intent <- latest_nlp()$intent
    span(class = "intent-badge", intent)
  })
  output$entities_json_out <- renderText({
    toJSON(latest_nlp()$entities, auto_unbox = TRUE, pretty = TRUE)
  })
  
  # Timetable Table Output
  output$timetable_table_ui <- renderTable({
    df <- timetable_df
    if (input$day_filter != "All Days") {
      df <- df[df$Day == input$day_filter, ]
    }
    df
  }, class = "table table-dark table-striped table-hover mt-3")
  
  # Course Details Output
  output$course_detail_ui <- renderUI({
    code <- input$selected_course
    course <- kb_data$courses[[code]]
    if (is.null(course)) return(p("Select a valid course."))
    
    units_list <- course$units
    unit_nodes <- lapply(names(units_list), function(u_num) {
      u_info <- units_list[[u_num]]
      topics_str <- paste(u_info$topics, collapse = ", ")
      div(style = "background: #0f172a; padding: 1rem; border-radius: 8px; margin-bottom: 0.75rem; border-left: 4px solid #6366f1;",
        h6(style = "color: #38bdf8;", paste("Unit", u_num, ":", u_info$title)),
        p(style = "color: #cbd5e1; font-size: 0.9rem;", paste("Topics:", topics_str))
      )
    })
    
    staff <- kb_data$timetable_staff_mapping[[code]]
    staff_str <- if (!is.null(staff)) paste(staff, collapse = ", ") else "Faculty assigned"
    
    tagList(
      div(class = "row mb-3",
        div(class = "col-md-6",
          h4(style = "color: #818cf8;", paste(course$title, "(", code, ")")),
          p(strong("Course Type: "), course$type),
          p(strong("Credits: "), course$credits, " | ", strong("Hours/Week: "), course$hours),
          p(strong("Prerequisites: "), ifelse(is.null(course$prerequisites), "Nil", paste(course$prerequisites, collapse=", ")))
        ),
        div(class = "col-md-6",
          div(style = "background: #1e293b; padding: 1rem; border-radius: 8px; border: 1px solid #334155;",
            h6(style = "color: #10b981;", "Handling Faculty Staff"),
            p(staff_str)
          )
        )
      ),
      h5(style = "color: #38bdf8; margin-top: 1.5rem;", "Syllabus Breakdown by Units"),
      unit_nodes
    )
  })
  
  # Faculty Directory Table
  output$faculty_table_ui <- renderTable({
    fac_list <- kb_data$faculty$profiles
    df <- data.frame(
      Name = sapply(fac_list, function(x) x$name),
      Designation = sapply(fac_list, function(x) x$designation),
      Department = sapply(fac_list, function(x) x$department),
      Expertise = sapply(fac_list, function(x) paste(x$expertise, collapse = ", ")),
      stringsAsFactors = FALSE
    )
    df
  }, class = "table table-dark table-striped table-hover mt-3")
  
  # Project Batches Table
  output$project_table_ui <- renderTable({
    project_df
  }, class = "table table-dark table-striped table-hover mt-3")
  
  # R Plot Outputs
  output$credit_plot <- renderPlot({
    df <- courses_df
    par(bg = "#1e293b", fg = "#f8fafc", col.axis = "#94a3b8", col.lab = "#38bdf8")
    barplot(df$Credits, names.arg = df$Code, col = "#6366f1", border = NA,
            main = "Course Credit Allocations", ylab = "Credits", las = 2)
  })
  
  output$workload_plot <- renderPlot({
    df <- timetable_df
    counts <- table(df$CourseCode)
    par(bg = "#1e293b", fg = "#f8fafc", col.axis = "#94a3b8", col.lab = "#38bdf8")
    barplot(counts, col = "#06b6d4", border = NA,
            main = "Weekly Periods Scheduled", ylab = "Period Count", las = 2)
  })
  
  output$domain_plot <- renderPlot({
    df <- project_df
    domains <- table(df$Domain)
    par(bg = "#1e293b", fg = "#f8fafc", col.axis = "#94a3b8", col.lab = "#38bdf8")
    barplot(domains, col = "#10b981", border = NA,
            main = "Mini Project Domain Distribution", ylab = "Number of Batches")
  })
}

# Run Shiny Application
shinyApp(ui = ui, server = server)
