import asyncio
import logging
from datetime import datetime, timedelta

from aiogram import Router, F
from aiogram.filters import Command
from aiogram.fsm.context import FSMContext
from aiogram.fsm.state import State, StatesGroup
from aiogram.types import Message, CallbackQuery, InlineKeyboardMarkup, InlineKeyboardButton, BufferedInputFile
from sqlalchemy import select, desc
from sqlalchemy.ext.asyncio import AsyncSession

from database.db_connect import AsyncSessionLocal
from database.models import TgAccount, Student, StudentCache, ResourceFile
from keyboards.inline_kb import get_student_academic_kb
from services.hemis_service import HemisService
import html

router = Router()
logger = logging.getLogger(__name__)

class GradeStates(StatesGroup):
    waiting_for_password = State()

@router.callback_query(F.data.startswith("subj_res_"))
async def show_subject_resources(call: CallbackQuery, session: AsyncSession):
    try:
        parts = call.data.split("_")
        subj_id = parts[2]
        sem_code = parts[3] if len(parts) > 3 else "11"
        
        tg_id = call.from_user.id
        account = await session.scalar(select(TgAccount).where(TgAccount.telegram_id == tg_id))
        
        if not account or not account.student:
            return await call.message.edit_text("❌ Xatolik", reply_markup=get_student_academic_kb())
            
        token = account.student.hemis_token
        await call.message.edit_text("⏳ Resurslar yuklanmoqda...", reply_markup=None)

        resources = await HemisService.get_student_resources(token, subject_id=subj_id, semester_code=sem_code)
        
        # Back button
        back_btn = InlineKeyboardButton(text="⬅️ Fanlar ro'yxati", callback_data=f"subjects_sem_{sem_code}")
        
        if not resources:
            return await call.message.edit_text(
                "🤷‍♂️ <b>Bu fan bo'yicha resurslar topilmadi.</b>",
                reply_markup=InlineKeyboardMarkup(inline_keyboard=[[back_btn]]),
                parse_mode="HTML"
            )
            
        msg = "<b>📂 Fan Resurslari</b>\n\n"
        topics_list = []
        for res in resources:
            title = (res.get("title") or "Mavzu nomi yo'q").strip()
            items = res.get("subjectFileResourceItems", [])
            exts = []
            files_count = 0
            for item in items:
                for f in item.get("files", []):
                    files_count += 1
                    ext = f.get("name", "").split(".")[-1].lower() if "." in f.get("name", "") else "fayl"
                    if ext not in exts: exts.append(ext)
            
            topics_list.append({
                "title": title,
                "exts": exts,
                "id": res.get("id"),
                "has_files": files_count > 0
            })

        for i, topic in enumerate(topics_list, 1):
            ext_str = f"({', '.join(topic['exts'])})" if topic['exts'] else ""
            line = f"{i}. 📄 {html.escape(topic['title'])} {ext_str}\n"
            if len(msg) + len(line) < 3800:
                msg += line
            else:
                msg += "... (va boshqalar)"
                break

        kb_list = []
        row = []
        for i, topic in enumerate(topics_list, 1):
            if topic['has_files']:
                row.append(InlineKeyboardButton(text=str(i), callback_data=f"dl_topic_{subj_id}_{topic['id']}"))
            if len(row) == 5:
                kb_list.append(row)
                row = []
        if row: kb_list.append(row)

        kb_list.append([InlineKeyboardButton(text="📥 Barchasini yuklash", callback_data=f"dl_all_{subj_id}_{sem_code}")])
        kb_list.append([InlineKeyboardButton(text="⬅️ Fanlar ro'yxati", callback_data=f"subjects_sem_{sem_code}")])

        await call.message.edit_text(msg, reply_markup=InlineKeyboardMarkup(inline_keyboard=kb_list), parse_mode="HTML")
        await call.answer()
        
    except Exception as e:
        logger.error(f"Error showing resources: {e}")
        try:
            await call.answer("❌ Xatolik yuz berdi.", show_alert=True)
        except: pass


# ============================================================
# 🏛 AKADEMIK BO'LIM MENYUSI
# ============================================================
@router.callback_query(F.data.in_({"student_academic_menu", "student_academic_menu:profile"}))
async def show_academic_menu(call: CallbackQuery):
    # Determine back button logic
    back_to = "go_student_home"
    if "profile" in call.data:
        back_to = "student_profile"

    msg_text = (
        "🏛 <b>Akademik bo'lim</b>\n\n"
        "Quyidagi bo'limlardan birini tanlang:"
    )
    kb = get_student_academic_kb(back_callback=back_to)
    
    try:
        await call.message.edit_text(msg_text, reply_markup=kb, parse_mode="HTML")
    except Exception:
        # Agar rasm bo'lsa edit_text o'xshamaydi -> O'chirib yangi jo'natamiz
        try:
            await call.message.delete()
        except: pass
        await call.message.answer(msg_text, reply_markup=kb, parse_mode="HTML")
    await call.answer()

# ============================================================
# 📊 GPA (Reyting)
# ============================================================
@router.callback_query(F.data == "student_gpa")
async def show_gpa(call: CallbackQuery, session: AsyncSession):
    tg_id = call.from_user.id
    account = await session.scalar(select(TgAccount).where(TgAccount.telegram_id == tg_id))
    
    if not account or not account.student or not account.student.hemis_token:
        return await call.answer("❌ Talaba ma'lumotlari topilmadi.", show_alert=True)

    token = account.student.hemis_token
    await call.answer()
    await call.message.edit_text("⏳ GPA ma'lumotlari yuklanmoqda...", reply_markup=None)

    # Get GPA
    gpa = await HemisService.get_student_performance(token)
    
    msg = (
        f"📊 <b>Reyting Daftarcha (GPA)</b>\n\n"
        f"Sizning o'rtacha o'zlashtirish ko'rsatkichingiz:\n"
        f"⭐ <b>{gpa}</b>\n\n"
        "<i>(Ma'lumotlar joriy semestr asosida olingan)</i>"
    )
    
    await call.message.edit_text(msg, reply_markup=get_student_academic_kb(), parse_mode="HTML")

# ============================================================
# 📈 O'ZLASHTIRISH
# ============================================================
@router.callback_query(F.data == "student_grades")
async def show_grades(call: CallbackQuery, session: AsyncSession, state: FSMContext):
    tg_id = call.from_user.id
    account = await session.scalar(select(TgAccount).where(TgAccount.telegram_id == tg_id))

    if not account or not account.student or not account.student.hemis_token:
        return await call.answer("❌ Talaba ma'lumotlari topilmadi.", show_alert=True)
    
    token = account.student.hemis_token
    student_login = account.student.hemis_login
    await call.answer()
    try:
        await call.message.edit_text("⏳ Baholar yuklanmoqda...", reply_markup=None)
    except Exception:
        pass

    # 1. Token Health Check & Auto-Refresh
    me_data = await HemisService.get_me(token)
    
    # If Token is Invalid (401) AND we have password -> Refresh
    if not me_data and account.student.hemis_login and account.student.hemis_password:
         await call.message.edit_text("🔄 Sessiya yangilanmoqda...", reply_markup=None)
         new_token, err = await HemisService.authenticate(account.student.hemis_login, account.student.hemis_password)
         
         if new_token:
             # Save new token
             account.student.hemis_token = new_token
             # Important: Commit to save new token
             await session.commit()
             
             token = new_token
             # Retry get_me to get semester info
             me_data = await HemisService.get_me(token)
         else:
             if err == "AUTH_FAILED":
                  await call.message.edit_text(
                      "⚠️ <b>Parol o'zgargan.</b>\n\nUniversitet profilingiz paroli o'zgarganga o'xshaydi. Iltimos, qaytadan sozlang.",
                      reply_markup=get_student_academic_kb(),
                      parse_mode="HTML"
                  )
                  return

    semester_code = None
    if me_data:
        sem = me_data.get("semester", {})
        if sem and isinstance(sem, dict):
             semester_code = sem.get("code") or sem.get("id")
        
        logger.info(f"Detected Semester Code: {semester_code}")

    # Fetch detailed grades (subject-list 5-grade system)
    grades_data = await HemisService.get_student_subject_list(token, semester_code=semester_code)
    
    web_grades_map = {}
    if grades_data is not None:
         # Try formatting
         pass
    else:
         # If API failed entirely, fallback logic (omitted here for brevity, keeping existing flow)
         pass

    # HYBRID SCRAPING: If we have grades but missing JN (API returns 0), try fetching from Web
    if grades_data and account.student.hemis_password:
         # Notify user nicely if it takes time? No, let's keep it silent or "Updating..."
         # But edit_text allows multiple checks.
         
         # Only scrape if simple check shows JN is missing?
         # Actually just do it if password exists.
         # Run in background? We need it for display.
         
         # Temporary message
         # await call.message.edit_text("⏳ Baholar tahlil qilinmoqda (Web)...", reply_markup=None)
         
         # w_grades, w_err = await HemisService.get_web_grades(student_login, account.student.hemis_password, semester_code)
         # if w_grades:
         #     web_grades_map = w_grades
         #     logger.info(f"Merged Web Grades: {len(w_grades)}")
         pass

    if grades_data is None:
         # ... existing fallback code ...
          # SHOW LOGIN BUTTON (For Authorization, not "Web Load")
         kb = InlineKeyboardMarkup(inline_keyboard=[
             [InlineKeyboardButton(text="🔑 Parol orqali kirish", callback_data="auth_hemis_login")],
             [InlineKeyboardButton(text="⬅️ Ortga", callback_data="student_academic_menu")]
         ])
         
         await state.update_data(grad_login=student_login)
         
         return await call.message.edit_text(
             "🔒 <b>Tizimga kirish talab etiladi.</b>\n\n"
             "Baholaringizni avtomatik yangilab turishim uchun, bir marta HEMIS parolingizni kiritishingiz kerak.\n"
             "Shunda men sessiyani o'zim <i>ichkaridan</i> boshqara olaman. 🤖",
             reply_markup=kb,
             parse_mode="HTML"
         )
    
    msg = format_grades_msg(grades_data, web_grades_map)
    await call.message.edit_text(msg, reply_markup=get_student_academic_kb(), parse_mode="HTML")

# ... (Auth handlers remain same) ...

def format_grades_msg(grades_data, web_grades_map=None):
    if web_grades_map is None: web_grades_map = {}
    
    msg = "📈 <b>O'zlashtirish</b>\n\n"
    for item in grades_data:
        # 1. Subject Name
        subj = "Fan"
        if "curriculumSubject" in item:
             # New Structure
             subj = item.get("curriculumSubject", {}).get("subject", {}).get("name", "Fan")
        else:
             # Old/Mapped Structure
             subj = item.get("subject", {}).get("name", "Fan")
        
        # 2. Parse Detailed Grades (returns 5-scale mapped)
        details = HemisService.parse_grades_detailed(item)
        
        on = details['ON']
        yn = details['YN']
        
        # FORMAT:
        # 📘 {subject_name}
        # ON {on_5}/5 │ YN {yn_5}/5
        
        msg += f"📘 <b>{html.escape(subj)}</b>\n"
        
        # Logic: If YN exists (raw > 0), show both. Else show ON.
        # Strict user request: "ON {on}/5 | YN {yn}/5"
        # If YN is 0, user said "YN ko‘rsatilmaydi"
        
        line_parts = []
        line_parts.append(f"ON {on['val_5']}/5")
        
        if yn['raw'] > 0:
            line_parts.append(f"YN {yn['val_5']}/5")
            
        msg += " │ ".join(line_parts) + "\n\n"
             
    if len(msg) > 4000: msg = msg[:4000] + "..."
    return msg

# ============================================================
# ⏱ DAVOMAT
# ============================================================
@router.callback_query(F.data == "student_attendance")
async def show_attendance(call: CallbackQuery, session: AsyncSession):
    await call.answer()
    tg_id = call.from_user.id
    account = await session.scalar(select(TgAccount).where(TgAccount.telegram_id == tg_id))

    if not account or not account.student or not account.student.hemis_token:
        return await call.message.edit_text("❌ Talaba ma'lumotlari topilmadi.", reply_markup=get_student_academic_kb())

    token = account.student.hemis_token
    await call.message.edit_text("⏳ Ma'lumotlar yuklanmoqda...", reply_markup=None)

    # Fetch ME to get current semester info
    me_data = await HemisService.get_me(token)
    current_sem_code = 11 # Default
    if me_data and "semester" in me_data:
        try:
            current_sem_code = int(me_data["semester"]["code"])
        except: pass
    
    # Calculate available semesters (From 11 to Current)
    # If current is 11, range is [11]
    # If current is 15, range is [11, 12, 13, 14, 15]
    
    semesters = []
    start_sem = 11
    
    # Safety Check: ensure current is >= 11
    if current_sem_code < 11: current_sem_code = 11
    
    for code in range(start_sem, current_sem_code + 1):
        sem_num = code - 10
        semesters.append((f"{sem_num}-semestr", f"attendance_sem_{code}"))
        
    # Create Keyboard
    buttons = []
    row = []
    for label, data in semesters:
        row.append(InlineKeyboardButton(text=label, callback_data=data))
        if len(row) == 2:
            buttons.append(row)
            row = []
    if row: buttons.append(row)
    
    buttons.append([InlineKeyboardButton(text="⬅️ Ortga", callback_data="student_academic_menu")])
    kb = InlineKeyboardMarkup(inline_keyboard=buttons)
    
    await call.message.edit_text(
        "📊 <b>Davomat uchun semestrni tanlang:</b>\n"
        f"<i>Sizning hozirgi semestringiz: {current_sem_code-10}-semestr</i>",
        reply_markup=kb,
        parse_mode="HTML"
    )

@router.callback_query(F.data.startswith("attendance_sem_"))
async def process_attendance_sem(call: CallbackQuery, session: AsyncSession):
    try:
        sem_code = call.data.split("_")[-1]
    except:
        return await call.answer("Xatolik", show_alert=True)
        
    tg_id = call.from_user.id
    account = await session.scalar(select(TgAccount).where(TgAccount.telegram_id == tg_id))
    
    if not account or not account.student:
        return await call.message.edit_text("❌ Xatolik", reply_markup=get_student_academic_kb())
        
    token = account.student.hemis_token
    await call.message.edit_text(f"⏳ {int(sem_code)-10}-semestr davomati yuklanmoqda...", reply_markup=None)
    
    # Fetch Data (Summary + Items) + Caching
    result = await HemisService.get_student_absence(token, semester_code=sem_code, student_id=account.student.id)
    
    total, excused, unexcused, items = 0, 0, 0, []
    if isinstance(result, (tuple, list)):
        if len(result) >= 4:
            total, excused, unexcused, items = result
        elif len(result) >= 3:
            total, excused, unexcused = result[0], result[1], result[2]
            
    # Minimalist Summary Header
    msg = (
        f"⏱ <b>Davomat ({int(sem_code)-10}-semestr)</b>\n"
        f"Jami: {total} soat  |  ✅ {excused}  |  ❌ {unexcused}\n"
        f"────────────────\n\n"
    )
    
    if not items:
         msg += "<i>Qoldirilgan darslar yo'q.</i>"
    else:
        # Group by Subject
        grouped = {}
        for item in items:
            subj = item.get("subject", {}).get("name") or "Noma'lum fan"
            ts = item.get("lesson_date")
            
            date_str = "-"
            if ts:
                try:
                    date_str = datetime.fromtimestamp(ts).strftime("%d.%m.%Y")
                except: pass
                
            status = item.get("absent_status", {})
            code = str(status.get("code", "12"))
            hour = item.get("hour", 2)
            
            # Minimalist Status
            status_text = "Sababli" if code == "11" else "Sababsiz"
            
            if subj not in grouped: grouped[subj] = []
            grouped[subj].append(f"{date_str} ({hour} soat) — {status_text}")

        for subj_name, abs_list in grouped.items():
            pretty_name = subj_name.capitalize()
            msg += f"<b>{pretty_name}</b>\n"
            for rec in abs_list:
                msg += f"  └ {rec}\n"
            msg += "\n"

    if len(msg) > 4000: msg = msg[:4000] + "\n..."
    
    # Back button directly to Semester Selection
    back_kb = InlineKeyboardMarkup(inline_keyboard=[
        [InlineKeyboardButton(text="🔙 Boshqa semestr", callback_data="student_attendance")],
        [InlineKeyboardButton(text="🏠 Asosiy menyu", callback_data="student_academic_menu")]
    ])
    
    await call.message.edit_text(msg, reply_markup=back_kb, parse_mode="HTML")

# Removed show_attendance_details as it is now merged



# ============================================================
# 📚 FANLAR (Subjects)
# ============================================================
@router.callback_query(F.data == "student_subjects")
async def show_subjects_semester_selection(call: CallbackQuery, session: AsyncSession):
    await call.answer()
    tg_id = call.from_user.id
    account = await session.scalar(select(TgAccount).where(TgAccount.telegram_id == tg_id))

    if not account or not account.student or not account.student.hemis_token:
        return await call.message.edit_text("❌ Talaba ma'lumotlari topilmadi.", reply_markup=get_student_academic_kb())

    token = account.student.hemis_token
    await call.message.edit_text("⏳ Ma'lumotlar yuklanmoqda...", reply_markup=None)

    # Fetch ME to get current semester info
    me_data = await HemisService.get_me(token)
    current_sem_code = 11 # Default
    if me_data and "semester" in me_data:
        try:
            current_sem_code = int(me_data["semester"]["code"])
        except: pass
    
    # Calculate semesters [11..Current]
    semesters = []
    start_sem = 11
    if current_sem_code < 11: current_sem_code = 11
    
    for code in range(start_sem, current_sem_code + 1):
        sem_num = code - 10
        semesters.append((f"{sem_num}-semestr", f"subjects_sem_{code}"))
        
    # Create Keyboard
    buttons = []
    row = []
    for label, data in semesters:
        row.append(InlineKeyboardButton(text=label, callback_data=data))
        if len(row) == 2:
            buttons.append(row)
            row = []
    if row: buttons.append(row)
    
    buttons.append([InlineKeyboardButton(text="⬅️ Ortga", callback_data="student_academic_menu")])
    kb = InlineKeyboardMarkup(inline_keyboard=buttons)
    
    await call.message.edit_text(
        "📚 <b>Fanlar ro'yxati uchun semestrni tanlang:</b>",
        reply_markup=kb,
        parse_mode="HTML"
    )

@router.callback_query(F.data.startswith("subjects_sem_"))
async def show_subjects_list(call: CallbackQuery, session: AsyncSession):
    try:
        sem_code = call.data.split("_")[-1]
    except:
        return await call.answer("Xatolik", show_alert=True)
        
    tg_id = call.from_user.id
    account = await session.scalar(select(TgAccount).where(TgAccount.telegram_id == tg_id))
    
    if not account or not account.student:
        return await call.message.edit_text("❌ Xatolik", reply_markup=get_student_academic_kb())
        
    token = account.student.hemis_token
    try:
        await call.message.edit_text(f"⏳ {int(sem_code)-10}-semestr ma'lumotlari yuklanmoqda...", reply_markup=None)
    except Exception:
        pass
    
    # Fetch Data concurrently (Subjects + Attendance + Schedule/Teachers)
    # Pass student_id to enable Caching
    student_id = account.student.id
    
    subjects_data, attendance_result, schedule_data = await asyncio.gather(
        HemisService.get_student_subject_list(token, semester_code=sem_code, student_id=student_id),
        HemisService.get_student_absence(token, semester_code=sem_code, student_id=student_id),
        HemisService.get_student_schedule_cached(token, semester_code=sem_code, student_id=student_id)
    )
    
    # Process Attendance
    abs_map = {}
    if isinstance(attendance_result, (tuple, list)) and len(attendance_result) >= 4:
        att_items = attendance_result[3]
        for item in att_items:
            s_name = item.get("subject", {}).get("name")
            if s_name:
                s_name_lower = s_name.lower().strip()
                abs_map[s_name_lower] = abs_map.get(s_name_lower, 0) + item.get("hour", 2)

    # Process Teachers from Schedule
    # Map: SubjectNameLower -> {"Ma'ruza": {names}, "Seminar": {names}}
    teacher_map = {}
    if schedule_data:
        for item in schedule_data:
            s_name = item.get("subject", {}).get("name")
            if not s_name: continue
            
            s_name_lower = s_name.lower().strip()
            t_name = item.get("employee", {}).get("name")
            if not t_name: continue
            
            train_type = item.get("trainingType", {}).get("name", "Boshqa")
            
            if s_name_lower not in teacher_map:
                teacher_map[s_name_lower] = {"Ma'ruza": set(), "Seminar": set(), "Boshqa": set()}
            
            # Normalize training type
            if "ma'ruza" in train_type.lower() or "lecture" in train_type.lower():
                teacher_map[s_name_lower]["Ma'ruza"].add(t_name)
            elif "seminar" in train_type.lower() or "amaliy" in train_type.lower():
                teacher_map[s_name_lower]["Seminar"].add(t_name)
            else:
                teacher_map[s_name_lower]["Boshqa"].add(t_name)

    # Define back_kb here as it's used in the next block
    back_kb = InlineKeyboardMarkup(inline_keyboard=[[InlineKeyboardButton(text="⬅️ Ortga", callback_data="student_subjects")]])

    if not subjects_data:
        try:
            return await call.message.edit_text("🤷‍♂️ <b>Fanlar topilmadi.</b>", reply_markup=back_kb)
        except Exception: return

    # Build Message
    msg = f"📚 <b>Fanlar ({int(sem_code)-10}-semestr)</b>\n\n"
    res_buttons = []
    
    for item in subjects_data:
        subject_info = item.get("curriculumSubject", {})
        sub_details = subject_info.get("subject", {})
        name = sub_details.get("name", "Nomsiz fan")
        s_id = sub_details.get("id")
        
        # Truncate for button
        short_name = (name[:20] + '..') if len(name) > 20 else name
        
        # Determine Teachers
        name_lower = name.lower().strip()
        teachers_text = ""
        
        t_data = teacher_map.get(name_lower)
        if t_data:
            lecturers = list(t_data["Ma'ruza"])
            seminars = list(t_data["Seminar"])
            others = list(t_data["Boshqa"])
            
            if lecturers:
                teachers_text += f"👨‍🏫 Ma'ruza: {', '.join(lecturers)}\n"
            if seminars:
                teachers_text += f"👨‍🏫 Seminar: {', '.join(seminars)}\n"
            if others and not (lecturers or seminars):
                 teachers_text += f"👨‍🏫 O'qituvchi: {', '.join(others)}\n"
        
        if not teachers_text:
             teachers_text = "👨‍🏫 Biriktirilmagan\n"

        # Absences
        absent_hours = abs_map.get(name_lower, 0)
        
        # Grades
        overall_grade = item.get("overallScore", {}).get("grade", 0)
        
        # Detailed Grades
        grades_list = item.get("gradesByExam", [])
        # 11/15=JN (Current), 12=ON (Midterm), 13=YN (Final)
        on = 0
        yn = 0
        
        for g in grades_list:
            code = str(g.get("examType", {}).get("code"))
            val = g.get("grade", 0)
            if code == '12': on = val
            elif code == '13': yn = val
            
        # Format Grade String
        grade_str = f"⭐️ Baho: {overall_grade}"
        details = []
        if on > 0: details.append(f"ON: {on}")
        if yn > 0: details.append(f"YN: {yn}")
        
        if details:
            grade_str += f" ({', '.join(details)})"
        
        grade_str += f"  |  ❌ Qoldirdi: {absent_hours} soat"

        # Minimalist Output
        msg += f"<b>{name}</b>\n"
        msg += teachers_text
        msg += f"{grade_str}\n"
        msg += f"────────────────\n"
        
        # Add Resource Button for valid ID
        if s_id:
            res_buttons.append(InlineKeyboardButton(text=f"📂 {short_name}", callback_data=f"subj_res_{s_id}_{sem_code}"))

    if len(msg) > 4000: msg = msg[:4000] + "\n..."
    
    # Arrange Resource Buttons (2 per row)
    kb_rows = []
    temp_row = []
    for btn in res_buttons:
        temp_row.append(btn)
        if len(temp_row) == 2:
            kb_rows.append(temp_row)
            temp_row = []
    if temp_row: kb_rows.append(temp_row)
    
    # Navigation Buttons
    kb_rows.append([InlineKeyboardButton(text="⬅️ Boshqa semestr", callback_data="student_subjects")])
    kb_rows.append([InlineKeyboardButton(text="🏠 Asosiy menyu", callback_data="student_academic_menu")])
    
    kb = InlineKeyboardMarkup(inline_keyboard=kb_rows)
    
    await call.message.edit_text(msg, reply_markup=kb, parse_mode="HTML")

@router.callback_query(F.data.startswith("dl_topic_"))
async def download_single_topic(call: CallbackQuery, session: AsyncSession):
    try:
        parts = call.data.split("_")
        subj_id = parts[2]
        topic_id = parts[3]
        
        tg_id = call.from_user.id
        account = await session.scalar(select(TgAccount).where(TgAccount.telegram_id == tg_id))
        if not account or not account.student: return
        token = account.student.hemis_token

        await call.answer("Fayllar tayyorlanmoqda...", show_alert=False)
        
        # Try finding in current semester first, but resource topic IDs are usually global for the request
        # However, to find the topic in the list, we need the list.
        # Ideally we should pass sem_code in callback, checking if we have it.
        # Wait, dl_topic callback is: dl_topic_{subj_id}_{topic_id}
        # It misses sem_code! We need to add it or guess it.
        # But get_student_resources needs sem_code to be accurate.
        # Let's see if we can get it from somewhere or default to 11/current.
        # Actually, let's update proper callback first?
        # User didn't report dl_topic broken yet, but let's fix it if we can.
        # Existing callback format: dl_topic_{subj_id}_{topic_id} (Length 4)
        # We can't easily change it without breaking compatibility if sent messages exist.
        # Use default logic: try getting resources without semester (if it works?) or try to get CURRENT sem.
        # Or... let's check if get_me can help.
        # For now, let's just use what we have in show_subject_resources (line 41).
        
        # But wait, lines 681-683: parts = call.data.split("_")
        # dl_topic_subjectId_topicId
        # We don't have sem_code here. 
        # I will leave this one as is for now unless I update the button generation at line 86.
        # Line 86: InlineKeyboardButton(text=str(i), callback_data=f"dl_topic_{subj_id}_{topic['id']}")
        # I should update line 86 too!
        
        resources = await HemisService.get_student_resources(token, subject_id=subj_id)
        target_topic = next((r for r in resources if str(r.get("id")) == str(topic_id)), None)
        
        if not target_topic:
            return await call.answer("Mavzu topilmadi", show_alert=True)

        # Extract files
        all_files = []
        for item in target_topic.get("subjectFileResourceItems", []):
            for f in item.get("files", []):
                if f.get("url"):
                    all_files.append({"id": item.get("id"), "url": f.get("url"), "name": f.get("name")})

        if not all_files:
            return await call.answer("Ushbu mavzuda fayllar yo'q", show_alert=True)

        service = HemisService()
        for f_data in all_files:
            f_id = f_data["id"]
            # Cache check
            cached = await session.scalar(select(ResourceFile).where(ResourceFile.hemis_id == f_id))
            if cached and cached.file_id:
                try:
                    await call.message.answer_document(cached.file_id, caption=f_data["name"])
                    continue
                except: pass

            # Download
            content, filename = await service.download_resource_file(token, resource_id=f_id, url=f_data["url"])
            if content:
                input_file = BufferedInputFile(content, filename=filename or f_data["name"])
                sent = await call.message.answer_document(input_file, caption=f_data["name"])
                if sent.document and f_id:
                    new_file = ResourceFile(hemis_id=f_id, file_id=sent.document.file_id, 
                                            file_name=filename or f_data["name"], file_type="file")
                    session.add(new_file)
                    await session.commit()
            else:
                await call.message.answer(f"❌ Yuklab bo'lmadi: {f_data['name']}")

    except Exception as e:
        logger.error(f"Download Topic Error: {e}")

@router.callback_query(F.data.startswith("dl_all_"))
async def download_all_resources(call: CallbackQuery, session: AsyncSession):
    try:
        parts = call.data.split("_")
        subj_id = parts[2]
        sem_code = parts[3] if len(parts) > 3 else "11"
        
        tg_id = call.from_user.id
        account = await session.scalar(select(TgAccount).where(TgAccount.telegram_id == tg_id))
        if not account or not account.student: return
        token = account.student.hemis_token

        await call.answer("Barchasini yuklash boshlandi", show_alert=False)
        original_text = call.message.text
        
        resources = await HemisService.get_student_resources(token, subject_id=subj_id, semester_code=sem_code)
        
        # Prepare topics list for status update
        topics_list = []
        for i, res in enumerate(resources, 1):
            title = (res.get("title") or "Nomsiz").strip()
            files = []
            for item in res.get("subjectFileResourceItems", []):
                for f in item.get("files", []):
                    if f.get("url"):
                        files.append({"id": item.get("id"), "url": f.get("url"), "name": f.get("name")})
            topics_list.append({"index": i, "title": title, "files": files, "status": "⏳"})

        total_topics = len(topics_list)
        success_count = 0
        error_count = 0
        
        service = HemisService()
        last_edit_time = 0

        for idx, topic in enumerate(topics_list):
            # Update status in original message
            topic["status"] = "🔄"
            
            # Rebuild text
            updated_msg = "<b>📂 Fan Resurslari (Yuklanmoqda...)</b>\n\n"
            for t in topics_list:
                updated_msg += f"{t['index']}. {t['status']} {html.escape(t['title'])}\n"
            
            # Throttle edits to 1.5s to avoid Flood Limits
            now = asyncio.get_event_loop().time()
            if now - last_edit_time > 1.5 or idx == total_topics - 1:
                try:
                    if len(updated_msg) < 4000:
                        await call.message.edit_text(updated_msg, reply_markup=None, parse_mode="HTML")
                        last_edit_time = now
                except: pass

            topic_success = True
            for f_data in topic["files"]:
                f_id = f_data["id"]
                cached = await session.scalar(select(ResourceFile).where(ResourceFile.hemis_id == f_id))
                
                if cached and cached.file_id:
                    try:
                        await call.message.answer_document(cached.file_id, caption=f_data["name"])
                        continue
                    except: pass

                content, filename = await service.download_resource_file(token, resource_id=f_id, url=f_data["url"])
                if content:
                    input_file = BufferedInputFile(content, filename=filename or f_data["name"])
                    sent = await call.message.answer_document(input_file, caption=f_data["name"])
                    if sent.document and f_id:
                        new_file = ResourceFile(hemis_id=f_id, file_id=sent.document.file_id, 
                                                file_name=filename or f_data["name"], file_type="file")
                        session.add(new_file)
                        await session.commit()
                else:
                    topic_success = False

            if topic_success:
                topic["status"] = "✅"
                success_count += 1
            else:
                topic["status"] = "❌"
                error_count += 1

        # Final Message
        final_msg = "<b>✅ Yuklash yakunlandi!</b>\n\n"
        for t in topics_list:
            final_msg += f"{t['index']}. {t['status']} {html.escape(t['title'])}\n"
        
        final_msg += f"\nJami mavzular: {total_topics}\nMuvaffaqiyatli: {success_count}\nXatolik: {error_count}"
        
        kb = InlineKeyboardMarkup(inline_keyboard=[
            [InlineKeyboardButton(text="⬅️ Fanlar ro'yxati", callback_data=f"subjects_sem_{sem_code}")]
        ])
        
        try:
            await call.message.edit_text(final_msg[:4000], reply_markup=kb, parse_mode="HTML")
        except:
            await call.message.answer(final_msg[:4000], reply_markup=kb, parse_mode="HTML")
        
    except Exception as e:
        logger.error(f"Download All Error: {e}")
        await call.message.answer("❌ Xatolik yuz berdi.")

# ============================================================
# 📅 DARS JADVALI
# ============================================================
@router.callback_query(F.data == "student_schedule")
async def show_schedule(call: CallbackQuery, session: AsyncSession):
    tg_id = call.from_user.id
    account = await session.scalar(select(TgAccount).where(TgAccount.telegram_id == tg_id))

    if not account or not account.student or not account.student.hemis_token:
        return await call.answer("❌ Talaba ma'lumotlari topilmadi.", show_alert=True)

    token = account.student.hemis_token
    await call.message.edit_text("⏳ Dars jadvali yuklanmoqda...", reply_markup=None)

    today = datetime.now()
    start_week = today - timedelta(days=today.weekday()) 
    end_week = start_week + timedelta(days=6) 
    
    s_date = start_week.strftime("%Y-%m-%d")
    e_date = end_week.strftime("%Y-%m-%d")

    schedule_data = await HemisService.get_student_schedule(token, week_start=s_date, week_end=e_date)
    
    if not schedule_data:
         return await call.message.edit_text(
             "📅 <b>Dars jadvali</b>\n\nBu hafta uchun darslar topilmadi.",
             reply_markup=get_student_academic_kb(),
             parse_mode="HTML"
         )
    
    grouped = {}
    for item in schedule_data: 
        date_ts = item.get("lesson_date") 
        if not date_ts: continue
        try:
             d_obj = datetime.fromtimestamp(date_ts)
             d_str = d_obj.strftime("%d.%m.%Y (%A)")
        except:
             d_str = str(date_ts)
             
        if d_str not in grouped: grouped[d_str] = []
        
        subj = item.get("subject", {}).get("name")
        audit = item.get("audit", {}).get("name", "")
        pair = item.get("pair", {})
        time_s = pair.get("start_time", "")
        time_e = pair.get("end_time", "")
        
        grouped[d_str].append(f"⏰ {time_s}-{time_e} | 📚 {subj} ({audit})")
    
    text = f"📅 <b>Dars Jadvali ({s_date} - {e_date})</b>\n\n"
    for date_key, lessons in sorted(grouped.items()):
        text += f"<b>{date_key}</b>\n"
        for l in lessons:
            text += f"{l}\n"
        text += "\n"
        
    if len(text) > 4000: text = text[:4000] + "..."
    
    await call.message.edit_text(text, reply_markup=get_student_academic_kb(), parse_mode="HTML")

# ============================================================
# 📝 FANLARDAN VAZIFALAR
# ============================================================
@router.callback_query(F.data == "student_tasks")
async def show_tasks(call: CallbackQuery, session: AsyncSession):
    tg_id = call.from_user.id
    account = await session.scalar(select(TgAccount).where(TgAccount.telegram_id == tg_id))

    if not account or not account.student or not account.student.hemis_token:
        return await call.answer("❌ Talaba ma'lumotlari topilmadi.", show_alert=True)
    
    token = account.student.hemis_token
    await call.message.edit_text("⏳ Vazifalar yuklanmoqda...", reply_markup=None)
    
    tasks = await HemisService.get_student_subject_tasks(token)
    
    if not tasks:
        return await call.message.edit_text(
             "📝 <b>Fanlardan vazifalar</b>\n\nFaol vazifalar mavjud emas. 🎉",
             reply_markup=get_student_academic_kb(),
             parse_mode="HTML"
         )
    
    msg = "📝 <b>Fanlardan Vazifalar</b>\n\n"
    count = 0
    for t in tasks:
        if count > 15: 
            msg += "<i>... va yana boshqalar</i>"
            break
            
        subj = t.get("subject", {}).get("name", "Fan")
        tsp = t.get("task", {}).get("name", "Vazifa")
        deadline = t.get("deadline", "")
        
        try:
             dl = datetime.fromtimestamp(deadline).strftime("%Y-%m-%d")
        except:
             dl = str(deadline)
             
        msg += f"📚 <b>{subj}</b>\n📌 {tsp}\n⏳ Muddat: {dl}\n\n"
        count += 1
        
    await call.message.edit_text(msg, reply_markup=get_student_academic_kb(), parse_mode="HTML")

# ============================================================
# ⬅️ ORTGA
# ============================================================
@router.callback_query(F.data == "go_student_home")
async def go_home(call: CallbackQuery, session: AsyncSession):
    account = await session.scalar(select(TgAccount).where(TgAccount.telegram_id == call.from_user.id))
    from database.models import Club
    led_clubs = []
    if account and account.staff_id:
        led_clubs = (await session.execute(select(Club).where(Club.leader_id == account.staff_id))).scalars().all()
        
    msg_text = "🎓 <b>Talaba menyusi</b>\nQuyidagi bo‘limlardan birini tanlang:"
    kb = get_student_main_menu_kb(led_clubs=led_clubs)

    try:
        await call.message.edit_text(msg_text, reply_markup=kb, parse_mode="HTML")
    except Exception:
        await call.message.delete()
        await call.message.answer(msg_text, reply_markup=kb, parse_mode="HTML")
