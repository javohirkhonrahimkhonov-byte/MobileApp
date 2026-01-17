from aiogram import Router, F
from aiogram.types import CallbackQuery, Message
from aiogram.fsm.context import FSMContext
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from database.models import Staff, TgAccount, StaffRole
from keyboards.inline_kb import (
    get_staff_role_select_kb,
    get_rahbariyat_main_menu_kb as get_rahbariyat_main_menu,
    get_dekanat_main_menu_kb,
    get_tutor_main_menu_kb,
)

from models.states import StaffAuthStates

router = Router()


# =========================================
# 1) Xodim bo‘limi - rol tanlash
# =========================================
@router.callback_query(F.data == "staff_menu")
async def staff_menu(call: CallbackQuery):
    await call.message.edit_text(
        "👨‍💼 Xodim sifatida tizimga kirish uchun rolingizni tanlang:",
        reply_markup=get_staff_role_select_kb()
    )
    await call.answer()


# =========================================
# 2) ROL tanlanganda JSHSHIR so‘raymiz
# =========================================
@router.callback_query(F.data.startswith("staff_role_"))
async def staff_role_selected(call: CallbackQuery, state: FSMContext):

    selected_role = call.data.replace("staff_role_", "")  # rahbariyat / dekanat / tyutor

    await state.set_state(StaffAuthStates.entering_jshshir)
    await state.update_data(expected_role=selected_role)

    await call.message.edit_text(
        f"🔑 <b>{selected_role.capitalize()}</b> sifatida kirish uchun JSHSHIR kiriting:",
        parse_mode="HTML"
    )
    await call.answer()


# =========================================
# 3) Xodim JSHSHIR yuboradi → DB tekshiramiz
# =========================================
@router.message(StaffAuthStates.entering_jshshir)
async def staff_jshshir_entered(message: Message, state: FSMContext, session: AsyncSession):

    jshshir = message.text.strip()
    data = await state.get_data()
    expected_role = data.get("expected_role")

    # Xodimni qidiramiz
    staff = await session.scalar(
        select(Staff).where(Staff.jshshir == jshshir)
    )

    if not staff:
        await message.answer("❌ Bunday JSHSHIR topilmadi. Qayta urinib ko‘ring.")
        return

    if staff.role.value != expected_role:
        await message.answer(
            f"❌ Sizning rolingiz <b>{staff.role.value}</b>.\n"
            f"Bu bo‘limga kirish uchun <b>{expected_role}</b> bo‘lishingiz kerak.",
            parse_mode="HTML"
        )
        return

    # TG account bilan bog‘laymiz
    tg_account = await session.scalar(
        select(TgAccount).where(TgAccount.telegram_id == message.from_user.id)
    )

    if not tg_account:
        tg_account = TgAccount(
            telegram_id=message.from_user.id,
            staff_id=staff.id,
            current_role=staff.role.value
        )
        session.add(tg_account)
    else:
        tg_account.staff_id = staff.id
        tg_account.current_role = staff.role.value

    await session.commit()
    await state.clear()

    # To‘g‘ri menyuga yo‘naltiramiz
    if staff.role == StaffRole.RAHBARIYAT:
        await message.answer(
            "🏛 Rahbariyat menyusiga xush kelibsiz!",
            reply_markup=get_rahbariyat_main_menu()
        )

    elif staff.role == StaffRole.DEKANAT:
        await message.answer(
            "🏫 Dekanat menyusiga xush kelibsiz!",
            reply_markup=get_dekanat_main_menu_kb()
        )

    elif staff.role == StaffRole.TYUTOR:
        await message.answer(
            "👨‍🏫 Tyutor menyusiga xush kelibsiz!",
            reply_markup=get_tutor_main_menu_kb()
        )
