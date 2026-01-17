from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from api.dependencies import get_current_student, get_db
from api.schemas import StudentDashboardSchema
from database.models import Student, UserActivity, ClubMembership

router = APIRouter()

@router.get("/", response_model=StudentDashboardSchema)
async def get_dashboard_stats(
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_db)
):
    """
    Get statistics for the student dashboard.
    GPA is hardcoded (simulate HEMIS fetch) or stored in DB.
    """
    
    # 1. Activities Count
    activities_count = await db.scalar(
        select(func.count(UserActivity.id))
        .where(UserActivity.student_id == student.id)
    ) or 0
    
    # 2. Approved Activities Count
    approved_count = await db.scalar(
        select(func.count(UserActivity.id))
        .where(
            UserActivity.student_id == student.id, 
            UserActivity.status == 'approved'
        )
    ) or 0
    
    # 3. Clubs Count
    clubs_count = await db.scalar(
        select(func.count(ClubMembership.id))
        .where(ClubMembership.student_id == student.id)
    ) or 0
    
    # 4. GPA (Mock or Fetch)
    # 4. GPA & Absence (Fetch from HEMIS if token exists)
    from services.hemis_service import HemisService
    
    gpa = 0.0
    missed_total = 0
    missed_excused = 0
    missed_unexcused = 0
    
    if student.hemis_token:
        try:
             # Fetch Real Data
             # 1. Get Current Semester Code
             me_data = await HemisService.get_me(student.hemis_token)
             current_sem = None
             if me_data and "semester" in me_data:
                 current_sem = me_data["semester"].get("code") or me_data["semester"].get("id")
             
             # 2. Get GPA & Absence for Current Semester
             gpa = await HemisService.get_student_performance(student.hemis_token, semester_code=current_sem)
             
             total, excused, unexcused, _ = await HemisService.get_student_absence(
                 student.hemis_token, 
                 semester_code=current_sem,
                 student_id=student.id
             )
             missed_total = total
             missed_excused = excused
             missed_unexcused = unexcused
             
             # Cache in DB (Optional, but good for profile view fallback)
             # student.missed_hours = missed_total 
             # await db.commit()
             
        except Exception as e:
            # Fallback to DB or Just Zeros (No Mock Data)
            print(f"Stats fetch error (Real Data Only): {e}")
            missed_total = 0
            missed_excused = 0
            missed_unexcused = 0
            gpa = 0.0
    
    return StudentDashboardSchema(
        gpa=gpa,
        missed_hours=missed_total,
        missed_hours_excused=missed_excused,
        missed_hours_unexcused=missed_unexcused,
        activities_count=activities_count,
        clubs_count=clubs_count,
        activities_approved_count=approved_count
    )
