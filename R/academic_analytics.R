# R/academic_analytics.R
# R Data Analytics engine for Student Academic Assistant

library(jsonlite)

# Load Knowledge Base Data
load_academic_data <- function(json_path = "data/student_academic_assistant_complete_knowledge_base.json") {
  if (!file.exists(json_path)) {
    # Fallback search
    json_files <- list.files("data", pattern = ".*knowledge.*base.*\\.json$", full.names = TRUE)
    if (length(json_files) > 0) json_path <- json_files[1]
  }
  return(fromJSON(json_path, simplifyVector = FALSE))
}

# Calculate summary metrics
get_summary_stats <- function(kb_data) {
  num_courses <- length(kb_data$courses)
  num_faculty <- length(kb_data$faculty$profiles)
  num_batches <- length(kb_data$mini_project$batches)
  
  # Calculate total weekly class periods
  timetable <- kb_data$timetable
  total_periods <- 0
  for (day in names(timetable)) {
    day_sched <- timetable[[day]]
    for (p in names(day_sched)) {
      if (nchar(day_sched[[p]]) > 0) {
        total_periods <- total_periods + 1
      }
    }
  }
  
  # Total credits
  total_credits <- 0
  for (code in names(kb_data$courses)) {
    cr <- kb_data$courses[[code]]$credits
    if (!is.null(cr) && is.numeric(cr)) {
      total_credits <- total_credits + cr
    }
  }

  list(
    total_courses = num_courses,
    total_faculty = num_faculty,
    total_batches = num_batches,
    weekly_periods = total_periods,
    total_credits = total_credits,
    degree = kb_data$metadata$degree,
    department = kb_data$metadata$department,
    semester = kb_data$metadata$semester,
    academic_year = kb_data$metadata$academic_year
  )
}

# Extract Course Data Frame for R Analysis
get_courses_df <- function(kb_data) {
  courses <- kb_data$courses
  codes <- names(courses)
  
  titles <- sapply(codes, function(c) courses[[c]]$title)
  types <- sapply(codes, function(c) ifelse(is.null(courses[[c]]$type), "Unknown", courses[[c]]$type))
  credits <- sapply(codes, function(c) ifelse(is.null(courses[[c]]$credits), 0, as.numeric(courses[[c]]$credits)))
  hours <- sapply(codes, function(c) ifelse(is.null(courses[[c]]$hours), 0, as.numeric(courses[[c]]$hours)))
  unit_counts <- sapply(codes, function(c) length(courses[[c]]$units))
  
  data.frame(
    Code = codes,
    Title = unname(titles),
    Type = unname(types),
    Credits = unname(credits),
    Hours = unname(hours),
    Units = unname(unit_counts),
    stringsAsFactors = FALSE
  )
}

# Extract Timetable Data Frame
get_timetable_df <- function(kb_data) {
  timetable <- kb_data$timetable
  days <- names(timetable)
  
  records <- list()
  idx <- 1
  for (day in days) {
    sched <- timetable[[day]]
    for (p in names(sched)) {
      code <- sched[[p]]
      if (nchar(code) > 0) {
        title <- if (!is.null(kb_data$courses[[code]])) kb_data$courses[[code]]$title else code
        time_slot <- if (!is.null(kb_data$periods[[p]])) paste0(kb_data$periods[[p]]$start, "-", kb_data$periods[[p]]$end) else ""
        records[[idx]] <- data.frame(
          Day = day,
          Period = p,
          CourseCode = code,
          CourseTitle = title,
          TimeSlot = time_slot,
          stringsAsFactors = FALSE
        )
        idx <- idx + 1
      }
    }
  }
  
  if (length(records) > 0) {
    do.call(rbind, records)
  } else {
    data.frame(Day=character(), Period=character(), CourseCode=character(), CourseTitle=character(), TimeSlot=character())
  }
}

# Extract Project Data Frame
get_project_df <- function(kb_data) {
  batches <- kb_data$mini_project$batches
  records <- list()
  for (i in seq_along(batches)) {
    b <- batches[[i]]
    records[[i]] <- data.frame(
      Batch = b$batch,
      Domain = b$domain,
      Mentor = b$mentor,
      TeamSize = length(b$members),
      Members = paste(b$members, collapse = ", "),
      stringsAsFactors = FALSE
    )
  }
  if (length(records) > 0) {
    do.call(rbind, records)
  } else {
    data.frame(Batch=integer(), Domain=character(), Mentor=character(), TeamSize=integer(), Members=character())
  }
}
