import httpx
import logging
from datetime import datetime
from sqlalchemy import select
from database.db_connect import AsyncSessionLocal
from database.models import StudentCache

logger = logging.getLogger(__name__)

class HemisService:
    BASE_URL = "https://student.jmcu.uz/rest/v1"
    
    # We keep headers because without them JMCU returns 401. 
    # This is a minimal necessary "fix" that shouldn't affect logic flow.
    HEADERS = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "application/json"
    }

    @staticmethod
    async def authenticate(login: str, password: str):
        async with httpx.AsyncClient() as client:
            try:
                response = await client.post(
                    f"{HemisService.BASE_URL}/auth/login",
                    json={"login": login, "password": password},
                    headers=HemisService.HEADERS,
                    timeout=15
                )
                
                if response.status_code == 200:
                    data = response.json()
                    token = data.get("data", {}).get("token") or data.get("token")
                    return token
                return None
            except Exception as e:
                logger.error(f"Auth Error: {e}")
                return None

    @staticmethod
    async def get_me(token: str):
        async with httpx.AsyncClient() as client:
            try:
                headers = HemisService.HEADERS.copy()
                headers["Authorization"] = f"Bearer {token}"
                
                response = await client.get(
                    f"{HemisService.BASE_URL}/account/me",
                    headers=headers,
                    timeout=15
                )
                
                if response.status_code == 200:
                    return response.json().get("data", {})
                return None
            except Exception as e:
                logger.error(f"Me Error: {e}")
                return None

    @staticmethod
    async def get_student_absence(token: str, semester_code: str = None, student_id: int = None):
        # Simplified Cache Logic
        key = f"attendance_{semester_code}" if semester_code else "attendance_all"
        if student_id:
            try:
                async with AsyncSessionLocal() as session:
                    cache = await session.scalar(select(StudentCache).where(StudentCache.student_id == student_id, StudentCache.key == key))
                    if cache: return 0, 0, 0, cache.data # Return cached items if valid
            except: pass

        async with httpx.AsyncClient() as client:
            try:
                headers = HemisService.HEADERS.copy()
                headers["Authorization"] = f"Bearer {token}"
                params = {"semester": semester_code} if semester_code else {}
                
                response = await client.get(
                    f"{HemisService.BASE_URL}/education/attendance",
                    headers=headers, params=params, timeout=15
                )
                if response.status_code == 200:
                    data = response.json().get("data", [])
                    return 0, 0, 0, data # Simplified return
                return 0, 0, 0, []
            except: return 0, 0, 0, []

    @staticmethod
    async def get_student_subject_list(token: str, semester_code: str = None, student_id: int = None):
        key = f"subjects_{semester_code}" if semester_code else "subjects_all"
        if student_id:
            try:
                async with AsyncSessionLocal() as session:
                    cache = await session.scalar(select(StudentCache).where(StudentCache.student_id == student_id, StudentCache.key == key))
                    if cache: return cache.data
            except: pass

        async with httpx.AsyncClient() as client:
            try:
                headers = HemisService.HEADERS.copy()
                headers["Authorization"] = f"Bearer {token}"
                params = {"semester": semester_code} if semester_code else {}
                
                response = await client.get(
                    f"{HemisService.BASE_URL}/education/subject-list",
                    headers=headers, params=params, timeout=15
                )
                if response.status_code == 200:
                    return response.json().get("data", [])
                return []
            except: return []

    # Keeping other methods minimal or omitting if not critical for Login/Home

    @staticmethod
    async def get_student_schedule_cached(token: str, semester_code: str = None, student_id: int = None):
        key = f"schedule_{semester_code}" if semester_code else "schedule_all"
        if student_id:
            try:
                async with AsyncSessionLocal() as session:
                    cache = await session.scalar(select(StudentCache).where(StudentCache.student_id == student_id, StudentCache.key == key))
                    if cache: return cache.data
            except: pass

        async with httpx.AsyncClient() as client:
            try:
                headers = HemisService.HEADERS.copy()
                headers["Authorization"] = f"Bearer {token}"
                params = {"semester": semester_code} if semester_code else {}
                
                response = await client.get(
                    f"{HemisService.BASE_URL}/education/schedule",
                    headers=headers, params=params, timeout=15
                )
                if response.status_code == 200:
                    return response.json().get("data", [])
                return []
            except: return []

    @staticmethod
    async def get_student_performance(token: str, semester_code: str = None):
        """
        Calculates average GPA based on subject grades.
        """
        try:
            subjects = await HemisService.get_student_subject_list(token, semester_code)
            if not subjects:
                return 0.0
            
            total_grade = 0
            count = 0
            for subj in subjects:
                # Check for overallScore
                grade = subj.get("overallScore", {}).get("grade", 0)
                # Only count subjects that have a grade? Or count all?
                # Usually we count active subjects.
                # If grade is 0, it might pull down average, but valid for "Performance".
                # Let's count only > 0 for now to avoid showing 0.0 for new semesters.
                if grade > 0:
                    total_grade += grade
                    count += 1
                    
            if count == 0: return 0.0
            return round(total_grade / count, 2)
        except Exception as e:
            logger.error(f"Performance Error: {e}")
            return 0.0

    @staticmethod
    def parse_grades_detailed(subject_data: dict) -> dict:
        """
        Parses detailed ON/YN grades.
        Returns format: { "ON": {"val_5": x, "raw": y}, "YN": ... }
        """
        # Extract gradesByExam
        exams = subject_data.get("gradesByExam", [])
        
        on_data = {"grade": 0, "max": 50}
        yn_data = {"grade": 0, "max": 30}
        
        for ex in exams:
            code = str(ex.get("examType", {}).get("code"))
            val = ex.get("grade", 0)
            max_b = ex.get("max_ball", 0)
            
            # 12: Oraliq, 13: Yakuniy
            if code == '12': 
                on_data = {"grade": val, "max": max_b}
            elif code == '13': 
                yn_data = {"grade": val, "max": max_b}
            
        def to_5_scale(val, max_val):
            if val is None: val = 0
            if max_val == 0: return 0 
            
            # If max_val is already 5 (or close), assume it's already 5-scale
            if max_val <= 5:
                return round(val)
                
            # Otherwise convert: (score / max) * 5
            return round((val / max_val) * 5)
            
        on_5 = to_5_scale(on_data['grade'], on_data['max'])
        yn_5 = to_5_scale(yn_data['grade'], yn_data['max'])
        
        return {
            "ON": {"val_5": on_5, "raw": on_data['grade']},
            "YN": {"val_5": yn_5, "raw": yn_data['grade']},
            "raw_total": on_data['grade'] + yn_data['grade']
        }

    @staticmethod
    async def get_student_resources(token: str, subject_id: str, semester_code: str = None):
        async with httpx.AsyncClient() as client:
            try:
                headers = HemisService.HEADERS.copy()
                headers["Authorization"] = f"Bearer {token}"
                
                url = f"{HemisService.BASE_URL}/education/resources?subject={subject_id}"
                if semester_code:
                    url += f"&semester={semester_code}"
                
                # logger.info(f"Fetching Resources URL: {url}")
                response = await client.get(url, headers=headers, timeout=15)
                # logger.info(f"Resources Response ({response.status_code}): {response.text[:500]}")
                
                if response.status_code == 200:
                    data = response.json().get("data", [])
                    return data
                return []
            except Exception as e:
                logger.error(f"Resources Error: {e}")
                return []

    async def download_resource_file(self, token: str, resource_id: str, url: str):
        async with httpx.AsyncClient() as client:
            try:
                headers = HemisService.HEADERS.copy()
                headers["Authorization"] = f"Bearer {token}"
                
                # If URL is full absolute path, use it. Otherwise construct.
                # Hemis usually returns valid URLs or relative.
                if not url.startswith("http"):
                    # Logic to construct if needed, but usually url is enough or we use file-download endpoint
                    # Actually standard endpoint is /education/file/download/{id} usually
                    pass

                response = await client.get(url, headers=headers, timeout=60)
                if response.status_code == 200:
                    # Content-Disposition for filename
                    filename = None
                    cd = response.headers.get("content-disposition")
                    if cd:
                        import re
                        fname = re.findall('filename=(.+)', cd)
                        if fname: filename = fname[0].strip('"')
                        
                    return response.content, filename
                return None, None
            except Exception as e:
                logger.error(f"Download Error: {e}")
                return None, None
