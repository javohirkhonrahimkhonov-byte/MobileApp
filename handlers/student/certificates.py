# handlers/student/certificates.py

from aiogram import Router, F
from aiogram.types import CallbackQuery, Message
from aiogram.filters import StateFilter
from aiogram.fsm.context import FSMContext
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from database.models import TgAccount, Student, UserCertificate
from keyboards.inline_kb import get_student_certificates_kb, get_student_certificates_simple_kb

router = Router()

# ===== Helper: Studentni olish =====

async def get_student(call_or_msg, session: AsyncSession):
    tg = await session.scalar(
        select(TgAccount).where(TgAccount.telegram_id == call_or_msg.from_user.id)
    )
    if not tg or not tg.student_id:
        return None
    return await session.get(Student, tg.student_id)

# ===== Asosiy menyu =====

@router.callback_query(F.data.startswith("student_certificates"))
async def student_certificates(call: CallbackQuery):
    # Determine back button logic
    back_to = "go_student_home"
    if "profile" in call.data:
        back_to = "student_profile"

    text = (
        "🎓 <b>Sertifikatlar bo‘limi</b>\n"
        "Quyidagilardan birini tanlang:"
    )
    kb = get_student_certificates_kb(back_callback=back_to)
    try:
        await call.message.edit_text(text, reply_markup=kb, parse_mode="HTML")
    except Exception:
        await call.message.delete()
        await call.message.answer(text, reply_markup=kb, parse_mode="HTML")
    await call.answer()

# ===== 1) Sertifikatlar ro‘yxati =====

@router.callback_query(F.data == "student_cert_list")
async def student_cert_list(call: CallbackQuery, session: AsyncSession):

    student = await get_student(call, session)
    if not student:
        await call.answer("Talaba topilmadi!", show_alert=True)
        return

    certs = await session.scalars(
        select(UserCertificate).where(UserCertificate.student_id == student.id)
    )
    certs = certs.all()

    if not certs:
        await call.message.answer("📁 Sizda hali sertifikatlar mavjud emas.")
    else:
        for c in certs:
            await call.message.answer_document(c.file_id)

    await call.message.answer(
        "🎓 Sertifikatlar menyusi:",
        reply_markup=get_student_certificates_simple_kb(),
    )
    await call.answer()

# ===== 2) Sertifikat qo‘shish =====

@router.callback_query(F.data == "student_cert_add")
async def student_cert_add(call: CallbackQuery, state: FSMContext):
    # Oddiy string state ishlatyapsiz: "cert_file"
    await state.set_state("cert_file")

    try:
        await call.message.edit_text(
            "➕ <b>Sertifikat faylini yuboring (PDF yoki Rasm).</b>",
            parse_mode="HTML"
        )
    except Exception:
        pass
    await call.answer()

# ===== 3) Sertifikat faylni qabul qilish =====
# E'TIBOR: bu yerda endi state= emas, StateFilter ishlatyapmiz

@router.message(
    StateFilter("cert_file"),
    F.document | F.photo | F.video,
)
async def cert_file_received(
    message: Message,
    state: FSMContext,
    session: AsyncSession,
):

    student = await get_student(message, session)
    if not student:
        await message.answer("Talaba topilmadi.")
        return

    # File tanlash
    if message.document:
        file_id = message.document.file_id
    elif message.photo:
        file_id = message.photo[-1].file_id
    else:
        file_id = message.video.file_id

    cert = UserCertificate(
        student_id=student.id,
        title="Sertifikat",
        file_id=file_id,
    )

    session.add(cert)
    await session.commit()

    await state.clear()

    await message.answer(
        "✅ Sertifikat muvaffaqiyatli yuklandi!",
        reply_markup=get_student_certificates_kb(),
    )
