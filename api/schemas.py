from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class FacultySchema(BaseModel):
    id: int
    name: str

class HemisLoginRequest(BaseModel):
    login: str
    password: str

class StudentProfileSchema(BaseModel):
    id: int
    full_name: str
    phone: Optional[str]
    hemis_login: str
    group_number: Optional[str] = None
    faculty_id: Optional[int] = None
    faculty_name: Optional[str] = None
    specialty_name: Optional[str] = None
    
    # Extended Profile
    first_name: Optional[str] = None
    short_name: Optional[str] = None
    image_url: Optional[str] = None
    level_name: Optional[str] = None
    semester_name: Optional[str] = None
    education_form: Optional[str] = None
    education_type: Optional[str] = None
    payment_form: Optional[str] = None
    student_status: Optional[str] = None
    
    email: Optional[str] = None
    province_name: Optional[str] = None
    district_name: Optional[str] = None
    accommodation_name: Optional[str] = None
    
    is_registered_bot: bool = False # New Field
    
    created_at: datetime
    
    class Config:
        from_attributes = True

class ActivityImageSchema(BaseModel):
    file_id: str
    file_type: str

class ActivityListSchema(BaseModel):
    id: int
    category: str
    name: str
    description: Optional[str]
    date: Optional[str]
    status: str
    images: list[ActivityImageSchema] = []

    class Config:
        from_attributes = True

class ActivityCreateSchema(BaseModel):
    category: str
    name: str
    description: str
    date: str

class StudentDashboardSchema(BaseModel):
    gpa: float = 0.0
    missed_hours: int = 0
    missed_hours_excused: int = 0
    missed_hours_unexcused: int = 0
    activities_count: int
    clubs_count: int
    activities_approved_count: int

class ClubSchema(BaseModel):
    id: int
    name: str
    description: Optional[str]
    image_file_id: Optional[str]

    class Config:
        from_attributes = True

class ClubMembershipSchema(BaseModel):
    club: ClubSchema
    role: str
    joined_at: datetime

    class Config:
        from_attributes = True

class FeedbackListSchema(BaseModel):
    id: int
    text: Optional[str]
    status: str
    assigned_role: Optional[str]
    created_at: datetime
    
    class Config:
        from_attributes = True

class FeedbackCreateSchema(BaseModel):
    text: str
    role: str # 'rahbariyat', 'dekanat', etc.

class DocumentRequestSchema(BaseModel):
    id: int
    type: str # 'reference', 'transcript'
    status: str
    file_id: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

class PostCreateSchema(BaseModel):
    content: str
    category_type: str # 'university', 'faculty', 'specialty'

class PostResponseSchema(BaseModel):
    id: int
    content: str
    category_type: str
    author_name: str
    author_role: str
    created_at: datetime
    
    # Context (Debugging mostly, but useful)
    target_university_id: Optional[int]
    target_faculty_id: Optional[int]
    target_specialty_name: Optional[str]

    target_specialty_name: Optional[str]

    # Likes & Comments
    likes_count: int = 0
    comments_count: int = 0
    is_liked_by_me: bool = False
    is_mine: bool = False

    class Config:
        from_attributes = True

class CommentCreateSchema(BaseModel):
    content: str

class CommentResponseSchema(BaseModel):
    id: int
    post_id: int
    content: str
    author_name: str
    created_at: datetime
    
    class Config:
        from_attributes = True
