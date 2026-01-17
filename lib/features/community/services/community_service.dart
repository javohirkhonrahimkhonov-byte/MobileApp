import '../models/community_models.dart';

class CommunityService {
  // Singleton Pattern for Persistence
  static final CommunityService _instance = CommunityService._internal();

  factory CommunityService() {
    return _instance;
  }

  CommunityService._internal() {
    _initializeMockData();
  }

  // In-Memory Storage
  final List<Post> _mockPosts = [];

  // Mock Current User Context (Usually from AuthService)
  final String _currentUniversityId = "univ_tatu";
  final String _currentFacultyId = "fac_cyber";
  final String _currentSpecialtyId = "spec_infosec";

  void _initializeMockData() {
    _mockPosts.addAll([
        // Specialty Posts
        Post(
          id: '5',
          authorName: 'Sardor aka (Mentor)',
          authorUsername: '@sardor_dev',
          authorAvatar: '',
          authorRole: 'Dasturlash Kafedrasi',
          content: 'Python bo\'yicha qo\'shimcha darslar har chorshanba 14:00 da 204-xonada bo\'ladi.',
          tags: ['#python', '#dars', '#elon'],
          likes: 25,
          commentsCount: 8,
          sharesCount: 12,
          repostsCount: 3,
          timeAgo: "45 daqiqa oldin",
          isVerified: true,
          usefulScore: 50,
          mediaUrls: [],
          scope: 'specialty',
          targetUniversityId: "univ_tatu",
          targetFacultyId: "fac_cyber",
          targetSpecialtyId: "spec_infosec",
        ),
        Post(
          id: '6',
          authorName: '315-21 Guruh sardori',
          authorUsername: '@leader_315',
          authorAvatar: '',
          authorRole: 'Guruh',
          content: 'Javalar darsiga vazifani gruppaga tashlab qo\'ydim. Ko\'rib olinglar.\n\nErtaga soat 10:00 da zoom bor.',
          tags: ['#java', '#vazifa'],
          likes: 12,
          commentsCount: 3,
          timeAgo: "1 soat oldin",
          scope: 'specialty',
          targetUniversityId: "univ_tatu",
          targetFacultyId: "fac_cyber",
          targetSpecialtyId: "spec_infosec",
        ),
        // University Posts
        Post(
          id: '10', // Poll
          authorName: 'Talabalar Kengashi',
          authorUsername: '@kengash_official',
          authorAvatar: '',
          authorRole: 'Rasmiy',
          content: 'Universitet oshxonasidagi ovqatlar sifati va narxi sizni qoniqtiradimi? Sizning fikringiz muhim! 🍲',
          tags: ['#sorovnoma', '#oshxona', '#muhim'],
          likes: 88,
          commentsCount: 15,
          timeAgo: "30 daqiqa oldin",
          isVerified: true,
          pollOptions: ["Ha, juda zo'r", "Yomon emas, bo'ladi", "Narxi qimmat", "Sifatsiz", "Oshxona bormi? 😅"],
          pollVotes: [12, 45, 20, 8, 3],
          userVote: null,
          scope: 'university',
          targetUniversityId: "univ_tatu",
        ),
        Post(
          id: '1',
          authorName: 'Akramjonov Muhammadali',
          authorUsername: '@akramjonov_m',
          authorAvatar: '',
          authorRole: '315-21 Axborot Xavfsizligi',
          content: 'Ertaga birinchi parada "Kiberxavfsizlik asoslari" darsi bo\'ladimi yoki bekor qilindimi? Domla kasal deb eshitgandim. 🤔',
          tags: ['#dars', '#savol', '#jadval'],
          likes: 5,
          commentsCount: 2,
          timeAgo: "2 soat oldin",
          usefulScore: 12, 
          scope: 'university',
          targetUniversityId: "univ_tatu",
        ),
        // Republic / Global (treated as general)
        Post(
          id: '3',
          authorName: 'Uzbekistan Youth Union',
          authorUsername: '@yoshlar_ittifoqi',
          authorAvatar: '',
          authorRole: 'Respublika',
          content: 'Yozgi "Raqamli Avlod" oromgohiga qabul boshlandi! Ishtirok etish uchun arizalarni @digitalcampbot orqali yuboring. \n\nJoylar soni cheklangan! 🏕️💻',
          tags: ['#lager', '#yoshlar', '#it'],
          mediaUrls: ['https://example.com/camp.jpg'], 
          likes: 128,
          commentsCount: 45,
          sharesCount: 100,
          repostsCount: 50,
          timeAgo: "1 kun oldin",
          isVerified: true, 
          views: 5400,
          scope: 'university', // fallback to university for now as republic tab is gone
          targetUniversityId: "univ_tatu", // Make visible to TATU
        ),
    ]);
  }

  Future<void> createPost(Post post) async {
    // Simulate Network Delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Enrich Post with Current User Context
    final enrichedPost = Post(
      id: post.id,
      authorName: post.authorName,
      authorUsername: post.authorUsername,
      authorAvatar: post.authorAvatar,
      authorRole: post.authorRole,
      content: post.content,
      tags: post.tags,
      timeAgo: post.timeAgo,
      scope: post.scope,
      pollOptions: post.pollOptions,
      pollVotes: post.pollVotes,
      
      // Strict Context Assignment
      targetUniversityId: _currentUniversityId,
      targetFacultyId: post.scope == 'faculty' || post.scope == 'specialty' ? _currentFacultyId : null,
      targetSpecialtyId: post.scope == 'specialty' ? _currentSpecialtyId : null,
    );

    // Add to top
    _mockPosts.insert(0, enrichedPost);
  }

  Future<List<Post>> getPosts({required String scope}) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // Strict Filtering Logic
    return _mockPosts.where((p) {
      // 1. Filter by requested Scope (Tab)
      if (p.scope != scope && !(scope == 'university' && p.scope == 'republic')) return false;

      // 2. Filter by User Context
      // University Tab -> Show only my University posts (and Global/Republic if mapped)
      if (scope == 'university') {
         return p.targetUniversityId == _currentUniversityId || p.targetUniversityId == null; // null means global
      }
      
      // Faculty Tab -> Show only my Faculty posts
      if (scope == 'faculty') {
         return p.targetUniversityId == _currentUniversityId && p.targetFacultyId == _currentFacultyId;
      }
      
      // Specialty Tab -> Show only my Specialty posts
      if (scope == 'specialty') {
         return p.targetUniversityId == _currentUniversityId && 
                p.targetFacultyId == _currentFacultyId &&
                p.targetSpecialtyId == _currentSpecialtyId;
      }

      return false;
    }).toList();
  }

  Future<List<Comment>> getComments(String postId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (postId == '1') {
      return [
        Comment(
          id: '101',
          authorName: 'Aliyev Vali',
          content: 'Ha, domla kasal ekanlar, dars bo\'lmaydi.',
          timeAgo: '1 soat oldin',
        ),
      ];
    } 
    return [];
  }

  // --- New Chat Methods ---

  Future<List<Chat>> getChats() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Chat(
        id: '1',
        partnerName: 'Akramjonov Muhammadali',
        partnerAvatar: '',
        lastMessage: 'Ertaga darsga borasanmi?',
        timeAgo: '5 daqiqa',
        unreadCount: 2,
        isOnline: true,
      ),
      Chat(
        id: '2',
        partnerName: 'Sardor aka (Mentor)',
        partnerAvatar: '',
        lastMessage: 'Rahmat, tushundim.',
        timeAgo: '1 soat',
        isOnline: false,
      ),
      Chat(
        id: '3',
        partnerName: 'Google DSC Lead',
        partnerAvatar: '',
        lastMessage: 'Jamoaga qabul qilindingiz!',
        timeAgo: 'Kecha',
      ),
    ];
  }

  Future<List<Message>> getMessages(String chatId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (chatId == '1') {
      return [
         Message(id: '1', content: 'Salom, qalaysan?', isMe: false, timestamp: '10:00'),
         Message(id: '2', content: 'Yaxshi rahmat, o\'zingchi?', isMe: true, timestamp: '10:01', isRead: true),
         Message(id: '3', content: 'Ertaga darsga borasanmi?', isMe: false, timestamp: '10:05'),
         Message(id: '4', content: 'Ha, albatta. 1-para muhim.', isMe: true, timestamp: '10:06', isRead: false),
      ];
    }
    return [];
  }
}

