import asyncio
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from database.db_connect import AsyncSessionLocal
from database.models import UserActivity, UserActivityImage, Student

async def check_activity():
    async with AsyncSessionLocal() as session:
        # Find activity by name 'somethings'
        query = select(UserActivity).where(UserActivity.name.ilike("%tewt%")).options(selectinload(UserActivity.images)).limit(1)
        result = await session.execute(query)
        activity = result.scalar_one_or_none()

        if activity:
            print(f"✅ Activity Found: ID={activity.id}, Name='{activity.name}'")
            print(f"📸 Images Count: {len(activity.images)}")
            for img in activity.images:
                print(f"   - Image ID: {img.id}, File ID: {img.file_id}")
        else:
            print("❌ Activity 'somethings' not found.")

if __name__ == "__main__":
    asyncio.run(check_activity())
