
from datetime import datetime, timedelta
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from database.models import (
    University, Faculty, Staff, Student, 
    TgAccount, UserActivity, UserActivityImage, 
    UserDocument, StudentFeedback, UserAppeal
)

async def get_owner_dashboard_text(session: AsyncSession) -> str:
    """
    Owner paneli uchun statistik ma'lumotlarni yig'ib,
    tayyor matn ko'rinishida qaytaradi.
    """
    now = datetime.utcnow()
    day_ago = now - timedelta(days=1)
    month_ago = now - timedelta(days=30)
    
    # 1. Total Counts
    total_uni = await session.scalar(select(func.count(University.id))) or 0
    total_fac = await session.scalar(select(func.count(Faculty.id))) or 0
    total_staff = await session.scalar(select(func.count(Staff.id))) or 0
    total_students = await session.scalar(select(func.count(Student.id))) or 0
    
    # 2. Telegram Accounts (Verified Users)
    total_tg = await session.scalar(select(func.count(TgAccount.id))) or 0
    
    # 3. DAU / MAU (Active Users)
    dau = await session.scalar(select(func.count(TgAccount.id)).where(TgAccount.last_active >= day_ago)) or 0
    mau = await session.scalar(select(func.count(TgAccount.id)).where(TgAccount.last_active >= month_ago)) or 0
    
    # 4. Activities
    total_acts = await session.scalar(select(func.count(UserActivity.id))) or 0
    pending_acts = await session.scalar(select(func.count(UserActivity.id)).where(UserActivity.status == 'pending')) or 0
    
    # 5. Content (Files/Images)
    total_imgs = await session.scalar(select(func.count(UserActivityImage.id))) or 0
    total_docs = await session.scalar(select(func.count(UserDocument.id))) or 0
    
    # 6. Feedback / Appeals
    total_feedback = await session.scalar(select(func.count(StudentFeedback.id))) or 0
    total_appeals = await session.scalar(select(func.count(UserAppeal.id))) or 0

    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    week_start = now - timedelta(days=7)
    month_start = now - timedelta(days=30)

    # 7. Request Stats (So'rovlar) - "Business Transactions"
    # Activities + Feedbacks + Appeals + Documents + TyutorLogs (if imported)
    
    # Helper for counting table rows after date
    async def count_after(model, date_field, start_date):
        return await session.scalar(select(func.count(model.id)).where(date_field >= start_date)) or 0

    req_today = (
        await count_after(UserActivity, UserActivity.created_at, today_start) +
        await count_after(StudentFeedback, StudentFeedback.created_at, today_start) +
        await count_after(UserAppeal, UserAppeal.created_at, today_start)
    )
    
    req_week = (
        await count_after(UserActivity, UserActivity.created_at, week_start) +
        await count_after(StudentFeedback, StudentFeedback.created_at, week_start) +
        await count_after(UserAppeal, UserAppeal.created_at, week_start)
    )
    
    req_month = (
        await count_after(UserActivity, UserActivity.created_at, month_start) +
        await count_after(StudentFeedback, StudentFeedback.created_at, month_start) +
        await count_after(UserAppeal, UserAppeal.created_at, month_start)
    )

    # Total requests (approximate sum of all main tables)
    req_total = total_acts + total_feedback + total_appeals

    text = (
        f"🏛 <b>Owner Boshqaruv Paneli</b>\n\n"
        f"📊 <b>So'rovlar (Requests):</b>\n"
        f"• Bugun: <b>{req_today}</b>\n"
        f"• Bu hafta: <b>{req_week}</b>\n"
        f"• Bu oy: <b>{req_month}</b>\n"
        f"• Jami: <b>{req_total}</b>\n\n"

        f"👥 <b>Foydalanuvchilar:</b>\n"
        f"• Talabalar: <b>{total_students}</b>\n"
        f"• Xodimlar: <b>{total_staff}</b>\n"
        f"• Bot foydalanuvchilari: <b>{total_tg}</b>\n\n"
        
        f"📈 <b>Faollik (Activity):</b>\n"
        f"• DAU (24s): <b>{dau}</b>\n"
        f"• MAU (30k): <b>{mau}</b>\n\n"
        
        f"🏫 <b>Tizim:</b>\n"
        f"• OTMlar: <b>{total_uni}</b>\n"
        f"• Fakultetlar: <b>{total_fac}</b>\n\n"
        
        f"📂 <b>Kontent:</b>\n"
        f"• Faolliklar: <b>{total_acts}</b> (Kutilmoqda: {pending_acts})\n"
        f"• Rasmlar/Fayllar: <b>{total_imgs + total_docs}</b>\n"
        f"• Murojaatlar: <b>{total_feedback + total_appeals}</b>"
    )
    
    return text
