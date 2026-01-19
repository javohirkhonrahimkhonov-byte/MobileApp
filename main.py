
import logging
import uvicorn
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from aiogram.webhook.aiohttp_server import SimpleRequestHandler, setup_application # We use this adapter for aiogram
from aiogram.types import Update

from bot import bot, dp
from config import WEBHOOK_URL, BOT_TOKEN
from database.db_connect import engine, create_tables, AsyncSessionLocal
from handlers import setup_routers
from utils.logging_config import setup_logging

# Middlewares
from middlewares.db import DbSessionMiddleware
from middlewares.subscription import SubscriptionMiddleware
from middlewares.activity import ActivityMiddleware

# Logging setup
setup_logging()
logger = logging.getLogger(__name__)

# ============================================================
#   LIFECYCLE
# ============================================================
# ============================================================
#   LIFECYCLE (WEBHOOK MODE)
# ============================================================
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    logger.info("🚀 Starting up (Webhook Mode)...")
    await create_tables()
    
    # Setup routers
    root_router = setup_routers()
    # Check if router is already registered to avoid duplicates
    if root_router not in dp.sub_routers:
        dp.include_router(root_router)
    
    await bot.set_webhook(WEBHOOK_URL, drop_pending_updates=True)
    
    yield
    
    # Shutdown
    logger.info("🛑 Shutting down...")
    await bot.session.close()

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from services.context_builder import build_student_context
from database.models import Student
from sqlalchemy import select

scheduler = AsyncIOScheduler()

async def daily_context_update():
    """Tashkent vaqti bilan 03:00-04:00 orasi (UTC 22:00-23:00)"""
    logger.info("🕛 Starting Daily AI Context Update...")
    async with AsyncSessionLocal() as session:
        # Get active students
        stmt = select(Student).where(Student.is_active == True)
        result = await session.execute(stmt)
        students = result.scalars().all()
        
        count = 0
        for student in students:
            try:
                await build_student_context(session, student.id)
                count += 1
            except Exception as e:
                logger.error(f"Context update failed for student {student.id}: {e}")
        
        await session.commit()
    logger.info(f"✅ Daily Context Update Finished. Updated {count} students.")

app = FastAPI(lifespan=lifespan)

@app.on_event("startup")
async def start_scheduler():
    # Tashkent is UTC+5. 03:30 -> 22:30 previous day UTC
    scheduler.add_job(daily_context_update, 'cron', hour=22, minute=30)
    scheduler.start()


# ============================================================
#   BOT HANDLER (WEBHOOK)
# ============================================================

dp.update.middleware(DbSessionMiddleware())
dp.message.middleware(ActivityMiddleware())
dp.callback_query.middleware(ActivityMiddleware())
dp.message.middleware(SubscriptionMiddleware())
dp.callback_query.middleware(SubscriptionMiddleware())

@app.post("/webhook/bot")
async def bot_webhook(request: Request):
    """Feed update to aiogram"""
    update = Update.model_validate(await request.json(), context={"bot": bot})
    await dp.feed_update(bot, update)
    return {"ok": True}

# ============================================================
#   API MOUNTING
# ============================================================
from api import router as api_router
from fastapi.staticfiles import StaticFiles

app.include_router(api_router, prefix="/api/v1")

# Mount Static Files (for user uploads)
import os
os.makedirs("static/uploads", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")

# ============================================================
#   MAIN
# ============================================================
# ============================================================
#   MAIN
# ============================================================
if __name__ == "__main__":
    import os
    import asyncio
    
    MODE = os.environ.get("BOT_MODE", "WEBHOOK")
    
    if MODE == "POLLING":
        logger.info("🔄 Starting in POLLING Mode (Test Server)...")
        
        async def run_polling():
            # Init DB
            await create_tables()
            
            # Setup Routers
            root_router = setup_routers()
            if root_router not in dp.sub_routers:
                dp.include_router(root_router)
                
            # Clear webhook to ensure polling works
            await bot.delete_webhook(drop_pending_updates=True)
            
            # Start
            await dp.start_polling(bot)
            
        asyncio.run(run_polling())
        
    else:
        # WEBHOOK MODE (Default)
        uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=False)
