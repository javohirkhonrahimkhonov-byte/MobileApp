from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from database.models import Student, TgAccount
from database.db_connect import get_session
from api.dependencies import get_current_student
from services.hemis_service import HemisService
from bot import bot
from aiogram.types import BufferedInputFile

router = APIRouter(prefix="/documents", tags=["documents"])

class DocumentRequest(BaseModel):
    type: str # 'reference', 'transcript', 'contract'

@router.post("/send")
async def send_document(
    req: DocumentRequest,
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_session)
):
    # 1. Check Telegram Link
    # Explicitly query TgAccount to avoid MissingGreenlet on lazy load
    stmt = select(TgAccount).where(TgAccount.student_id == student.id)
    result = await db.execute(stmt)
    tg_account = result.scalars().first()
        
    if not tg_account:
         return {"success": False, "message": "Botga ulanmagansiz. Avval botga kiring."}
    
    chat_id = tg_account.telegram_id

    # 2. Identify Document
    doc_type = req.type.lower()
    doc_name = "Hujjat"
    url_suffix = ""
    
    if "reference" in doc_type or "ma'lumotnoma" in doc_type:
        doc_name = "O'qish joyidan ma'lumotnoma"
        url_suffix = "/student/reference"
    elif "transcript" in doc_type or "transkript" in doc_type:
        doc_name = "Transkript (Reyting daftarchasi)"
        url_suffix = "/education/transcript" # Or /student/transcript
    elif "contract" in doc_type or "shartnoma" in doc_type:
        doc_name = "To'lov-kontrakt shartnomasi"
        url_suffix = "/finance/contract"

    try:
        # 3. Simulate Fetch (Since Real PDF Gen API is hidden/protected or 404)
        # We try to get content. Use HemisService to fetch.
        # Check if we can get a real file.
        
        # NOTE: Since actual PDF endpoints are elusive (404), 
        # we will send a helpful message with a direct link for now.
        # If we had the PDF bytes, we would use:
        # file_bytes = await HemisService.download_file(...)
        # if file_bytes:
        #    await bot.send_document(chat_id, BufferedInputFile(file_bytes, filename=...))
        
        message = (
            f"📄 <b>{doc_name}</b>\n\n"
            f"Hurmatli {student.full_name}, ushbu hujjatni shakllantirish uchun "
            f"quyidagi havolaga o'ting (HEMIS tizimi):\n\n"
            f"🔗 <a href='https://student.jmcu.uz{url_suffix}'>Yuklab olish (HEMIS)</a>\n\n"
            f"<i>Izoh: Mobil ilova orqali to'g'ridan-to'g'ri PDF olish hozircha cheklangan.</i>"
        )
        
        await bot.send_message(chat_id, message, parse_mode="HTML")
        
        return {"success": True, "message": "Telegramga yuborildi"}
        
    except Exception as e:
        return {"success": False, "message": f"Xatolik: {str(e)}"}
