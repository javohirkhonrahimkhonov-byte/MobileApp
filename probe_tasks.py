import asyncio
import json
import httpx
from services.hemis_service import HemisService

# User Token
USER_TOKEN = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJ2MVwvYXV0aFwvbG9naW4iLCJhdWQiOiJ2MVwvYXV0aFwvbG9naW4iLCJleHAiOjE3NjkxNjE4OTcsImp0aSI6IjM5NTI1MTEwMTQxMSIsInN1YiI6IjgzMDAifQ.Wxer16yq1E5eSJT7x2aLqTPRWO_TljCIkQsbEJ-2NHg"

async def main():
    print("Fetching Task List...")
    token = USER_TOKEN
    
    headers = {
        "Authorization": f"Bearer {token}",
        "X-Requested-With": "XMLHttpRequest",
        "Referer": "https://student.jmcu.uz/dashboard/tasks-list" 
    }
    
    async with httpx.AsyncClient() as client:
        # Try 1: education/task-list (Guessing pattern from subject-list)
        endpoints = [
            ("https://student.jmcu.uz/rest/v1/education/task-list", 11),
            ("https://student.jmcu.uz/rest/v1/education/task-list", 2023), # Try ID
            ("https://student.jmcu.uz/rest/v1/data/subject-task-student-list", 11)
        ]
        
        for url, sem in endpoints:
            print(f"--- Trying {url} (sem={sem}) ---")
            resp = await client.get(url, headers=headers, params={"semester": sem, "limit": 200})
            
            if resp.status_code == 200:
                 print(f"✅ SUCCESS: {url}")
                 data = resp.json().get("data", [])
                 if not data: data = resp.json().get("result", {}).get("list", [])
                 
                 print(f"Found {len(data)} tasks.")
                 
                 if len(data) > 0:
                     # Group by Subject
                     subjects = {}
                     for t in data:
                         subj_name = t.get("subject", {}).get("name", "Unknown")
                         grade = t.get("grade", 0) or 0
                         
                         if subj_name not in subjects: subjects[subj_name] = 0
                         subjects[subj_name] += grade
                    
                     print("\n--- CALCULATED JORIY (TASK SUMS) ---")
                     for s, total in subjects.items():
                         print(f"📚 {s}: {total}")
                     return 
            else:
                 print(f"❌ Failed: {resp.status_code}")

if __name__ == "__main__":
    asyncio.run(main())
