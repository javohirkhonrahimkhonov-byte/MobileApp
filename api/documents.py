from fastapi import APIRouter, Depends, Form, File, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime

from api.dependencies import get_current_student, get_db
from database.models import Student, UserDocument
from bot import bot

router = APIRouter()

# Schema for Personal Documents (Uploaded)
class UserDocumentSchema(BaseModel):
    id: int
    category: str
    title: str
    file_id: str
    status: str
    created_at: datetime
    
    class Config:
        from_attributes = True

# Schema for HEMIS Documents (Static/Mock)
class HemisDocumentSchema(BaseModel):
    id: str
    title: str
    type: str # 'reference', 'transcript', etc
    available: bool

class DocumentsResponse(BaseModel):
    hemis_docs: List[HemisDocumentSchema]
    personal_docs: List[UserDocumentSchema]


@router.get("/", response_model=DocumentsResponse)
async def get_documents(
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_db)
):
    """
    Get all documents (HEMIS and Personal).
    """
    
    # 1. HEMIS Docs (Static for now, simulates available types)
    hemis_docs = [
        HemisDocumentSchema(id="ref_edu", title="O'qish joyidan ma'lumotnoma", type="reference", available=True),
        HemisDocumentSchema(id="rating_book", title="Reyting daftarchasi", type="transcript", available=True),
        HemisDocumentSchema(id="orders", title="Buyruqlar ko'chirmasi", type="order", available=True),
        HemisDocumentSchema(id="contract", title="Shartnoma", type="contract", available=True),
    ]
    
    # 2. Personal Docs (From DB)
    personal_docs_db = await db.scalars(
        select(UserDocument)
        .where(UserDocument.student_id == student.id)
        .order_by(desc(UserDocument.id))
    )
    personal_docs = personal_docs_db.all()
    
    return DocumentsResponse(
        hemis_docs=hemis_docs,
        personal_docs=[UserDocumentSchema.from_orm(d) for d in personal_docs]
    )

@router.post("/upload")
async def upload_personal_document(
    title: str = Form(...),
    category: str = Form("Boshqa"), # Passport, ID Card, etc.
    file: UploadFile = File(...),
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_db)
):
    """
    Upload a personal document (e.g. Passport copy).
    """
    DUMP_CHANNEL_ID = -1002952642487
    
    file_id = ""
    try:
        content = await file.read()
        from aiogram.types import BufferedInputFile
        input_file = BufferedInputFile(content, filename=file.filename)
        
        caption = f"Document: {title} ({category})\nStudent: {student.full_name}"
        msg = await bot.send_document(chat_id=DUMP_CHANNEL_ID, document=input_file, caption=caption)
        file_id = msg.document.file_id
        
    except Exception as e:
        print(f"Upload Error: {e}")
        return {"status": "error", "message": "Fayl yuklashda xatolik"}

    doc = UserDocument(
        student_id=student.id,
        category=category,
        title=title,
        file_id=file_id,
        status="active" # No approval needed for personal docs usually
    )
    db.add(doc)
    await db.commit()
    await db.refresh(doc)
    
    return {"status": "success", "id": doc.id, "file_id": file_id}
