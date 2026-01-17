from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from api.dependencies import get_current_student, get_db
from api.schemas import StudentProfileSchema
from database.models import Student, TgAccount
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter()

@router.get("/me")
@router.get("/me/")
async def get_my_profile(
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_db)
):
    """Get the currently logged-in student's profile."""
    # Ensure consistency with auth.py
    data = StudentProfileSchema.model_validate(student).model_dump()
    # Explicitly ensure short_name/first_name is passed if stored
    data['first_name'] = student.short_name
    data['university_name'] = student.university_name
    
    data['university_name'] = student.university_name

    # Check Telegram Registration
    tg_acc = await db.scalar(select(TgAccount).where(TgAccount.student_id == student.id))
    data['is_registered_bot'] = True if tg_acc else False
    
    return data
