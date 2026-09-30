"""Generate template-based answers from the loaded academic knowledge base."""

from datetime import date, datetime, timedelta
from typing import Any

from knowledge import KnowledgeBase
from nlp.normalizer import normalize_text


def _values(entities: dict[str, Any], name: str) -> list[str]:
    value = entities.get(name)
    if value is None:
        return []
    return [str(item) for item in value] if isinstance(value, list) else [str(value)]


def _matching_courses(data: dict[str, Any], entities: dict[str, Any]) -> list[tuple[str, dict[str, Any]]]:
    """Find courses by code or by a title/fragment detected in the question."""
    courses = data.get("courses", {})
    requested_codes = {value.upper() for value in _values(entities, "COURSE_CODE")}
    if requested_codes:
        return [
            (code, course)
            for code, course in courses.items()
            if code.upper() in requested_codes and isinstance(course, dict)
        ]

    requested_names = [normalize_text(value) for value in _values(entities, "COURSE_NAME")]
    return [
        (code, course)
        for code, course in courses.items()
        if isinstance(course, dict)
        and any(
            name in normalize_text(str(course.get("title", "")))
            or normalize_text(str(course.get("title", ""))) in name
            for name in requested_names
            if name
        )
    ]


def _course_label(code: str, course: dict[str, Any]) -> str:
    return f"{course.get('title', code)} ({code})"


def _course_staff(data: dict[str, Any], code: str, course: dict[str, Any]) -> list[str]:
    staff_mapping = data.get("timetable_staff_mapping", {})
    return staff_mapping.get(code) or course.get("faculty", [])


def _topic_locations(data: dict[str, Any], topic: str) -> list[str]:
    locations = []
    requested_topic = normalize_text(topic)
    for code, course in data.get("courses", {}).items():
        for unit, details in course.get("units", {}).items():
            for stored_topic in details.get("topics", []):
                if normalize_text(str(stored_topic)) == requested_topic:
                    locations.append(
                        f"{stored_topic} is listed in {course.get('title', code)} "
                        f"({code}), Unit {unit}."
                    )
    return locations


def _day_name(entities: dict[str, Any], offset: int = 0) -> str | None:
    days = _values(entities, "DAY")
    if not days:
        return None
    day = days[0].lower()
    if day in {"today", "tomorrow"}:
        target = date.today() + timedelta(days=offset + (day == "tomorrow"))
        return target.strftime("%A")
    return day.capitalize()


def _classes_for_day(data: dict[str, Any], day: str) -> list[str]:
    schedule = data.get("timetable", {}).get(day, {})
    periods = data.get("periods", {})
    courses = data.get("courses", {})
    items = []
    for period, code in schedule.items():
        if not code:
            continue
        timing = periods.get(period, {})
        course = courses.get(code, {})
        label = course.get("title", code) if isinstance(course, dict) else code
        time_range = f"{timing['start']}-{timing['end']}" if timing else "time not listed"
        items.append(f"Period {period} ({time_range}): {label} [{code}]")
    return items


def _answer_next_class(data: dict[str, Any]) -> str:
    today = datetime.now()
    timetable = data.get("timetable", {})
    periods = data.get("periods", {})
    courses = data.get("courses", {})

    for offset in range(8):
        target_date = today.date() + timedelta(days=offset)
        day = target_date.strftime("%A")
        schedule = timetable.get(day, {})
        for period, code in schedule.items():
            timing = periods.get(period, {})
            start = timing.get("start")
            if not code or not start:
                continue
            class_time = datetime.strptime(start, "%H:%M").time()
            if offset == 0 and class_time <= today.time():
                continue
            course = courses.get(code, {})
            label = course.get("title", code) if isinstance(course, dict) else code
            return f"Your next scheduled class is {label} [{code}] on {day}, Period {period} at {start}."

    return "I could not find an upcoming class in the timetable."


def _answer_calendar(data: dict[str, Any], entities: dict[str, Any], holiday_only: bool = False) -> str:
    calendar = data.get("academic_calendar", {})
    requested_dates = _values(entities, "DATE")
    if not requested_dates and _values(entities, "DAY"):
        day = _values(entities, "DAY")[0].lower()
        if day in {"today", "tomorrow"}:
            requested_dates = [(date.today() + timedelta(days=day == "tomorrow")).isoformat()]

    if holiday_only:
        if not requested_dates:
            return "Please include a date, or ask whether today is a holiday."
        target = normalize_text(requested_dates[0])
        events = [
            event
            for event in calendar.get("events_readable_from_source", [])
            if normalize_text(str(event.get("date", ""))) == target
        ]
        if target:
            try:
                target_date = date.fromisoformat(target)
            except ValueError:
                target_date = None
            if target_date and target_date.strftime("%A").lower() == "sunday":
                return f"Yes. {target} is a Sunday Holiday according to the calendar."
        if events:
            descriptions = "; ".join(f"{item['event']} ({item['date']})" for item in events)
            return f"The calendar lists: {descriptions}. Check the event details to confirm whether classes are cancelled."
        return f"No holiday is listed for {requested_dates[0]} in the readable calendar entries."

    events = calendar.get("events_readable_from_source", [])
    assessments = calendar.get("assessment_periods", [])
    if not events and not assessments:
        return "The knowledge base does not contain readable calendar events."
    lines = [f"{item.get('date')}: {item.get('event')}" for item in events]
    lines.extend(
        f"{item.get('type')}: {item.get('period')}"
        for item in assessments
    )
    return "Calendar entries: " + "; ".join(lines)


def _answer_project(data: dict[str, Any], intent: str, entities: dict[str, Any]) -> str:
    batches = data.get("mini_project", {}).get("batches", [])
    requested_batch = _values(entities, "BATCH")
    requested_students = {normalize_text(name) for name in _values(entities, "STUDENT")}
    matching = []
    for batch in batches:
        members = batch.get("members", [])
        batch_matches = requested_batch and str(batch.get("batch")) in requested_batch
        student_matches = requested_students.intersection(normalize_text(str(name)) for name in members)
        if batch_matches or student_matches:
            matching.append((batch, student_matches))

    if not matching:
        return "Please provide a batch number or a student name that appears in the project records."

    answers = []
    for batch, student_matches in matching:
        number = batch.get("batch")
        domain = batch.get("domain", "domain not listed")
        mentor = batch.get("mentor", "mentor not listed")
        if intent == "STUDENT_BATCH_LOOKUP":
            names = [name for name in batch.get("members", []) if normalize_text(str(name)) in student_matches]
            answers.append(f"{', '.join(names)} is in batch {number} ({domain}); mentor: {mentor}.")
        elif intent == "MINI_PROJECT_MENTOR":
            answers.append(f"Batch {number}'s mentor is {mentor}.")
        elif intent == "MINI_PROJECT_DOMAIN":
            answers.append(f"Batch {number}'s project domain is {domain}.")
        else:
            members = ", ".join(str(name) for name in batch.get("members", []))
            answers.append(f"Batch {number} ({domain}); mentor: {mentor}; members: {members}.")
    return " ".join(answers)


def generate_response(
    intent: str,
    entities: dict[str, Any],
    knowledge_base: KnowledgeBase,
) -> str:
    """Return a grounded answer for a recognized intent using stored records only."""
    data = knowledge_base.data

    if intent == "NEXT_CLASS":
        return _answer_next_class(data)
    if intent == "CLASS_BY_DAY":
        day = _day_name(entities)
        if day is None:
            return "Please specify a day so I can check the timetable."
        items = _classes_for_day(data, day)
        return f"{day}'s timetable: " + "; ".join(items) if items else f"No classes are listed for {day}."
    if intent == "CLASS_VENUE":
        venue = data.get("class", {}).get("venue")
        return f"Your class venue is {venue}." if venue else "The class venue is not listed in the knowledge base."
    if intent == "CLASS_TIME":
        period = _values(entities, "PERIOD")
        courses = _matching_courses(data, entities)
        if period:
            timing = data.get("periods", {}).get(period[0].upper())
            if timing:
                return f"Period {period[0]} runs from {timing['start']} to {timing['end']}."
        if courses:
            timetable = data.get("timetable", {})
            matches = []
            for code, course in courses:
                for day, schedule in timetable.items():
                    for period, scheduled_code in schedule.items():
                        if scheduled_code == code:
                            time = data.get("periods", {}).get(period, {})
                            matches.append(f"{_course_label(code, course)}: {day}, Period {period} ({time.get('start')} to {time.get('end')})")
            return "; ".join(matches) if matches else "No timetable times are listed for that course."
        return "Please specify a course or period so I can find its class time."
    if intent in {"FACULTY_FOR_CLASS", "SUBJECT_INFORMATION"}:
        courses = _matching_courses(data, entities)
        if not courses:
            return "I could not match that course to a stored course title or code. Please include its full name or course code."
        details = []
        for code, course in courses:
            if intent == "FACULTY_FOR_CLASS":
                staff = _course_staff(data, code, course)
                details.append(f"{_course_label(code, course)} is taught by {', '.join(staff)}." if staff else f"No faculty is listed for {_course_label(code, course)}.")
            else:
                details.append(
                    f"{_course_label(code, course)}: {course.get('type', 'type not listed')}; "
                    f"{course.get('credits', 'credits not listed')} credits; "
                    f"{course.get('hours', 'hours not listed')} hours."
                )
        if len(details) > 1:
            return "That name matches multiple courses: " + " ".join(details)
        return details[0]
    if intent in {"SYLLABUS_TOPIC_LOCATION", "TOPIC_INFORMATION"}:
        topics = _values(entities, "TOPIC")
        if not topics:
            return "Please include a topic name so I can search the syllabus."
        locations = [location for topic in topics for location in _topic_locations(data, topic)]
        if locations:
            if intent == "TOPIC_INFORMATION":
                return "The knowledge base stores this topic's syllabus location, not an explanation. " + " ".join(locations)
            return " ".join(locations)
        return f"I could not find {topics[0]} in the stored course topics."
    if intent == "UNIT_TOPICS":
        units = _values(entities, "UNIT")
        if not units:
            return "Please specify a unit number or numeral."
        unit = units[0].upper()
        courses = _matching_courses(data, entities)
        found = []
        source_courses = courses or list(data.get("courses", {}).items())
        for code, course in source_courses:
            details = course.get("units", {}).get(unit)
            if details:
                found.append((_course_label(code, course), details.get("topics", [])))
        if not found:
            return f"No topics are listed for Unit {unit} in the matching course records."
        if len(found) > 1 and not courses:
            labels = ", ".join(label for label, _ in found)
            return f"Unit {unit} appears in several courses ({labels}). Please specify a course to get the right topic list."
        return "; ".join(f"{label}, Unit {unit}: {', '.join(topics) if topics else 'no topics listed'}" for label, topics in found)
    if intent == "FACULTY_INFORMATION":
        requested = {normalize_text(name) for name in _values(entities, "FACULTY")}
        profiles = data.get("faculty", {}).get("profiles", [])
        matching = [profile for profile in profiles if normalize_text(str(profile.get("name", ""))) in requested]
        if not matching:
            return "Please include a faculty member's name so I can look up their stored profile."
        return " ".join(
            f"{profile['name']}: {profile.get('designation', 'designation not listed')}; "
            f"department: {profile.get('department', 'not listed')}; "
            f"expertise: {', '.join(profile.get('expertise', [])) or 'not listed'}."
            for profile in matching
        )
    if intent == "ACADEMIC_CALENDAR":
        return _answer_calendar(data, entities)
    if intent == "HOLIDAY_CHECK":
        return _answer_calendar(data, entities, holiday_only=True)
    if intent in {"INTERNAL_TEST", "EXAM_PERIOD"}:
        assessments = data.get("academic_calendar", {}).get("assessment_periods", [])
        target = "internal" if intent == "INTERNAL_TEST" else "exam"
        matching = [
            item
            for item in assessments
            if target in normalize_text(str(item.get("type", "")))
            or (intent == "EXAM_PERIOD" and "ese" in normalize_text(str(item.get("type", ""))))
        ]
        if matching:
            return "; ".join(f"{item.get('type')}: {item.get('period')}" for item in matching)
        return f"No {target} period is listed in the academic calendar records."
    if intent in {"MINI_PROJECT_MENTOR", "MINI_PROJECT_BATCH", "MINI_PROJECT_DOMAIN", "STUDENT_BATCH_LOOKUP"}:
        return _answer_project(data, intent, entities)
    if intent == "UNKNOWN":
        return "I could not identify that question. Try asking about a class, course, syllabus topic, faculty member, calendar event, or project batch."
    return "I recognized the question type, but do not have a response rule for it yet."