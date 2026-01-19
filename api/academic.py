from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from services.hemis_service import HemisService
from database.db_connect import get_session
from api.dependencies import get_current_student
from database.models import Student, TgAccount

router = APIRouter()

@router.get("/grades")
async def get_grades(
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_session)
):
    """
    Returns detailed grades (ON/YN 5-scale) using the same logic as the Bot.
    """
    if not student.hemis_token:
         return {"success": False, "message": "No Token", "data": []}
         
    # 1. Fetch ME to get current semester (Critical for correct grades)
    me_data = await HemisService.get_me(student.hemis_token)
    semester_code = None
    if me_data:
        sem = me_data.get("semester", {})
        if sem and isinstance(sem, dict):
             semester_code = sem.get("code") or sem.get("id")

    # 2. Fetch Subjects with Semester Code
    subjects = await HemisService.get_student_subject_list(student.hemis_token, semester_code=semester_code)
    
    parsed_data = []
    
    for item in subjects:
        # Extract Name
        subj_name = "Fan"
        if "curriculumSubject" in item:
             subj_name = item.get("curriculumSubject", {}).get("subject", {}).get("name", "Fan")
        else:
             subj_name = item.get("subject", {}).get("name", "Fan")
             
        # Parse Grades
        grades = HemisService.parse_grades_detailed(item)
        
        parsed_data.append({
            "subject": subj_name,
            "on": grades['ON'],
            "yn": grades['YN']
        })
        
    return {"success": True, "data": parsed_data}
@router.get("/subjects")
async def get_subjects(
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_session)
):
    """
    Returns rich subject data including Teachers, Grades, and Absences.
    """
    if not student.hemis_token:
        return {"success": False, "message": "No Token"}

    import asyncio
    
    # 1. Fetch data concurrently
    # Note: We use None for sem_code to let HemisService handle defaults
    subjects_task = HemisService.get_student_subject_list(student.hemis_token, student_id=student.id)
    absence_task = HemisService.get_student_absence(student.hemis_token, student_id=student.id)
    schedule_task = HemisService.get_student_schedule_cached(student.hemis_token, student_id=student.id)
    
    subjects_data, attendance_result, schedule_data = await asyncio.gather(
        subjects_task, absence_task, schedule_task
    )
    
    # 2. Process Absence Map
    abs_map = {}
    if isinstance(attendance_result, (tuple, list)) and len(attendance_result) >= 4:
        att_items = attendance_result[3]
        for item in att_items:
            s_name = item.get("subject", {}).get("name")
            if s_name:
                s_name_lower = s_name.lower().strip()
                abs_map[s_name_lower] = abs_map.get(s_name_lower, 0) + item.get("hour", 2)

    # 3. Process Teachers Map
    teacher_map = {}
    if schedule_data:
        for item in schedule_data:
            s_name = item.get("subject", {}).get("name")
            if not s_name: continue
            
            s_name_lower = s_name.lower().strip()
            t_name = item.get("employee", {}).get("name")
            if not t_name: continue
            
            train_type = item.get("trainingType", {}).get("name", "Boshqa")
            
            if s_name_lower not in teacher_map:
                teacher_map[s_name_lower] = {"lecturer": None, "seminar": None}
            
            if "ma'ruza" in train_type.lower() or "lecture" in train_type.lower():
                teacher_map[s_name_lower]["lecturer"] = t_name
            else:
                teacher_map[s_name_lower]["seminar"] = t_name

    # 4. Final Data Assembly
    results = []
    for item in (subjects_data or []):
        subject_info = item.get("curriculumSubject", {})
        sub_details = subject_info.get("subject", {})
        name = sub_details.get("name", "Nomsiz fan")
        s_id = sub_details.get("id")
        
        name_lower = name.lower().strip()
        t_info = teacher_map.get(name_lower, {})
        
        # Detailed Grades
        grades = HemisService.parse_grades_detailed(item)
        
        results.append({
            "id": s_id,
            "name": name,
            "lecturer": t_info.get("lecturer"),
            "seminar": t_info.get("seminar"),
            "absent_hours": abs_map.get(name_lower, 0),
            "overall_grade": item.get("overallScore", {}).get("grade", 0),
            "on": grades['ON'],
            "yn": grades['YN']
        })
        
    return {"success": True, "data": results}

@router.get("/resources/{subject_id}")
async def get_resources(
    subject_id: str,
    student: Student = Depends(get_current_student)
):
    """
    Returns topics and files for a specific subject.
    """
    if not student.hemis_token:
        return {"success": False, "message": "No Token"}
        
    resources = await HemisService.get_student_resources(student.hemis_token, subject_id=subject_id)
    
    # Process into clean format for App
    parsed = []
    for res in resources:
        topics = []
        for item in res.get("subjectFileResourceItems", []):
            for f in item.get("files", []):
                topics.append({
                    "id": item.get("id"),
                    "name": f.get("name") or "Fayl",
                    "url": f.get("url")
                })
        
        parsed.append({
            "id": res.get("id"),
            "title": res.get("title") or "Mavzu",
            "files": topics
        })
        
    return {"success": True, "data": parsed}

@router.get("/attendance")
async def get_attendance(
    semester: str = None,
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_session)
):
    """
    Returns detailed attendance data.
    If no semester or data empty, tries fallback logic similar to bot.
    """
    if not student.hemis_token:
        return {"success": False, "message": "No Token"}

    # Fetch attendance
    # get_student_absence returns (0,0,0, list)
    _, _, _, data = await HemisService.get_student_absence(student.hemis_token, semester_code=semester, student_id=student.id)
    
    # Logic: If data is empty and semester is NOT provided (default), we might want to check the previous semester or verify current.
    # However, HemisService.get_student_absence already defaults to current if None.
    # If the current semester has NO attendance, checking the previous one is good UX.
    # We need to know what the current "default" semester code is to guess the previous one.
    # We can get it from 'me' or just parsing the first available semester from the list if we had one.
    # For now, let's stick to the requested logic: "If current is empty, show old".
    
    current_sem_code = None
    if not semester:
        # We assume the default call returned current. If empty, try to find previous.
        if not data:
            # Quick check for 'me' to find current semester
            me_data = await HemisService.get_me(student.hemis_token)
            if me_data:
                curr_sem = me_data.get("currentSemester", {})
                if curr_sem:
                    current_sem_code = str(curr_sem.get("code", "12")) # Default logic
                    # Try previous: e.g., 12 -> 11
                    try:
                        prev_code = str(int(current_sem_code) - 1)
                        # Retry with previous
                        _, _, _, data_prev = await HemisService.get_student_absence(student.hemis_token, semester_code=prev_code, student_id=student.id)
                        if data_prev: 
                            data = data_prev
                            # We should probably notify the frontend that we switched, but usually just showing data is enough.
                    except: pass

    parsed = []
    
    # Calculate stats for debugging/headers if needed later
    # total_hours = 0
    
    for item in data:
        # "subject": {"name": "Subject"}, "date": "timestamp?", "hour": 2
        subj_name = item.get("subject", {}).get("name", "Fan")
        
        # Date Logic
        ts = item.get("lesson_date")
        date_str = item.get("date", "") 
        if ts and not date_str:
            from datetime import datetime
            try:
                date_str = datetime.fromtimestamp(ts).strftime("%Y-%m-%d")
            except: pass
            
        lesson_theme = item.get("trainingType", {}).get("name", "")
        
        # Hours and Status from absent_on/off
        absent_on = item.get("absent_on", 0)
        absent_off = item.get("absent_off", 0)
        
        # If explicitly has absent_on > 0, treat as excused.
        # If absent_off > 0, treat as unexcused.
        # If both, technically we should split, but let's prioritize unexcused if mixed? 
        # Or just return total hours and is_excused based on explicable.
        
        hours = absent_on + absent_off
        if hours == 0:
             # Fallback to old 'hour' field if available
             hours = item.get("hour", 2)
        
        # Explicable flag is usually reliable
        is_excused = item.get("explicable", False)
        
        # Double check with absent_on
        if absent_on > 0 and absent_off == 0:
            is_excused = True
        elif absent_off > 0 and absent_on == 0:
            is_excused = False
            
        parsed.append({
            "subject": subj_name,
            "date": date_str,
            "theme": lesson_theme,
            "hours": hours,
            "is_excused": is_excused
        })

    # Calculate Totals Manually
    total_hours = sum(p['hours'] for p in parsed)
    excused_hours = sum(p['hours'] for p in parsed if p['is_excused'])
    unexcused_hours = total_hours - excused_hours
    
    return {
        "success": True, 
        "data": {
            "total": total_hours,
            "excused": excused_hours,
            "unexcused": unexcused_hours,
            "items": parsed
        }
    }

from pydantic import BaseModel
class ResourceSendRequest(BaseModel):
    url: str
    name: str

@router.post("/resources/send")
async def send_resource_to_bot(
    req: ResourceSendRequest,
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_session)
):
    """
    Downloads the file from Hemis and sends it to the user's Telegram.
    """
    if not student.hemis_token:
        return {"success": False, "message": "No Token"}
        
    # Retrieve Telegram Account
    stmt = select(TgAccount).where(TgAccount.student_id == student.id)
    result = await db.execute(stmt)
    tg_account = result.scalar_one_or_none()

    if not tg_account:
        return {"success": False, "message": "Telegram hisob ulanmagan. Iltimos, botga kiring."}
    
    chat_id = tg_account.telegram_id
        
    # Download
    content, filename = await HemisService.download_resource_file(student.hemis_token, req.url)
    
    if not content:
         return {"success": False, "message": "Failed to download file from University server."}
         
    # Send to Telegram
    try:
        from bot import bot
        from aiogram.types import BufferedInputFile
        
        # Use filename from header if available, else user provided name
        final_name = filename if filename and "document" not in filename else req.name
        # Ensure extension
        if "." not in final_name:
             final_name += ".pdf" # Default assumption or we could sniff mime
             
        input_file = BufferedInputFile(content, filename=final_name)
        await bot.send_document(chat_id=student.telegram_id, document=input_file, caption=f"📄 {req.name}")
        
        return {"success": True, "message": "Sent to Telegram!"}
    except Exception as e:
        return {"success": False, "message": f"Bot Error: {str(e)}"}

@router.get("/subject/{subject_id}/details")
async def get_subject_details_endpoint(
    subject_id: str,
    semester: str = None,
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_session)
):
    if not student.hemis_token:
        return {"success": False, "message": "No Token"}
        
    # 1. Get Subject Info (from List)
    subjects = await HemisService.get_student_subject_list(student.hemis_token, semester_code=semester)
    target_subject = next((
        s for s in subjects 
        if str((s.get("curriculumSubject", {}).get("subject", {}) or {}).get("id") or s.get("subject", {}).get("id")) == str(subject_id)
    ), None)
    
    # helper to safely get nested
    def get_nested(d, path):
        keys = path.split(".")
        val = d
        for k in keys:
             if isinstance(val, dict): val = val.get(k, {})
             else: return None
        return val if val != {} else None

    # Re-search with helper if needed or just iterate
    if not target_subject:
        # Fallback search
        for s in subjects:
             sid = get_nested(s, "curriculumSubject.subject.id") or get_nested(s, "subject.id")
             if str(sid) == str(subject_id):
                 target_subject = s
                 break
                 
    subject_info = {}
    if target_subject:
        # Extract load
        curr_subj = target_subject.get("curriculumSubject", {})
        subject_info = {
            "name": get_nested(curr_subj, "subject.name") or get_nested(target_subject, "subject.name"),
            "code": get_nested(curr_subj, "subject.code"),
            "type": get_nested(curr_subj, "subjectType.name"),
            "total_hours": curr_subj.get("total_acload", 0),
            "credits": curr_subj.get("credit", 0)
        }
        
        # Extract Grades (ON / YN)
        # Parse using HemisService helper
        grades_parsed = HemisService.parse_grades_detailed(target_subject)
        subject_info["grades"] = {
            "overall": target_subject.get("overallScore", {}).get("grade", 0),
            "on": grades_parsed["ON"],
            "yn": grades_parsed["YN"]
        }
    else:
        subject_info = {"name": "Fan topilmadi", "total_hours": 0, "grades": {"overall": 0}}

    # 2. Get Teachers (from Schedule)
    # We need to fetch schedule and filter by subject
    schedule = await HemisService.get_student_schedule_cached(student.hemis_token, semester_code=semester, student_id=student.id)
    teachers = set()
    if schedule:
        for item in schedule:
            s_name = get_nested(item, "subject.name")
            # Loose matching by name if ID is missing in schedule (schedule usually has subject dict)
            s_id = get_nested(item, "subject.id")
            
            if str(s_id) == str(subject_id):
                 t_name = get_nested(item, "employee.name")
                 if t_name: teachers.add(t_name)
    
    # 3. Get Absence (List)
    _, _, _, absence_items = await HemisService.get_student_absence(student.hemis_token, semester_code=semester, student_id=student.id)
    
    subject_absence = []
    total_missed = 0
    
    if absence_items:
        for item in absence_items:
             s_id = get_nested(item, "subject.id")
             if str(s_id) == str(subject_id):
                 # Parse details
                 absent_on = item.get("absent_on", 0)
                 absent_off = item.get("absent_off", 0)
                 hours = absent_on + absent_off
                 if hours == 0: hours = item.get("hour", 2)
                 
                 is_excused = item.get("explicable", False)
                 if absent_on > 0 and absent_off == 0: is_excused = True
                 elif absent_off > 0 and absent_on == 0: is_excused = False
                 
                 ts = item.get("lesson_date")
                 from datetime import datetime
                 date_str = ""
                 if ts: date_str = datetime.fromtimestamp(ts).strftime("%d.%m.%Y")
                 
                 type_name = get_nested(item, "trainingType.name") or "Dars"
                 
                 subject_absence.append({
                     "date": date_str,
                     "hours": hours,
                     "is_excused": is_excused,
                     "type": type_name
                 })
                 total_missed += hours

    # Calculate Percent
    percent = 0.0
    total_load = subject_info.get("total_hours", 0)
    if total_load > 0:
        percent = round((total_missed / total_load) * 100, 1)

    return {
        "success": True, 
        "data": {
            "subject": subject_info,
            "teachers": list(teachers),
            "attendance": {
                "total_missed": total_missed,
                "percent": percent,
                "details": subject_absence
            }
        }
    }
