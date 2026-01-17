from fastapi import APIRouter, HTTPException, Request, Depends
from fastapi.responses import RedirectResponse, HTMLResponse
import httpx
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession
import logging

from database.db_connect import get_session
from database.models import Student, Staff, StaffRole
from config import HEMIS_CLIENT_ID, HEMIS_CLIENT_SECRET, HEMIS_REDIRECT_URL, HEMIS_AUTH_URL, HEMIS_TOKEN_URL, BOT_USERNAME
from services.hemis_service import HemisService
from api.schemas import StudentProfileSchema # Re-use schemas

router = APIRouter(prefix="/oauth", tags=["OAuth"])
logger = logging.getLogger(__name__)

@router.get("/login")
async def oauth_login(source: str = "mobile"):
    """
    Redirects user to HEMIS OAuth Authorization Page
    source: 'mobile' (default) or 'bot'
    """
    # Use 'state' parameter to pass source
    state = source
    params = f"?response_type=code&client_id={HEMIS_CLIENT_ID}&redirect_uri={HEMIS_REDIRECT_URL}&scope=public&state={state}"
    redirect_url = f"{HEMIS_AUTH_URL}{params}"
    return RedirectResponse(redirect_url)

@router.get("/callback")
async def oauth_callback(code: str, state: str = "mobile", db: AsyncSession = Depends(get_session)):
    """
    Handles the callback from HEMIS (redirected via Nginx /authlog)
    """
    logger.info(f"OAuth Callback received code: {code}, state: {state}")
    
    # 1. Exchange Code for Access Token
    token_resp = None
    async with httpx.AsyncClient() as client:
        try:
            token_resp = await client.post(
                HEMIS_TOKEN_URL,
                data={
                    "grant_type": "authorization_code",
                    "client_id": HEMIS_CLIENT_ID,
                    "client_secret": HEMIS_CLIENT_SECRET,
                    "redirect_uri": HEMIS_REDIRECT_URL,
                    "code": code
                },
                timeout=15
            )
        except Exception as e:
            logger.error(f"OAuth Token Exchange Error: {e}")
            return HTMLResponse(content="<h1>Server bilan aloqa xatoligi (Token)</h1>", status_code=500)

    if token_resp.status_code != 200:
        logger.error(f"OAuth Token Failed: {token_resp.text}")
        return HTMLResponse(content=f"<h1>Login Xatoligi: {token_resp.status_code}</h1><p>{token_resp.text}</p>", status_code=400)

    token_data = token_resp.json()
    access_token = token_data.get("access_token")
    
    if not access_token:
         return HTMLResponse(content="<h1>Token olinmadi</h1>", status_code=400)
    
    # 2. Get User Profile with this Token
    me = await HemisService.get_me(access_token)
    if not me:
         return HTMLResponse(content="<h1>Foydalanuvchi ma'lumotlarini olib bo'lmadi</h1>", status_code=500)
         
    # 3. Save/Update User in DB (Same logic as auth.py)
    h_id = str(me.get("id", ""))
    h_login = me.get("login")
    user_type = me.get("type", "student")
    
    internal_token = ""
    role = "student"
    
    if user_type == "student":
        role = "student"
        result = await db.execute(select(Student).where(Student.hemis_login == h_login))
        student = result.scalar_one_or_none()
        
        full_name = f"{me.get('firstname', '')} {me.get('lastname', '')} {me.get('fathername', '')}".strip()
        
        if not student:
            student = Student(
                full_name=full_name,
                hemis_login=h_login,
                hemis_id=h_id,
                hemis_token=access_token,
            )
            db.add(student)
            await db.commit()
            await db.refresh(student)
        else:
            student.hemis_token = access_token
            # FORCE UPDATE info
            student.full_name = full_name
            # Also update other fields if needed, e.g. if we add university_name here later
            await db.commit()
            
        internal_token = f"student_id_{student.id}"
        
    else:
        # Staff
        role = "staff" # Generic
        from database.models import Staff
        pinfl = me.get("pinfl") or me.get("jshshir")
        
        staff = None
        if h_login:
            result = await db.execute(select(Staff).where(Staff.hemis_login == h_login))
            staff = result.scalar_one_or_none()
            
        if not staff and pinfl:
            result = await db.execute(select(Staff).where(Staff.jshshir == pinfl))
            staff = result.scalar_one_or_none()
            
        if staff:
            staff.hemis_login = h_login
            role = staff.role
            await db.commit()
            internal_token = f"staff_id_{staff.id}"
        else:
             return HTMLResponse(content="<h1>Tizimda xodim topilmadi</h1>", status_code=403)

    # 4. Return HTML
    
    if state == "bot":
        # Redirect to Telegram Bot with Deep Link
        # Format: https://t.me/BOT_USERNAME?start=login_TOKEN
        # Note: Telegram start param only allows [a-zA-Z0-9_-], no special chars.
        # internal_token format is "student_id_123", which is safe.
        
        telegram_link = f"https://t.me/{BOT_USERNAME}?start=login__{internal_token}"
        
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Login Muvaffaqiyatli</title>
            <meta http-equiv="refresh" content="0; url={telegram_link}">
            <style>
                body {{ font-family: sans-serif; text-align: center; padding: 20px; }}
                .btn {{ display: inline-block; padding: 15px 30px; background-color: #0088cc; color: white; text-decoration: none; border-radius: 5px; font-weight: bold; }}
            </style>
        </head>
        <body>
            <h1>✅ Muvaffaqiyatli!</h1>
            <p>Botga qaytayapsiz...</p>
            <a href="{telegram_link}" class="btn">Botni Ochish</a>
        </body>
        </html>
        """
        return HTMLResponse(content=html_content)
        
    else:
        # Default: Mobile App Deep Link
        redirect_uri = f"talabahamkor://login?token={internal_token}&role={role}"
        
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Login Muvaffaqiyatli</title>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body {{ font-family: sans-serif; text-align: center; padding: 20px; }}
                .btn {{ display: inline-block; padding: 15px 30px; background-color: #007bff; color: white; text-decoration: none; border-radius: 5px; font-weight: bold; }}
            </style>
        </head>
        <body>
            <h1>✅ Login Muvaffaqiyatli!</h1>
            <p>Ilovaga qaytishingiz mumkin.</p>
            
            <script>
                // Auto redirect
                window.location.href = "{redirect_uri}";
            </script>
            
            <br><br>
            <a href="{redirect_uri}" class="btn">Ilovani Ochish</a>
        </body>
        </html>
        """
        
        return HTMLResponse(content=html_content)
