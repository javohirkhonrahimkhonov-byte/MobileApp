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

@router.callback_query(F.data.in_({"student_documents", "student_documents:profile"}))
async def student_documents(call: CallbackQuery):
    # Determine back button logic
    back_to = "go_student_home"
    if "profile" in call.data:
        back_to = "student_profile"

    text = "📄 <b>Hujjatlar bo‘limi</b>"
    kb = get_student_documents_kb(back_callback=back_to)
    try:
        await call.message.edit_text(text, reply_markup=kb, parse_mode="HTML")
    except Exception:
        await call.message.delete()
        await call.message.answer(text, reply_markup=kb, parse_mode="HTML")
    await call.answer()


# ============================================================
# 1) HUJJATLAR RO‘YXATI
# ============================================================

@router.callback_query(F.data == "student_documents_list")
async def student_documents_list(call: CallbackQuery, session: AsyncSession):

    student = await get_student(call, session)
    if not student:
        await call.answer("Talaba topilmadi!", show_alert=True)
        return

    docs = await session.scalars(
        select(UserDocument).where(UserDocument.student_id == student.id)
    )
    docs = docs.all()

    if not docs:
        await call.message.answer("📄 Sizda hali hujjatlar mavjud emas.")
    else:
        for doc in docs:
            caption = f"📄 <b>{doc.title}</b>\nKategoriya: {doc.category}"

            if doc.file_type == "photo":
                await call.message.answer_photo(doc.file_id, caption=caption, parse_mode="HTML")
            else:
                await call.message.answer_document(doc.file_id, caption=caption, parse_mode="HTML")

    await call.message.answer(
        "📂 Hujjatlar menyusi:",
        reply_markup=get_student_documents_simple_kb(),
    )

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


# ============================================================
# 7) TALABA ASOSIY MENYUSI — ORTGA
# ============================================================

