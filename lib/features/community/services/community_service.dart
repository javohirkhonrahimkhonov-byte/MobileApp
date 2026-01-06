import '../models/community_models.dart';

class CommunityService {
  Future<List<Post>> getPosts({required String scope}) async {
    // Mock API Delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (scope == "university") {
      return [
        Post(
          id: '1',
          authorName: 'Akramjonov Muhammadali',
          authorAvatar: '',
          authorRole: '315-21 Axborot Xavfsizligi',
          content: 'Ertaga birinchi parada "Kiberxavfsizlik asoslari" darsi bo\'ladimi yoki bekor qilindimi? Domla kasal deb eshitgandim.',
          tags: ['#dars', '#savol', '#jadval'],
          likes: 5,
          commentsCount: 2,
          timeAgo: "2 soat oldin",
        ),
        Post(
          id: '2',
          authorName: 'Abdullayeva Zarnigor',
          authorAvatar: '',
          authorRole: 'Tyutor',
          content: 'Hurmatli talabalar! Kontrakt to\'lovining oxirgi muddati 15-martgacha uzaytirildi. Iltimos, to\'lov kvitansiyalarini dekanatga topshiring.',
          tags: ['#kontrakt', '#muhim', '#dekanat'],
          likes: 42,
          commentsCount: 0,
          timeAgo: "5 soat oldin",
        ),
      ];
    } else {
      // Republic / Global
      return [
        Post(
          id: '3',
          authorName: 'Uzbekistan Youth Union',
          authorAvatar: '',
          authorRole: 'Respublika',
          content: 'Yozgi "Raqamli Avlod" oromgohiga qabul boshlandi! Ishtirok etish uchun arizalarni @digitalcampbot orqali yuboring.',
          tags: ['#lager', '#yoshlar', '#it'],
          likes: 128,
          commentsCount: 45,
          timeAgo: "1 kun oldin",
        ),
        Post(
          id: '4',
          authorName: 'Google DSC Lead',
          authorAvatar: '',
          authorRole: 'Community',
          content: 'Google Solution Challenge 2026 uchun jamoalar yig\'yapmiz. Flutter va Python biladiganlar kerak. DM yozing.',
          tags: ['#hackathon', '#google', '#team'],
          likes: 56,
          commentsCount: 12,
          timeAgo: "3 kun oldin",
        ),
      ];
    }
  }
}
