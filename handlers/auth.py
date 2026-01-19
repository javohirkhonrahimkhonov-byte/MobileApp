import logging
from aiogram import Router, F
from aiogram.filters import CommandStart
from aiogram.fsm.context import FSMContext
from aiogram.types import Message, CallbackQuery
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from config import OWNER_TELEGRAM_ID
from database.models import Staff, StaffRole, Student, TgAccount, Club
from keyboards.inline_kb import (
    get_start_role_inline_kb,
    get_owner_main_menu_inline_kb,
    get_retry_or_home_kb,
    get_data_confirmation_keyboard,
    get_student_main_menu_kb,
    get_yetakchi_main_menu_kb,
)
from models.states import AuthStates
from services.hemis_service import HemisService

router = Router()
logger = logging.getLogger(__name__)

from keyboards.inline_kb import (
    get_rahbariyat_main_menu_kb,
    get_dekanat_main_menu_kb,
    get_tutor_main_menu_kb,
)
from utils.owner_stats import get_owner_dashboard_text


# =====================================================================
#                         /start
# =====================================================================
@router.message(CommandStart())
async def cmd_start(message: Message, state: FSMContext, session: AsyncSession):
    await state.clear()
    tg_id = message.from_user.id

    account = await session.scalar(
        select(TgAccount).where(TgAccount.telegram_id == tg_id)
    )

    # ===================== AGAR AVVAL RO‘YXATDAN O‘TGAN BO‘LSA =====================
    if account:
        # TELEFON RAQAM TEKSHIRISH (Agar yo'q bo'lsa, qayta so'rash)
        # Talaba uchun
        if account.student_id:
            student = await session.get(Student, account.student_id)
            
            # --- FORCE HEMIS RE-AUTH (Yangi talab) ---
            # Agar talabada HEMIS ID bo'lmasa (eski import), qayta kirishni talab qilamiz
            if not student.hemis_id:
                 await state.update_data(hemis_login=student.hemis_login) # Loginni saqlab qolamiz
                 await state.set_state(AuthStates.entering_hemis_password) # Parol so'raymiz
                 return await message.answer(
                    "⚠️ <b>Diqqat! Tizim yangilandi.</b>\n\n"
                    "Xavfsizlik maqsadida HEMIS orqali qayta kirishingiz kerak.\n"
                    f"Login: <b>{student.hemis_login}</b>\n\n"
                    "🔐 Iltimos, <b>HEMIS parolingizni</b> kiriting:",
                    parse_mode="HTML"
                )
            # -----------------------------------------

            if not student.phone:
                await state.update_data(student_id=student.id)
                await state.set_state(AuthStates.entering_phone)
                return await message.answer(
                    "📱 <b>Telefon raqamingiz kiritilmagan.</b>\n"
                    "Iltimos, faol telefon raqamingizni kiriting.\n"
                    "Format: <code>+998XXXXXXXXX</code>",
                    parse_mode="HTML"
                )

        # Xodim uchun
        if account.staff_id:
            staff = await session.get(Staff, account.staff_id)
            # Owner bundan mustasno bo'lishi mumkin, lekin mayli tekshiramiz
            if not staff.phone:
                # Rolni aniqlash
                role = (
                    StaffRole.OWNER.value
                    if message.from_user.id == OWNER_TELEGRAM_ID
                    else staff.role
                )
                await state.update_data(staff_id=staff.id, role=role)
                await state.set_state(AuthStates.entering_phone)
                return await message.answer(
                    "📱 <b>Telefon raqamingiz kiritilmagan.</b>\n"
                    "Iltimos, faol telefon raqamingizni kiriting.\n"
                    "Format: <code>+998XXXXXXXXX</code>",
                    parse_mode="HTML"
                )

        # ===================== OWNER =====================

        # ===================== OWNER =====================
        if account.current_role == StaffRole.OWNER.value:
            text = await get_owner_dashboard_text(session)
            return await message.answer(
                text,
                reply_markup=get_owner_main_menu_inline_kb(),
                parse_mode="HTML"
            )

        if account.staff_id:
            staff = await session.get(Staff, account.staff_id)
            
            # Agar lavozim bor bo'lsa: "Assalomu alaykum, Prorektor Olimov Alisher!"
            # Agar yo'q bo'lsa: "Assalomu alaykum, Olimov Alisher!"
            if staff.position:
                greeting = f"Assalomu alaykum, {staff.position} {staff.full_name}!"
            else:
                greeting = f"Assalomu alaykum, {staff.full_name}!"
            
            # ===================== RAHBARIYAT =====================
            if account.current_role == StaffRole.RAHBARIYAT.value:
                return await message.answer(
                    f"🏢 <b>{greeting}</b>\n\n"
                    "Rahbariyat paneliga xush kelibsiz.",
                    reply_markup=get_rahbariyat_main_menu_kb(),
                    parse_mode="HTML"
                )

            # ===================== DEKANAT =====================
            if account.current_role == StaffRole.DEKANAT.value:
                return await message.answer(
                    f"🏛 <b>{greeting}</b>\n\n"
                    "Dekanat paneliga xush kelibsiz.",
                    reply_markup=get_dekanat_main_menu_kb(),
                    parse_mode="HTML"
                )

            # ===================== TYUTOR =====================
            if account.current_role == StaffRole.TYUTOR.value:
                return await message.answer(
                    f"🎓 <b>{greeting}</b>\n\n"
                    "Tyutor paneliga xush kelibsiz.",
                    reply_markup=get_tutor_main_menu_kb(),
                    parse_mode="HTML"
                )
            
            # ===================== YOSHLAR YETAKCHISI / KLUB RAHBARI =====================
            if account.current_role == StaffRole.YOSHLAR_YETAKCHISI.value:
                 return await message.answer(f"<b>{greeting}</b>\nYoshlar yetakchisi paneliga xush kelibsiz.", reply_markup=get_yetakchi_main_menu_kb(), parse_mode="HTML")

        # ===================== TALABA =====================
        if account.current_role == "student" or account.current_role == StaffRole.KLUB_RAHBARI.value:
            # Check for Led Clubs
            led_clubs = []
            if account.staff_id:
                led_clubs = (await session.execute(select(Club).where(Club.leader_id == account.staff_id))).scalars().all()

            # --- 🔄 AUTO-REFRESH DATA ---
            if account.student and account.student.hemis_token:
                try:
                    s = account.student
                    me = await HemisService.get_me(s.hemis_token)
                    if me:
                        # Extract Semester Code
                        sem_code = None
                        if "semester" in me and isinstance(me["semester"], dict):
                            sem_code = me["semester"].get("code")
                            if not sem_code:
                                sem_code = me["semester"].get("id")

                        # Call new absence method (No PNFL needed)
                        usage_hours = await HemisService.get_student_absence(s.hemis_token, semester_code=str(sem_code) if sem_code else None)
                        
                        # Fix: Extract Total from Tuple (total, excused, unexcused)
                        if isinstance(usage_hours, (tuple, list)) and len(usage_hours) > 0:
                            hours = usage_hours[0]
                        else:
                            hours = int(usage_hours)
                        
                        if s.missed_hours != hours:
                            s.missed_hours = hours
                            await session.commit()
                            
                        # Also refresh Specialty if missing (Quick Fix)
                        if not s.specialty_name:
                             spec_name = me.get("specialty", {}).get("name") if isinstance(me.get("specialty"), dict) else None
                             if spec_name:
                                 s.specialty_name = spec_name
                                 await session.commit()

                except Exception as e:
                    print(f"Auto-refresh start error: {e}")
            # ---------------------------
                
            return await message.answer(
                "🎓 <b>Talaba menyusi</b>\nQuyidagi bo‘limlardan birini tanlang:",
                reply_markup=get_student_main_menu_kb(led_clubs=led_clubs),
                parse_mode="HTML"
            )

        # ===================== BOSHQA HOLAT =====================
        return await message.answer(
            "⚠️ Sizning rolingiz aniqlanmadi. /start ni qayta yuboring."
        )

    # ===================== AGAR RO‘YXATDAN O‘TMAGAN BO‘LSA =====================
    # Direct HEMIS Login (Unified Auth)
    await state.set_state(AuthStates.entering_hemis_login)
    await message.answer(
        "👋 <b>Assalomu alaykum!</b>\n\n"
        "Tizimga kirish uchun <b>HEMIS login</b>ingizni yozib yuboring:",
        parse_mode="HTML"
    )


# =====================================================================
#                       ROLE → STAFF (XODIM)
# =====================================================================
# =====================================================================
#                     LOGOUT / EXIT
# =====================================================================
@router.message(CommandStart(deep_link=False, magic=F.text == "/exit"))
async def cmd_exit_start(message: Message, state: FSMContext, session: AsyncSession):
    await cmd_exit(message, state, session)

from aiogram.filters import Command
@router.message(Command("exit"))
async def cmd_exit(message: Message, state: FSMContext, session: AsyncSession):
    await state.clear()
    
    # Check link
    account = await session.scalar(select(TgAccount).where(TgAccount.telegram_id == message.from_user.id))
    if account:
        # We can either delete account or just unlink. 
        # For safety/cleanliness, we delete the link.
        await session.delete(account)
        await session.commit()
        await message.answer("✅ <b>Muvaffaqiyatli chiqildi.</b>\n\nQayta kirish uchun /start ni bosing.", parse_mode="HTML")
    else:
        await message.answer("Siz oldin tizimga kirmagansiz.", parse_mode="HTML")

# =====================================================================
#                       ROLE → STAFF (XODIM)
# =====================================================================
# Removed Role Handlers
# =====================================================================
#                       XODIM → JSHSHIR KIRITISH (UNUSED)
# =====================================================================


# =====================================================================
#                       XODIM → JSHSHIR KIRITISH
# =====================================================================
@router.message(AuthStates.entering_jshshir)
async def process_jshshir(message: Message, state: FSMContext, session: AsyncSession):

    jshshir = (message.text or "").strip()

    if not (jshshir.isdigit() and len(jshshir) == 14):
        return await message.answer(
            "❌ JSHSHIR formati noto‘g‘ri.\nQayta urinib ko‘ring:",
            reply_markup=get_retry_or_home_kb()
        )

    staff = await session.scalar(select(Staff).where(Staff.jshshir == jshshir))

    if not staff or not staff.is_active:
        return await message.answer(
            "❌ Ushbu JSHSHIR bo‘yicha faol xodim topilmadi.",
            reply_markup=get_retry_or_home_kb()
        )

    # Staff -> TgAccount mavjudmi?
    linked = await session.scalar(
        select(TgAccount).where(TgAccount.staff_id == staff.id)
    )

    if linked and linked.telegram_id != message.from_user.id:
        return await message.answer("⚠️ Bu JSHSHIR boshqa Telegramga ulangan!")

    # Rol aniqlanadi
    role = (
        StaffRole.OWNER.value
        if message.from_user.id == OWNER_TELEGRAM_ID
        else staff.role
    )

    # FSM ga saqlash
    await state.update_data(staff_id=staff.id, role=role)
    await state.set_state(AuthStates.entering_phone)

    await message.answer(
        f"✅ <b>{staff.full_name}</b>\n"
        f"Lavozim: <b>{role}</b>\n\n"
        "📱 Iltimos, faol telefon raqamingizni kiriting.\n"
        "Format: <code>+998XXXXXXXXX</code>",
        parse_mode="HTML"
    )


# =====================================================================
#                     TALABA → HEMIS LOGIN KIRITISH
# =====================================================================
@router.message(AuthStates.entering_hemis_login)
async def process_hemis(message: Message, state: FSMContext, session: AsyncSession):

    hemis = (message.text or "").strip()

    student = await session.scalar(
        select(Student).where(Student.hemis_login == hemis)
    )

    if not student:
        # AGAR BAZADA YO'Q BO'LSA - HEMIS TIZIMIDAN TEKSHIRAMIZ
        # Buning uchun parolini so'raymiz
        await state.update_data(hemis_login=hemis)
        await state.set_state(AuthStates.entering_hemis_password)
        return await message.answer(
            "🔑 <b>HEMIS Parolini Kiriting</b>\n\n"
            "Tizimga kirish uchun parolingizni yozib yuboring:\n"
            "(Parol faqat bir marta tekshirish uchun ishlatiladi)",
            reply_markup=get_retry_or_home_kb()
        )

    linked = await session.scalar(
        select(TgAccount).where(TgAccount.student_id == student.id)
    )

    if linked and linked.telegram_id != message.from_user.id:
        return await message.answer(
            "⚠️ Ushbu HEMIS boshqa foydalanuvchiga ulangan!"
        )

    # Tasdiqlash oynasi
    await state.update_data(student_id=student.id)
    await state.set_state(AuthStates.confirm_data)

    await message.answer(
        f"👤 <b>{student.full_name}</b>\n"
        f"🎓 HEMIS: <b>{student.hemis_login}</b>\n"
        "Ma’lumotlar to‘g‘rimi?",
        parse_mode="HTML",
        reply_markup=get_data_confirmation_keyboard()
    )






# =====================================================================
#                     TALABA → HEMIS PAROL (AGAR LOGIN YO'Q BO'LSA)
# =====================================================================
@router.message(AuthStates.entering_hemis_password)
async def process_hemis_password(message: Message, state: FSMContext, session: AsyncSession):
    password = (message.text or "").strip()
    data = await state.get_data()
    login = data.get("hemis_login")

    # HEMIS tekshirish
    from services.hemis_service import HemisService
    logger.info(f"Process HEMIS Auth for {login}...")
    token, error_msg = await HemisService.authenticate(login, password)

    if not token:
        # Show specific error from HEMIS
        msg_text = (
            f"❌ <b>Xatolik yuz berdi!</b>\n"
            f"Sababi: <i>{error_msg}</i>\n\n"
            "Iltimos, qaytadan urinib ko‘ring."
        )
        return await message.answer(
            msg_text,
            reply_markup=get_retry_or_home_kb(),
            parse_mode="HTML"
        )

    # Ma'lumotlarni olish
    logger.info(f"Fetching profile for {login}...")
    me = await HemisService.get_me(token)
    if not me:
         logger.warning(f"Profile fetch failed for {login}")
         return await message.answer("❌ HEMIS ma'lumotlarini yuklab bo'lmadi.")

    h_id = str(me.get("id", ""))
    full_name = f"{me.get('firstname', '')} {me.get('lastname', '')} {me.get('fathername', '')}".strip()
    
    # Extract extra details
    uni_name = None
    uni_data = me.get("university")
    if isinstance(uni_data, dict):
        uni_name = uni_data.get("name")
    elif isinstance(uni_data, str):
        uni_name = uni_data
    
    # Faculty or Department (handling both cases)
    fac_name = None
    if isinstance(me.get("faculty"), dict):
        fac_name = me["faculty"].get("name")
    elif isinstance(me.get("department"), dict):
        fac_name = me["department"].get("name")
    elif isinstance(me.get("department"), str): # API Docs example showed string
        fac_name = me.get("department")

    # --- Extended Profile Extraction ---
    short_name = me.get("short_name", "").title()
    image_url = me.get("image")
    
    level_name = me.get("level", {}).get("name") if isinstance(me.get("level"), dict) else None
    semester_name = me.get("semester", {}).get("name") if isinstance(me.get("semester"), dict) else None
    
    # Specialty
    specialty_name = me.get("specialty", {}).get("name") if isinstance(me.get("specialty"), dict) else None

    # Education Details
    education_form = me.get("educationForm", {}).get("name") if isinstance(me.get("educationForm"), dict) else None
    education_type = me.get("educationType", {}).get("name") if isinstance(me.get("educationType"), dict) else None
    payment_form = me.get("paymentForm", {}).get("name") if isinstance(me.get("paymentForm"), dict) else None
    student_status = me.get("studentStatus", {}).get("name") if isinstance(me.get("studentStatus"), dict) else None
    
    # Contact
    email = me.get("email")
    province_name = me.get("province", {}).get("name") if isinstance(me.get("province"), dict) else None
    district_name = me.get("district", {}).get("name") if isinstance(me.get("district"), dict) else None
    accommodation_name = me.get("accommodation", {}).get("name") if isinstance(me.get("accommodation"), dict) else None
    
    # --- Try Fetching Absence (Davomat) ---
    missed_hours = 0
    try:
        # Semester kodini olish (Masalan '11' yoki '2024-2025-1')
        sem_code = None
        if "semester" in me and isinstance(me["semester"], dict):
            sem_code = me["semester"].get("code")
            # Fallback: ba'zan ID ham ishlashi mumkin
            if not sem_code:
                sem_code = me["semester"].get("id")
        
        # Yangi method Endi PNFL so'ramaydi, Token + Semester Code yetadi
        usage_hours = await HemisService.get_student_absence(token, semester_code=str(sem_code) if sem_code else None)
        # Handle Tuple return (total, excused, unexcused)
        if isinstance(usage_hours, tuple) or isinstance(usage_hours, list):
            missed_hours = usage_hours[0]
        else:
            missed_hours = int(usage_hours)
    except Exception as e:
        logger.error(f"Absence fetch error: {e}")
        missed_hours = 0
    # --------------------------------------

    # --- ROLE DETECTION ---
    user_type = me.get("type", "student")
    roles = me.get("roles", [])
    
    # Debug roles
    logger.info(f"User {login} Roles: {roles} Type: {user_type}")

    detected_role = None

    if user_type == "employee" or me.get("employee_id_number"):
        for r in roles:
            r_obj = r if isinstance(r, dict) else {"name": str(r), "code": str(r)}
            code = str(r_obj.get("code", "")).lower()
            name = r_obj.get("name", "").lower()
            
            # 1. Tyutor
            if code == "tutor" or "tyutor" in name or "murabbiy" in name:
                detected_role = "tyutor"
                break
            
            # 2. Dekanat (Dean)
            if code == "dean" or "dekan" in name:
                 detected_role = "dekanat" # Or specific DEKAN
                 # break ? Maybe Tutor has priority if multiple roles? 
                 # Usually users have one primary role context in login?
    
    if detected_role == "tyutor":
        # --- HANDLE TUTOR / STAFF REGISTRATION ---
        # 1. Create/Update Staff
        # Use 'employee_id_number' as JSHSHIR? Or just login/hemis_id?
        # Staff model uses JSHSHIR as unique. HEMIS might give it in 'pinfl' or similar.
        pinfl = me.get("pinfl") or me.get("passport_pin") or me.get("login") # Fallback to login if no PINFL
        
        staff = await session.scalar(select(Staff).where(Staff.hemis_login == login)) # Using login as unique identifier if possible
        if not staff:
             # Try finding by JSHSHIR/PINFL
             if pinfl and len(str(pinfl)) == 14:
                 staff = await session.scalar(select(Staff).where(Staff.jshshir == pinfl))
        
        if not staff:
            staff = Staff(
                full_name=full_name,
                jshshir=pinfl if pinfl and len(str(pinfl)) == 14 else None,
                hemis_login=login,
                role=StaffRole.TYUTOR.value,
                position="Tyutor",
                phone=me.get("phone"),
                is_active=True
            )
            session.add(staff)
            await session.commit()
            await session.refresh(staff)
        else:
            # Update Staff info
            staff.hemis_login = login
            staff.full_name = full_name
            staff.is_active = True
            await session.commit()

        # 2. Link TgAccount
        account = await session.scalar(select(TgAccount).where(TgAccount.telegram_id == message.from_user.id))
        if not account:
            account = TgAccount(telegram_id=message.from_user.id, staff_id=staff.id, current_role=StaffRole.TYUTOR.value)
            session.add(account)
        else:
            account.staff_id = staff.id
            account.student_id = None # Clear student link if exists
            account.current_role = StaffRole.TYUTOR.value
        
        await session.commit()
        await state.clear()
        
        return await message.answer(
            f"🎓 <b>Assalomu alaykum, {staff.full_name}!</b>\n"
            "Siz <b>Tyutor</b> sifatida tizimga kirdingiz.",
            reply_markup=get_tutor_main_menu_kb(),
            parse_mode="HTML"
        )
        # ------------------------------------------

    # Talabani yaratish yoki topish
    student = await session.scalar(select(Student).where(Student.hemis_login == login))
    
    if not student:
        student = Student(
            full_name=full_name or "Talaba",
            hemis_login=login,
            hemis_id=h_id,
            university_name=uni_name,
            faculty_name=fac_name,
            specialty_name=specialty_name, # New
            short_name=short_name,
            image_url=image_url,
            level_name=level_name,
            semester_name=semester_name,
            education_form=education_form,
            education_type=education_type,
            payment_form=payment_form,
            student_status=student_status,
            email=email,
            province_name=province_name,
            district_name=district_name,
            accommodation_name=accommodation_name,
            missed_hours=missed_hours,
            hemis_token=token,
            hemis_password=password # Saving password for shared auth
        )
        if "group" in me and isinstance(me["group"], dict):
            student.group_number = me["group"].get("name")
        if "phone" in me:
            student.phone = me["phone"]
            
        session.add(student)
        await session.commit()
        await session.refresh(student)
    else:
        # Yangilash
        has_changes = False
        if h_id and student.hemis_id != h_id:
            student.hemis_id = h_id
            has_changes = True
        
        # Ismni yangilash
        if full_name and student.full_name != full_name:
            student.full_name = full_name
            has_changes = True

        # Universitet / Fakultet yangilash
        if uni_name and student.university_name != uni_name:
            student.university_name = uni_name
            has_changes = True
        if fac_name and student.faculty_name != fac_name:
             student.faculty_name = fac_name
             has_changes = True

        # --- Extended Profile Update ---
        for key, val in [
            ("short_name", short_name), ("image_url", image_url), 
            ("level_name", level_name), ("semester_name", semester_name),
            ("specialty_name", specialty_name), # New
            ("education_form", education_form), ("education_type", education_type),
            ("payment_form", payment_form), ("student_status", student_status),
            ("email", email), ("province_name", province_name),
            ("district_name", district_name), ("accommodation_name", accommodation_name),
            ("missed_hours", missed_hours), ("hemis_token", token),
            ("hemis_password", password) # Ensure password is up to date
        ]:
            if val is not None and getattr(student, key) != val: # is not None check for int 0 case
                setattr(student, key, val)
                has_changes = True
        # -------------------------------
             
        if has_changes:
             await session.commit()

    # TgAccount bog'lash
    account = await session.scalar(
        select(TgAccount).where(TgAccount.telegram_id == message.from_user.id)
    )

    if not account:
        account = TgAccount(
            telegram_id=message.from_user.id,
            student_id=student.id,
            current_role="student"
        )
        session.add(account)
    else:
        account.student_id = student.id
        account.current_role = "student"
    
    await session.commit()
    await state.clear()

    # Check led clubs
    led_clubs = []
    if account.staff_id:
        led_clubs = (await session.execute(select(Club).where(Club.leader_id == account.staff_id))).scalars().all()

    await message.answer(
        f"✅ <b>Tabriklaymiz, {student.full_name}!</b>\n"
        "Siz tizimga muvaffaqiyatli ulandingiz.",
        reply_markup=get_student_main_menu_kb(led_clubs=led_clubs),
        parse_mode="HTML"
    )


# =====================================================================
#                 TALABA → TASDIQLASH → RO‘YXATDAN O‘TKAZISH
# =====================================================================
@router.callback_query(AuthStates.confirm_data, F.data == "confirm_yes")
async def confirm_yes(call: CallbackQuery, state: FSMContext, session: AsyncSession):

    data = await state.get_data()
    student = await session.get(Student, data["student_id"])

    # FSM ga saqlash
    await state.update_data(student_id=student.id)
    await state.set_state(AuthStates.entering_phone)

    await call.message.edit_text(
        f"✅ <b>{student.full_name}</b>\n"
        f"HEMIS: <b>{student.hemis_login}</b>\n\n"
        "📱 Iltimos, faol telefon raqamingizni kiriting.\n"
        "Format: <code>+998XXXXXXXXX</code>",
        parse_mode="HTML"
    )
    await call.answer()


@router.callback_query(AuthStates.confirm_data, F.data == "confirm_no")
async def confirm_no(call: CallbackQuery, state: FSMContext):
    await state.set_state(AuthStates.entering_hemis_login)
    await call.message.edit_text("❗️ HEMIS loginini qayta yuboring.")
    await call.answer()


# =====================================================================
#                     RETRY / HOME tugmalari
# =====================================================================
@router.callback_query(F.data == "retry")
async def retry(call: CallbackQuery, state: FSMContext):
    await state.set_state(AuthStates.choosing_role)
    await call.message.edit_text("Rolni qayta tanlang:")
    await call.message.answer("Rol:", reply_markup=get_start_role_inline_kb())
    await call.answer()


# =====================================================================
#                 TELEFON RAQAMINI QABUL QILISH VA VALIDATSIYA
# =====================================================================
@router.message(AuthStates.entering_phone)
async def process_phone(message: Message, state: FSMContext, session: AsyncSession):
    phone = (message.text or "").strip()
    
    # Validatsiya: +998 bilan boshlanishi va 13 ta belgi bo'lishi kerak
    if not (phone.startswith("+998") and len(phone) == 13 and phone[1:].isdigit()):
        return await message.answer(
            "❌ Telefon raqami formati noto'g'ri.\n"
            "To'g'ri format: <code>+998XXXXXXXXX</code>\n\n"
            "Qayta kiriting:",
            parse_mode="HTML"
        )
    
    data = await state.get_data()
    
    # XODIM uchun
    if "staff_id" in data:
        staff_id = data["staff_id"]
        role = data["role"]
        
        # TgAccount yaratish yoki yangilash
        account = await session.scalar(
            select(TgAccount).where(TgAccount.telegram_id == message.from_user.id)
        )
        
        if not account:
            account = TgAccount(
                telegram_id=message.from_user.id,
                staff_id=staff_id,
                current_role=role
            )
            session.add(account)
        else:
            account.staff_id = staff_id
            account.current_role = role
        
        # Xodim telefonini yangilash
        staff = await session.get(Staff, staff_id)
        if staff:
            staff.phone = phone
            session.add(staff)
        
        await session.commit()
        await state.clear()
        
        # OWNER
        if role == StaffRole.OWNER.value:
            text = await get_owner_dashboard_text(session)
            return await message.answer(
                text,
                reply_markup=get_owner_main_menu_inline_kb(),
                parse_mode="HTML"
            )
        
        # Rahbariyat
        if staff.position:
            greeting = f"Assalomu alaykum, {staff.position} {staff.full_name}!"
        else:
            greeting = f"Assalomu alaykum, {staff.full_name}!"
            
        # Rahbariyat
        if role == StaffRole.RAHBARIYAT.value:
            return await message.answer(
                f"🏢 <b>{greeting}</b>\n\n"
                "Rahbariyat paneliga xush kelibsiz.",
                reply_markup=get_rahbariyat_main_menu_kb(),
                parse_mode="HTML"
            )
        
        # Dekanat
        if role == StaffRole.DEKANAT.value:
            return await message.answer(
                f"🏛 <b>{greeting}</b>\n\n"
                "Dekanat paneliga xush kelibsiz.",
                reply_markup=get_dekanat_main_menu_kb(),
                parse_mode="HTML"
            )
        
        # Tyutor
        if role == StaffRole.TYUTOR.value:
            return await message.answer(
                f"🎓 <b>{greeting}</b>\n\n"
                "Tyutor paneliga xush kelibsiz.",
                reply_markup=get_tutor_main_menu_kb(),
                parse_mode="HTML"
            )
    
    # TALABA uchun
    elif "student_id" in data:
        student_id = data["student_id"]
        
        # TgAccount yaratish yoki yangilash
        account = await session.scalar(
            select(TgAccount).where(TgAccount.telegram_id == message.from_user.id)
        )
        
        if not account:
            account = TgAccount(
                telegram_id=message.from_user.id,
                student_id=student_id,
                current_role="student"
            )
            session.add(account)
        else:
            account.student_id = student_id
            account.current_role = "student"
        
        # Talaba telefonini yangilash
        student = await session.get(Student, student_id)
        if student:
            student.phone = phone
            session.add(student)
        
        await session.commit()
        await state.clear()
        
        # Check for Led Clubs
        led_clubs = []
        if account.staff_id: # If account has staff link (rare for new student login unless manual DB edit, but robust)
             led_clubs = (await session.execute(select(Club).where(Club.leader_id == account.staff_id))).scalars().all()

        display_name = student.short_name or student.full_name
        await message.answer(
            f"🎉 <b>Xush kelibsiz, {display_name}!</b>\n"
            "Siz tizimga muvaffaqiyatli kirdingiz.\n\n"
            "Quyidagilardan birini tanlang:",
            reply_markup=get_student_main_menu_kb(led_clubs=led_clubs),
            parse_mode="HTML"
        )
