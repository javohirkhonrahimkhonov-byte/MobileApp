from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete

from services.ai_service import generate_response
from database.models import Student, AiMessage
from database.db_connect import get_session
from api.dependencies import get_current_student

router = APIRouter(prefix="/ai", tags=["ai"])

class ChatRequest(BaseModel):
    message: str

@router.get("/history")
async def get_chat_history(
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_session)
):
    """
    Get chat history for current student.
    """
    stmt = select(AiMessage).where(AiMessage.student_id == student.id).order_by(AiMessage.created_at)
    result = await db.execute(stmt)
    messages = result.scalars().all()
    
    return {
        "success": True, 
        "data": [
            {"role": m.role, "content": m.content, "created_at": m.created_at.isoformat()} 
            for m in messages
        ]
    }

@router.delete("/history")
async def clear_chat_history(
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_session)
):
    """
    Clear all chat history.
    """
    stmt = delete(AiMessage).where(AiMessage.student_id == student.id)
    await db.execute(stmt)
    await db.commit()
    
    return {"success": True, "message": "Tarix tozalandi"}

@router.post("/chat")
async def chat_with_ai(
    req: ChatRequest,
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_session)
):
    """
    AI Chat endpoint with persistence.
    """
    if not req.message:
        return {"success": False, "message": "Bo'sh xabar"}
        
    # 1. Save User Message
    user_msg = AiMessage(student_id=student.id, role="user", content=req.message)
    db.add(user_msg)
    await db.commit()
        
    # 2. Generate Response
    response_text = await generate_response(req.message)
    
    # 3. Save AI Response
    ai_msg = AiMessage(student_id=student.id, role="assistant", content=response_text)
    db.add(ai_msg)
    await db.commit()
    
    return {"success": True, "data": response_text}
