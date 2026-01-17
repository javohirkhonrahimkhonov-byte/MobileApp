from aiogram import Router, F
from aiogram.types import CallbackQuery, URLInputFile
from aiogram.fsm.context import FSMContext
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from database.models import (
    Student,
    TgAccount,
    UserActivity,
    UserDocument,
    UserCertificate,
    StudentFeedback
)
from keyboards.inline_kb import get_student_profile_menu_kb

router = Router()


async def _get_student_by_tg(telegram_id: int, session: AsyncSession):
    """
    Studentni TgAccount orqali olish.
    """
    tg_acc = await session.scalar(
        select(TgAccount).where(TgAccount.telegram_id == telegram_id)
    )

    if not tg_acc or not tg_acc.student_id:
        return None

    student = await session.scalar(
        select(Student)
        .options(
            selectinload(Student.university),
            selectinload(Student.faculty)
        )
        .where(Student.id == tg_acc.student_id)
    )

    return student


@router.callback_query(F.data == "student_profile")
async def student_profile(call: CallbackQuery, state: FSMContext, session: AsyncSession):
    await state.clear()

    student = await _get_student_by_tg(call.from_user.id, session)
    if not student:
        return await call.answer("Siz talaba sifatida ro‘yxatdan o‘tmagansiz!", show_alert=True)

    # ================================
    # 📊 Faolliklar statistikasi
    # ================================
    total_activities = await session.scalar(select(func.count(UserActivity.id)).where(UserActivity.student_id == student.id)) or 0
    approved_activities = await session.scalar(select(func.count(UserActivity.id)).where(UserActivity.student_id == student.id, UserActivity.status == "approved")) or 0
    
    # ================================
    # 📄 Hujjatlar & Murojaatlar
    # ================================
    documents_count = await session.scalar(select(func.count(UserDocument.id)).where(UserDocument.student_id == student.id)) or 0
    certificates_count = await session.scalar(select(func.count(UserCertificate.id)).where(UserCertificate.student_id == student.id)) or 0
    
    total_feedbacks = await session.scalar(select(func.count(StudentFeedback.id)).where(StudentFeedback.student_id == student.id)) or 0
    answered_feedbacks = await session.scalar(select(func.count(StudentFeedback.id)).where(StudentFeedback.student_id == student.id, StudentFeedback.status == "answered")) or 0

    # ================================
    # 📌 Matnni tayyorlash
    # ================================
    
    # 1. Short Name formatting (Fallback to full name if missing)
    display_name = student.short_name or student.full_name
    
    # 2. Group formatting (First 5 chars)
    group_display = student.group_number
    if group_display and len(group_display) > 5:
        group_display = group_display[:5].strip()

    # 3. Dynamic Fields
    uni = student.university_name or (student.university.name if student.university else '-')
    fac = student.faculty_name or (student.faculty.name if student.faculty else '-')
    
    level = student.level_name or "?" 
    sem = student.semester_name or "?"
    edu_form = student.education_form or "-"
    edu_type = student.education_type or "-"
    pay_form = student.payment_form or "-"
    status = student.student_status or "Aktiv"
    
    city = student.province_name or "-"
    dist = student.district_name or "-"
    phone = student.phone or "-"
    email = student.email or "-"
    accom = student.accommodation_name or "-"

    caption = (
        f"🎓 <b>{level} | {sem}</b>\n"
        f"👤 <b>{display_name}</b>\n\n"
        
        f"🏫 <b>O‘qish joyi:</b>\n"
        f"• OTM: {uni}\n"
        f"• Fakultet: {fac}\n"
        f"• Yo‘nalish: {student.specialty_name or 'Mutaxassislik'}\n"
        f"• Guruh: <b>{group_display}</b>\n\n"
        f"⏳ Qoldirilgan darslar: <b>{student.missed_hours} soat</b>\n\n"
        
        f"📚 <b>Ta’lim ma’lumotlari:</b>\n"
        f"• Status: {status}\n"
        f"• Shakli: {edu_form} | {edu_type}\n"
        f"• To‘lov: {pay_form}\n\n"
        
        f"📞 <b>Aloqa:</b>\n"
        f"• Tel: {phone}\n"
        f"• Email: {email}\n"
        f"• Manzil: {city}, {dist}\n\n"
        
        f"🏠 <b>Ijtimoiy holat:</b>\n"
        f"• Yashash joyi: {accom}\n\n"

        f"📊 <b>Platformadagi Faollik:</b>\n"
        f"• Faolliklar: {approved_activities}/{total_activities}\n"
        f"• Hujjatlar: {documents_count}\n"
        f"• Sertifikatlar: {certificates_count}\n"
        f"• Murojaatlar: {answered_feedbacks}/{total_feedbacks}"
    )

    try:
        # Agar rasm bo'lsa - Rasm bilan chiqarish (Eski xabarni o'chirish kerak, chunki Text -> Photo update qilib bo'lmaydi)
        if student.image_url:
            await call.message.delete()
            await call.message.answer_photo(
                photo=URLInputFile(student.image_url, filename="profile.jpg"), # Using URL directly usually works if supported, else assume valid URL
                caption=caption,
                reply_markup=get_student_profile_menu_kb(),
                parse_mode="HTML"
            )
        else:
            # Rasm yo'q bo'lsa odatiy text edit
            await call.message.edit_text(
                caption, # Text as caption content
                reply_markup=get_student_profile_menu_kb(),
                parse_mode="HTML"
            )
    except Exception as e:
        # Fallback for errors (e.g. invalid URL, or delete failed)
        try:
             await call.message.answer(caption, reply_markup=get_student_profile_menu_kb(), parse_mode="HTML")
        except:
            pass

    await call.answer()
