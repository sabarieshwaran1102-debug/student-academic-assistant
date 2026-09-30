# 🎓 Student Academic Assistant

> **A Classical AI & Knowledge-Based Academic Assistant System**  
> Designed for **II AI&DS Section B (Semester III)** at **Dr. N.G.P. Institute of Technology**.

---

## 📌 Overview

The **Student Academic Assistant** is a comprehensive, rule-based classical AI system built to answer student queries regarding course schedules, faculty details, unit syllabi, exam dates, mini-project mentor allocations, and academic calendars. 

It features a dual-frontend architecture—offering both a lightweight **Python REST API + Glassmorphism Web Interface** and a statistical **R Shiny Analytics Dashboard**.

---

## ✨ Key Features

- 🧠 **Classical Rule-Based NLP Pipeline**:
  - Custom text normalizer and token generator.
  - Regex and keyword-matching **Intent Recognition** supporting 18+ specific academic intent categories.
  - **Dynamic Entity Extraction** powered by knowledge-base lookup for course codes, course titles, faculty names, unit topics, student names, project domains, dates, and time slots.
- 🗄️ **Structured Knowledge Base**:
  - Complete JSON schema managing institution metadata, 13+ courses, 12+ faculty profiles, 22 mini-project batches, unit-wise syllabi, timetable grids, and exam schedules.
- 🌐 **Modern Web Interface (Python Backend)**:
  - Responsive dark-mode glassmorphism UI with interactive Q&A assistant.
  - Quick action suggestion chips, live timetable inspector, course breakdown, and analytical charts.
  - Zero third-party backend dependencies (`http.server` base).
- 📊 **R Shiny Analytics Dashboard**:
  - Full statistical breakdown of course workloads, credit allocations, and mini-project domain distributions.
  - Integrated R NLP engine (`R/academic_analytics.R`, `R/helper_nlp.R`).
- 💻 **Interactive CLI Interface**:
  - Lightweight command-line shell for instant testing of normalization, tokenization, intent detection, and entity extraction.

---

## 🛠️ Tech Stack & Architecture

```
                                  ┌───────────────────────────────┐
                                  │   Academic Question Input     │
                                  └───────────────┬───────────────┘
                                                  │
                                                  ▼
                                  ┌───────────────────────────────┐
                                  │      Classical NLP Engine     │
                                  │  (Normalize ➔ Tokenize ➔      │
                                  │   Intent Detection ➔          │
                                  │   KB Entity Extraction)       │
                                  └───────────────┬───────────────┘
                                                  │
                                                  ▼
                                  ┌───────────────────────────────┐
                                  │    Knowledge Base Engine      │
                                  │  (JSON Store: Courses,        │
                                  │   Faculty, Timetable, Exams)  │
                                  └───────────────┬───────────────┘
                                                  │
                        ┌─────────────────────────┴─────────────────────────┐
                        ▼                                                   ▼
         ┌─────────────────────────────┐                     ┌─────────────────────────────┐
         │     Python HTTP Server      │                     │     R Shiny Analytics UI    │
         │  (REST API + Web UI @ 8000) │                     │   (Dashboard & Viz @ 3838)  │
         └─────────────────────────────┘                     └─────────────────────────────┘
```

| Layer | Technologies Used |
|---|---|
| **Core NLP Engine** | Python 3.10+ (`re`, `json`, `pathlib`), R (`jsonlite`, `bslib`, `shiny`) |
| **Backend API** | Standard Python `http.server` |
| **Web Frontend** | HTML5, CSS3 (Glassmorphism design, CSS Variables), JavaScript (ES6 fetch, Chart rendering) |
| **Analytics & Data Viz**| R Shiny Framework, `bslib`, `jsonlite` |
| **Data Storage** | JSON Knowledge Base (`data/student_academic_assistant_complete_knowledge_base.json`) |

---

## 📂 Directory Structure

```
student_academic_assistant/
├── data/
│   └── student_academic_assistant_complete_knowledge_base.json # Primary Knowledge Base
├── knowledge/
│   ├── __init__.py
│   └── knowledge_base.py          # Knowledge base loader & query interface
├── nlp/
│   ├── __init__.py
│   ├── normalizer.py              # Text cleaning & normalization
│   ├── tokenizer.py               # Lexical token splitter
│   ├── intent.py                  # Rule-based intent detection engine
│   └── entity.py                  # KB-backed & regex entity extractor
├── R/
│   ├── academic_analytics.R       # R statistical analytics functions
│   └── helper_nlp.R               # R NLP bridging functions
├── static/
│   ├── index.html                 # Web App UI template
│   ├── style.css                  # Dark mode Glassmorphism styles
│   └── app.js                     # Frontend API interaction & DOM logic
├── app.R                          # R Shiny application main entry point
├── main.py                        # Interactive Terminal CLI tool
├── response.py                    # Intent-to-Response generation engine
├── run_python_frontend.bat        # Windows batch script to launch Python server
├── run_r_app.R                    # R dependency bootstrapper & app runner
├── run_r_app.bat                  # Windows batch script to launch R Shiny app
├── server.py                      # REST API & static web server
└── .gitignore                     # Git ignore file
```

---

## 🚀 Getting Started

### Prerequisites

- **Python**: Version `3.8+` (No external pip dependencies required for core server).
- **R** *(Optional, for R Shiny app)*: Version `4.0+` with packages: `shiny`, `jsonlite`, `bslib`.

---

## 🏃 Running the Application

### Option A: Python Web Server & Web Interface (Recommended)

Run the Python HTTP server (serves the web interface at **http://localhost:8000**):

```bash
python server.py 8000
```
*Or double-click `run_python_frontend.bat` on Windows.*

Open your web browser and navigate to:
```
http://localhost:8000
```

---

### Option B: R Shiny Analytics Application

Launch the interactive R Shiny Dashboard on port **3838**:

```bash
Rscript run_r_app.R
```
*Or double-click `run_r_app.bat` on Windows.*

Navigate to:
```
http://localhost:3838
```

---

### Option C: Command Line Interface (CLI)

For quick debugging and terminal-based NLP inspection:

```bash
python main.py
```

Example CLI Session:
```text
Knowledge base loaded from: d:\Projects\student_academic_assistant\data\student_academic_assistant_complete_knowledge_base.json

Ask an academic question (blank to quit): Who teaches Linear Algebra?
Normalized: who teaches linear algebra
Tokens: ['who', 'teaches', 'linear', 'algebra']
Intent: FACULTY_FOR_CLASS
Entities: {
    "COURSE_NAME": "Linear Algebra"
}
Answer: Linear Algebra and Partial Differential Equations (22UMA301) is handled by Dr. S. Kowsalya.
```

---

## 📡 REST API Reference

The Python backend provides three lightweight JSON API endpoints:

### 1. `POST /api/query`
Processes a student academic query through the NLP pipeline and returns intent, extracted entities, and the answer.

- **Request Body**:
```json
{
  "question": "When is the next internal exam?"
}
```

- **Response**:
```json
{
  "question": "When is the next internal exam?",
  "normalized": "when is the next internal exam",
  "tokens": ["when", "is", "the", "next", "internal", "exam"],
  "intent": "INTERNAL_TEST",
  "entities": {},
  "answer": "Internal Assessment Test I is scheduled from 2026-10-05 to 2026-10-10.",
  "r_status": "R Analytics Available"
}
```

---

### 2. `GET /api/analytics`
Returns aggregated statistical metrics from the knowledge base.

- **Response**:
```json
{
  "metadata": { ... },
  "total_courses": 13,
  "total_faculty": 12,
  "total_batches": 22,
  "credits_by_course": { "22UMA301": 3, "22UAD301": 4, ... },
  "workload_by_course": { "22UMA301": 5, "22UAD301": 5, ... },
  "project_domains": { "Artificial Intelligence": 13, "Machine Learning": 8, "Web Development": 1 },
  "r_interop_ready": true
}
```

---

### 3. `GET /api/data`
Returns the raw Knowledge Base JSON contents.

---

## 🎯 Supported Intents

| Intent Code | Sample User Queries |
|---|---|
| `FACULTY_FOR_CLASS` | *"Who teaches Linear Algebra?"*, *"Who is the teacher for Discrete Structures?"* |
| `NEXT_CLASS` | *"What is the next lecture?"*, *"What class is upcoming?"* |
| `CLASS_TIME` | *"What time is Data Structures class?"*, *"When is period 3?"* |
| `CLASS_VENUE` | *"Where is the AI lab class conducted?"*, *"Which room is 22UAD301 in?"* |
| `EXAM_PERIOD` | *"When are the semester exams?"*, *"Exam dates for Semester III"* |
| `INTERNAL_TEST` | *"When is internal test 1?"*, *"Cycle test schedule"* |
| `UNIT_TOPICS` | *"What are the topics in Unit 2 of Linear Algebra?"* |
| `SYLLABUS_TOPIC_LOCATION` | *"Which unit covers Eigenvalues?"*, *"Where in syllabus is Bayes Theorem?"* |
| `MINI_PROJECT_MENTOR` | *"Who is the mentor for Batch 4?"*, *"Guide for project team 12"* |
| `MINI_PROJECT_DOMAIN` | *"What is the domain of Batch 7?"*, *"List AI domain projects"* |
| `MINI_PROJECT_BATCH` | *"Members of Batch 3?"*, *"Details of mini project team 5"* |
| `STUDENT_BATCH_LOOKUP` | *"Which batch does Sabarish belong to?"* |
| `ACADEMIC_CALENDAR` | *"Show academic calendar"*, *"When does semester end?"* |
| `HOLIDAY_CHECK` | *"Is tomorrow a holiday?"*, *"Are there classes on Friday?"* |
| `CLASS_BY_DAY` | *"What classes are on Monday?"*, *"Show timetable for Today"* |
| `FACULTY_INFORMATION` | *"Tell me about Dr. S. Kowsalya"*, *"Faculty profile for Class Advisor"* |
| `SUBJECT_INFORMATION` | *"Course details for 22UAD301"*, *"Prerequisites for Data Structures"* |

---

## 📄 License

Developed for educational & academic demonstration purposes at **Dr. N.G.P. Institute of Technology**.
