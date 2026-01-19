from aiogram import Router, F
from aiogram.types import CallbackQuery, Message, InlineKeyboardMarkup, InlineKeyboardButton
from aiogram.fsm.context import FSMContext
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from database.models import TgAccount, Student, UserDocument
from keyboards.inline_kb import (
    get_student_documents_kb,
    get_student_documents_simple_kb,
    get_document_type_kb,
    get_student_main_menu_kb,
)
from models.states import DocumentAddStates

router = Router()


# ============================================================
# Helper — Student olish
# ============================================================

async def get_student(call_or_msg, session: AsyncSession):
    tg = await session.scalar(
        select(TgAccount).where(TgAccount.telegram_id == call_or_msg.from_user.id)
    )
    if not tg or not tg.student_id:
        return None
    return await session.get(Student, tg.student_id)


# ============================================================
# 📂 Hujjatlar bo‘limi asosiy menyusi
# ============================================================

# ============================================================
# 📂 Hujjatlar bo‘limi (Direct List)
# ============================================================

@router.callback_query(F.data.in_({"student_documents", "student_documents:profile", "student_documents_list"}))
async def student_documents_list(call: CallbackQuery, session: AsyncSession):
    # Determine back button logic
    # If we are in the list, "Back" should go to Main Menu (or Profile if came from there)
    back_to = "go_student_home"
    if "profile" in call.data:
        back_to = "student_profile"

    student = await get_student(call, session)
    if not student:
        await call.answer("Talaba topilmadi!", show_alert=True)
        return

    # 1. User Uploaded Docs
    user_docs = (await session.scalars(
        select(UserDocument).where(UserDocument.student_id == student.id)
    )).all()

    # 2. Build Unified List
    # Static HEMIS Docs (Temporarily Hidden per User Request)
    hemis_docs = []
    # hemis_docs = [
    #     "O'qish joyidan ma'lumotnoma",
    #     "Transkript (Reyting daftarchasi)",
    #     "O'quv varaqa (Shaxsiy reja)",
    #     "To'lov-kontrakt shartnomasi"
    # ]

    text = "📄 <b>Hujjatlar ro‘yxati:</b>\n\n"
    
    # 3. Create Keyboard
    buttons = []
    
    # Add HEMIS Docs (Hidden)
    for idx, name in enumerate(hemis_docs, start=1):
        text += f"{idx}. {name}\n"
        buttons.append(InlineKeyboardButton(text=str(idx), callback_data=f"doc_sel:{idx}"))

    # Add User Docs
    # Start index from 5
    start_user_idx = 5
    if not user_docs:
        text += "\n<i>Sizda shaxsiy hujjatlar yo'q.</i>"
    else:
        text += "\n<b>Mening hujjatlarim:</b>\n"
        for i, doc in enumerate(user_docs):
            real_idx = start_user_idx + i
            text += f"{real_idx}. {doc.category} ({doc.title})\n"
            buttons.append(InlineKeyboardButton(text=str(real_idx), callback_data=f"doc_sel:{real_idx}"))

    # Add "Add Document" button separate row
    kb_rows = [buttons[i:i + 5] for i in range(0, len(buttons), 5)] # Chunk by 5
    kb_rows.append([InlineKeyboardButton(text="➕ Hujjat qo‘shish", callback_data="student_document_add")])
    kb_rows.append([InlineKeyboardButton(text="⬅️ Ortga", callback_data=back_to)])

    try:
        await call.message.edit_text(
            text,
            reply_markup=InlineKeyboardMarkup(inline_keyboard=kb_rows),
            parse_mode="HTML"
        )
    except Exception:
        # If message is identical or something fails, allow delete/re-send
        await call.message.delete()
        await call.message.answer(
            text,
            reply_markup=InlineKeyboardMarkup(inline_keyboard=kb_rows),
            parse_mode="HTML"
        )
    await call.answer()


# ============================================================
# 1.5) HUJJAT TANLASH HANDLERI
# ============================================================

# ============================================================
# 1.5) HUJJAT TANLASH HANDLERI
# ============================================================

# ============================================================
# 1.5) HUJJAT TANLASH HANDLERI
# ============================================================

@router.callback_query(F.data.startswith("doc_sel:"))
async def document_selection_handler(call: CallbackQuery, session: AsyncSession):
    import os
    import time
    from aiogram.types import FSInputFile
    from services.pdf_service import PdfService
    from services.hemis_service import HemisService
    
    # --- TMP CONFIG ---
    TMP_DIR = "/tmp/hemis_docs"
    if not os.path.exists(TMP_DIR):
        os.makedirs(TMP_DIR)

    try:
        selection_idx = int(call.data.split(":")[1])
    except:
        await call.answer("Xatolik!", show_alert=True)
        return

    student = await get_student(call, session)
    if not student:
        await call.answer("Talaba topilmadi!", show_alert=True)
        return

    # Helper to save and send
    async def save_and_send(pdf_buffer, filename_hint):
        safe_name = filename_hint.replace("/", "_").replace("\\", "_")
        tmp_path = os.path.join(TMP_DIR, f"{student.id}_{int(time.time())}_{safe_name}")
        
        # 1. Save to TMP
        with open(tmp_path, "wb") as f:
            f.write(pdf_buffer.read())
            
        # 2. Add to Cleanup List (In a real app, use a queue context or try/finally block)
        # Here we just use try/finally in the block
        return tmp_path

    # ------------------------------------------------------------
    # 1. Ma'lumotnoma
    # ------------------------------------------------------------
    if selection_idx == 1:
        status_msg = await call.message.answer("⏳ <b>Ma'lumotnoma:</b> So'rov qabul qilindi...", parse_mode="HTML")
        try:
            # Generate PDF
            pdf_buffer = PdfService.generate_reference_pdf(
                student_name=student.full_name,
                hemis_id=str(student.hemis_id or "---"),
                faculty=student.faculty_name or (student.faculty.name if student.faculty else "Aniqlanmagan"),
                level=student.education_type or "Bakalavr",
                courses=student.level_name or "1-kurs"
            )
            
            await status_msg.edit_text("📤 <b>Ma'lumotnoma:</b> PDF yuborilmoqda...", parse_mode="HTML")
            
            # Save & Send
            tmp_path = await save_and_send(pdf_buffer, "malumotnoma.pdf")
            try:
                file_input = FSInputFile(tmp_path)
                await call.message.answer_document(
                    document=file_input, 
                    caption="📄 <b>O'qish joyidan ma'lumotnoma</b>\nBot orqali shakllantirildi."
                )
            finally:
                if os.path.exists(tmp_path):
                    os.remove(tmp_path)

            await status_msg.delete()
            
        except Exception as e:
            await status_msg.edit_text(f"❌ <b>Xatolik:</b> PDF yaratishda muammo.\n\n<code>{str(e)}</code>", parse_mode="HTML")
        
        await call.answer()
        return

    # ------------------------------------------------------------
    # 2. Transkript (FIX: Parsing)
    # ------------------------------------------------------------
    elif selection_idx == 2:
        if not student.hemis_token:
            await call.answer("HEMIS token mavjud emas. /start bosing.", show_alert=True)
            return
            
        status_msg = await call.message.answer("⏳ <b>Transkript:</b> HEMIS tizimidan baholar olinmoqda...", parse_mode="HTML")
        try:
            # 1. Fetch Data
            subjects_data = await HemisService.get_student_subject_list(token=student.hemis_token, student_id=student.id)
            
            await status_msg.edit_text(f"⏳ <b>Transkript:</b> {len(subjects_data)} ta fan topildi. PDF shakllantirilmoqda...", parse_mode="HTML")

            # 2. Normalize (FIXED LOGIC)
            clean_subjects = []
            for subj in subjects_data:
                # FIX: Use curriculumSubject -> subject -> name
                cs = subj.get("curriculumSubject", {})
                subj_obj = cs.get("subject", {})
                
                # Name
                subj_name = subj_obj.get("name") 
                if not subj_name:
                    # Fallback to root subject
                    subj_name = subj.get("subject", {}).get("name", "Noma'lum fan")

                # Grade
                score_obj = subj.get("overallScore", {})
                grade = score_obj.get("grade", 0) if score_obj else 0
                if grade == 0: grade = subj.get("totalPoint", 0)
                
                # Credit (Load)
                load = cs.get("credit", 0) # Credits usually in curriculumSubject
                if load == 0: load = cs.get("total_acload", 0)
                if load == 0: load = subj.get("curriculumSubject", {}).get("credit", 0) # Direct check just in case
                
                clean_subjects.append({"name": subj_name, "grade": grade, "load": load})

            # 3. Generate PDF
            pdf_buffer = PdfService.generate_transcript_pdf(
                student_name=student.full_name,
                hemis_id=str(student.hemis_id or "---"),
                faculty=student.faculty_name or "Aniqlanmagan",
                level=student.education_type or "Bakalavr",
                subjects=clean_subjects
            )
            
            await status_msg.edit_text("📤 <b>Transkript:</b> PDF yuborilmoqda...", parse_mode="HTML")
            
            # Save & Send
            tmp_path = await save_and_send(pdf_buffer, "transkript.pdf")
            try:
                file_input = FSInputFile(tmp_path)
                await call.message.answer_document(document=file_input, caption="📄 <b>Transkript (Reyting daftarchasi)</b>")
            finally:
                if os.path.exists(tmp_path):
                    os.remove(tmp_path)

            await status_msg.delete()

        except Exception as e:
            await status_msg.edit_text(f"❌ <b>Xatolik:</b> Transkript olishda muammo.\n\n<code>{str(e)}</code>", parse_mode="HTML")

        await call.answer()
        return

    # ------------------------------------------------------------
    # 3. O'quv varaqa (FIX: Parsing)
    # ------------------------------------------------------------
    elif selection_idx == 3:
        if not student.hemis_token:
            await call.answer("HEMIS token mavjud emas.", show_alert=True)
            return

        status_msg = await call.message.answer("⏳ <b>O'quv varaqa:</b> fanlar yuklanmoqda...", parse_mode="HTML")
        try:
            # 1. Fetch Data
            subjects_data = await HemisService.get_student_subject_list(token=student.hemis_token, student_id=student.id)
            
            await status_msg.edit_text(f"⏳ <b>O'quv varaqa:</b> {len(subjects_data)} ta fan yuklandi. PDF yasalmoqda...", parse_mode="HTML")
            
            clean_subjects = []
            for subj in subjects_data:
                # FIX: Use curriculumSubject
                cs = subj.get("curriculumSubject", {})
                subj_obj = cs.get("subject", {})
                
                subj_name = subj_obj.get("name") 
                if not subj_name:
                    subj_name = subj.get("subject", {}).get("name", "Noma'lum fan")

                credit = cs.get("credit", 0)
                load = cs.get("total_acload", 0) # total_acload often implies hours/load

                clean_subjects.append({
                    "name": subj_name,
                    "credit": credit,
                    "load": load
                })

            pdf_buffer = PdfService.generate_study_sheet_pdf(
                student_name=student.full_name,
                hemis_id=str(student.hemis_id or "---"),
                faculty=student.faculty_name or "Aniqlanmagan",
                level=student.education_type or "Bakalavr",
                semester=student.semester_name or "Joriy",
                subjects=clean_subjects
            )
            
            await status_msg.edit_text("📤 <b>O'quv varaqa:</b> PDF yuborilmoqda...", parse_mode="HTML")
            
            # Save & Send
            tmp_path = await save_and_send(pdf_buffer, "oquv_varaqa.pdf")
            try:
                file_input = FSInputFile(tmp_path)
                await call.message.answer_document(document=file_input, caption="📄 <b>O'quv varaqa (Shaxsiy reja)</b>")
            finally:
                if os.path.exists(tmp_path):
                    os.remove(tmp_path)

            await status_msg.delete()
            
        except Exception as e:
            await status_msg.edit_text(f"❌ <b>Xatolik:</b> O'quv varaqasini olishda muammo.\n\n<code>{str(e)}</code>", parse_mode="HTML")

        await call.answer()
        return
        
    # ------------------------------------------------------------
    # 4. Shartnoma
    # ------------------------------------------------------------
    elif selection_idx == 4:
        url = "https://student.jmcu.uz/finance/contract_pdf"
        await call.message.answer(
            f"📄 <b>To'lov-kontrakt shartnomasi</b>\n\n"
            f"Ushbu hujjatni faqat HEMIS tizimidan yuklab olish mumkin:\n"
            f"🔗 <a href='{url}'>Yuklab olish (PDF)</a>",
            parse_mode="HTML",
            disable_web_page_preview=True
        )
        await call.answer()
        return

    # ------------------------------------------------------------
    # 5+. User Documents
    # ------------------------------------------------------------
    status_msg = await call.message.answer("⏳ Hujjat qidirilmoqda...")
    try:
        start_user_idx = 5
        user_docs = (await session.scalars(
            select(UserDocument).where(UserDocument.student_id == student.id)
        )).all()

        if not user_docs:
            await status_msg.edit_text("❌ Sizda shaxsiy hujjatlar topilmadi.")
            return

        array_idx = selection_idx - start_user_idx
        if 0 <= array_idx < len(user_docs):
            doc = user_docs[array_idx]
            caption = f"📄 <b>{doc.title}</b>\nKategoriya: {doc.category}"
            
            await status_msg.edit_text(f"📤 <b>{doc.title}</b> yuborilmoqda...", parse_mode="HTML")
            
            if doc.file_type == "photo":
                await call.message.answer_photo(doc.file_id, caption=caption, parse_mode="HTML")
            else:
                await call.message.answer_document(doc.file_id, caption=caption, parse_mode="HTML")
            
            await status_msg.delete()
        else:
            await status_msg.edit_text("❌ Noto'g'ri hujjat raqami.")
            
    except Exception as e:
         await status_msg.edit_text(f"❌ Xatolik: {str(e)}")
    
    await call.answer()


# ============================================================
# 2) HUJJAT QO‘SHISH – BOSHLANISHI
# ============================================================

@router.callback_query(F.data == "student_document_add")
async def student_document_add(call: CallbackQuery, state: FSMContext):
    await state.set_state(DocumentAddStates.CATEGORY)
    await call.message.edit_text(
        "🗂 Hujjat turini tanlang:",
        reply_markup=get_document_type_kb(),
    )
    await call.answer()


# ============================================================
# 3) HUJJAT KATEGORIYASINI TANLASH
# ============================================================

@router.callback_query(DocumentAddStates.CATEGORY, F.data.startswith("doc_type_"))
async def document_type_selected(call: CallbackQuery, state: FSMContext):
    category = call.data.replace("doc_type_", "")
    await state.update_data(category=category)

    await state.set_state(DocumentAddStates.FILE)

    try:
        await call.message.edit_text(
            f"Tanlangan hujjat turi: <b>{category}</b>\n\n"
            "📎 <b>Hujjat faylini yuboring (PDF, Word, Rasm).</b>",
            parse_mode="HTML"
        )
    except Exception:
        pass
    await call.answer()


# ============================================================
# 4) FAYL QABUL QILISH + TASDIQLASH
# ============================================================

@router.message(DocumentAddStates.FILE)
async def document_file(message: Message, state: FSMContext, session: AsyncSession):

    student = await get_student(message, session)
    if not student:
        await message.answer("❌ Talaba topilmadi.")
        await state.clear()
        return

    file_id = None
    file_type = None

    if message.document:
        file_id = message.document.file_id
        file_type = "document"
    elif message.photo:
        file_id = message.photo[-1].file_id
        file_type = "photo"
    elif message.video:
        file_id = message.video.file_id
        file_type = "video"
    else:
        await message.answer("❌ Iltimos, istalgan fayl yuboring (PDF, JPG, DOC).")
        return

    await state.update_data(file_id=file_id, file_type=file_type)

    kb = InlineKeyboardMarkup(
        inline_keyboard=[
            [InlineKeyboardButton(text="✅ Saqlash", callback_data="save_document")],
            [InlineKeyboardButton(text="❌ Bekor qilish", callback_data="cancel_document")],
        ]
    )

    await message.answer(
        "📑 Hujjat qabul qilindi.\n"
        "Saqlashni tasdiqlang yoki bekor qiling.",
        reply_markup=kb,
    )


# ============================================================
# 5) HUJJATNI SAQLASH (asosiy xotiraga)
# ============================================================

@router.callback_query(F.data == "save_document")
async def save_document(call: CallbackQuery, state: FSMContext, session: AsyncSession):

    data = await state.get_data()
    student = await get_student(call, session)

    if not student:
        await call.answer("Talaba topilmadi!", show_alert=True)
        await state.clear()
        return

    doc = UserDocument(
        student_id=student.id,
        category=data["category"],      # passport / kontrakt / diplom...
        title=data["category"],         # hozircha kategoriya = nom
        description=None,
        file_id=data["file_id"],
        file_type=data["file_type"],
        status="pending",
    )

    session.add(doc)
    await session.commit()
    await state.clear()

    # Return to Main List after save
    # Re-use logic from documents_list but need to call it or send simplified msg
    # Simplest: Send success and offer to go back
    
    await call.message.edit_text(
        "✅ Hujjat muvaffaqiyatli saqlandi!",
        reply_markup=get_student_documents_kb(),
    )
    await call.answer()


# ============================================================
# 6) HUJJAT QO‘SHISHNI BEKOR QILISH
# ============================================================

@router.callback_query(F.data == "cancel_document")
async def cancel_document(call: CallbackQuery, state: FSMContext):
    await state.clear()
    try:
        await call.message.edit_text(
            "✅ Hujjat o‘chirildi.",
            reply_markup=get_student_documents_kb()
        )
    except Exception:
        pass
    await call.answer()


