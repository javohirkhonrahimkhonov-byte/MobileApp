class Post {
  final String id;
  final String authorName;
  final String authorAvatar; // Url or Initials
  final String authorRole; // e.g. "315-21 Guruh", "Dekan"
  final String content;
  final String? timeAgo;
  final int likes;
  final int commentsCount;
  final List<String> tags;
  final bool isLiked; // by current user
  final bool isVerified; // Blue checkmark (Official)
  final bool isTyutor; // Special badge
  final int views; // View count
  final int usefulScore; // "Foydali" score

  Post({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.authorRole,
    required this.content,
    this.timeAgo = "Hozirgina",
    this.likes = 0,
    this.commentsCount = 0,
    this.tags = const [],
    this.isLiked = false,
    this.isVerified = false,
    this.isTyutor = false,
    this.views = 0,
    this.usefulScore = 0,
  });
}

class Comment {
  final String id;
  final String authorName;
  final String authorAvatar; // Initials or URL
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
