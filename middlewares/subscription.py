import logging
from typing import Callable, Dict, Any, Awaitable

from aiogram import BaseMiddleware
from aiogram.types import TelegramObject, Message, CallbackQuery, Update
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from database.models import TgAccount, University, Staff, Student

logger = logging.getLogger(__name__)


class SubscriptionMiddleware(BaseMiddleware):
    """
    Foydalanuvchi o‘z universitetining majburiy kanaliga a'zo ekanligini tekshiradi.
    Faqatgina ro'yxatdan o'tgan (TgAccount bor) foydalanuvchilar uchun ishlaydi.
    """

    async def __call__(
        self,
        handler: Callable[[TelegramObject, Dict[str, Any]], Awaitable[Any]],
        event: TelegramObject,
        data: Dict[str, Any],
    ) -> Any:

        # 1. Update turini aniqlash (Message yoki CallbackQuery)
        if isinstance(event, Message):
            user = event.from_user
            chat_id = event.chat.id
        elif isinstance(event, CallbackQuery):
            user = event.from_user
            chat_id = event.message.chat.id
        else:
            return await handler(event, data)

        if not user or user.is_bot:
            return await handler(event, data)

        session: AsyncSession = data.get("session")
        if not session:
            # Agar DB session bo'lmasa, tekshira olmaymiz (ehtimol xato)
            return await handler(event, data)

        # 2. Foydalanuvchi akkauntini topish
        # Bizga Universitet ID kerak. Uni Staff yoki Student orqali olamiz.
        stmt = (
            select(TgAccount)
            .where(TgAccount.telegram_id == user.id)
            .outerjoin(TgAccount.staff)
            .outerjoin(TgAccount.student)
            .outerjoin(Staff.university)
            .outerjoin(Student.university)
        )
        
        # Bu yerda joinlar biroz murakkab bo'lishi mumkin, oddiyroq yo'li:
        # TgAccount -> Staff -> University
        # TgAccount -> Student -> University
        # Shuning uchun Eager Loading qilishimiz kerak yoki alohida tekshirish.

        # Keling, oddiyroq select qilamiz, keyin mantiq bilan ajratamiz.
        # TgAccount o‘zi yetarli emas, chunki University ID Staff yoki Student ichida.
        
        # Lekin ORM relationship `lazy="select"` bo'lsa, sessiya ichida `account.staff.university` desa bo'ladi.
        # Asyncda lazy loading muammo bo'lishi mumkin, shuning uchun `select(TgAccount).options(...)` ishlatgan ma'qul.
        # Yoki oddiyroq: TgAccount ni olib, keyin kerakli qismini yuklaymiz.
        
        # Hozircha oddiy select, chunki models.py da relationship default (lazy) turibdi.
        # AsyncSession bilan lazy loading xato beradi (MissingGreenlet).
        # Shuning uchun options ishlatamiz.
        from sqlalchemy.orm import selectinload

        account = await session.scalar(
            select(TgAccount)
            .where(TgAccount.telegram_id == user.id)
            .options(
                selectinload(TgAccount.staff).selectinload(Staff.university),
                selectinload(TgAccount.student).selectinload(Student.university),
            )
        )


        # 3. Agar akkaunt yo'q bo'lsa -> mehmon -> tekshirmaymiz (Auth handlerlar ishlayveradi)
        if not account:
            # logger.info(f"Middleware: User {user.id} not found in TgAccount.")
            return await handler(event, data)

        # 4. Universitetni aniqlash
        university = None
        if account.staff and account.staff.university:
            university = account.staff.university
        elif account.student and account.student.university:
            university = account.student.university

        if not university:
            logger.info(f"Middleware: User {user.id} has no university linked.")
            return await handler(event, data)

        if not university.required_channel:
            # Kanal yo'q yoki universitetga birikmagan -> ruxsat
            logger.info(f"Middleware: University {university.name} ({university.id}) has no required_channel.")
            return await handler(event, data)

        channel_id_str = university.required_channel
        logger.info(f"Middleware: Checking subscription for user {user.id} to channel {channel_id_str}")

        # 5. A'zolikni tekshirish
        try:
            # Bot ob'ekti data ichida bo'ladi (aiogram 3 da)
            bot = data.get("bot")
            if not bot:
                logger.error("Middleware: Bot instance not found in data.")
                return await handler(event, data)

            member = await bot.get_chat_member(chat_id=channel_id_str, user_id=user.id)
            logger.info(f"Middleware: Chat member status for user {user.id}: {member.status}")
            
            if member.status not in ("member", "administrator", "creator"):
                # A'zo emas!
                logger.info(f"Middleware: User {user.id} is NOT a member. Blocking.")

                # Kanal havolasini topish (username yoki invite link)
                try:
                    chat_info = await bot.get_chat(channel_id_str)
                    invite_link = chat_info.invite_link
                    
                    if not invite_link and chat_info.username:
                        invite_link = f"https://t.me/{chat_info.username}"
                    
                    if not invite_link:
                        # Agar link bo'lmasa, yaratishga harakat qilamiz
                        try:
                            link_obj = await bot.create_chat_invite_link(channel_id_str, name="Bot Subscription Check")
                            invite_link = link_obj.invite_link
                        except Exception as create_err:
                            logger.warning(f"Failed to create invite link: {create_err}")
                            invite_link = "https://t.me/"  # Fallback
                            
                except Exception as e:
                    logger.error(f"Failed to get chat info for {channel_id_str}: {e}")
                    invite_link = "https://t.me/" # Fallback

                from keyboards.inline_kb import get_subscription_check_kb
                
                text = (
                    f"🚫 <b>Diqqat!</b> Botdan foydalanish uchun "
                    f"quyidagi kanalga a'zo bo'lishingiz kerak."
                )

                if isinstance(event, Message):
                    await event.answer(text, reply_markup=get_subscription_check_kb(invite_link))
                elif isinstance(event, CallbackQuery):
                    if event.data == "check_subscription":
                        await event.answer("❌ Hali ham a'zo emassiz!", show_alert=True)
                    else:
                        try:
                            await event.message.delete()
                        except:
                            pass
                        await event.message.answer(text, reply_markup=get_subscription_check_kb(invite_link))
                
                # Handlerga o'tkazmaymiz (Stop Propagation)
                return

        except Exception as e:
            # Agar bot kanalga admin bo'lmasa yoki boshqa xato -> Log yozamiz va ruxsat beramiz (Fail Open)
            logger.error(f"Subscription check failed for user {user.id}: {e}")
            return await handler(event, data)

        # 6. Agar a'zo bo'lsa -> ruxsat
        return await handler(event, data)
