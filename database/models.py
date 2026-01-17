import enum
from datetime import datetime

from sqlalchemy import (
    BigInteger,
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .db_connect import Base


# ============================================================
# ENUM ROLLAR
# ============================================================

class StaffRole(str, enum.Enum):
    OWNER = "owner"
    DEVELOPER = "developer"
    RAHBARIYAT = "rahbariyat"
    DEKANAT = "dekanat"
    TYUTOR = "tyutor"
    PSIXOLOG = "psixolog"
    YOSHLAR_YETAKCHISI = "yoshlar_yetakchisi"
    KLUB_RAHBARI = "klub_rahbari"
    
    # Yangi rollar (Student Feedback uchun)
    TEACHER = "teacher"
    KAFEDRA_MUDIRI = "kafedra_mudiri"
    DEKAN = "dekan"
    DEKAN_ORINBOSARI = "dekan_orinbosari"
    DEKAN_YOSHLAR = "dekan_yoshlar"
    PROREKTOR = "prorektor"
    YOSHLAR_PROREKTOR = "yoshlar_prorektor"
    REKTOR = "rektor"
    BUXGALTER = "buxgalter"
    KUTUBXONA = "kutubxona"
    INSPEKTOR = "inspektor"


class StudentStatus(str, enum.Enum):
    ACTIVE = "active"
    GRADUATED = "graduated"
    ACADEMIC_LEAVE = "academic_leave"
    EXPELLED = "expelled"


# ============================================================
# UNIVERSITET MODELI
# ============================================================

class University(Base):
    __tablename__ = "universities"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    uni_code: Mapped[str] = mapped_column(String(32), unique=True, nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    short_name: Mapped[str | None] = mapped_column(String(64), nullable=True)

    required_channel: Mapped[str | None] = mapped_column(String(128), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(), default=datetime.utcnow)

    faculties: Mapped[list["Faculty"]] = relationship("Faculty", back_populates="university")
    staff: Mapped[list["Staff"]] = relationship("Staff", back_populates="university")
    students: Mapped[list["Student"]] = relationship("Student", back_populates="university")
    tutor_groups: Mapped[list["TutorGroup"]] = relationship("TutorGroup", back_populates="university")

    def __repr__(self):
        return f"<University {self.uni_code}>"


# ============================================================
# FAKULTET MODELI
# ============================================================

class Faculty(Base):
    __tablename__ = "faculties"
    __table_args__ = (
        UniqueConstraint("university_id", "faculty_code", name="uq_faculty_uni_code"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    university_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("universities.id", ondelete="CASCADE"), nullable=False
    )
    faculty_code: Mapped[str] = mapped_column(String(64), nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)

    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    university: Mapped["University"] = relationship("University", back_populates="faculties")
    
    staff: Mapped[list["Staff"]] = relationship("Staff", back_populates="faculty")
    students: Mapped[list["Student"]] = relationship("Student", back_populates="faculty")
    tutor_groups: Mapped[list["TutorGroup"]] = relationship("TutorGroup", back_populates="faculty")

    def __repr__(self):
        return f"<Faculty {self.faculty_code} - {self.name}>"


# ============================================================
# CACHE MODELI
# ============================================================
from sqlalchemy import JSON

class StudentCache(Base):
    __tablename__ = "student_cache"
    __table_args__ = (
        UniqueConstraint("student_id", "key", name="uq_student_cache_key"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    student_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False
    )
    key: Mapped[str] = mapped_column(String(64), nullable=False) # e.g. "subjects_11", "attendance_11"
    data: Mapped[dict] = mapped_column(JSON, nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(), default=datetime.utcnow, onupdate=datetime.utcnow)

    student: Mapped["Student"] = relationship("Student", backref="caches")

    def __repr__(self):
        return f"<Faculty {self.faculty_code}>"


# ============================================================
# XODIM MODELI
# ============================================================

class Staff(Base):
    __tablename__ = "staff"
    __table_args__ = (
        UniqueConstraint("jshshir", name="uq_staff_jshshir"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    jshshir: Mapped[str] = mapped_column(String(20), nullable=False)
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    position: Mapped[str | None] = mapped_column(String(255), nullable=True)

    role: Mapped[StaffRole] = mapped_column(String(32), nullable=False)
    telegram_id: Mapped[int | None] = mapped_column(BigInteger, nullable=True)

    university_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("universities.id", ondelete="SET NULL"), nullable=True
    )
    faculty_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("faculties.id", ondelete="SET NULL"), nullable=True
    )

    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(), default=datetime.utcnow)

    university: Mapped["University"] = relationship("University", back_populates="staff")
    faculty: Mapped["Faculty"] = relationship("Faculty", back_populates="staff")
    tg_accounts: Mapped[list["TgAccount"]] = relationship("TgAccount", back_populates="staff")
    tutor_groups: Mapped[list["TutorGroup"]] = relationship("TutorGroup", back_populates="tutor")
    
    managed_clubs: Mapped[list["Club"]] = relationship(
        "Club",
        secondary="club_leaders",
        back_populates="leaders",
        lazy="selectin"
    )

    def __repr__(self):
        return f"<Staff {self.full_name}>"


class ResourceFile(Base):
    __tablename__ = "resource_files"
    
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    hemis_id: Mapped[int] = mapped_column(BigInteger, unique=True, nullable=False)
    file_id: Mapped[str] = mapped_column(String(255), nullable=False)
    file_name: Mapped[str] = mapped_column(String(255), nullable=True)
    file_type: Mapped[str] = mapped_column(String(50), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)


# ============================================================
# TALABA MODELI
# ============================================================

class Student(Base):
    __tablename__ = "students"
    __table_args__ = (
        UniqueConstraint("hemis_login", name="uq_student_hemis"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    hemis_id: Mapped[str | None] = mapped_column(String(64), nullable=True) # HEMIS specific ID
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    hemis_login: Mapped[str] = mapped_column(String(128), nullable=False)
    hemis_token: Mapped[str | None] = mapped_column(String(1024), nullable=True) # SAVING TOKEN FOR REFRESH
    hemis_password: Mapped[str | None] = mapped_column(String(255), nullable=True) # SAVING PASS FOR AUTO-SCRAPE
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)

    university_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("universities.id", ondelete="SET NULL"), nullable=True
    )
    university_name: Mapped[str | None] = mapped_column(String(255), nullable=True) # New Field

    faculty_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("faculties.id", ondelete="SET NULL"), nullable=True
    )
    faculty_name: Mapped[str | None] = mapped_column(String(255), nullable=True) # New Field
    specialty_name: Mapped[str | None] = mapped_column(String(255), nullable=True) # Yor'nalish
    
    group_number: Mapped[str | None] = mapped_column(String(255), nullable=True) # Expanded length
    
    # --- New Profile Fields ---
    short_name: Mapped[str | None] = mapped_column(String(64), nullable=True)
    image_url: Mapped[str | None] = mapped_column(String(255), nullable=True)
    
    level_name: Mapped[str | None] = mapped_column(String(64), nullable=True) # 1-kurs
    semester_name: Mapped[str | None] = mapped_column(String(64), nullable=True) # 1-semestr
    education_form: Mapped[str | None] = mapped_column(String(64), nullable=True) # Kunduzgi
    education_type: Mapped[str | None] = mapped_column(String(64), nullable=True) # Bakalavr
    payment_form: Mapped[str | None] = mapped_column(String(64), nullable=True) # Davlat granti
    student_status: Mapped[str | None] = mapped_column(String(64), nullable=True) # O'qimoqda
    
    email: Mapped[str | None] = mapped_column(String(128), nullable=True)
    province_name: Mapped[str | None] = mapped_column(String(128), nullable=True)
    district_name: Mapped[str | None] = mapped_column(String(128), nullable=True)
    accommodation_name: Mapped[str | None] = mapped_column(String(128), nullable=True) # Ijaradagi uyda
    
    missed_hours: Mapped[int] = mapped_column(Integer, default=0) # New Field
    
    # --- AI Context ---
    ai_context: Mapped[str | None] = mapped_column(Text, nullable=True) # Summarized info for AI
    last_context_update: Mapped[datetime | None] = mapped_column(DateTime(), nullable=True)
    # --------------------------

    status: Mapped[StudentStatus] = mapped_column(String(32), default=StudentStatus.ACTIVE.value)

    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(), default=datetime.utcnow)

    university: Mapped["University"] = relationship("University", back_populates="students")
    faculty: Mapped["Faculty"] = relationship("Faculty", back_populates="students")
    tg_accounts: Mapped[list["TgAccount"]] = relationship("TgAccount", back_populates="student")

    activities: Mapped[list["UserActivity"]] = relationship(
        "UserActivity", back_populates="student", cascade="all, delete-orphan"
    )
    documents: Mapped[list["UserDocument"]] = relationship(
        "UserDocument", back_populates="student", cascade="all, delete-orphan"
    )
    certificates: Mapped[list["UserCertificate"]] = relationship(
        "UserCertificate", back_populates="student", cascade="all, delete-orphan"
    )
    feedbacks: Mapped[list["StudentFeedback"]] = relationship(
        "StudentFeedback", back_populates="student", cascade="all, delete-orphan"
    )

    def __repr__(self):
        return f"<Student {self.full_name}>"


# ============================================================
# TELEGRAM ACCOUNT
# ============================================================

class TgAccount(Base):
    __tablename__ = "tg_accounts"
    __table_args__ = (
        UniqueConstraint("telegram_id", name="uq_tg_accounts_telegram_id"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    telegram_id: Mapped[int] = mapped_column(BigInteger, nullable=False)

    staff_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("staff.id", ondelete="SET NULL"), nullable=True
    )
    student_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("students.id", ondelete="SET NULL"), nullable=True
    )

    current_role: Mapped[str | None] = mapped_column(String(32), nullable=True)
    channel_verified_at: Mapped[datetime | None] = mapped_column(DateTime(), nullable=True)
    last_active: Mapped[datetime | None] = mapped_column(DateTime(), nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(), default=datetime.utcnow)

    staff: Mapped["Staff"] = relationship("Staff", back_populates="tg_accounts")
    student: Mapped["Student"] = relationship("Student", back_populates="tg_accounts")

    def __repr__(self):
        return f"<TgAccount {self.telegram_id}>"


# ============================================================
# FAOLLIKLAR
# ============================================================

class UserActivity(Base):
    __tablename__ = "user_activities"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    student_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False
    )

    category: Mapped[str] = mapped_column(String(64), nullable=False)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(String(2000), nullable=True)
    date: Mapped[str | None] = mapped_column(String(32), nullable=True)

    status: Mapped[str] = mapped_column(String(32), default="pending")
    created_at: Mapped[datetime] = mapped_column(DateTime(), default=datetime.utcnow)

    student: Mapped["Student"] = relationship("Student", back_populates="activities")

    images: Mapped[list["UserActivityImage"]] = relationship(
        "UserActivityImage", back_populates="activity", cascade="all, delete-orphan"
    )


# ============================================================
# HUJJATLAR MODELI
# ============================================================

class UserDocument(Base):
    __tablename__ = "user_documents"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)

    student_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False
    )

    category: Mapped[str] = mapped_column(String(64), nullable=False)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(String(1000), nullable=True)

    file_id: Mapped[str] = mapped_column(String(255), nullable=False)
    file_type: Mapped[str] = mapped_column(String(32), default="document")

    status: Mapped[str] = mapped_column(String(32), default="pending")
    created_at: Mapped[datetime] = mapped_column(DateTime(), default=datetime.utcnow)

    student: Mapped["Student"] = relationship("Student", back_populates="documents")


# ============================================================
# SERTIFIKATLAR
# ============================================================

class UserCertificate(Base):
    __tablename__ = "user_certificates"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    student_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False
    )

    title: Mapped[str] = mapped_column(String(255), nullable=False)
    file_id: Mapped[str] = mapped_column(String(255), nullable=False)

    created_at: Mapped[datetime] = mapped_column(DateTime(), default=datetime.utcnow)

    student: Mapped["Student"] = relationship("Student", back_populates="certificates")


# ============================================================
# FAOLLIK RASMLARI
# ============================================================

class UserActivityImage(Base):
    __tablename__ = "user_activity_images"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    activity_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("user_activities.id", ondelete="CASCADE"), nullable=False
    )

    file_id: Mapped[str] = mapped_column(String(255), nullable=False)
    file_type: Mapped[str] = mapped_column(String(32), default="photo")

    created_at: Mapped[datetime] = mapped_column(DateTime(), default=datetime.utcnow)

    activity: Mapped["UserActivity"] = relationship("UserActivity", back_populates="images")


# ============================================================
# TALABA MUROJAATLARI
# ============================================================

class StudentFeedback(Base):
    __tablename__ = "student_feedback"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    student_id: Mapped[int] = mapped_column(Integer, ForeignKey("students.id", ondelete="CASCADE"))
    text: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(String(32), default="pending")
    assigned_role: Mapped[str | None] = mapped_column(String(32), nullable=True)
    assigned_staff_id: Mapped[int | None] = mapped_column(Integer, nullable=True)
    file_id: Mapped[str | None] = mapped_column(String(255), nullable=True)
    file_type: Mapped[str | None] = mapped_column(String(32), nullable=True)
    is_anonymous: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(), default=datetime.utcnow)
    parent_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("student_feedback.id"), nullable=True)

    student: Mapped["Student"] = relationship("Student", back_populates="feedbacks")
    replies: Mapped[list["FeedbackReply"]] = relationship("FeedbackReply", back_populates="feedback")
    children: Mapped[list["StudentFeedback"]] = relationship("StudentFeedback", back_populates="parent", remote_side=[id])
    parent: Mapped["StudentFeedback"] = relationship("StudentFeedback", back_populates="children", remote_side=[parent_id])


class FeedbackReply(Base):
    __tablename__ = "feedback_replies"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    feedback_id: Mapped[int] = mapped_column(Integer, ForeignKey("student_feedback.id", ondelete="CASCADE"))
    staff_id: Mapped[int] = mapped_column(Integer, ForeignKey("staff.id", ondelete="SET NULL"), nullable=True)
    text: Mapped[str] = mapped_column(Text, nullable=True) # Text can be null if file is present
    file_id: Mapped[str | None] = mapped_column(String(255), nullable=True)
    file_type: Mapped[str | None] = mapped_column(String(32), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(), default=datetime.utcnow)

    feedback: Mapped["StudentFeedback"] = relationship("StudentFeedback", back_populates="replies")
    staff: Mapped["Staff"] = relationship("Staff")


class UserAppeal(Base):
    __tablename__ = "user_appeals"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    student_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False
    )

    file_id: Mapped[str | None] = mapped_column(String(255), nullable=True)
    file_type: Mapped[str | None] = mapped_column(String(32), nullable=True)
    text: Mapped[str | None] = mapped_column(String(2048), nullable=True)

    status: Mapped[str] = mapped_column(String(32), default="pending")
    created_at: Mapped[datetime] = mapped_column(DateTime(), default=datetime.utcnow)

    student: Mapped["Student"] = relationship("Student")



# ============================================================
# TUTOR GROUP — TYUTOR → GURUHLAR
# ============================================================

class TutorGroup(Base):
    __tablename__ = "tutor_groups"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)

    tutor_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("staff.id", ondelete="SET NULL"),
        nullable=True, index=True
    )

    university_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("universities.id", ondelete="CASCADE"),
        nullable=False, index=True
    )

    faculty_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("faculties.id", ondelete="SET NULL"),
        nullable=True, index=True
    )

    group_number: Mapped[str] = mapped_column(String(32), nullable=False, index=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(), default=datetime.utcnow)

    tutor: Mapped["Staff"] = relationship("Staff", back_populates="tutor_groups")
    university: Mapped["University"] = relationship("University", back_populates="tutor_groups")
    faculty: Mapped["Faculty"] = relationship("Faculty", back_populates="tutor_groups")

    __table_args__ = (
        UniqueConstraint("tutor_id", "group_number", name="uq_tutor_group"),
    )


# ============================================================
# TYUTOR MODULI
# ============================================================

class TyutorWorkLog(Base):
    """6 yo'nalish bo'yicha tyutor ishlari"""
    __tablename__ = "tyutor_work_log"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tyutor_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("staff.id", ondelete="CASCADE"), nullable=False
    )
    student_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=True
    )
    
    direction_type: Mapped[str] = mapped_column(String(50), nullable=False)
    # normativ, darsdan_tashqari, manaviy, profilaktika, turar_joy, ota_ona
    
    title: Mapped[str | None] = mapped_column(String(255), nullable=True)
    completion_date: Mapped[str | None] = mapped_column(String(20), nullable=True)
    
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    file_id: Mapped[str | None] = mapped_column(String(255), nullable=True)
    file_type: Mapped[str | None] = mapped_column(String(32), nullable=True)
    
    status: Mapped[str] = mapped_column(String(20), default="completed")
    points: Mapped[int] = mapped_column(Integer, default=0)
    
    created_at: Mapped[datetime] = mapped_column(DateTime(), default=datetime.utcnow)


class TyutorKPI(Base):
    """Tyutor KPI hisoblash"""
    __tablename__ = "tyutor_kpi"
    __table_args__ = (
        UniqueConstraint("tyutor_id", "quarter", "year", name="uq_tyutor_kpi_period"),
    )

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tyutor_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("staff.id", ondelete="CASCADE"), nullable=False
    )
    
    quarter: Mapped[int] = mapped_column(Integer, nullable=False)  # 1, 2, 3, 4
    year: Mapped[int] = mapped_column(Integer, nullable=False)
    
    coverage_score: Mapped[float] = mapped_column(Integer, default=0)  # 30%
    risk_detection_score: Mapped[float] = mapped_column(Integer, default=0)  # 25%
    activity_score: Mapped[float] = mapped_column(Integer, default=0)  # 20%
    parent_contact_score: Mapped[float] = mapped_column(Integer, default=0)  # 15%
    discipline_score: Mapped[float] = mapped_column(Integer, default=0)  # 10%
    
    total_kpi: Mapped[float] = mapped_column(Integer, default=0)
    
    updated_at: Mapped[datetime] = mapped_column(DateTime(), default=datetime.utcnow, onupdate=datetime.utcnow)


class StudentRiskAssessment(Base):
    """Talaba xavf darajasi"""
    __tablename__ = "student_risk_assessment"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    student_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False, unique=True
    )
    
    risk_level: Mapped[str] = mapped_column(String(20), default="low")
    # low, medium, high, critical
    
    risk_factors: Mapped[str | None] = mapped_column(Text, nullable=True)
    # JSON string: {"attendance": "low", "activity": "none", "grades": "poor"}
    
    last_assessed: Mapped[datetime] = mapped_column(DateTime(), default=datetime.utcnow)


class ParentContactLog(Base):
    """Ota-ona bilan aloqa"""
    __tablename__ = "parent_contact_log"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    student_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False
    )
    tyutor_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("staff.id", ondelete="CASCADE"), nullable=False
    )
    
    contact_date: Mapped[datetime] = mapped_column(DateTime(), nullable=False)
    contact_type: Mapped[str] = mapped_column(String(50), nullable=False)
    # phone, visit, meeting
    
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    
    created_at: Mapped[datetime] = mapped_column(DateTime(), default=datetime.utcnow)

# ============================================================
# KLUB MODELLARI
# ============================================================

class ClubLeader(Base):
    __tablename__ = "club_leaders"
    
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    club_id: Mapped[int] = mapped_column(Integer, ForeignKey("clubs.id", ondelete="CASCADE"), nullable=False)
    staff_id: Mapped[int] = mapped_column(Integer, ForeignKey("staff.id", ondelete="CASCADE"), nullable=False)
    appointed_at: Mapped[datetime] = mapped_column(DateTime(), default=datetime.utcnow)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

class Club(Base):
    __tablename__ = "clubs"
    
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(String(1000), nullable=True)
    statute_link: Mapped[str | None] = mapped_column(String(500), nullable=True)
    channel_link: Mapped[str | None] = mapped_column(String(500), nullable=True)
    spreadsheet_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    leader_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("staff.id", ondelete="SET NULL"), nullable=True)
    
    # Deprecating single leader relationship in favor of list
    # leader: Mapped["Staff"] = relationship("Staff", foreign_keys=[leader_id], lazy="selectin")
    
    # New relationship: Multiple Leaders
    leaders: Mapped[list["Staff"]] = relationship(
        "Staff", 
        secondary="club_leaders",
        back_populates="managed_clubs", # Need to add this to Staff model too
        lazy="selectin"
    )
    # Shared Auth Implementation
    # - [x] Design strategy for Bot-App sync
    # - [x] Update Bot to store HEMIS passwords
    # - [x] Implement production `/api/auth/check` endpoint
    # - [x] Test Telegram login flow on emulator
    memberships: Mapped[list["ClubMembership"]] = relationship("ClubMembership", back_populates="club")

    @property
    def leader(self):
        """Backward compatibility: returns first leader or None"""
        return self.leaders[0] if self.leaders else None

class ClubMembership(Base):
    __tablename__ = "club_memberships"
    
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    student_id: Mapped[int] = mapped_column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    club_id: Mapped[int] = mapped_column(Integer, ForeignKey("clubs.id", ondelete="CASCADE"), nullable=False)
    joined_at: Mapped[datetime] = mapped_column(DateTime(), default=datetime.utcnow)
    
    student: Mapped["Student"] = relationship("Student")
    club: Mapped["Club"] = relationship("Club", back_populates="memberships")


# ============================================================
# AI SUHBAT LOGLARI
# ============================================================
class StudentAILog(Base):
    __tablename__ = "student_ai_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    student_id: Mapped[int] = mapped_column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    
    # Snapshot of student info (for analytics even if student changes)
    full_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    university_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    faculty_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    group_number: Mapped[str | None] = mapped_column(String(255), nullable=True) # Increased from 64
    
    user_query: Mapped[str] = mapped_column(Text, nullable=False)
    ai_response: Mapped[str] = mapped_column(Text, nullable=False)
    
    created_at: Mapped[datetime] = mapped_column(DateTime(), default=datetime.utcnow)

    student: Mapped["Student"] = relationship("Student")

# ============================================================
# PENDING UPLOAD (TELEGRAM-FIRST FLOW)
# ============================================================

class PendingUpload(Base):
    __tablename__ = "pending_uploads"

    session_id: Mapped[str] = mapped_column(String(64), primary_key=True) # UUID from App
    student_id: Mapped[int] = mapped_column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)
    file_ids: Mapped[str] = mapped_column(Text, default="") # Comma-separated list of file_ids
    
    created_at: Mapped[datetime] = mapped_column(DateTime(), default=datetime.utcnow)

    student: Mapped["Student"] = relationship("Student")


# ============================================================
# AI CHAT HISTORY (PERSISTENT)
# ============================================================
class AiMessage(Base):
    __tablename__ = "ai_messages"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    student_id: Mapped[int] = mapped_column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False, index=True)
    
    role: Mapped[str] = mapped_column(String(20), nullable=False) # 'user' or 'assistant'
    content: Mapped[str] = mapped_column(Text, nullable=False)
    
    created_at: Mapped[datetime] = mapped_column(DateTime(), default=datetime.utcnow)

    student: Mapped["Student"] = relationship("Student")


# ============================================================
# CHOYXONA (COMMUNITY)
# ============================================================

class ChoyxonaPost(Base):
    __tablename__ = "choyxona_posts"

    # ID va User
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    student_id: Mapped[int] = mapped_column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False)

    # Content
    content: Mapped[str] = mapped_column(Text, nullable=False)
    
    # Kategoriya (universitet | fakultet | yonalish)
    category_type: Mapped[str] = mapped_column(String(32), nullable=False) 
    
    # Target Context (Access Control)
    # Qaysi auditoriya uchun mo'ljallangan?
    target_university_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("universities.id", ondelete="CASCADE"), nullable=True)
    target_faculty_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("faculties.id", ondelete="CASCADE"), nullable=True)
    target_specialty_name: Mapped[str | None] = mapped_column(String(255), nullable=True) # Direction ID o'rniga name ishlatilmoqda chunki alohida jadval yo'q

    created_at: Mapped[datetime] = mapped_column(DateTime(), default=datetime.utcnow)

    # Relationships
    student: Mapped["Student"] = relationship("Student")
    university: Mapped["University"] = relationship("University")
    faculty: Mapped["Faculty"] = relationship("Faculty")

    def __repr__(self):
        return f"<ChoyxonaPost {self.id} by {self.student_id} ({self.category_type})>"

