// static/app.js - Web Application Logic & R Analytics Integration

let kbData = null;
let analyticsData = null;
let currentTimetableDay = "All";

document.addEventListener("DOMContentLoaded", () => {
  fetchKBData();
  fetchAnalytics();
});

// Fetch Knowledge Base Data
async function fetchKBData() {
  try {
    const res = await fetch("/api/data");
    kbData = await res.json();
    populateCourseDropdown();
    renderTimetable();
    renderFacultyTable();
    renderProjects();
  } catch (err) {
    console.error("Failed to load knowledge base:", err);
  }
}

// Fetch Analytics
async function fetchAnalytics() {
  try {
    const res = await fetch("/api/analytics");
    analyticsData = await res.json();
    renderAnalyticsCharts();
  } catch (err) {
    console.error("Failed to load analytics:", err);
  }
}

// Tab Switching
function switchTab(tabId) {
  document.querySelectorAll(".nav-item").forEach(btn => btn.classList.remove("active"));
  document.querySelectorAll(".tab-pane").forEach(pane => pane.classList.remove("active"));

  const navBtn = document.getElementById(`nav-${tabId}`);
  const tabPane = document.getElementById(`tab-${tabId}`);

  if (navBtn) navBtn.classList.add("active");
  if (tabPane) tabPane.classList.add("active");

  const titles = {
    chat: ["AI Academic Query Assistant", "Interactive grounded answers powered by classical NLP & R statistics"],
    timetable: ["Weekly Class Timetable", "View period schedules, time slots, and handling faculty"],
    courses: ["Course Catalog & Syllabus Breakdown", "Explore credits, unit topics, and prerequisites"],
    faculty: ["Department Faculty Directory", "Instructor designations, departments, and expertise"],
    projects: ["Mini Project Batches & Teams", "Group numbers, domains, mentors, and member lists"],
    analytics: ["R Statistical Analytics Engine", "Visual metrics rendered from project knowledge base data"]
  };

  if (titles[tabId]) {
    document.getElementById("page-title").innerText = titles[tabId][0];
    document.getElementById("page-subtitle").innerText = titles[tabId][1];
  }
}

// Quick Prompt Handler
function askQuick(text) {
  const input = document.getElementById("user-question-input");
  input.value = text;
  sendQuery();
}

function handleEnterKey(e) {
  if (e.key === "Enter") sendQuery();
}

// Send Query to Python/R NLP Engine
async function sendQuery() {
  const input = document.getElementById("user-question-input");
  const qText = input.value.trim();
  if (!qText) return;

  appendMessage("user", qText);
  input.value = "";

  try {
    const res = await fetch("/api/query", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ question: qText })
    });

    const data = await res.json();

    appendMessage("bot", data.answer);
    updateInspector(data);

  } catch (err) {
    appendMessage("bot", "Error connecting to NLP backend API.");
  }
}

function appendMessage(sender, text) {
  const history = document.getElementById("chat-history");
  const msgDiv = document.createElement("div");
  msgDiv.className = `chat-message ${sender}`;

  const bubble = document.createElement("div");
  bubble.className = "message-bubble";
  bubble.innerText = text;

  const ts = document.createElement("span");
  ts.className = "timestamp";
  ts.innerText = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

  msgDiv.appendChild(bubble);
  msgDiv.appendChild(ts);

  history.appendChild(msgDiv);
  history.scrollTop = history.scrollHeight;
}

function updateInspector(data) {
  document.getElementById("insp-norm").innerText = data.normalized || "N/A";
  document.getElementById("insp-intent").innerText = data.intent || "UNKNOWN";
  document.getElementById("insp-entities").innerText = JSON.stringify(data.entities || {}, null, 2);
}

// Timetable Renderer
function renderTimetable() {
  if (!kbData || !kbData.timetable) return;
  const tbody = document.getElementById("timetable-tbody");
  tbody.innerHTML = "";

  const timetable = kbData.timetable;
  const periods = kbData.periods || {};
  const courses = kbData.courses || {};

  for (const day in timetable) {
    if (currentTimetableDay !== "All" && currentTimetableDay !== day) continue;
    const daySched = timetable[day];

    for (const period in daySched) {
      const code = daySched[period];
      if (!code) continue;

      const course = courses[code] || {};
      const timing = periods[period] ? `${periods[period].start} - ${periods[period].end}` : "TBA";
      const title = course.title || code;

      const tr = document.createElement("tr");
      tr.innerHTML = `
        <td><strong>${day}</strong></td>
        <td>Period ${period}</td>
        <td>${timing}</td>
        <td><span class="intent-pill">${code}</span></td>
        <td>${title}</td>
        <td><span class="domain-tag">Scheduled</span></td>
      `;
      tbody.appendChild(tr);
    }
  }
}

function filterTimetable(day) {
  currentTimetableDay = day;
  document.querySelectorAll(".day-btn").forEach(b => b.classList.remove("active"));
  event.target.classList.add("active");
  renderTimetable();
}

// Course Dropdown & Details
function populateCourseDropdown() {
  if (!kbData || !kbData.courses) return;
  const select = document.getElementById("course-dropdown");
  select.innerHTML = "";

  for (const code in kbData.courses) {
    const opt = document.createElement("option");
    opt.value = code;
    opt.innerText = `${code} - ${kbData.courses[code].title}`;
    select.appendChild(opt);
  }
  renderCourseDetails();
}

function renderCourseDetails() {
  const code = document.getElementById("course-dropdown").value;
  if (!code || !kbData || !kbData.courses[code]) return;

  const course = kbData.courses[code];
  const container = document.getElementById("course-detail-container");

  const staff = kbData.timetable_staff_mapping[code] || course.faculty || ["Unassigned"];

  let unitsHTML = "";
  if (course.units) {
    for (const uNum in course.units) {
      const unit = course.units[uNum];
      const topics = (unit.topics || []).map(t => `<span class="chip">${t}</span>`).join(" ");
      unitsHTML += `
        <div style="background: rgba(15,23,42,0.8); padding: 1rem; border-radius: 8px; margin-bottom: 0.75rem; border-left: 4px solid var(--accent-indigo);">
          <h5 style="color: #38bdf8; margin-bottom: 0.5rem;">Unit ${uNum}: ${unit.title}</h5>
          <div style="display:flex; flex-wrap:wrap; gap:0.35rem; margin-top:0.5rem;">${topics}</div>
        </div>
      `;
    }
  }

  container.innerHTML = `
    <div style="display:grid; grid-template-columns: 1fr 1fr; gap:1.5rem; margin-bottom: 1.5rem;">
      <div>
        <h3 style="color: #818cf8;">${course.title} (${code})</h3>
        <p style="color:var(--text-sub); margin-top:0.5rem;">Type: <strong>${course.type}</strong> | Credits: <strong>${course.credits}</strong> | Hours/Week: <strong>${course.hours}</strong></p>
      </div>
      <div style="background: rgba(15,23,42,0.8); padding:1rem; border-radius:8px;">
        <h5 style="color: #34d399;">Handling Faculty</h5>
        <p style="margin-top:0.35rem;">${staff.join(", ")}</p>
      </div>
    </div>
    <h4 style="color: #38bdf8; margin-bottom: 1rem;">Syllabus Units Breakdown</h4>
    ${unitsHTML}
  `;
}

// Faculty Profiles Table
function renderFacultyTable() {
  if (!kbData || !kbData.faculty || !kbData.faculty.profiles) return;
  const tbody = document.getElementById("faculty-tbody");
  tbody.innerHTML = "";

  kbData.faculty.profiles.forEach(prof => {
    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td><strong>${prof.name}</strong></td>
      <td>${prof.designation || "Faculty"}</td>
      <td>${prof.department || "CSE"}</td>
      <td>${(prof.expertise || []).join(", ")}</td>
    `;
    tbody.appendChild(tr);
  });
}

function filterFaculty() {
  const query = document.getElementById("faculty-search").value.toLowerCase();
  const rows = document.querySelectorAll("#faculty-tbody tr");
  rows.forEach(r => {
    const text = r.innerText.toLowerCase();
    r.style.display = text.includes(query) ? "" : "none";
  });
}

// Projects Cards
function renderProjects() {
  if (!kbData || !kbData.mini_project || !kbData.mini_project.batches) return;
  const container = document.getElementById("projects-container");
  container.innerHTML = "";

  kbData.mini_project.batches.forEach(b => {
    const card = document.createElement("div");
    card.className = "project-card";
    card.innerHTML = `
      <div style="display:flex; justify-content:space-between; align-items:center;">
        <h4>Batch ${b.batch}</h4>
        <span class="domain-tag">${b.domain}</span>
      </div>
      <p style="font-size:0.9rem; color:var(--text-sub);">Mentor: <strong style="color:#f8fafc;">${b.mentor}</strong></p>
      <div>
        <span style="font-size:0.8rem; color:var(--text-sub);">Team Members:</span>
        <p style="font-size:0.85rem; margin-top:0.25rem;">${b.members.join(", ")}</p>
      </div>
    `;
    container.appendChild(card);
  });
}

// Chart.js R Analytics Renderers
function renderAnalyticsCharts() {
  if (!analyticsData) return;

  // Chart 1: Credits
  const ctxCredits = document.getElementById("chart-credits").getContext("2d");
  new Chart(ctxCredits, {
    type: "bar",
    data: {
      labels: Object.keys(analyticsData.credits_by_course),
      datasets: [{
        label: "Course Credits",
        data: Object.values(analyticsData.credits_by_course),
        backgroundColor: "rgba(99, 102, 241, 0.7)",
        borderColor: "#6366f1",
        borderWidth: 1
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { labels: { color: "#f8fafc" } } },
      scales: {
        x: { ticks: { color: "#94a3b8" }, grid: { color: "rgba(255,255,255,0.05)" } },
        y: { ticks: { color: "#94a3b8" }, grid: { color: "rgba(255,255,255,0.05)" } }
      }
    }
  });

  // Chart 2: Workload
  const ctxWorkload = document.getElementById("chart-workload").getContext("2d");
  new Chart(ctxWorkload, {
    type: "bar",
    data: {
      labels: Object.keys(analyticsData.workload_by_course),
      datasets: [{
        label: "Weekly Periods",
        data: Object.values(analyticsData.workload_by_course),
        backgroundColor: "rgba(6, 182, 212, 0.7)",
        borderColor: "#06b6d4",
        borderWidth: 1
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { labels: { color: "#f8fafc" } } },
      scales: {
        x: { ticks: { color: "#94a3b8" }, grid: { color: "rgba(255,255,255,0.05)" } },
        y: { ticks: { color: "#94a3b8" }, grid: { color: "rgba(255,255,255,0.05)" } }
      }
    }
  });

  // Chart 3: Domains Pie
  const ctxDomains = document.getElementById("chart-domains").getContext("2d");
  new Chart(ctxDomains, {
    type: "pie",
    data: {
      labels: Object.keys(analyticsData.project_domains),
      datasets: [{
        data: Object.values(analyticsData.project_domains),
        backgroundColor: ["#6366f1", "#06b6d4", "#10b981", "#ec4899", "#8b5cf6"]
      }]
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      plugins: { legend: { labels: { color: "#f8fafc" } } }
    }
  });
}
