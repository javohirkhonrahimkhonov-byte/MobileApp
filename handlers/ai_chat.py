
import os
import logging
from aiogram import Router, F, Bot
from aiogram.types import CallbackQuery, InlineKeyboardMarkup, InlineKeyboardButton, Message, FSInputFile
from aiogram.fsm.context import FSMContext
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from database.models import TgAccount, StaffRole, Staff, Student
from services.ai_service import generate_answer_by_key, summarize_konspekt
from utils.document_parser import extract_text_from_file
from models.states import AIStates

router = Router()
logger = logging.getLogger(__name__)

# ============================================================
# 1. AI BOSHMENYU (Role bo'yicha)
# ============================================================
@router.callback_query(F.data == "ai_assistant_main")
async def cb_ai_main(call: CallbackQuery, session: AsyncSession, state: FSMContext):
    await state.clear() # Reset any previous states
    
    tg_id = call.from_user.id
    acc = await session.scalar(select(TgAccount).where(TgAccount.telegram_id == tg_id))
    
    if not acc:
        return await call.answer("Hisob topilmadi", show_alert=True)
        
    role = acc.current_role
    
    # Back button logic
    back_cb = "go_home"
    if role == "student":
        back_cb = "go_student_home"
    elif role == StaffRole.OWNER.value:
        back_cb = "owner_menu"
    elif role == StaffRole.RAHBARIYAT.value:
        back_cb = "rahb_menu"
    elif role == StaffRole.DEKANAT.value:
        back_cb = "dek_menu"
    elif role == StaffRole.TYUTOR.value:
        back_cb = "tutor_menu"
    elif role == StaffRole.YOSHLAR_YETAKCHISI.value:
        back_cb = "yetakchi_broadcast_menu" # Fallback, usually they have their own menu
        
    keyboard_rows = []
    
    # ------------------ STUDENT PROMPTS ------------------
    if role == "student" or role == StaffRole.KLUB_RAHBARI.value:
        keyboard_rows.append([InlineKeyboardButton(text="💰 Stipendiya haqida", callback_data="ai_ask:scholarship")])
        keyboard_rows.append([InlineKeyboardButton(text="🔑 Hemis parolini tiklash", callback_data="ai_ask:hemis_reset")])
        keyboard_rows.append([InlineKeyboardButton(text="📏 Kredit-modul tizimi", callback_data="ai_ask:credit_system")])
        keyboard_rows.append([InlineKeyboardButton(text="📅 Dars jadvali", callback_data="ai_ask:schedule_info")])
        # KONSPEKT
        keyboard_rows.append([InlineKeyboardButton(text="📝 Konspekt qilish (File/Matn)", callback_data="ai_konspekt_start")])
        
    # ------------------ TYUTOR PROMPTS ------------------
    elif role == StaffRole.TYUTOR.value:
        keyboard_rows.append([InlineKeyboardButton(text="🧠 Psixologik yondashuv", callback_data="ai_ask:student_psychology")])
        keyboard_rows.append([InlineKeyboardButton(text="📋 Faollikni baholash", callback_data="ai_ask:activity_grading")])
        # Common staff prompts
        keyboard_rows.append([InlineKeyboardButton(text="📝 Mehnat ta'tili", callback_data="ai_ask:labor_laws")])
        keyboard_rows.append([InlineKeyboardButton(text="💼 KPI tizimi", callback_data="ai_ask:kpi_system")])

    # ------------------ STAFF (Rahbariyat/Dekanat/Owner) PROMPTS ------------------
    else:
        keyboard_rows.append([InlineKeyboardButton(text="📝 Mehnat ta'tili qoidalari", callback_data="ai_ask:labor_laws")])
        keyboard_rows.append([InlineKeyboardButton(text="💼 KPI tizimi", callback_data="ai_ask:kpi_system")])

    # Footer
    keyboard_rows.append([InlineKeyboardButton(text="💬 AI bilan suhbat", callback_data="ai_start_free_chat")]) # NEW
    keyboard_rows.append([InlineKeyboardButton(text="⬅️ Ortga", callback_data=back_cb)])
    
    await call.message.edit_text(
        "🤖 <b>AI Yordamchi</b>\n\n"
        "Sizga qanday yordam bera olaman? Quyidagi mavzulardan birini tanlang:",
        reply_markup=InlineKeyboardMarkup(inline_keyboard=keyboard_rows),
        parse_mode="HTML"
    )
    await call.answer()


# ============================================================
# 2. SAVOL-JAVOB TUGMALARI (Tez orada...)
# ============================================================
@router.callback_query(F.data.startswith("ai_ask:"))
async def cb_ai_ask(call: CallbackQuery):
    # topic_key = call.data.split(":")[1]
    
    # User request: "Bular ishga tushmagunicha tez orada deb tursin"
    await call.answer("🛠 Bu bo'lim tez orada ishga tushadi!", show_alert=True)
    
    # OLD LOGIC (Disabled for now)
    # await call.message.edit_text("🤖 <i>AI javob tayyorlamoqda...</i>", parse_mode="HTML")
    # answer = await generate_answer_by_key(topic_key)
    # await call.message.edit_text(f"🤖 <b>AI Javobi:</b>\n\n{answer}", ...)


# ============================================================
# 3. ERKIN SUHBAT (Free Chat)
# ============================================================
@router.callback_query(F.data == "ai_start_free_chat")
async def cb_start_free_chat(call: CallbackQuery, session: AsyncSession, state: FSMContext):
    await state.set_state(AIStates.chatting)
    
    # Get Name
    tg_id = call.from_user.id
    acc = await session.scalar(select(TgAccount).where(TgAccount.telegram_id == tg_id))
    name = "Talaba"
    
    if acc and acc.current_role == "student" and acc.student_id:
        student = await session.get(Student, acc.student_id)
        if student:
            # Name check and auto-fix
            # Force update if name is missing OR generic "Talaba"
            # Note: We can implicitly check if token is valid by trying get_me
            if not student.full_name or student.full_name == "Talaba":
                from services.hemis_service import HemisService
                
                # Check token validity / fetch name
                if student.hemis_token:
                     me_data = await HemisService.get_me(student.hemis_token)
                     
                     # If 401 (None returned or error), try refreshing if password exists
                     if not me_data and student.hemis_login and student.hemis_password:
                         logger.info(f"Token expired for {student.id}, attempting refresh...")
                         new_token, err = await HemisService.authenticate(student.hemis_login, student.hemis_password)
                         if new_token:
                             student.hemis_token = new_token
                             await session.commit()
                             # Retry get_me
                             me_data = await HemisService.get_me(new_token)
                             logger.info("Token refreshed successfully.")
                         else:
                             logger.error(f"Auto-refresh failed for {student.id}: {err}")

                     if me_data:
                         # Construct full name safely
                         f_name_parts = [
                             me_data.get('firstname', ''), 
                             me_data.get('lastname', ''), 
                             me_data.get('fathername', '')
                         ]
                         f_name = " ".join(filter(None, f_name_parts)).strip()
                         
                         if f_name:
                             student.full_name = f_name
                             await session.commit()
            
            if student.full_name:
                parts = student.full_name.split()
                if len(parts) >= 2:
                     name = f"{parts[1]}" if len(parts) > 1 else parts[0]
                else:
                     name = student.full_name

    await call.message.edit_text(
        f"🤖 <b>Salom, {name}!</b>\n\n"
        "Men sizning shaxsiy AI yordamchingizman. Sizga o'qish, baholar va boshqa masalalarda yordam bera olaman.\n\n"
        "Menga istalgan savolingizni yozing 👇",
        reply_markup=InlineKeyboardMarkup(inline_keyboard=[
            [InlineKeyboardButton(text="❌ Suhbatni tugatish", callback_data="ai_assistant_main")]
        ]),
        parse_mode="HTML"
    )
    await call.answer()

from services.ai_service import generate_response

from datetime import datetime, timedelta
from services.context_builder import build_student_context

@router.message(AIStates.chatting)
async def process_chat_message(message: Message, session: AsyncSession, state: FSMContext):
    if not message.text:
        return

    wait_msg = await message.answer("🤔 O'ylayapman...")
    
    # 1. Talaba kontekstini aniqlash
    tg_id = message.from_user.id
    acc = await session.scalar(select(TgAccount).where(TgAccount.telegram_id == tg_id))
    
    prompt_text = message.text
    
    if acc and acc.current_role == "student" and acc.student_id:
        student = await session.get(Student, acc.student_id)
        if student:
            # Context yangilash kerakmi? (Agar yo'q bo'lsa yoki eski bo'lsa)
            # User "tizimga kirishi bilan" dedi, bu yerda "chatga kirishi bilan" deb tushunamiz.
            # Va 24 soatlik limitni tekshiramiz.
            need_update = False
            if not student.ai_context:
                need_update = True
            elif student.last_context_update:
                if datetime.utcnow() - student.last_context_update > timedelta(hours=24):
                    need_update = True
            
            context_str = student.ai_context
            if need_update:
                 # Real-time update (Nightly job also does this, but this is fallback/lazy-load)
                 context_str = await build_student_context(session, student.id)
            
            if context_str:
                # System prompt injection technique
                prompt_text = f"STUDENT_CONTEXT:\n{context_str}\n\nUSER_QUERY:\n{message.text}"

    response = await generate_response(prompt_text)
    
    # 2. Log yozish (Analytics)
    if acc and acc.current_role == "student" and acc.student_id:
        # Student object may be loaded above, if not load it
        if 'student' not in locals() or not student:
            student = await session.get(Student, acc.student_id)
            
        if student:
            from database.models import StudentAILog # Import here to avoid circular or top-level mess
            
            log_entry = StudentAILog(
                student_id=student.id,
                full_name=student.full_name,
                university_name=student.university_name,
                faculty_name=student.faculty_name,
                group_number=student.group_number,
                user_query=message.text, # Original user text, not prompt
                ai_response=response
            )
            session.add(log_entry)
            await session.commit()

    await wait_msg.delete()
    
    await message.answer(
        response,
        parse_mode="Markdown",
        reply_markup=InlineKeyboardMarkup(inline_keyboard=[
            [InlineKeyboardButton(text="❌ Suhbatni tugatish", callback_data="ai_assistant_main")]
        ])
    )


# ============================================================
# 4. KONSPEKT QILISH FUNKSIYASI
# ============================================================
@router.callback_query(F.data == "ai_konspekt_start")
async def cb_konspekt_start(call: CallbackQuery, state: FSMContext):
    await state.set_state(AIStates.waiting_for_konspekt)
    
    msg_text = (
        "📚 <b>Konspekt Yordamchisi</b>\n\n"
        "Men sizga uzun ma'ruza matnlari yoki taqdimotlardan eng muhim joylarini ajratib olishga yordam beraman.\n\n"
        "📎 <b>Nima qilishingiz kerak?</b>\n"
        "Menga <b>Word (DOCX)</b>, <b>PowerPoint (PPTX)</b>, <b>PDF</b> fayl yoki shunchaki <b>uzun matn</b> yuboring.\n\n"
        "Men uni tahlil qilib, daftarga yozish uchun qulay, qisqa va lo'nda <b>konspekt</b> tayyorlab beraman.\n\n"
        "👇 <i>Marhamat, faylni yoki matnni shu yerga tashlang:</i>"
    )
    
    await call.message.edit_text(
        msg_text,
        reply_markup=InlineKeyboardMarkup(inline_keyboard=[
            [InlineKeyboardButton(text="⬅️ Bekor qilish", callback_data="ai_assistant_main")]
        ]),
        parse_mode="HTML"
    )
    await call.answer()


@router.message(AIStates.waiting_for_konspekt)
async def msg_process_konspekt(message: Message, state: FSMContext, bot: Bot):
    
    processing_msg = await message.answer("⏳ <i>Fayl o'qilmoqda va tahlil qilinmoqda...</i>", parse_mode="HTML")
    
    text_content = ""
    
    try:
        # A) Matn yuborilganda
        if message.text:
            text_content = message.text
            
        # B) Fayl yuborilganda (Document)
        elif message.document:
            import io
            from utils.document_parser import extract_text_from_stream
            
            file_id = message.document.file_id
            file_name = message.document.file_name
            
            # Download to Memory
            file_stream = io.BytesIO()
            await bot.download(message.document, destination=file_stream)
            
            # Extract text from stream
            ext = file_name.split(".")[-1]
            text_content = extract_text_from_stream(file_stream, ext)
            
            # No cleanup needed as it's in RAM
                
        else:
            await processing_msg.edit_text("❌ Iltimos, fayl yoki matn yuboring.")
            return

        # Check if text was extracted
        if not text_content or len(text_content.strip()) < 10:
            await processing_msg.edit_text("⚠️ Fayldan matn o'qib bo'lmadi yoki matn juda qisqa.")
            return

        # AI Summary
        await processing_msg.edit_text("🤖 <i>AI konspekt yozmoqda...</i>", parse_mode="HTML")
        summary = await summarize_konspekt(text_content)
        
        # Send result
        # Agar javob juda uzun bo'lsa
        if len(summary) > 4000:
            parts = [summary[i:i+4000] for i in range(0, len(summary), 4000)]
            for part in parts:
                await message.answer(part, parse_mode="Markdown")
        else:
            await message.answer(summary, parse_mode="Markdown")
            
        # Error check
        if summary.startswith("⚠️") or "xatolik" in summary.lower():
            await state.clear()
            return # Don't show success message

        # Finish with options
        await message.answer(
            "✅ Konspekt tayyor!",
            reply_markup=InlineKeyboardMarkup(inline_keyboard=[
                [InlineKeyboardButton(text="🔙 AI menyusiga qaytish", callback_data="ai_assistant_main")]
            ])
        )
        await state.clear()
        
    except Exception as e:
        logger.error(f"Konspekt error: {e}")
        await processing_msg.edit_text("❌ Xatolik yuz berdi. Birozdan so'ng qayta urinib ko'ring.")
        await state.clear()
