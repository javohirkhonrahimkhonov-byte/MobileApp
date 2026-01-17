from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from sqlalchemy.orm import selectinload
from typing import List

from database.db_connect import AsyncSessionLocal
from database.models import Student, ChoyxonaPost
from api.dependencies import get_current_student, get_db
from api.schemas import PostCreateSchema, PostResponseSchema

router = APIRouter()

@router.post("/posts", response_model=PostResponseSchema)
async def create_post(
    data: PostCreateSchema,
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_db)
):
    """
    Create a new post with strict context binding.
    """
    # 1. Determine Context based on Category
    target_uni = student.university_id
    target_fac = None
    target_spec = None
    
    category = data.category_type
    
    if category == 'university':
        target_uni = student.university_id
        
    elif category == 'faculty':
        target_uni = student.university_id
        target_fac = student.faculty_id
        if not target_fac:
            raise HTTPException(status_code=400, detail="Sizda fakultet biriktirilmagan")
            
    elif category == 'specialty':
        target_uni = student.university_id
        target_fac = student.faculty_id
        target_spec = student.specialty_name
        if not target_spec:
             raise HTTPException(status_code=400, detail="Sizda mutaxassislik (yo'nalish) ma'lumoti yo'q")
    else:
         raise HTTPException(status_code=400, detail="Noto'g'ri kategoriya")
    
    # 2. Create Post
    new_post = ChoyxonaPost(
        student_id=student.id,
        content=data.content,
        category_type=category,
        target_university_id=target_uni,
        target_faculty_id=target_fac,
        target_specialty_name=target_spec
    )
    
    db.add(new_post)
    await db.commit()
    await db.refresh(new_post)
    
    # Re-fetch with author to map response
    # Or just use the student object we have
    return _map_post(new_post, student)

@router.get("/posts", response_model=List[PostResponseSchema])
async def get_posts(
    category: str = Query(..., description="university, faculty, specialty"),
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_db)
):
    """
    Get posts with strict access control filtering.
    """
    # Eager load student for author details
    query = select(ChoyxonaPost).options(selectinload(ChoyxonaPost.student)).order_by(desc(ChoyxonaPost.created_at))
    
    # 1. Category Filter (Tab Filter)
    query = query.where(ChoyxonaPost.category_type == category)
    
    # 2. Access Control (Context Filter) - LOGIC
    # User can ONLY see posts that belong to their context.
    
    if category == 'university': 
        # Show posts for my university
        query = query.where(ChoyxonaPost.target_university_id == student.university_id)
        
    elif category == 'faculty':
        # Show posts for my faculty in my university
        query = query.where(
            ChoyxonaPost.target_university_id == student.university_id,
            ChoyxonaPost.target_faculty_id == student.faculty_id
        )
        
    elif category == 'specialty':
        # Show posts for my specialty
        query = query.where(
            ChoyxonaPost.target_university_id == student.university_id,
            ChoyxonaPost.target_faculty_id == student.faculty_id,
            ChoyxonaPost.target_specialty_name == student.specialty_name
        )
        
    result = await db.execute(query)
    posts = result.scalars().all()
    
    return [_map_post(p, p.student) for p in posts]

def _map_post(post: ChoyxonaPost, author: Student):
    return PostResponseSchema(
        id=post.id,
        content=post.content,
        category_type=post.category_type,
        author_name=author.full_name if author else "Unknown",
        author_role="Talaba", 
        created_at=post.created_at,
        target_university_id=post.target_university_id,
        target_faculty_id=post.target_faculty_id,
        target_specialty_name=post.target_specialty_name
    )
