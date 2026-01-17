from fastapi import APIRouter, Depends, Form, File, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from typing import List
from pydantic import BaseModel
from datetime import datetime

from api.dependencies import get_current_student, get_db
from database.models import Student, UserCertificate
from bot import bot

router = APIRouter()

class CertificateSchema(BaseModel):
    id: int
    title: str
    file_id: str
    created_at: datetime
    
    class Config:
        from_attributes = True

@router.get("/", response_model=List[CertificateSchema])
async def get_my_certificates(
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_db)
):
    """List all certificates."""
    certs = await db.scalars(
        select(UserCertificate)
        .where(UserCertificate.student_id == student.id)
        .order_by(desc(UserCertificate.id))
    )
    return certs.all()

@router.post("/")
async def upload_certificate(
    title: str = Form(...),
    file: UploadFile = File(...),
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_db)
):
    """
    Upload a certificate.
    Files are uploaded to a Telegram Dump Channel to get a file_id.
    """
    
    # 1. Upload to Telegram to get file_id
    # Using a dedicated dump channel or the bot's private storage
    DUMP_CHANNEL_ID = -1002952642487 # Replace with config value later
    
    file_id = ""
    try:
        content = await file.read()
        from aiogram.types import BufferedInputFile
        input_file = BufferedInputFile(content, filename=file.filename)
        
        caption = f"Certificate: {title}\nStudent: {student.full_name} ({student.hemis_id})"
        msg = await bot.send_document(chat_id=DUMP_CHANNEL_ID, document=input_file, caption=caption)
        file_id = msg.document.file_id
        
    except Exception as e:
        # Fallback or Error
        print(f"Telegram Upload Error: {e}")
        # In MVP, we might want to proceed or error out. 
        # For now, let's error if we can't save the file.
        return {"status": "error", "message": "Faylni saqlashda xatolik"}

    # 2. Save to DB
    cert = UserCertificate(
        student_id=student.id,
        title=title,
        file_id=file_id
    )
    db.add(cert)
    await db.commit()
    await db.refresh(cert)
    
    return {"status": "success", "id": cert.id, "file_id": file_id}
