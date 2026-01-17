
import asyncio
import httpx
from services.hemis_service import HemisService
from config import OPENAI_API_KEY
# from services.student_service import get_student_by_telegram_id

# Need a valid token. 
# Attempt to login using a known test user or just assume token availability if running on server with DB access.
# I will use the database to pick an active student and probe endpoints.

async def probe():
    from database.db_connect import AsyncSessionLocal
    from sqlalchemy import select
    from database.models import Student

    async with AsyncSessionLocal() as session:
        # Get a student with a token
        stmt = select(Student).where(Student.hemis_token != None).limit(1)
        result = await session.execute(stmt)
        student = result.scalar_one_or_none()
        
        if not student:
            print("No student with token found.")
            return

        token = student.hemis_token
        print(f"Probing with Student: {student.full_name} ({student.hemis_id})")

        headers = HemisService.HEADERS.copy()
        headers["Authorization"] = f"Bearer {token}"

        async with httpx.AsyncClient() as client:
            # Common endpoints for documents
            endpoints = [
                "/account/reference", # Ma'lumotnoma
                "/account/transcript", # Transkript
                "/account/contracts", # Shartnoma
                "/doc/reference-pdf",
                "/doc/transcript-pdf",
                "/student/reference",
                "/education/transcript",
                "/finance/contract"
            ]
            
            for ep in endpoints:
                url = f"{HemisService.BASE_URL}{ep}"
                try:
                    resp = await client.get(url, headers=headers)
                    print(f"GET {ep}: {resp.status_code}")
                    if resp.status_code == 200:
                        print(f"--> Content-Type: {resp.headers.get('content-type')}")
                        if "application/json" in resp.headers.get("content-type", ""):
                            print(resp.json())
                except Exception as e:
                    print(f"Error {ep}: {e}")

if __name__ == "__main__":
    asyncio.run(probe())
