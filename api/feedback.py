from fastapi import APIRouter, Depends, Form, File, UploadFile, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from sqlalchemy.orm import selectinload
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime

from api.dependencies import get_current_student, get_db
from api.schemas import FeedbackListSchema
from database.models import Student, StudentFeedback, FeedbackReply
from bot import bot

router = APIRouter()

class MessageSchema(BaseModel):
    id: int
    sender: str # 'me', 'staff', 'system'
    text: Optional[str]
    time: str
    file_id: Optional[str]

class FeedbackDetailSchema(BaseModel):
    id: int
    title: str
    recipient: str
    status: str
    date: str
    is_anonymous: bool
    messages: List[MessageSchema]

@router.get("/", response_model=List[FeedbackListSchema])
async def get_my_feedback(
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_db)
):
    """List all feedback/appeals sent by the student."""
    feedbacks = await db.scalars(
        select(StudentFeedback)
        .where(
            StudentFeedback.student_id == student.id,
            StudentFeedback.parent_id == None # Only root appeals
        )
        .order_by(desc(StudentFeedback.id))
    )
    return feedbacks.all()

@router.get("/{id}", response_model=FeedbackDetailSchema)
async def get_feedback_detail(
    id: int,
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_db)
):
    """
    Get detailed conversation thread.
    Includes:
    - The Main Appeal (Student)
    - Staff Replies (FeedbackReply)
    - Student Follow-up Replies (Child StudentFeedback)
    """
    # Load separate queries for better control or specific loading
    # 1. Fetch Root
    stmt = (
        select(StudentFeedback)
        .where(StudentFeedback.id == id, StudentFeedback.student_id == student.id)
        .options(selectinload(StudentFeedback.replies), selectinload(StudentFeedback.children))
    )
    appeal = await db.scalar(stmt)
    
    if not appeal:
        raise HTTPException(status_code=404, detail="Appeal not found")

    messages = []
    
    # 1. Root Message (Me)
    messages.append({
        "id": appeal.id,
        "sender": "me",
        "text": appeal.text,
        "time": appeal.created_at.strftime("%H:%M"),
        "timestamp": appeal.created_at,
        "file_id": appeal.file_id
    })
    
    # 2. Staff Replies
    for reply in appeal.replies:
        messages.append({
            "id": reply.id,
            "sender": "staff",
            "text": reply.text or "[Fayl]",
            "time": reply.created_at.strftime("%H:%M"),
            "timestamp": reply.created_at,
            "file_id": reply.file_id
        })
        
    # 3. Student Follow-ups (Children) - Recursive logic might be needed for deep nesting, 
    # but initially assuming 1 level of depth or just linear list.
    # For MVP, let's just show direct children.
    # PRO-TIP: We should fetch all descendants if needed, but 'children' gives direct ones.
    # If the bot structure flat-links replies to root, this works.
    
    for child in appeal.children:
         messages.append({
            "id": child.id,
            "sender": "me",
            "text": child.text,
            "time": child.created_at.strftime("%H:%M"),
            "timestamp": child.created_at,
            "file_id": child.file_id
        })

    # Sort by time
    messages.sort(key=lambda x: x['timestamp'])

    return {
        "id": appeal.id,
        "title": f"Murojaat #{appeal.id}", # Or derive from text
        "recipient": appeal.assigned_role or "General",
        "status": appeal.status,
        "date": appeal.created_at.strftime("%d.%m.%Y"),
        "is_anonymous": appeal.is_anonymous,
        "messages": [MessageSchema(**m) for m in messages]
    }

@router.post("/")
async def create_feedback(
    text: str = Form(...),
    role: str = Form("dekanat"), 
    is_anonymous: bool = Form(False),
    file: UploadFile = File(None),
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_db)
):
    """
    Send feedback/appeal to specific staff role.
    """
    
    feedback = StudentFeedback(
        student_id=student.id,
        text=text,
        assigned_role=role,
        is_anonymous=is_anonymous,
        status="pending"
    )
    
    if file:
        try:
             DUMP_CHANNEL_ID = -1002952642487
             content = await file.read()
             from aiogram.types import BufferedInputFile
             input_file = BufferedInputFile(content, filename=file.filename)
             
             caption = f"Murojaat ({role}): {student.full_name}" if not is_anonymous else f"Murojaat ({role}): ANONIM"
             msg = await bot.send_document(chat_id=DUMP_CHANNEL_ID, document=input_file, caption=caption)
             feedback.file_id = msg.document.file_id
             feedback.file_type = "document"
             
        except Exception as e:
            print(f"Feedback Upload Error: {e}")
            
    db.add(feedback)
    await db.commit()
    return {"status": "success", "id": feedback.id}

@router.post("/{id}/reply")
async def reply_feedback(
    id: int,
    text: str = Form(...),
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_db)
):
    """
    Reply to an existing feedback thread.
    Creates a new StudentFeedback with parent_id = id.
    """
    # Verify parent exists and belongs to student
    parent = await db.scalar(select(StudentFeedback).where(StudentFeedback.id == id, StudentFeedback.student_id == student.id))
    if not parent:
         raise HTTPException(status_code=404, detail="Appeal not found")
         
    reply = StudentFeedback(
        student_id=student.id,
        text=text,
        assigned_role=parent.assigned_role,
        is_anonymous=parent.is_anonymous,
        status="pending",
        parent_id=parent.id # Link to parent
    )
    
    db.add(reply)
    await db.commit()
    
    return {"status": "success", "id": reply.id}
