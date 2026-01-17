from datetime import datetime
import logging
from services.ai_service import analyze_appeal # AI Import

logger = logging.getLogger(__name__)
from aiogram import Router, F
from aiogram.types import CallbackQuery, Message
from aiogram.fsm.context import FSMContext
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from database.models import TgAccount, Student, StudentFeedback, Staff
from models.states import FeedbackStates
from keyboards.inline_kb import (
    get_student_main_menu_kb,
    get_feedback_anonymity_kb,
    get_rahb_appeal_actions_kb,
    get_student_feedback_menu_kb,
    get_student_feedback_list_kb,
    get_student_feedback_detail_kb,
    get_feedback_recipient_kb,
    get_feedback_cancel_kb,
    get_feedback_rahbariyat_menu_kb,
    get_feedback_dekanat_menu_kb,
)
from database.models import StaffRole, TutorGroup, Faculty, UserAppeal
from utils.feedback_utils import get_feedback_thread_text

router = Router()


# ============================
# Helper — Student olish
# ============================
async def get_student(event, session: AsyncSession):
    tg = await session.scalar(
        select(TgAccount).where(TgAccount.telegram_id == event.from_user.id)
    )
    if tg and tg.student_id:
        return await session.get(Student, tg.student_id)
    return None


# ============================
# 1) Murojaat yuborishni boshlash
# ============================
# ============================
# 1) Murojaatlar menyusi
# ============================
@router.callback_query(F.data.startswith("student_feedback_menu"))
async def feedback_menu(call: CallbackQuery, state: FSMContext):
    await state.clear()
    
    # Determine back button logic
    back_to = "go_student_home"
    if "profile" in call.data:
        back_to = "student_profile"
    
    text = (
        "📨 <b>Murojaatlar bo'limi</b>\n\n"
        "Yangi murojaat yuborishingiz yoki eskilarini kuzatishingiz mumkin."
    )
    kb = get_student_feedback_menu_kb(back_callback=back_to)

    try:
        await call.message.edit_text(text, parse_mode="HTML", reply_markup=kb)
    except Exception:
        # Agar oldingi xabar Rasm bo'lsa (Profile) edit_text o'xshamaydi
        await call.message.delete()
        await call.message.answer(text, parse_mode="HTML", reply_markup=kb)
    
    await call.answer()


@router.callback_query(F.data == "student_menu")
async def back_to_main_menu(call: CallbackQuery, state: FSMContext):
    await state.clear()
    try:
        await call.message.edit_text(
            "🏠 <b>Bosh sahifa</b>",
            parse_mode="HTML",
            reply_markup=get_student_main_menu_kb()
        )
    except Exception:
        await call.message.delete()
        await call.message.answer(
            "🏠 <b>Bosh sahifa</b>",
            parse_mode="HTML",
            reply_markup=get_student_main_menu_kb()
        )


# ============================
# 2) Yangi murojaat (Start)
# ============================
@router.callback_query(F.data == "student_feedback_new")
async def feedback_new(call: CallbackQuery, state: FSMContext):
    await state.set_state(FeedbackStates.anonymity_choice)
    try:
        await call.message.edit_text(
            "🕵️‍♂️ <b>Murojaat turini tanlang:</b>",
            parse_mode="HTML",
            reply_markup=get_feedback_anonymity_kb()
        )
    except Exception:
        pass
    await call.answer()


# ============================
# 3) Murojaatlar ro'yxati
# ============================
@router.callback_query(F.data == "student_feedback_list")
async def feedback_list(call: CallbackQuery, session: AsyncSession):
    student = await get_student(call, session)
    if not student:
        return await call.answer("Talaba topilmadi", show_alert=True)

    # 50 ta eng oxirgi murojaatni olamiz
    stmt = select(StudentFeedback).where(
        StudentFeedback.student_id == student.id,
        StudentFeedback.parent_id == None  # Faqat root (asosiy) murojaatlarni
    ).order_by(StudentFeedback.created_at.desc()).limit(50)
    
    result = await session.execute(stmt)
    feedbacks = result.scalars().all()
    
    if not feedbacks:
        await call.answer("Sizda murojaatlar yo'q", show_alert=True)
        return

    try:
        await call.message.edit_text(
            "📂 <b>Sizning murojaatlaringiz:</b>",
            parse_mode="HTML",
            reply_markup=get_student_feedback_list_kb(feedbacks)
        )
    except Exception:
        pass
    await call.answer()


# ============================
# 4) Murojaatni ko'rish (Detail)
# ============================
@router.callback_query(F.data.startswith("student_feedback_view:"))
async def feedback_view(call: CallbackQuery, session: AsyncSession):
    feedback_id = int(call.data.split(":")[1])
    
    # Asosiy info va statusni tekshirish uchun
    fb = await session.get(StudentFeedback, feedback_id)
    if not fb:
        return await call.answer("Murojaat topilmadi", show_alert=True)

    # To'liq tarix (Thread)
    thread_text = await get_feedback_thread_text(feedback_id, session)
    
    # Yopilganligini tekshirish (tugmalar uchun)
    is_closed = (fb.status == "closed")
    
    # Agar fayl bo'lsa (faqat rootniki), uni jo'natish qiyin chunki edit qilyapmiz.
    # Shuning uchun matn mode ga o'tamiz yoki yangi xabar jo'natish kerak bo'ladi.
    # Lekin biz `edit_text` qilsak faylni ko'rsata olmaymiz agar oldingisi text bo'lsa.
    # Eng yaxshisi: Agar fayl bo'lsa, delete qilib yangi xabar jonatamiz. 
    # Yoki oddiygina matn chiqarib, "Media faylni ko'rish imkonsiz" deymiz (MVP).
    # Keling, hozircha matnni o'zini chiqaramiz. get_feedback_thread_text da [Media] deb ketilgan.

    # Status icon
    status_emoji = {
        "pending": "⏳ Kutilmoqda",
        "answered": "✅ Javob berilgan",
        "closed": "🔒 Yopilgan",
        "reappeal": "🔄 Jarayonda"
    }.get(fb.status, fb.status)

    final_text = (
        f"🆔 <b>Murojaat #{fb.id}</b>\n"
        f"Holat: {status_emoji}\n\n"
        f"{thread_text}"
    )
    
    # Agar message juda uzun bo'lsa (4096), qisqartirish kerak.
    if len(final_text) > 4000:
        final_text = final_text[:4000] + "\n...(davomi bor)"

    # Edit message (agar oldingi xabar rasm bo'lsa, edit_caption ishlaydi, text bo'lsa edit_text)
    # Universal yechim: Eski xabarni o'chirib yangisini yozish (clean UI)
    await call.message.delete()
    
    await call.message.answer(
        final_text,
        parse_mode="HTML",
        reply_markup=get_student_feedback_detail_kb(feedback_id, is_closed)
    )
    await call.answer()


# ============================
# 1.1) Anonimlik tanlandi -> Xabar kuting
# ============================
@router.callback_query(FeedbackStates.anonymity_choice, F.data.startswith("feedback_mode_"))
async def feedback_anonymity_chosen(call: CallbackQuery, state: FSMContext):
    is_anon = (call.data == "feedback_mode_anon")
    await state.update_data(is_anonymous=is_anon)

    # Keyingi bosqich: Kimga yuborishni tanlash
    await state.set_state(FeedbackStates.recipient_choice)
    
    await call.message.edit_text(
        "📩 <b>Murojaat kimga yuborilsin?</b>\n\n"
        "Tegishli bo'limni tanlang:",
        reply_markup=get_feedback_recipient_kb(),
        parse_mode="HTML"
    )
    await call.answer()


@router.callback_query(FeedbackStates.recipient_choice, F.data == "student_feedback_recipient")
async def feedback_back_to_main(call: CallbackQuery):
    await call.message.edit_text(
        "📩 <b>Murojaat kimga yuborilsin?</b>\n\n"
        "Tegishli bo'limni tanlang:",
        reply_markup=get_feedback_recipient_kb(),
        parse_mode="HTML"
    )

@router.callback_query(FeedbackStates.recipient_choice, F.data.startswith("fb_menu:"))
async def feedback_menu_nav(call: CallbackQuery):
    target = call.data.split(":")[1]
    text = "📩 <b>Murojaat kimga yuborilsin?</b>"
    kb = None
    
    if target == "rahbariyat":
        text = "🏛 <b>Rahbariyatga murojaat</b>\n\nKimga yuborilishi kerakligini tanlang:"
        kb = get_feedback_rahbariyat_menu_kb()
    elif target == "dekanat":
        text = "🏫 <b>Dekanatga murojaat</b>\n\nKimga yuborilishi kerakligini tanlang:"
        kb = get_feedback_dekanat_menu_kb()
        
    if kb:
        await call.message.edit_text(text, reply_markup=kb, parse_mode="HTML")
    await call.answer()

@router.callback_query(FeedbackStates.recipient_choice, F.data.startswith("fb_recipient:"))
async def feedback_recipient_chosen(call: CallbackQuery, state: FSMContext, session: AsyncSession):
    _, role_key = call.data.split(":")
    
    student = await get_student(call, session)
    if not student:
        return await call.answer("Talaba topilmadi", show_alert=True)

    assigned_role = None
    assigned_staff_id = None
    
    # --- 1. FACULTY LEVEL ROLES ---
    faculty_role_map = {
        "dekan": StaffRole.DEKAN,
        "dekan_orinbosari": StaffRole.DEKAN_ORINBOSARI,
        "kafedra": StaffRole.KAFEDRA_MUDIRI,
        "teacher": StaffRole.TEACHER,
        "inspektor": StaffRole.INSPEKTOR,
        "dekanat": StaffRole.DEKANAT # Old legacy
    }

    if role_key in faculty_role_map:
        if not student.faculty_id:
            return await call.answer("Sizga fakultet biriktirilmagan!", show_alert=True)
        
        assigned_role = faculty_role_map[role_key].value
        
        # Try to find a specific staff member in this faculty with this role
        # Note: For teachers there might be many, we just pick one or None (so it appears in the list key)
        staff = await session.scalar(
            select(Staff).where(Staff.faculty_id == student.faculty_id, Staff.role == assigned_role)
        )
        if staff:
            assigned_staff_id = staff.id

    # --- 2. UNIVERSITY LEVEL ROLES ---
    elif role_key == "rahbariyat":
        assigned_role = StaffRole.RAHBARIYAT.value
    
    elif role_key == "prorektor":
        assigned_role = StaffRole.PROREKTOR.value

    elif role_key == "yoshlar_prorektor":
        assigned_role = StaffRole.YOSHLAR_PROREKTOR.value

    elif role_key == "rektor":
        assigned_role = StaffRole.REKTOR.value

    # --- 3. SPECIFIC (TYUTOR) ---
    elif role_key == "tyutor":
        # Talabaning guruhiga biriktirilgan tyutorni topish
        tutor_group = await session.scalar(select(TutorGroup).where(TutorGroup.group_number == student.group_number))
        
        if not tutor_group or not tutor_group.tutor_id:
            return await call.answer("Sizning guruhingizga tyutor biriktirilmagan!", show_alert=True)
            
        assigned_role = StaffRole.TYUTOR.value
        assigned_staff_id = tutor_group.tutor_id

    # --- 4. OTHER (PSIXOLOG) ---
    elif role_key == "psixolog":
        assigned_role = StaffRole.PSIXOLOG.value
        staff = await session.scalar(select(Staff).where(Staff.role == StaffRole.PSIXOLOG))
        if staff:
             assigned_staff_id = staff.id

    # --- 5. BUXGALTERIYA ---
    elif role_key == "buxgalter":
        assigned_role = StaffRole.BUXGALTER.value
        staff = await session.scalar(select(Staff).where(Staff.role == StaffRole.BUXGALTER))
        if staff:
             assigned_staff_id = staff.id

    # --- 6. KUTUBXONA ---
    elif role_key == "kutubxona":
        assigned_role = StaffRole.KUTUBXONA.value
        staff = await session.scalar(select(Staff).where(Staff.role == StaffRole.KUTUBXONA))
        if staff:
             assigned_staff_id = staff.id

    await state.update_data(assigned_role=assigned_role, assigned_staff_id=assigned_staff_id)
    await state.set_state(FeedbackStates.waiting_message)
    
    role_names = {
        "rahbariyat": "🏛️ Rahbariyat",
        "prorektor": "👔 O'quv ishlari prorektori",
        "yoshlar_prorektor": "👔 Yoshlar ishlari prorektori",
        "rektor": "🎓 Rektor",
        "dekan": "👤 Dekan",
        "dekan_orinbosari": "👤 Dekan o'rinbosari",
        "kafedra": "🏫 Kafedra mudiri",
        "teacher": "👨‍🏫 Professor-o'qituvchi",
        "inspektor": "🔍 Inspektor",
        "tyutor": "🧑‍🏫 Tyutor",
        "psixolog": "🧠 Psixolog",
        "buxgalter": "💰 Buxgalteriya",
        "kutubxona": "📚 Kutubxona",
        "dekanat": "🏫 Dekanat"
    }

    await call.message.edit_text(
        f"Qabul qiluvchi: <b>{role_names.get(role_key, role_key)}</b>\n\n"
        "✍️ <b>Endi murojaat matnini yoki faylni yuboring.</b>",
        reply_markup=get_feedback_cancel_kb(),
        parse_mode="HTML"
    )
    await call.answer()


# ============================
# 2) Matn / media qabul qilish
# ============================
@router.message(FeedbackStates.waiting_message)
async def feedback_receive(message: Message, state: FSMContext, session: AsyncSession):
    data = await state.get_data()
    is_anonymous = data.get("is_anonymous", False)
    assigned_role = data.get("assigned_role")
    assigned_staff_id = data.get("assigned_staff_id")

    text = message.text if message.text else None
    file_id = None
    file_type = None

    # Rasm
    if message.photo:
        file_id = message.photo[-1].file_id
        file_type = "photo"

    # Video
    elif message.video:
        file_id = message.video.file_id
        file_type = "video"

    # Hujjat
    elif message.document:
        file_id = message.document.file_id
        file_type = "document"

    # Studentni aniqlash
    student = await get_student(message, session)

    # Yangi murojaat yaratish
    feedback = StudentFeedback(
        student_id=student.id,
        text=text,
        file_id=file_id,
        file_type=file_type,
        status="pending" if assigned_role == StaffRole.RAHBARIYAT.value else f"assigned_{assigned_role}", # Statusni ajratish
        assigned_role=assigned_role,
        assigned_staff_id=assigned_staff_id,
        is_anonymous=is_anonymous
    )

    session.add(feedback)
    await session.commit()
    
    # 🤖 AI ANALYSIS (Background Task)
    # Asinxron ishga tushiramiz, foydalanuvchini kuttirmaslik uchun
    # Lekin hozircha oddiy await qilib turamiz tez sinash uchun
    try:
        analysis = await analyze_appeal(text)
        if analysis:
            feedback.ai_topic = analysis.get("topic")
            feedback.ai_sentiment = analysis.get("sentiment")
            feedback.ai_summary = analysis.get("summary")
            await session.commit()
            # Xodimga boradigan xabarda AI natijasini qo'shsak bo'ladi (keyinchalik)
    except Exception as e:
        logger.error(f"AI Analysis failed: {e}")

    await state.clear()

    # Javob
    await message.answer(
        "✅ <b>Murojaatingiz qabul qilindi!</b>\n"
        "Tez orada javob beriladi.",
        parse_mode="HTML",
        reply_markup=get_student_main_menu_kb()
    )


# ============================
# 3) Murojaatni yopish
# ============================
@router.callback_query(F.data.startswith("feedback_close:"))
async def feedback_close(call: CallbackQuery, session: AsyncSession):
    feedback_id = int(call.data.split(":")[1])
    feedback = await session.get(StudentFeedback, feedback_id)
    
    if feedback:
        feedback.status = "closed"
        await session.commit()
    
    # Xabarni o'zgartirish (tugmalarni olib tashlash)
    current_text = call.message.html_text if hasattr(call.message, "html_text") else call.message.caption or call.message.text
    
    try:
        await call.message.edit_text(
            f"{current_text}\n\n🔒 <b>Murojaat yopildi.</b>",
            parse_mode="HTML",
            # Qayta 'closed' holatda detail kb chaqirilsa, faqat 'Orqaga' chiqadi
            reply_markup=get_student_feedback_detail_kb(feedback_id, is_closed=True)
        )
    except Exception:
        pass
    await call.answer()


# ============================
# 4) Qayta murojaat (Re-appeal)
# ============================
@router.callback_query(F.data.startswith("feedback_reappeal:"))
async def feedback_reappeal(call: CallbackQuery, state: FSMContext):
    feedback_id = int(call.data.split(":")[1])
    await state.update_data(reappeal_feedback_id=feedback_id)
    await state.set_state(FeedbackStates.reappealing)
    
    await call.message.answer(
        "🔄 <b>Qayta murojaat matnini yozing:</b>\n"
        "Xabaringiz to'g'ridan-to'g'ri xodimga yuboriladi.",
        parse_mode="HTML"
    )
    await call.answer()


@router.message(FeedbackStates.reappealing)
async def feedback_reappeal_receive(message: Message, state: FSMContext, session: AsyncSession):
    data = await state.get_data()
    original_feedback_id = data.get("reappeal_feedback_id")
    
    if not original_feedback_id:
        await message.answer("❌ Xatolik: Murojaat ID topilmadi.")
        await state.clear()
        return

    original_feedback = await session.get(StudentFeedback, original_feedback_id)
    
    if not original_feedback or not original_feedback.assigned_staff_id:
        await message.answer("❌ Murojaat yoki mas'ul xodim topilmadi.")
        await state.clear()
        return

    # Xodimning Telegram ID sini topish
    staff_tg = await session.scalar(
        select(TgAccount).where(TgAccount.staff_id == original_feedback.assigned_staff_id)
    )

    if staff_tg:
        target_tg_id = staff_tg.telegram_id
    else:
        # FALLBACK: Agar aniq xodim topilmasa, o'sha roldagi boshqa xodimni qidiramiz
        fallback_stmt = select(TgAccount).join(Staff).where(Staff.role == original_feedback.assigned_role)
        
        # Agar Dekanat bo'lsa, fakultet bo'yicha
        if original_feedback.assigned_role == StaffRole.DEKANAT.value:
            # Studentni load qilib olish kerak (agar hali olinmagan bo'lsa)
            student_chk = await session.get(Student, original_feedback.student_id)
            if student_chk and student_chk.faculty_id:
                fallback_stmt = fallback_stmt.where(Staff.faculty_id == student_chk.faculty_id)
        
        # Agar Tyutor bo'lsa, guruh bo'yicha (murakkabroq, hozircha shunchaki log qilib qo'yamiz)
        # Tyutor o'zgargan bo'lsa, baribir yangi tyutorga borishi kerak.
        
        target_tg = await session.scalar(fallback_stmt)
        if target_tg:
            target_tg_id = target_tg.telegram_id
            # Feedbackni ham yangi xodimga assign qilib qo'yamiz
            original_feedback.assigned_staff_id = target_tg.staff_id
            await session.commit()
        else:
             await message.answer("❌ Mas'ul xodim topilmadi (Fallback failed).")
             return

    try:
        student = await get_student(message, session)
        
        # Parent ID ni aniqlash (Zanjir hosil qilish)
        # Agar originalning o'zi child bo'lsa, uning parentini olamiz.
        # Agar original root bo'lsa, uning o'zi parent bo'ladi.
        real_parent_id = original_feedback.parent_id if original_feedback.parent_id else original_feedback.id

        # Yangi feedback yaratish (History uchun)
        new_feedback = StudentFeedback(
            student_id=student.id,
            text=message.text or "Media fayl",
            file_id=message.photo[-1].file_id if message.photo else (message.document.file_id if message.document else None),
            file_type="photo" if message.photo else (
                       "video" if message.video else (
                       "document" if message.document else None)),
            status="reappeal",
            assigned_staff_id=original_feedback.assigned_staff_id, # Updated potentially by fallback
            assigned_role=original_feedback.assigned_role,
            is_anonymous=original_feedback.is_anonymous, # Avvalgi anonimlikni saqlash
            parent_id=real_parent_id 
        )
        session.add(new_feedback)
        await session.commit()

        # Xodimga yuborish (To'liq tarix bilan)
        history_text = await get_feedback_thread_text(new_feedback.id, session)
        
        row_kb = get_rahb_appeal_actions_kb(new_feedback.id) # Reusable variable

        # Agar fayl bo'lsa
        if new_feedback.file_id:
            if new_feedback.file_type == "photo":
                await message.bot.send_photo(
                    target_tg_id, 
                    new_feedback.file_id, 
                    caption=history_text, 
                    parse_mode="HTML",
                    reply_markup=row_kb
                )
            elif new_feedback.file_type == "document":
                await message.bot.send_document(
                    target_tg_id, 
                    new_feedback.file_id, 
                    caption=history_text, 
                    parse_mode="HTML",
                    reply_markup=row_kb
                )
            else:
                await message.bot.send_message(
                    target_tg_id, 
                    history_text, 
                    parse_mode="HTML",
                    reply_markup=row_kb
                )
        else:
            await message.bot.send_message(
                target_tg_id, 
                history_text, 
                parse_mode="HTML",
                reply_markup=row_kb
            )

        await message.answer("✅ Xabar xodimga yuborildi.")
        await state.clear()

    except Exception as e:
        await message.answer(f"❌ Xatolik: {e}")
