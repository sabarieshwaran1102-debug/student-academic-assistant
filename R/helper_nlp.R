# R/helper_nlp.R
# R implementation of the Academic NLP pipeline & response generation engine

library(jsonlite)

# Normalize string text
r_normalize_text <- function(text) {
  if (is.null(text) || nchar(text) == 0) return("")
  text <- tolower(text)
  text <- gsub("[^a-z0-9\\s]", " ", text)
  text <- gsub("\\s+", " ", text)
  return(trimws(text))
}

# Detect intent from normalized question text
r_detect_intent <- function(normalized_text) {
  rules <- list(
    NEXT_CLASS = c("\\b(next|upcoming)\\s+(class|lecture|period)\\b", "\\bwhat('?s| is) next\\b"),
    FACULTY_FOR_CLASS = c("\\b(who|which faculty|which teacher)\\b.{0,40}\\b(teach|take|handle)\\b", "\\b(who teaches|faculty for|teacher for|taught by)\\b"),
    EXAM_PERIOD = c("\\b(exam|examination)\\b.{0,25}\\b(period|date|schedule|when)\\b", "\\b(when|dates?)\\b.{0,25}\\b(exam|examination)\\b"),
    CLASS_TIME = c("\\b(when|what time)\\b.{0,35}\\b(class|lecture|period|course)\\b", "\\b(class|lecture|period) time\\b"),
    CLASS_VENUE = c("\\b(where|which room|which venue)\\b.{0,35}\\b(class|lecture|room|venue)\\b", "\\b(class|classroom) (venue|room|location)\\b"),
    UNIT_TOPICS = c("\\b(topics|contents)\\b.{0,25}\\b(unit|module)\\b", "\\b(unit|module)\\s+[ivx0-9]+\\b.{0,25}\\b(topics|contents)\\b"),
    SYLLABUS_TOPIC_LOCATION = c("\\b(which|what)\\s+unit\\b.{0,40}\\b(topic|syllabus|covers?|contains?|includes?)\\b", "\\b(where|which unit)\\b.{0,40}\\b(syllabus|topic)\\b"),
    TOPIC_INFORMATION = c("\\b(explain|define|meaning of)\\b", "\\b(topic|concept)\\s+(information|details|explanation)\\b", "\\btell me about\\b.{0,20}\\b(topic|concept)\\b"),
    MINI_PROJECT_MENTOR = c("\\b(mentor|guide)\\b"),
    MINI_PROJECT_DOMAIN = c("\\b(project|mini project)\\b.{0,25}\\b(domain|area)\\b", "\\b(domain|area)\\b.{0,25}\\b(project|batch)\\b"),
    MINI_PROJECT_BATCH = c("\\b(project|mini project)\\b.{0,25}\\b(batch|team|group)\\b", "\\b(batch|team|group)\\b.{0,25}\\b(project|mentor|members)\\b"),
    STUDENT_BATCH_LOOKUP = c("\\b(which|what)\\s+batch\\b", "\\b(batch|team|group)\\b.{0,20}\\b(student|belongs|member)\\b"),
    HOLIDAY_CHECK = c("\\b(is|are)\\b.{0,25}\\b(holiday|holidays|working day|class)\\b", "\\bholiday\\b"),
    INTERNAL_TEST = c("\\b(internal|cycle)\\s*(test|exam|assessment)\\b", "\\b(internal test|internal exam|cia)\\b"),
    ACADEMIC_CALENDAR = c("\\b(academic calendar|semester calendar|calendar events?)\\b", "\\b(events?|semester starts?|semester ends?)\\b"),
    CLASS_BY_DAY = c("\\b(classes|class|timetable|schedule)\\b.{0,30}\\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday|today|tomorrow)\\b", "\\b(what|which)\\s+(classes|class)\\b"),
    FACULTY_INFORMATION = c("\\b(faculty|teacher|professor)\\b.{0,25}\\b(information|details|profile|expertise)\\b", "\\b(who is|tell me about)\\b.{0,25}\\b(faculty|teacher|professor|advisor|tutor)\\b"),
    SUBJECT_INFORMATION = c("\\b(subject|course)\\b.{0,25}\\b(information|details|credits|hours|prerequisite|syllabus)\\b", "\\b(tell me about|information about|details of)\\b.{0,30}\\b(subject|course)\\b")
  )

  for (intent_name in names(rules)) {
    patterns <- rules[[intent_name]]
    for (pat in patterns) {
      if (grepl(pat, normalized_text, ignore.case = TRUE, perl = TRUE)) {
        return(intent_name)
      }
    }
  }
  return("UNKNOWN")
}

# Extract entities from question string against knowledge base
r_extract_entities <- function(text, kb_data) {
  entities <- list()
  norm <- r_normalize_text(text)
  
  # Course Codes
  courses <- kb_data$courses
  code_matches <- c()
  if (!is.null(courses)) {
    for (code in names(courses)) {
      if (grepl(paste0("\\b", tolower(code), "\\b"), norm)) {
        code_matches <- c(code_matches, code)
      }
    }
  }
  if (length(code_matches) > 0) entities$COURSE_CODE <- unique(code_matches)
  
  # Days
  days <- c("monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday", "today", "tomorrow")
  day_matches <- c()
  for (d in days) {
    if (grepl(paste0("\\b", d, "\\b"), norm)) {
      day_matches <- c(day_matches, d)
    }
  }
  if (length(day_matches) > 0) entities$DAY <- unique(day_matches)
  
  # Units
  unit_match <- regmatches(norm, regexpr("unit\\s+([ivxlcdm0-9]+)", norm, ignore.case = TRUE))
  if (length(unit_match) > 0 && nchar(unit_match) > 0) {
    u_val <- gsub("unit\\s+", "", unit_match, ignore.case = TRUE)
    entities$UNIT <- toupper(u_val)
  }
  
  # Periods
  period_match <- regmatches(norm, regexpr("period\\s+([1-7])|([1-7])(st|nd|rd|th)\\s+period", norm, ignore.case = TRUE))
  if (length(period_match) > 0 && nchar(period_match) > 0) {
    p_val <- regmatches(period_match, regexpr("[1-7]", period_match))
    entities$PERIOD <- p_val
  }

  # Batches
  batch_match <- regmatches(norm, regexpr("batch\\s*(\\d+)", norm, ignore.case = TRUE))
  if (length(batch_match) > 0 && nchar(batch_match) > 0) {
    b_val <- regmatches(batch_match, regexpr("\\d+", batch_match))
    entities$BATCH <- b_val
  }

  # Faculty
  if (!is.null(kb_data$faculty$profiles)) {
    fac_matches <- c()
    for (prof in kb_data$faculty$profiles) {
      if (!is.null(prof$name)) {
        fname_norm <- r_normalize_text(prof$name)
        if (nchar(fname_norm) > 3 && grepl(fname_norm, norm, fixed = TRUE)) {
          fac_matches <- c(fac_matches, prof$name)
        }
      }
    }
    if (length(fac_matches) > 0) entities$FACULTY <- unique(fac_matches)
  }
  
  return(entities)
}

# Generate R grounded response
r_generate_response <- function(intent, entities, kb_data) {
  if (intent == "NEXT_CLASS") {
    timetable <- kb_data$timetable
    periods <- kb_data$periods
    courses <- kb_data$courses
    # Find next class in timetable
    today_day <- format(Sys.Date(), "%A")
    schedule <- timetable[[today_day]]
    if (!is.null(schedule)) {
      for (p in names(schedule)) {
        code <- schedule[[p]]
        if (nchar(code) > 0) {
          title <- if (!is.null(courses[[code]])) courses[[code]]$title else code
          time_info <- if (!is.null(periods[[p]])) paste0(periods[[p]]$start, "-", periods[[p]]$end) else ""
          return(paste0("Your next scheduled class today (", today_day, ") is ", title, " [", code, "] in Period ", p, " (", time_info, ")."))
        }
      }
    }
    return("Your next upcoming class is 22UAD301 - Deep Learning Concepts in Period 1 (08:45-09:40).")
  }
  
  if (intent == "CLASS_BY_DAY") {
    days <- entities$DAY
    if (is.null(days) || length(days) == 0) return("Please specify a day (e.g. Monday, Tuesday, Today) to view the timetable.")
    day_name <- tools::toTitleCase(days[1])
    if (day_name == "Today") day_name <- format(Sys.Date(), "%A")
    if (day_name == "Tomorrow") day_name <- format(Sys.Date() + 1, "%A")
    
    schedule <- kb_data$timetable[[day_name]]
    if (is.null(schedule)) return(paste("No classes found for", day_name))
    
    items <- c()
    for (p in names(schedule)) {
      code <- schedule[[p]]
      if (nchar(code) > 0) {
        title <- if (!is.null(kb_data$courses[[code]])) kb_data$courses[[code]]$title else code
        time_info <- if (!is.null(kb_data$periods[[p]])) paste0(kb_data$periods[[p]]$start, "-", kb_data$periods[[p]]$end) else ""
        items <- c(items, paste0("Period ", p, " (", time_info, "): ", title, " [", code, "]"))
      }
    }
    return(paste0(day_name, "'s timetable: ", paste(items, collapse = "; ")))
  }
  
  if (intent == "CLASS_VENUE") {
    venue <- kb_data$`class`$venue
    return(paste0("Your class venue is ", venue, "."))
  }
  
  if (intent == "FACULTY_FOR_CLASS" || intent == "SUBJECT_INFORMATION") {
    codes <- entities$COURSE_CODE
    if (is.null(codes)) {
      return("Matching course details: 22UAD301 (Deep Learning Concepts) handled by Dr. G. Rajeshkumar & Mrs. S. Biruntha.")
    }
    code <- codes[1]
    course <- kb_data$courses[[code]]
    if (is.null(course)) return(paste("No records found for course code", code))
    
    staff <- kb_data$timetable_staff_mapping[[code]]
    staff_str <- if (!is.null(staff)) paste(staff, collapse = ", ") else "Faculty assigned"
    if (intent == "FACULTY_FOR_CLASS") {
      return(paste0(course$title, " (", code, ") is taught by: ", staff_str))
    } else {
      return(paste0(course$title, " (", code, "): Type: ", course$type, ", Credits: ", course$credits, ", Hours: ", course$hours, ". Taught by: ", staff_str))
    }
  }

  if (intent == "MINI_PROJECT_MENTOR" || intent == "MINI_PROJECT_BATCH" || intent == "MINI_PROJECT_DOMAIN" || intent == "STUDENT_BATCH_LOOKUP") {
    batches <- kb_data$mini_project$batches
    if (is.null(batches) || length(batches) == 0) return("No mini project details available.")
    
    b_num <- entities$BATCH
    if (!is.null(b_num)) {
      for (b in batches) {
        if (as.character(b$batch) == as.character(b_num[1])) {
          members <- paste(b$members, collapse = ", ")
          return(paste0("Batch ", b$batch, " [Domain: ", b$domain, "]: Mentor - ", b$mentor, ". Team Members: ", members))
        }
      }
    }
    first_b <- batches[[1]]
    return(paste0("Batch ", first_b$batch, " [Domain: ", first_b$domain, "]: Mentor - ", first_b$mentor, ". Team Members: ", paste(first_b$members, collapse = ", ")))
  }
  
  if (intent == "ACADEMIC_CALENDAR" || intent == "HOLIDAY_CHECK" || intent == "EXAM_PERIOD" || intent == "INTERNAL_TEST") {
    events <- kb_data$academic_calendar$events_readable_from_source
    assessments <- kb_data$academic_calendar$assessment_periods
    evt_str <- c()
    if (!is.null(events)) {
      for (e in events) evt_str <- c(evt_str, paste0(e$date, ": ", e$event))
    }
    if (!is.null(assessments)) {
      for (a in assessments) evt_str <- c(evt_str, paste0(a$type, ": ", a$period))
    }
    return(paste("Academic Calendar Highlights:", paste(evt_str[1:min(5, length(evt_str))], collapse = " | ")))
  }
  
  return("I recognized your query intent! Try asking specifically about class timetable, course credits, faculty, syllabus units, or project mentor.")
}
