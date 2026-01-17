from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from services.hemis_service import HemisService
from database.db_connect import get_session
from api.dependencies import get_current_student
from database.models import Student

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
         
    subjects = await HemisService.get_student_subject_list(student.hemis_token)
    
    parsed_data = []
    
    for item in subjects:
        subj_name = "Fan"
        if "curriculumSubject" in item:
             subj_name = item.get("curriculumSubject", {}).get("subject", {}).get("name", "Fan")
        else:
             subj_name = item.get("subject", {}).get("name", "Fan")
             
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
    Returns enriched subject list with teachers, absences, and grades.
    """
    if not student.hemis_token:
         return {"success": False, "message": "No Token", "data": []}

    # 1. Fetch concurrent data (Same as Bot)
    import asyncio
    subjects_data, attendance_result, schedule_data = await asyncio.gather(
        HemisService.get_student_subject_list(student.hemis_token, student_id=student.id),
        HemisService.get_student_absence(student.hemis_token, student_id=student.id),
        HemisService.get_student_schedule_cached(student.hemis_token, student_id=student.id)
    )

    # 2. Process Attendance Map
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
                teacher_map[s_name_lower] = {"Ma'ruza": set(), "Seminar": set(), "Boshqa": set()}
            if "ma'ruza" in train_type.lower() or "lecture" in train_type.lower():
                teacher_map[s_name_lower]["Ma'ruza"].add(t_name)
            elif "seminar" in train_type.lower() or "amaliy" in train_type.lower():
                teacher_map[s_name_lower]["Seminar"].add(t_name)
            else:
                teacher_map[s_name_lower]["Boshqa"].add(t_name)

    # 4. Build Enriched Response
    result = []
    for item in subjects_data:
        sub_details = item.get("curriculumSubject", {}).get("subject", {})
        if not sub_details: sub_details = item.get("subject", {})
        
        name = sub_details.get("name", "Nomsiz fan")
        s_id = sub_details.get("id")
        name_lower = name.lower().strip()
        
        # Teachers
        teachers = []
        t_data = teacher_map.get(name_lower)
        if t_data:
            if t_data["Ma'ruza"]: teachers.append({"role": "Ma'ruza", "names": list(t_data["Ma'ruza"])})
            if t_data["Seminar"]: teachers.append({"role": "Seminar", "names": list(t_data["Seminar"])})
            if t_data["Boshqa"] and not (t_data["Ma'ruza"] or t_data["Seminar"]):
                 teachers.append({"role": "O'qituvchi", "names": list(t_data["Boshqa"])})

        # Absences
        absent_hours = abs_map.get(name_lower, 0)
        
        # Grades
        grades = HemisService.parse_grades_detailed(item)
        
        result.append({
            "id": s_id,
            "name": name,
            "teachers": teachers,
            "absent_hours": absent_hours,
            "grades": grades
        })

    return {"success": True, "data": result}

@router.get("/resources")
async def get_resources(
    subject_id: str,
    student: Student = Depends(get_current_student)
):
    """
    Returns resources for a subject, grouped by topic.
    """
    if not student.hemis_token:
         return {"success": False, "message": "No Token", "data": []}

    resources = await HemisService.get_student_resources(student.hemis_token, subject_id=subject_id)
    
    result = []
    for res in resources:
        title = (res.get("title") or "Mavzu nomi yo'q").strip()
        items = res.get("subjectFileResourceItems", [])
        
        files = []
        for item in items:
            for f in item.get("files", []):
                if f.get("url"):
                    files.append({
                        "id": item.get("id"),
                        "name": f.get("name"),
                        "url": f.get("url"),
                        "ext": f.get("name", "").split(".")[-1].lower() if "." in f.get("name", "") else "file"
                    })
        
        if files:
            result.append({
                "id": res.get("id"),
                "title": title,
                "files": files
            })
            
    return {"success": True, "data": result}
