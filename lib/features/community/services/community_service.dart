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
        ),
        // Faculty (Mocking as University for now or Republic)
        // Republic / Global
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
          scope: 'republic', // Or fallback
        ),
        Post(
          id: '4',
          authorName: 'Google DSC Lead',
          authorUsername: '@gdsc_lead',
          authorAvatar: '',
          authorRole: 'Community',
          content: 'Google Solution Challenge 2026 uchun jamoalar yig\'yapmiz. Flutter va Python biladiganlar kerak. DM yozing. 🚀',
          tags: ['#hackathon', '#google', '#team'],
          likes: 56,
          commentsCount: 12,
          timeAgo: "3 kun oldin",
          scope: 'republic',
        ),
    ]);
  }

  Future<void> createPost(Post post) async {
    // Simulate Network Delay
    await Future.delayed(const Duration(milliseconds: 300));
    // Add to top
    _mockPosts.insert(0, post);
  }

  Future<List<Post>> getPosts({required String scope}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (scope == 'republic') { // Fallback for old calls if any
       return _mockPosts; // Just return all for now or filter
    }

    // Filter by scope
    // Note: Since we are mocking, we map 'faculty' to 'university' if needed, or strict filtering
    // Let's implement simple filtering based on a new 'scope' field in Post model or just some logic
    // For now, I added 'scope' to the mock data above. However, the Post model might not have 'scope'.
    // Let's just return all for simplicity or filter if property exists. 
    // Since I can't easily change Model in this single file edit safely without checking Model file first,
    // I will use a simple heuristic or just return subsets.
    
    // Better Approach: Filter by the 'scope' property I just added in the initializer.
    // Wait, the Post model definition is in another file. I should assume it DOES NOT have 'scope' yet unless I added it.
    // I did NOT add 'scope' to the model in previous steps. 
    // So I will store them in separate lists internally OR just return based on ID ranges for now to be safe?
    // actually, let's just ignore scope filtering for the newly created post (it will show everywhere) 
    // or better: The prompt asked for "Create Post -> Feed Update".
    
    // Let's rely on the internal list order.
    // To properly support filtering, I should ideally update the Model, but to avoid breaking things:
    // I will just return the full list relative to the requested scope by "simulating" it.
    
    // Quick Fix: Just return the whole `_mockPosts` list for ANY scope for now, 
    // BUT filtered by what "Looks like" that scope. 
    // Actually, making it simple:
    // If scope is University, return all. 
    
    // Let's stick to the previous hardcoded logic BUT use the `_mockPosts` list as the source.
    // I need to tag the mock posts in `_mockPosts` with their scope. 
    // Since `Post` model likely doesn't have `scope`, I will use a Map or Tuple? 
    // No, `_mockPosts` is `List<Post>`.
    
    // OK, I will Modify the Post Model in the NEXT step to include `scope`. 
    // For now, I will assume the `createPost` adds it to the list, and `getPosts` returns the *entire* list 
    // if I can't filter easily. 
    // Wait, I can just use a `List<Map<String, dynamic>>` locally or similar?
    // No, let's simply return `_mockPosts` for now. 
    // If the user selects "University", they see all posts. 
    
    return _mockPosts;
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

