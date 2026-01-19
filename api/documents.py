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
    
    # 3. Handle Reference (Ma'lumotnoma) via Generator
    if "reference" in doc_type or "ma'lumotnoma" in doc_type:
        from services.pdf_service import PdfService
        
        # Prepare Data
        # Ensure we have student data loaded. 
        # get_current_student usually loads basic fields. 
        # Check specific fields like faculty, level.
        # If not present in `student` model, we might use generic text or fetch.
        # Assuming Student model has 'short_name' or similar, we use 'full_name'.
        
        # Prepare Data using correct Student model fields
        pdf_buffer = PdfService.generate_reference_pdf(
            student_name=student.full_name,
            hemis_id=str(student.hemis_id or "---"),
            faculty=student.faculty_name or (student.faculty.name if student.faculty else "Aniqlanmagan"),
            level=student.education_type or "Bakalavr",
            courses=student.level_name or "1-kurs"
        )
        
        file_input = BufferedInputFile(pdf_buffer.read(), filename="malumotnoma.pdf")
        
        caption = (
            "📄 <b>O'qish joyidan ma'lumotnoma</b>\n\n"
            "Sizning so'rovingiz bo'yicha shakllantirildi."
        )
        
        await bot.send_document(chat_id, document=file_input, caption=caption)
        return {"success": True, "message": "Ma'lumotnoma PDF shaklida Telegramga yuborildi"}

    # 4. Handle Transcript (Reyting Daftarchasi)
    if "transcript" in doc_type or "transkript" in doc_type:
        from services.pdf_service import PdfService
        
        # Determine token
        token = student.hemis_token
        if not token:
             return {"success": False, "message": "HEMIS token topilmadi. Iltimos, ilovada qayta kiring."}
        
        # Fetch Subjects
        subjects_data = await HemisService.get_student_subject_list(token=token, student_id=student.id)
        
        # Normalize Data
        clean_subjects = []
        for subj in subjects_data:
            subj_name = subj.get("subject", {}).get("name", "Noma'lum fan")
            
            score_obj = subj.get("overallScore", {})
            grade = score_obj.get("grade", 0) if score_obj else 0
            if grade == 0:
                grade = subj.get("totalPoint", 0)
            
            load = subj.get("credit", 0)
            if load == 0:
                load = subj.get("totalLoad", 0)
            
            clean_subjects.append({
                "name": subj_name,
                "grade": grade,
                "load": load
            })
            
        pdf_buffer = PdfService.generate_transcript_pdf(
            student_name=student.full_name,
            hemis_id=str(student.hemis_id or "---"),
            faculty=student.faculty_name or (student.faculty.name if student.faculty else "Aniqlanmagan"),
            level=student.education_type or "Bakalavr",
            subjects=clean_subjects
        )
        
        file_input = BufferedInputFile(pdf_buffer.read(), filename="transkript.pdf")
        
        caption = (
            "📄 <b>Transkript (Reyting daftarchasi)</b>\n\n"
            f"Jami fanlar: {len(clean_subjects)} ta.\n"
            "Sizning so'rovingiz bo'yicha shakllantirildi."
        )
        
        await bot.send_document(chat_id, document=file_input, caption=caption)
        return {"success": True, "message": "Transkript PDF shaklida Telegramga yuborildi"}

    # 5. Handle Study Sheet (O'quv varaqa)
    if "study" in doc_type or "uquv" in doc_type or "o'quv" in doc_type:
        from services.pdf_service import PdfService
        
        token = student.hemis_token
        if not token:
             return {"success": False, "message": "HEMIS token topilmadi."}
        
        # Fetch Subjects
        subjects_data = await HemisService.get_student_subject_list(token=token, student_id=student.id)
        
        # Normalize
        clean_subjects = []
        for subj in subjects_data:
            clean_subjects.append({
                "name": subj.get("subject", {}).get("name", "Noma'lum"),
                "credit": subj.get("credit", 0),
                "load": subj.get("totalLoad", 0)
            })
            
        pdf_buffer = PdfService.generate_study_sheet_pdf(
            student_name=student.full_name,
            hemis_id=str(student.hemis_id or "---"),
            faculty=student.faculty_name or "Aniqlanmagan",
            level=student.education_type or "Bakalavr",
            semester=student.semester_name or "Joriy",
            subjects=clean_subjects
        )
        
        file_input = BufferedInputFile(pdf_buffer.read(), filename="oquv_varaqa.pdf")
        
        caption = (
            "📄 <b>O'quv varaqa (Shaxsiy reja)</b>\n\n"
            f"Fanlar soni: {len(clean_subjects)} ta.\n"
            "Sizning so'rovingiz bo'yicha shakllantirildi."
        )
        
        await bot.send_document(chat_id, document=file_input, caption=caption)
        return {"success": True, "message": "O'quv varaqa PDF yuborildi"}

    # 6. Handle Contract (Fallback to Link)
    doc_name = "Hujjat"
    url_suffix = ""
    
    if "contract" in doc_type or "shartnoma" in doc_type:
        doc_name = "To'lov-kontrakt shartnomasi"
        url_suffix = "/finance/contract"

    try:
        message = (
            f"📄 <b>{doc_name}</b>\n\n"
            f"Hurmatli {student.full_name}, ushbu hujjatni shakllantirish uchun "
            f"quyidagi havolaga o'ting (HEMIS tizimi):\n\n"
            f"🔗 <a href='https://student.jmcu.uz{url_suffix}_pdf'>Yuklab olish (PDF)</a>\n\n"
            f"<i>Izoh: Shartnoma (QR kodli) faqat web-tizim orqali generatsiya qilinadi.</i>"
        )
        
        await bot.send_message(chat_id, message, parse_mode="HTML")
        
        return {"success": True, "message": "Havola Telegramga yuborildi"}
        
    except Exception as e:
        return {"success": False, "message": f"Xatolik: {str(e)}"}
