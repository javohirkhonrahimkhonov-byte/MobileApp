from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from sqlalchemy.orm import selectinload
from typing import List

from database.db_connect import AsyncSessionLocal
from database.models import Student, ChoyxonaPost, ChoyxonaPostLike, ChoyxonaPostRepost, ChoyxonaComment
from api.dependencies import get_current_student, get_db
from api.dependencies import get_current_student, get_db
from api.schemas import PostCreateSchema, PostResponseSchema, CommentCreateSchema, CommentResponseSchema

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
    # Manually construct response to avoid lazy loading 'likes' on async session
    return PostResponseSchema(
        id=new_post.id,
        content=new_post.content,
        category_type=new_post.category_type,
        author_name=student.full_name if student.full_name else "Talaba",
        author_role="Talaba",
        created_at=new_post.created_at,
        target_university_id=new_post.target_university_id,
        target_faculty_id=new_post.target_faculty_id,
        target_specialty_name=new_post.target_specialty_name,
        likes_count=0,
        is_liked_by_me=False
    )

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
    # Eager load likes and reposts ONLY for determining "is_liked_by_me/is_reposted_by_me" status
    # We DO NOT need to load all comments/likes to count them anymore.
    
    query = select(ChoyxonaPost).options(
        selectinload(ChoyxonaPost.student), 
        selectinload(ChoyxonaPost.likes), 
        selectinload(ChoyxonaPost.reposts)
    ).order_by(desc(ChoyxonaPost.created_at))
    
    # ... (filters remain same) ...
    # 1. Category Filter (Tab Filter)
    query = query.where(ChoyxonaPost.category_type == category)
    
    if category == 'university': 
         query = query.where(ChoyxonaPost.target_university_id == student.university_id)
    elif category == 'faculty':
         query = query.where(
             ChoyxonaPost.target_university_id == student.university_id,
             ChoyxonaPost.target_faculty_id == student.faculty_id
         )
    elif category == 'specialty':
         query = query.where(
             ChoyxonaPost.target_university_id == student.university_id,
             ChoyxonaPost.target_faculty_id == student.faculty_id,
             ChoyxonaPost.target_specialty_name == student.specialty_name
         )
        
    result = await db.execute(query)
    posts = result.scalars().all()
    
    return [_map_post(p, p.student, student.id) for p in posts]

def _map_post(post: ChoyxonaPost, author: Student, current_user_id: int):
    from utils.role_mapper import get_role_label
    # Use stored counts
    is_liked = any(l.student_id == current_user_id for l in post.likes) if post.likes else False
    is_reposted = any(r.student_id == current_user_id for r in post.reposts) if post.reposts else False

    return PostResponseSchema(
        id=post.id,
        content=post.content,
        category_type=post.category_type,
        author_name=author.full_name if author else "Unknown",
        author_username=author.username if author else None,
        author_avatar=author.image_url,
        author_role=get_role_label(author.hemis_role) if author else "Talaba", 
        created_at=post.created_at,
        target_university_id=post.target_university_id,
        target_faculty_id=post.target_faculty_id,
        target_specialty_name=post.target_specialty_name,
        
        likes_count=post.likes_count,
        comments_count=post.comments_count,
        reposts_count=post.reposts_count,
        
        is_liked_by_me=is_liked,
        is_reposted_by_me=is_reposted,
        is_mine=(post.student_id == current_user_id)
    )
    
@router.get("/posts/{post_id}", response_model=PostResponseSchema)
async def get_post_by_id(
    post_id: int,
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_db)
):
    query = select(ChoyxonaPost).options(
        selectinload(ChoyxonaPost.student), 
        selectinload(ChoyxonaPost.likes),
        selectinload(ChoyxonaPost.reposts)
    ).where(ChoyxonaPost.id == post_id)
    
    result = await db.execute(query)
    post = result.scalar_one_or_none()
    
    if not post:
        raise HTTPException(status_code=404, detail="Post topilmadi")
        
    return _map_post(post, post.student, student.id)

@router.put("/posts/{post_id}", response_model=PostResponseSchema)
async def update_post(
    post_id: int,
    data: PostCreateSchema, # Reuse create schema (content + category)
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_db)
):
    # Eager load relationships to prevent 500 error during mapping
    query = select(ChoyxonaPost).options(
        selectinload(ChoyxonaPost.likes),
        selectinload(ChoyxonaPost.reposts)
    ).where(ChoyxonaPost.id == post_id)
    
    result = await db.execute(query)
    post = result.scalar_one_or_none()
    
    if not post:
        raise HTTPException(status_code=404, detail="Post topilmadi")
        
    if post.student_id != student.id:
        raise HTTPException(status_code=403, detail="Siz faqat o'zingizning postingizni o'zgartira olasiz")
        
    post.content = data.content
    # We generally don't allow changing category/context after creation, but content yes.
    
    await db.commit()
    await db.refresh(post)
    
    # We need to manually load relationships or just return mapped with empty lists if we know they didn't change count-wise
    # But better to just re-fetch fully if needed. For speed, assume 0 for response or existing.
    # Simple fix: return mapped with current user
    return _map_post(post, student, student.id)

@router.delete("/posts/{post_id}")
async def delete_post(
    post_id: int,
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_db)
):
    post = await db.get(ChoyxonaPost, post_id)
    if not post:
        raise HTTPException(status_code=404, detail="Post topilmadi")
        
    if post.student_id != student.id:
        raise HTTPException(status_code=403, detail="Siz faqat o'zingizning postingizni o'chira olasiz")
        
    await db.delete(post)
    await db.commit()
    return {"status": "success", "message": "Post o'chirildi"}

@router.post("/posts/{post_id}/like")
async def toggle_like(
    post_id: int,
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_db)
):
    # Check if post exists
    post = await db.get(ChoyxonaPost, post_id)
    if not post:
        raise HTTPException(status_code=404, detail="Post topilmadi")

    # Check for existing like
    existing_like = await db.scalar(select(ChoyxonaPostLike).where(ChoyxonaPostLike.post_id == post_id, ChoyxonaPostLike.student_id == student.id))
    
    if existing_like:
        await db.delete(existing_like)
        post.likes_count = max(0, post.likes_count - 1) # Atomic-ish in app logic, better to use SQL expression if high concurrency, but OK for now
        liked = False
    else:
        new_like = ChoyxonaPostLike(post_id=post_id, student_id=student.id)
        db.add(new_like)
        post.likes_count += 1
        liked = True

    await db.commit()
    return {"status": "success", "liked": liked, "count": post.likes_count}

@router.post("/posts/{post_id}/repost")
async def toggle_repost(
    post_id: int,
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_db)
):
    from database.models import ChoyxonaPostRepost
    # Check if post exists
    post = await db.get(ChoyxonaPost, post_id)
    if not post:
        raise HTTPException(status_code=404, detail="Post topilmadi")

    # Check for existing repost
    existing_repost = await db.scalar(select(ChoyxonaPostRepost).where(ChoyxonaPostRepost.post_id == post_id, ChoyxonaPostRepost.student_id == student.id))
    
    if existing_repost:
        await db.delete(existing_repost)
        post.reposts_count = max(0, post.reposts_count - 1)
        reposted = False
    else:
        new_repost = ChoyxonaPostRepost(post_id=post_id, student_id=student.id)
        db.add(new_repost)
        post.reposts_count += 1
        reposted = True

    await db.commit()
    return {"status": "success", "reposted": reposted, "count": post.reposts_count}

@router.post("/posts/{post_id}/comments", response_model=CommentResponseSchema)
async def create_comment(
    post_id: int,
    data: CommentCreateSchema,
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_db)
):
    # ... (same checks)
    # 1. Fetch Post to verify access logic
    post = await db.get(ChoyxonaPost, post_id)
    if not post:
        raise HTTPException(status_code=404, detail="Post topilmadi")
    
    # ... (access checks)
    # 2. Verify Access (User must have same context as post)
    if post.category_type == 'university' and post.target_university_id != student.university_id:
        raise HTTPException(status_code=403, detail="Siz bu universitet postiga yozolmaysiz")
    
    if post.category_type == 'faculty' and (post.target_university_id != student.university_id or post.target_faculty_id != student.faculty_id):
        raise HTTPException(status_code=403, detail="Siz bu fakultet postiga yozolmaysiz")
        
    if post.category_type == 'specialty' and (post.target_specialty_name != student.specialty_name):
         raise HTTPException(status_code=403, detail="Siz bu yo'nalish postiga yozolmaysiz")

    # 3. Create Comment
    from database.models import ChoyxonaComment
    new_comment = ChoyxonaComment(
        post_id=post_id,
        student_id=student.id,
        content=data.content,
        reply_to_comment_id=data.reply_to_comment_id
    )
    
    db.add(new_comment)
    post.comments_count += 1 
    await db.commit()
    await db.refresh(new_comment)
    
    # Reload to get parent if needed
    if new_comment.reply_to_comment_id:
        query = select(ChoyxonaComment).options(
            selectinload(ChoyxonaComment.parent_comment).selectinload(ChoyxonaComment.student),
            selectinload(ChoyxonaComment.student),
            selectinload(ChoyxonaComment.post) # For author check
        ).where(ChoyxonaComment.id == new_comment.id)
        res = await db.execute(query)
        new_comment = res.scalar_one()

    return _map_comment(new_comment, student, student.id)

@router.get("/posts/{post_id}/comments", response_model=List[CommentResponseSchema])
async def get_comments(
    post_id: int,
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_db)
):
    """
    Get comments for a post.
    """
    from database.models import ChoyxonaComment
    
    post = await db.get(ChoyxonaPost, post_id)
    if not post:
        raise HTTPException(status_code=404, detail="Post topilmadi")

    # Eager load student, parent, likes, and post (for owner check)
    query = select(ChoyxonaComment).options(
        selectinload(ChoyxonaComment.student),
        selectinload(ChoyxonaComment.parent_comment).selectinload(ChoyxonaComment.student),
        selectinload(ChoyxonaComment.likes),
        selectinload(ChoyxonaComment.post)
    ).where(ChoyxonaComment.post_id == post_id).order_by(desc(ChoyxonaComment.likes_count), desc(ChoyxonaComment.created_at))
    
    result = await db.execute(query)
    comments = result.scalars().all()
    
    return [_map_comment(c, c.student, student.id) for c in comments]

@router.post("/comments/{comment_id}/like")
async def toggle_comment_like(
    comment_id: int,
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_db)
):
    from database.models import ChoyxonaComment, ChoyxonaCommentLike
    comment = await db.get(ChoyxonaComment, comment_id)
    if not comment:
        raise HTTPException(status_code=404, detail="Komment topilmadi")

    existing_like = await db.scalar(select(ChoyxonaCommentLike).where(ChoyxonaCommentLike.comment_id == comment_id, ChoyxonaCommentLike.student_id == student.id))
    
    if existing_like:
        await db.delete(existing_like)
        # Atomic Decrement
        comment.likes_count = ChoyxonaComment.likes_count - 1
        liked = False
    else:
        new_like = ChoyxonaCommentLike(comment_id=comment_id, student_id=student.id)
        db.add(new_like)
        # Atomic Increment
        comment.likes_count = ChoyxonaComment.likes_count + 1
        liked = True

    await db.commit()
    # Refresh to get the actual integer value after SQL update
    await db.refresh(comment)
    
    return {"status": "success", "liked": liked, "count": comment.likes_count}

@router.delete("/comments/{comment_id}")
async def delete_comment(
    comment_id: int,
    student: Student = Depends(get_current_student),
    db: AsyncSession = Depends(get_db)
):
    from database.models import ChoyxonaComment
    comment = await db.get(ChoyxonaComment, comment_id)
    if not comment:
        raise HTTPException(status_code=404, detail="Komment topilmadi")
    
    # Allow deletion if:
    # 1. User is the author of the comment
    # 2. User is the author of the POST (admin of thread)
    # But user requirement says: "User faqat o'z kommentini o'chira... olsin"
    # So we strictly check comment author.
    
    if comment.student_id != student.id:
        raise HTTPException(status_code=403, detail="Siz faqat o'zingizning kommentingizni o'chira olasiz")
        
    await db.delete(comment)
    
    # Decrement Post comment count (Optional but good for consistency)
    if comment.post_id:
        post = await db.get(ChoyxonaPost, comment.post_id)
        if post:
            post.comments_count = max(0, post.comments_count - 1)

    await db.commit()
    return {"status": "success", "message": "Komment o'chirildi"}

def _map_comment(comment: "ChoyxonaComment", author: Student, current_user_id: int):
    from api.schemas import CommentResponseSchema
    from utils.role_mapper import get_role_label
    
    reply_user = None
    reply_content = None
    
    if comment.parent_comment:
        reply_user = comment.parent_comment.student.full_name if comment.parent_comment.student else "Noma'lum"
        reply_content = comment.parent_comment.content

    # Determine if liked by me
    # If loaded eagerly:
    is_liked = any(l.student_id == current_user_id for l in comment.likes) if comment.likes else False
    
    # Identify Author role or "Author Like"
    # Logic: is_liked_by_author = True if the POST OWNER liked this comment.
    # To do this, we need post_owner_id. Comment->Post->Student.
    # We should eager load Post to check this.
    # Identify Author role or "Author Like"
    # Logic: is_liked_by_author = True if the POST OWNER liked this comment.
    is_liked_by_author = False
    
    # Safely check if post exists and if we have likes on the comment
    if comment.post and comment.likes:
         is_liked_by_author = any(l.student_id == comment.post.student_id for l in comment.likes)

    return CommentResponseSchema(
        id=comment.id,
        post_id=comment.post_id,
        content=comment.content,
        author_name=author.full_name if author else "Noma'lum",
        author_username=author.username if author else None,
        author_avatar=author.image_url, 
        author_role=get_role_label(author.hemis_role) if author else "Talaba",
        created_at=comment.created_at,
        
        likes_count=comment.likes_count,
        is_liked=is_liked,
        is_liked_by_author=is_liked_by_author,
        author_role="Talaba", # Placeholder
        
        is_mine=(comment.student_id == current_user_id),

        reply_to_username=reply_user,
        reply_to_content=reply_content
    )
