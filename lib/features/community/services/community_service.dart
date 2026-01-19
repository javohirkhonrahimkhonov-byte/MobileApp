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

  Post _mapJsonToPost(Map<String, dynamic> json) {
    return Post(
      id: json['id'].toString(),
      authorName: json['author_name'] ?? "Talaba",
      authorUsername: "@student", // Placeholder
      authorAvatar: "", // Placeholder
      authorRole: json['author_role'] ?? "Talaba",
      content: json['content'] ?? "",
      timeAgo: _formatDate(json['created_at']),
      scope: json['category_type'],
      targetUniversityId: json['target_university_id']?.toString(),
      targetFacultyId: json['target_faculty_id']?.toString(),
      targetSpecialtyId: json['target_specialty_name'], // Mapping name to ID field as per backend logic
      
      // Defaults for now (Backend doesn't have these yet)
      likes: 0,
      commentsCount: 0,
      isVerified: false,
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

