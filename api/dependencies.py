from fastapi import Header, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from database.db_connect import AsyncSessionLocal
from database.models import TgAccount, Student

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session


async def get_current_user_token_data(authorization: str = Header(None)):
    """
    Parses token. Returns dict: {"type": "telegram"|"student", "id": int}
    """
    import logging
    logger = logging.getLogger(__name__)
    if not authorization:
        logger.warning(f"Auth failed: Missing Authorization header")
        raise HTTPException(status_code=401, detail="Missing Authorization Header")
    
    logger.info(f"Checking auth header: {authorization[:25]}...")
    token = authorization.replace("Bearer ", "")
    
    if token.startswith("jwt_token_for_"):
        try:
            tid = int(token.replace("jwt_token_for_", ""))
            return {"type": "telegram", "id": tid}
        except:
             pass

    if token.startswith("student_id_"):
        try:
            sid = int(token.replace("student_id_", ""))
            return {"type": "student", "id": sid}
        except:
            pass
            
    logger.error(f"Auth failed: Invalid Token Format: {authorization[:25]}")
    raise HTTPException(status_code=401, detail="Invalid Token Format")

async def get_current_user_id(token_data: dict = Depends(get_current_user_token_data)):
    # Legacy support if needed, but better to use token_data directly
    return token_data["id"]

async def get_current_student(
    token_data: dict = Depends(get_current_user_token_data),
    db: AsyncSession = Depends(get_db)
):
    if token_data["type"] == "telegram":
        # Lookup via TgAccount
        tg_acc = await db.scalar(select(TgAccount).where(TgAccount.telegram_id == token_data["id"]))
        if not tg_acc or not tg_acc.student_id:
            raise HTTPException(status_code=404, detail="Student not found (TG)")
        student = await db.get(Student, tg_acc.student_id)
    else:
        # Direct Student ID
        student = await db.get(Student, token_data["id"])

    if not student:
        raise HTTPException(status_code=404, detail="Student profile not found")
        
    return student
