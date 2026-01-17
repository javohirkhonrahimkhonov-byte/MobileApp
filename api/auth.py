from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from database.db_connect import get_session
from database.models import Student
from services.hemis_service import HemisService
from api.schemas import HemisLoginRequest, StudentProfileSchema
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/hemis")
@router.post("/hemis/")
async def login_via_hemis(
    creds: HemisLoginRequest,
    db: AsyncSession = Depends(get_session)
):
    # 1. AUTHENTICATE
    token = await HemisService.authenticate(creds.login, creds.password)
    
    if not token:
        raise HTTPException(status_code=401, detail="Login yoki parol noto'g'ri")
        
    # 2. GET PROFILE
    me = await HemisService.get_me(token)
    
    # DEBUG LOGGING
    import json
    logger.info(f"HEMIS RAW PROFILE REPSONSE: {json.dumps(me, indent=2)}")
    print(f"HEMIS RAW PROFILE REPSONSE: {json.dumps(me, indent=2)}") # Print to stdout for journalctl
    
    if not me:
        raise HTTPException(status_code=500, detail="Profil ma'lumotlarini olib bo'lmadi")
        
    # 3. SYNC TO DB
    h_id = str(me.get("id", ""))
    h_login = me.get("login") or creds.login
    
    # Parse Names - Expanded Logic
    first_name = me.get('firstname', '').capitalize()
    last_name = me.get('lastname', '').capitalize()
    father_name = me.get('fathername', '').capitalize()
    full_name_db = f"{last_name} {first_name} {father_name}".strip()

    # Fallback: If split fields are empty, try unified "name" or "full_name" string
    # User says: "AKRAMJONOV MUXAMMADALI ULUG'BEK O'G'LI" (Last First Middle)
    if not first_name or not last_name:
        raw_name = me.get('name') or me.get('full_name') or ""
        parts = raw_name.split()
        if len(parts) >= 2:
            # Assuming standard Uzbek format: LAST FIRST MIDDLE
            last_name = parts[0].capitalize()
            first_name = parts[1].capitalize() # This is what we want for greeting
            father_name = " ".join(parts[2:]).title()
            full_name_db = raw_name # Store original full string or reconstructed
        elif len(parts) == 1:
            first_name = parts[0].capitalize()
            full_name_db = raw_name

    logger.info(f"PARSED NAME: First={first_name}, Full={full_name_db}")

    # Helper for safe extraction
    def get_name(key):
        val = me.get(key)
        if isinstance(val, dict): return val.get('name')
        return val # specific handle if string

    # Extract Data
    uni_code = me.get("university", {}).get("code") if isinstance(me.get("university"), dict) else ""
    uni_name = get_name("university")
    
    # Custom University Mapping
    if uni_code == "jmcu" or "pedagogika" in (uni_name or "").lower():
         uni_name = "O‘zbekiston jurnalistika va ommaviy kommunikatsiyalar universiteti" # User requested exact string
    elif not uni_name:
         uni_name = "JMCU"

    fac_name = get_name("faculty")
    spec_name = get_name("specialty")
    group_num = get_name("group")
    level_name = get_name("level")
    sem_name = get_name("semester")
    edu_form = get_name("educationForm")
    edu_type = get_name("educationType")
    pay_form = get_name("paymentForm")
    st_status = get_name("studentStatus")
    image_url = me.get("image") # URL string

    result = await db.execute(select(Student).where(Student.hemis_login == h_login))
    student = result.scalar_one_or_none()
    
    if not student:
        student = Student(
            full_name=full_name_db or "Talaba",
            hemis_login=h_login,
            hemis_id=h_id,
            hemis_password=creds.password,
            hemis_token=token,
            # Profile Fields
            university_name=uni_name,
            faculty_name=fac_name,
            specialty_name=spec_name,
            group_number=group_num,
            level_name=level_name,
            semester_name=sem_name,
            education_form=edu_form,
            education_type=edu_type,
            payment_form=pay_form,
            student_status=st_status,
            image_url=image_url,
            short_name=first_name # Using short_name for First Name storage
        )
        db.add(student)
    else:
        # Update basics
        student.hemis_token = token
        student.hemis_password = creds.password 
        if full_name_db: student.full_name = full_name_db
        if h_id: student.hemis_id = h_id
        
        # Update Profile
        student.university_name = uni_name
        student.faculty_name = fac_name
        student.specialty_name = spec_name
        student.group_number = group_num
        student.level_name = level_name
        student.semester_name = sem_name
        student.education_form = edu_form
        student.education_type = edu_type
        student.payment_form = pay_form
        student.student_status = st_status
        student.image_url = image_url
        student.short_name = first_name
        
    await db.commit()
    await db.refresh(student)
    
    # Prepare response data specifically
    profile_data = StudentProfileSchema.model_validate(student).model_dump()
    profile_data['first_name'] = first_name # Explicitly add first_name to response
    
    return {
        "success": True,
        "data": {
            "token": f"student_id_{student.id}",
            "role": "student",
            "profile": profile_data
        }
    }

@router.get("/check/{uuid}")
async def check_auth(uuid: str, db: AsyncSession = Depends(get_session)):
    # Simple check placeholder - kept minimal for compatibility
    return {"status": "waiting"}
