
# AI uchun oldindan tayyorlangan prompt so'rovlari
# Rol va mavzu bo'yicha ajratilgan

AI_PROMPTS = {
    # 🎓 TALABA
    "scholarship": (
        "O'zbekiston OTMlarida amaldagi stipendiya turlari va miqdorlari haqida batafsil ma'lumot ber."
        "3, 4, 5 baho olganda qancha stipendiya beriladi?"
        "Prezident stipendiyasi va nomdor stipendiyalar haqida ham qisqacha aytib o't."
    ),
    "hemis_reset": (
        "Hemis axborot tizimida talaba parolini unutganda uni qayta tiklash bo'yicha qadamma-qadam yo'riqnoma ber."
        "Agar telefon raqam o'zgargan bo'lsa nima qilish kerakligini ham tushuntir."
    ),
    "credit_system": (
        "Kredit-modul tizimi nima ekanligini sodda tilda tushuntir."
        "GPA nima? O'tish ballari qanday hisoblanadi? Bir semestrda necha kredit yig'ish kerak?"
        "Qayta o'qish (retake) qoidalari haqida ham ma'lumot ber."
    ),
    "schedule_info": (
        "Dars jadvali va xonalar qanday taqsimlanishini tushuntir."
        "Hemis tizimidan dars jadvalini qanday ko'rish mumkin?"
    ),

    # 👨‍🏫 TYUTOR
    "student_psychology": (
        "Talabalar bilan ishlashda psixologik yondashuv bo'yicha maslahatlar ber."
        "O'qishga qiziqishi past talabalarni qanday motivatsiya qilish mumkin?"
        "Konfliktli vaziyatlarda tyutor o'zini qanday tutishi kerak?"
    ),
    "activity_grading": (
        "Talabalarning jamoat ishlaridagi faolligini baholash mezonlari qanday bo'lishi kerak?"
        "Qanday faolliklar uchun rag'batlantirish (tashakkurnoma, stipendiya qo'shimchasi) berilishi mumkin?"
    ),

    # 🏛 XODIM (Rahbariyat / Dekanat)
    "labor_laws": (
        "O'zbekiston Mehnat kodeksi bo'yicha OTM xodimlariga mehnat ta'tili berish tartibini tushuntir."
        "Ta'til muddatlari va ta'til puli (otpusknoy) hisoblash qoidalari haqida ma'lumot ber."
    ),
    "kpi_system": (
        "Zamonaviy OTMlarda xodimlar faoliyatini baholash (KPI) tizimi haqida ma'lumot ber."
        "KPI ko'rsatkichlari nimalardan iborat bo'lishi mumkin va u ish haqiga qanday ta'sir qiladi?"
    ),

    # 📝 KONSPEKT (Umumiy prompt)
    "konspekt_prompt": (
        "Sen professional talaba yordamchisi va konspektlashtirish bo‘yicha ekspertsan.\n\n"
        "Vazifa:\n"
        "Berilgan matn (ma’ruza, dars konspekti, taqdimot slaydi yoki ilmiy matn)ni talaba daftarga ko‘chirib olishi uchun qulay, qisqa va tushunarli konspekt shakliga keltir.\n\n"
        "Qoidalar:\n"
        "1. Keraksiz, takroriy va umumiy gaplarni olib tashla.\n"
        "2. Faqat asosiy va imtihon uchun muhim ma’lumotlarni qoldir.\n"
        "3. Matnni qisqa, lo‘nda va aniq yoz.\n"
        "4. Fikrlarni tizimli (strukturaviy) ko‘rinishda ber.\n\n"
        "Asosiy e’tibor qaratiladigan jihatlar:\n"
        "📌 Ta’riflar (aniq va qisqa)\n"
        "📅 Sanalar va davrlar\n"
        "👤 Shaxslar, mualliflar, olimlar\n"
        "📐 Formulalar, qoidalar, qonunlar\n"
        "📊 Faktlar, misollar, raqamlar\n"
        "📚 Atamalar va tushunchalar\n\n"
        "Format talablari:\n"
        "- Faqat bullet points (•) yoki raqamlangan ro‘yxatlar.\n"
        "- Uzun gaplardan qoch.\n"
        "- Har bir band bitta asosiy fikrni ifodalasın.\n"
        "- Kerak bo‘lsa bo‘limlarga ajrat (sarlavhalar bilan).\n\n"
        "Taqiqlanadi:\n"
        "- Keraksiz izohlar.\n"
        "- Shaxsiy fikr yoki sharh.\n"
        "- Badiiy yoki og‘zaki uslub.\n\n"
        "Chiqarish tili:\n"
        "👉 O‘zbek tili (rasmiy va akademik uslubda)"
    )
}
