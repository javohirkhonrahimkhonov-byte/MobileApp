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

from fastapi import UploadFile, File, Request
import shutil
import time
import os

@router.post("/image")
async def upload_profile_image(
    request: Request,
    file: UploadFile = File(...),
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_db)
):
    """
    Upload and set a custom profile image for the student.
    """
    try:
        # Validate Image
        if not file.content_type.startswith("image/"):
             return {"success": False, "message": "Faqat rasm yuklash mumkin"}
             
        # Create Filename
        ext = file.filename.split(".")[-1]
        filename = f"{student.id}_{int(time.time())}.{ext}"
        file_path = f"static/uploads/{filename}"
        
        # Save File
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        # Build URL
        # e.g. https://api.example.com/static/uploads/123.jpg
        base_url = str(request.base_url).rstrip("/")
        full_url = f"{base_url}/{file_path}"
        
        # Update DB
        student.image_url = full_url
        await db.commit()
        
        return {
            "success": True,
            "data": {
                "image_url": full_url
            }
        }
    except Exception as e:
        return {"success": False, "message": f"Server xatosi: {str(e)}"}
