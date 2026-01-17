from aiogram.types import KeyboardButton, ReplyKeyboardMarkup


def get_start_role_keyboard() -> ReplyKeyboardMarkup:
    keyboard = [
        [
            KeyboardButton(text="👨‍🏫 Xodim"),
            KeyboardButton(text="🎓 Talaba"),
        ]
    ]
    return ReplyKeyboardMarkup(
        keyboard=keyboard,
        resize_keyboard=True,
        input_field_placeholder="Iltimos, rolni tanlang",
        one_time_keyboard=True,
    )


def get_owner_main_menu_keyboard() -> ReplyKeyboardMarkup:
    keyboard = [
        [KeyboardButton(text="🏛 OTM va fakultetlar")],
        [KeyboardButton(text="👥 Xodim / talaba importi")],
        [KeyboardButton(text="📢 Umumiy e'lon yuborish")],
        [KeyboardButton(text="👨‍💻 Developerlar boshqaruvi")],
        [KeyboardButton(text="⚙️ Bot sozlamalari")],
        [KeyboardButton(text="🏠 Bosh menyu")],
    ]
    return ReplyKeyboardMarkup(
        keyboard=keyboard,
        resize_keyboard=True,
        input_field_placeholder="Owner menyusidan bo'limni tanlang",
    )


def get_student_activity_reply_kb() -> ReplyKeyboardMarkup:
    return ReplyKeyboardMarkup(
        keyboard=[
            [KeyboardButton(text="➕ Faollik qo‘shish")]
        ],
        resize_keyboard=True,
        input_field_placeholder="Faollik qo'shish uchun bosing..."
    )


def get_date_select_kb() -> ReplyKeyboardMarkup:
    return ReplyKeyboardMarkup(
        keyboard=[
            [KeyboardButton(text="📅 Bugun")]
        ],
        resize_keyboard=True,
        input_field_placeholder="Sana kiriting yoki tanlang..."
    )
