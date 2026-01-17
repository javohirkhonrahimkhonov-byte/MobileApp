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

  Post({
    required this.id,
    required this.authorName,
    this.authorUsername = "@student",
    required this.authorAvatar,
    required this.authorRole,
    required this.content,
    this.timeAgo = "Hozirgina",
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
  });
}

class Comment {
  final String id;
  final String authorName;
  final String authorAvatar;
  final String content;
  final String timeAgo;

  Comment({
    required this.id,
    required this.authorName,
    this.authorAvatar = "",
    required this.content,
    required this.timeAgo,
  });
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
