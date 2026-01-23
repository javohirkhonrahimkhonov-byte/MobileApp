class Post {
  final String id;
  final String authorName;
  final String authorUsername; // @handle
  final String authorAvatar; // Url or Initials
  final String authorRole; // e.g. "315-21 Guruh", "Dekan"
  final String content;
  final String? timeAgo;
  final int likes;
  final int commentsCount;
  final int sharesCount;
  final int repostsCount;
  final List<String> tags;
  final List<String> mediaUrls; // Images/Videos
  final bool isLiked; // by current user
  final bool isVerified; // Blue checkmark (Official)
  final bool isTyutor; // Special badge
  final int views; // View count
  final int usefulScore; // "Foydali" score
  final List<String>? pollOptions; // If not null, it's a poll
  final List<int>? pollVotes; // Vote counts per option
  final int? userVote; // Index of option user voted for (or null)
  final String? scope; // 'university', 'faculty', 'specialty'
  final String? targetUniversityId;
  final String? targetFacultyId;
  final String? targetSpecialtyId;
  final bool isMine;
  final bool isRepostedByMe;
  final DateTime createdAt; // Added

  Post({
    required this.id,
    required this.authorName,
    this.authorUsername = "",
    required this.authorAvatar,
    required this.authorRole,
    required this.content,
    this.timeAgo = "Hozirgina", // Can be calculated from createdAt
    required this.createdAt, // Added
    this.likes = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.repostsCount = 0,
    this.tags = const [],
    this.mediaUrls = const [],
    this.isLiked = false,
    this.isVerified = false,
    this.isTyutor = false,
    this.views = 0,
    this.usefulScore = 0,
    this.pollOptions,
    this.pollVotes,
    this.userVote,
    this.scope,
    this.targetUniversityId,
    this.targetFacultyId,
    this.targetSpecialtyId,
    this.isMine = false,
    this.isRepostedByMe = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'].toString(),
      content: json['content'],
      scope: json['category_type'],
      authorName: json['author_name'],
      authorUsername: json['author_username'] ?? "",
      authorAvatar: json['author_avatar'] ?? "",
      authorRole: json['author_role'] ?? "Talaba",
      createdAt: DateTime.parse(json['created_at']),
      likes: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      repostsCount: json['reposts_count'] ?? 0,
      isLiked: json['is_liked_by_me'] ?? false,
      isRepostedByMe: json['is_reposted_by_me'] ?? false,
      isMine: json['is_mine'] ?? false,
      targetUniversityId: json['target_university_id']?.toString(),
      targetFacultyId: json['target_faculty_id']?.toString(),
      targetSpecialtyId: json['target_specialty_name'],
    );
  }

  Post copyWith({
    String? id,
    String? authorName,
    String? authorUsername,
    String? authorAvatar,
    String? authorRole,
    String? content,
    String? timeAgo,
    int? likes,
    int? commentsCount,
    int? sharesCount,
    int? repostsCount,
    List<String>? tags,
    List<String>? mediaUrls,
    bool? isLiked,
    bool? isVerified,
    bool? isTyutor,
    int? views,
    int? usefulScore,
    List<String>? pollOptions,
    List<int>? pollVotes,
    int? userVote,
    String? scope,
    String? targetUniversityId,
    String? targetFacultyId,
    String? targetSpecialtyId,
    bool? isMine,
    bool? isRepostedByMe,
    DateTime? createdAt,
  }) {
    return Post(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorRole: authorRole ?? this.authorRole,
      content: content ?? this.content,
      timeAgo: timeAgo ?? this.timeAgo,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      repostsCount: repostsCount ?? this.repostsCount,
      tags: tags ?? this.tags,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      isLiked: isLiked ?? this.isLiked,
      isVerified: isVerified ?? this.isVerified,
      isTyutor: isTyutor ?? this.isTyutor,
      views: views ?? this.views,
      usefulScore: usefulScore ?? this.usefulScore,
      pollOptions: pollOptions ?? this.pollOptions,
      pollVotes: pollVotes ?? this.pollVotes,
      userVote: userVote ?? this.userVote,
      scope: scope ?? this.scope,
      targetUniversityId: targetUniversityId ?? this.targetUniversityId,
      targetFacultyId: targetFacultyId ?? this.targetFacultyId,
      targetSpecialtyId: targetSpecialtyId ?? this.targetSpecialtyId,
      isMine: isMine ?? this.isMine,
      isRepostedByMe: isRepostedByMe ?? this.isRepostedByMe,
    );
  }
}

class Comment {
  final String id;
  final String postId; // Added
  final String authorName;
  final String authorUsername; // Added
  final String authorAvatar;
  final String content;
  final String timeAgo;
  final DateTime createdAt; // Added
  final int likes;
  final bool isLiked;
  final bool isLikedByAuthor;
  final String? authorRole;
  final String? replyToUserName;
  final String? replyToContent;
  final bool isMine;

  Comment({
    required this.id,
    required this.postId, // Added
    required this.authorName,
    this.authorUsername = "", // Added
    this.authorAvatar = "",
    required this.content,
    required this.timeAgo,
    required this.createdAt, // Added
    this.likes = 0,
    this.isLiked = false,
    this.isLikedByAuthor = false,
    this.authorRole,
    this.replyToUserName,
    this.replyToContent,
    this.isMine = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'].toString(),
      postId: json['post_id']?.toString() ?? "0",
      content: json['content'],
      authorName: json['author_name'],
      authorUsername: json['author_username'] ?? "", // Added
      authorAvatar: json['author_avatar'] ?? "",
      authorRole: "Talaba",
      createdAt: DateTime.parse(json['created_at']),
      timeAgo: "Hozirgina", 
      likes: json['likes_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      isMine: json['is_mine'] ?? false,
      isLikedByAuthor: json['is_liked_by_author'] ?? false,
      replyToUserName: json['reply_user'],
    );
  }

  Comment copyWith({
    String? id,
    String? postId,
    String? authorName,
    String? authorUsername,
    String? authorAvatar,
    String? content,
    String? timeAgo,
    DateTime? createdAt,
    int? likes,
    bool? isLiked,
    bool? isLikedByAuthor,
    String? authorRole,
    String? replyToUserName,
    String? replyToContent,
    bool? isMine,
  }) {
    return Comment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorName: authorName ?? this.authorName,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      content: content ?? this.content,
      timeAgo: timeAgo ?? this.timeAgo,
      createdAt: createdAt ?? this.createdAt,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      isLikedByAuthor: isLikedByAuthor ?? this.isLikedByAuthor,
      authorRole: authorRole ?? this.authorRole,
      replyToUserName: replyToUserName ?? this.replyToUserName,
      replyToContent: replyToContent ?? this.replyToContent,
      isMine: isMine ?? this.isMine,
    );
  }
}

class Chat {
  final String id;
  final String partnerName;
  final String partnerAvatar;
  final String lastMessage;
  final String timeAgo;
  final int unreadCount;
  final bool isOnline;

  Chat({
    required this.id,
    required this.partnerName,
    required this.partnerAvatar,
    required this.lastMessage,
    required this.timeAgo,
    this.unreadCount = 0,
    this.isOnline = false,
  });
}

class Message {
  final String id;
  final String content;
  final bool isMe;
  final String timestamp;
  final bool isRead;
  final String? mediaUrl;

  Message({
    required this.id,
    required this.content,
    required this.isMe,
    required this.timestamp,
    this.isRead = false,
    this.mediaUrl,
  });
}
