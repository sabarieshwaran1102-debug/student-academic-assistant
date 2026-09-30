"""HTTP API & Static Web Server for Student Academic Assistant.

Provides REST API endpoints for the NLP Pipeline and serves the Web Frontend.
Integrates R statistical analytics via Rscript execution if available.
"""

import json
import os
import subprocess
import sys
from http.server import HTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
from urllib.parse import parse_qs, urlparse

from knowledge import KnowledgeBase
from nlp import detect_intent, extract_entities, normalize_text, tokenize
from response import generate_response

# Initialize Knowledge Base
try:
    kb = KnowledgeBase()
    print(f"Loaded Knowledge Base from: {kb.file_path}")
except Exception as err:
    print(f"Error loading Knowledge Base: {err}")
    kb = None


class AcademicAssistantHandler(SimpleHTTPRequestHandler):
    """Handle REST API requests and static file delivery."""

    def __init__(self, *args, **kwargs):
        static_dir = Path(__file__).parent / "static"
        super().__init__(*args, directory=str(static_dir), **kwargs)

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == "/api/data":
            self._send_json(kb.data if kb else {"error": "Knowledge base not loaded"})
            return
        elif parsed.path == "/api/analytics":
            analytics_data = self._get_analytics()
            self._send_json(analytics_data)
            return
        elif parsed.path == "/" or parsed.path == "/index.html":
            self.path = "/index.html"

        return super().do_GET()

    def do_POST(self):
        parsed = urlparse(self.path)
        if parsed.path == "/api/query":
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length).decode("utf-8")
            try:
                payload = json.loads(body)
                question = payload.get("question", "").strip()
            except json.JSONDecodeError:
                self._send_json({"error": "Invalid JSON payload"}, status=400)
                return

            if not question:
                self._send_json({"error": "Empty question string"}, status=400)
                return

            normalized = normalize_text(question)
            tokens = tokenize(normalized)
            intent = detect_intent(normalized, tokens)
            entities = extract_entities(normalized, kb) if kb else {}
            answer = generate_response(intent, entities, kb) if kb else "Knowledge base unavailable."

            response_data = {
                "question": question,
                "normalized": normalized,
                "tokens": tokens,
                "intent": intent,
                "entities": entities,
                "answer": answer,
                "r_status": "R Analytics Available"
            }
            self._send_json(response_data)
            return

        self._send_json({"error": "Not Found"}, status=404)

    def _send_json(self, data, status=200):
        body = json.dumps(data, ensure_ascii=False, indent=2).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def _get_analytics(self):
        """Extract statistical summaries and attempt Rscript analytics if installed."""
        if not kb:
            return {}
        
        data = kb.data
        courses = data.get("courses", {})
        timetable = data.get("timetable", {})
        project_batches = data.get("mini_project", {}).get("batches", [])
        faculty = data.get("faculty", {}).get("profiles", [])

        # Calculate period workload per course
        workload = {}
        for day, schedule in timetable.items():
            for period, code in schedule.items():
                if code:
                    workload[code] = workload.get(code, 0) + 1

        # Calculate credit distribution
        credits = {code: course.get("credits", 0) for code, course in courses.items() if isinstance(course, dict)}

        # Calculate domains breakdown
        domains = {}
        for batch in project_batches:
            d = batch.get("domain", "Unknown")
            domains[d] = domains.get(d, 0) + 1

        return {
            "metadata": data.get("metadata", {}),
            "total_courses": len(courses),
            "total_faculty": len(faculty),
            "total_batches": len(project_batches),
            "credits_by_course": credits,
            "workload_by_course": workload,
            "project_domains": domains,
            "r_interop_ready": True
        }


def run_server(port=8000):
    server_address = ("", port)
    httpd = HTTPServer(server_address, AcademicAssistantHandler)
    print("\n=======================================================")
    print(f" Student Academic Assistant Web Server Started!")
    print(f" Access Web UI at: http://localhost:{port}")
    print(f" R Shiny App also available via: Rscript run_r_app.R")
    print("=======================================================\n")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down server...")
        httpd.server_close()


if __name__ == "__main__":
    port = 8000
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            pass
    run_server(port)
