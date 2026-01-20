import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/auth_service.dart';
import '../models/community_models.dart';

class CommunityService {
  // Singleton Pattern
  static final CommunityService _instance = CommunityService._internal();

  factory CommunityService() {
    return _instance;
  }

  CommunityService._internal();

  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<void> createPost(Post post) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.communityPosts),
        headers: await _getHeaders(),
        body: json.encode({
          'content': post.content,
          'category_type': post.scope,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Failed to create post: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("CommunityService: Error creating post: $e");
      rethrow;
    }
  }

  Future<List<Post>> getPosts({required String scope}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.communityPosts}?category=$scope'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => _mapJsonToPost(json)).toList();
      } else {
        print("CommunityService: Failed to load posts: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("CommunityService: Error loading posts: $e");
      return [];
    }
  }

  Future<Post?> getPost(String postId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.communityPosts}/$postId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return _mapJsonToPost(json.decode(response.body));
      } else {
        print("CommunityService: Failed to load post: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("CommunityService: Error loading post: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> likePost(String postId) async {
    final token = await _authService.getToken(); 
    final url = '${ApiConstants.communityPosts}/$postId/like';
    print("CommunityService: Liking post at $url");
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("CommunityService: Like failed ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("CommunityService: Like error $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> repostPost(String postId) async {
    final url = '${ApiConstants.communityPosts}/$postId/repost';
    print("CommunityService: Reposting post at $url");
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("CommunityService: Repost failed ${response.statusCode}");
        return null;
      }
    } catch (e) {
       print("CommunityService: Repost error $e");
       return null;
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      final response = await http.delete(
         Uri.parse('${ApiConstants.communityPosts}/$postId'),
         headers: await _getHeaders(),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print("CommunityService: Error deleting post: $e");
      return false;
    }
  }

  Future<bool> editPost(String postId, String newContent) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.communityPosts}/$postId'),
        headers: await _getHeaders(),
        body: json.encode({
          'content': newContent,
          'category_type': 'university', 
        }),
      );
      
      print("Edit Post Result: ${response.statusCode}");
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print("CommunityService: Error editing post: $e");
      return false;
    }
  }

  Post _mapJsonToPost(Map<String, dynamic> json) {
    return Post(
      id: json['id'].toString(),
      authorName: json['author_name'] ?? "Noma'lum",
      authorUsername: "@student", // Placeholder
      authorAvatar: "", // Placeholder
      authorRole: json['author_role'] ?? "Talaba",
      content: json['content'] ?? "",
      timeAgo: _formatDate(json['created_at']),
      scope: json['category_type'],
      targetUniversityId: json['target_university_id']?.toString(),
      targetFacultyId: json['target_faculty_id']?.toString(),
      targetSpecialtyId: json['target_specialty_name'], // Mapping name to ID field as per backend logic
      
      likes: json['likes_count'] ?? 0,
      isLiked: json['is_liked_by_me'] ?? false,
      repostsCount: json['reposts_count'] ?? 0,
      isRepostedByMe: json['is_reposted_by_me'] ?? false,
      commentsCount: json['comments_count'] ?? 0,
      isVerified: false,
      isMine: json['is_mine'] ?? false,
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "";
    try {
      // Backend returns UTC time (e.g. 2024-01-19T07:00:00)
      // We must append 'Z' if missing to properly parse as UTC, or force isUtc: true.
      if (!dateStr.endsWith('Z')) {
        dateStr = "${dateStr}Z";
      }
      
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return "Hozirgina";
      if (diff.inMinutes < 60) return "${diff.inMinutes} daqiqa oldin";
      if (diff.inHours < 24) return "${diff.inHours} soat oldin";
      return "${diff.inDays} kun oldin";
    } catch (e) {
      return "Yaqinda";
    }
  }

  // --- Mocked Chat Methods (Keep as Mock for now) ---

  Future<List<Comment>> getComments(String postId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.communityPosts}/$postId/comments'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Comment(
          id: json['id'].toString(),
          authorName: json['author_name'] ?? "Talaba",
          authorAvatar: json['author_avatar'] ?? "",
          content: json['content'] ?? "",
          timeAgo: _formatDate(json['created_at']),
          likes: json['likes_count'] ?? 0,
          isLiked: json['is_liked'] ?? false,
          isLikedByAuthor: json['is_liked_by_author'] ?? false,
          authorRole: json['author_role'] ?? "Talaba",
          replyToUserName: json['reply_to_username'],
          replyToContent: json['reply_to_content'],
        )).toList();
      } else {
        print("CommunityService: Failed to load comments: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("CommunityService: Error loading comments: $e");
      return [];
    }
  }

  Future<void> createComment(String postId, String content, {String? replyToId}) async {
    try {
      final body = {
        'content': content,
      };
      if (replyToId != null) {
        body['reply_to_comment_id'] = replyToId;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.communityPosts}/$postId/comments'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Failed to create comment: ${response.statusCode}");
      }
    } catch (e) {
      print("CommunityService: Error creating comment: $e");
      rethrow;
    }
  }

  Future<bool> likeComment(String commentId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.backendUrl}/community/comments/$commentId/like'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print("CommunityService: Error liking comment: $e");
      return false;
    }
  }

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
    ];
  }

  Future<List<Message>> getMessages(String chatId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }
}

