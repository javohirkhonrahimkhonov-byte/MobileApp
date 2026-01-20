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
        async with httpx.AsyncClient(verify=False) as client:
            # --- TEST CREDENTIALS ---
            if login == "test_tutor" and password == "123":
                return "test_token_tutor", None
            # ------------------------

            try:
                response = await client.post(
                    f"{HemisService.BASE_URL}/auth/login",
                    json={"login": login, "password": password},
                    headers=HemisService.HEADERS,
                    timeout=15
                )
                
                # logger.info(f"Auth Response ({response.status_code}): {response.text[:200]}") # Debug Log

                if response.status_code == 200:
                    data = response.json()
                    if data.get("success") is False:
                        return None, data.get("error", "Login yoki parol noto'g'ri")
                        
                    token = data.get("data", {}).get("token") or data.get("token")
                    return token, None
                elif response.status_code == 401:
                     try:
                         data = response.json()
                         return None, data.get("error", "Login yoki parol noto'g'ri")
                     except:
                         return None, "Login yoki parol noto'g'ri"
                elif response.status_code == 404:
                     return None, "Bunday foydalanuvchi topilmadi"
                else:
                     return None, f"Server xatosi: {response.status_code}"
            except Exception as e:
                logger.error(f"Auth Error: {e}")
                return None, "Tarmoq xatoligi (SSL/Timeout)"

    @staticmethod
    async def get_me(token: str):
        # --- TEST CREDENTIALS ---
        if token == "test_token_tutor":
            return {
                "id": 99999,
                "uuid": "test-tutor-uuid",
                "type": "employee",
                "login": "test_tutor",
                "firstname": "Test",
                "lastname": "Tyutor",
                "fathername": "Admin",
                "image": "https://ui-avatars.com/api/?name=Test+Tyutor",
                "roles": [{"code": "tutor", "name": "Tyutor"}]
            }
        # ------------------------

        async with httpx.AsyncClient(verify=False) as client:
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
        
        def calculate_totals(data):
            total, excused, unexcused = 0, 0, 0
            for item in data:
                hour = item.get("hour", 2)
                total += hour
                status_code = str(item.get("absent_status", {}).get("code", "12"))
                if status_code == "11": 
                    excused += hour
                else: 
                    unexcused += hour
            return total, excused, unexcused

        if student_id:
            try:
                async with AsyncSessionLocal() as session:
                    cache = await session.scalar(select(StudentCache).where(StudentCache.student_id == student_id, StudentCache.key == key))
                    if cache: 
                        t, e, u = calculate_totals(cache.data)
                        return t, e, u, cache.data
            except: pass

        async with httpx.AsyncClient(verify=False) as client:
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
                    t, e, u = calculate_totals(data)
                    return t, e, u, data
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

        async with httpx.AsyncClient(verify=False) as client:
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

        async with httpx.AsyncClient(verify=False) as client:
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
        async with httpx.AsyncClient(verify=False) as client:
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

    @staticmethod
    async def download_resource_file(token: str, url: str):
        async with httpx.AsyncClient(verify=False) as client:
            try:
                headers = HemisService.HEADERS.copy()
                headers["Authorization"] = f"Bearer {token}"
                
                # Handle relative URLs
                if not url.startswith("http"):
                   # Basic assumption: if starts with /, append to host. 
                   # BASE_URL is https://student.jmcu.uz/rest/v1
                   # We probably need https://student.jmcu.uz + url
                   base = "https://student.jmcu.uz"
                   if not url.startswith("/"):
                       url = "/" + url
                   url = base + url

                response = await client.get(url, headers=headers, timeout=60)
                if response.status_code == 200:
                    filename = "document" # default
                    cd = response.headers.get("content-disposition")
                    if cd:
                        import re
                        fname = re.findall('filename="?([^"]+)"?', cd)
                        if fname: filename = fname[0]
                        
                    return response.content, filename
                return None, None
            except Exception as e:
                logger.error(f"Download Error: {e}")
                return None, None
