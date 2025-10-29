import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/post_model.dart';

class PostsManagementService {
  static const String baseUrl = 'http://103.14.120.163:8081/api/posts-management';

  /// Upload a post with media (image or video) or text only
  static Future<PostsManagementResponse> uploadPost({
    required String token,
    File? media,
    String? caption,
    bool isPublic = true,
  }) async {
    try {
      print('PostsManagementService: Uploading post...');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add caption
      if (caption != null && caption.isNotEmpty) {
        request.fields['caption'] = caption;
      }

      // Add isPublic field
      request.fields['isPublic'] = isPublic.toString();

      // Add media if provided
      if (media != null && await media.exists()) {
        final fileExtension = media.path.split('.').last.toLowerCase();
        final isVideo = ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm'].contains(fileExtension);
        
        final contentType = isVideo
            ? MediaType('video', fileExtension)
            : MediaType('image', fileExtension);

        request.files.add(
          await http.MultipartFile.fromPath(
            'media',
            media.path,
            contentType: contentType,
          ),
        );
      }

      print('PostsManagementService: Sending request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('PostsManagementService: Response status: ${response.statusCode}');
      print('PostsManagementService: Response body: ${response.body}');

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (jsonResponse['success'] == true && jsonResponse['post'] != null) {
          return PostsManagementResponse(
            success: true,
            message: jsonResponse['message'] ?? 'Post uploaded successfully',
            post: _parsePostFromJson(jsonResponse['post']),
          );
        }
      }

      return PostsManagementResponse(
        success: false,
        message: jsonResponse['error'] ?? jsonResponse['message'] ?? 'Failed to upload post',
      );
    } catch (e) {
      print('PostsManagementService: Error uploading post: $e');
      return PostsManagementResponse(
        success: false,
        message: 'Error uploading post: $e',
      );
    }
  }

  /// Retrieve posts with optional filters
  static Future<PostsManagementListResponse> retrievePosts({
    required String token,
    String? postId,
    String? userId,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      print('PostsManagementService: Retrieving posts...');
      
      final queryParams = <String, String>{};
      if (postId != null) queryParams['postId'] = postId;
      if (userId != null) queryParams['userId'] = userId;
      queryParams['limit'] = limit.toString();
      queryParams['offset'] = offset.toString();

      final uri = Uri.parse('$baseUrl/retrieve').replace(queryParameters: queryParams);
      
      print('PostsManagementService: Request URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('PostsManagementService: Response status: ${response.statusCode}');
      print('PostsManagementService: Response body: ${response.body}');

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        List<Post> posts = [];
        
        if (jsonResponse['post'] != null) {
          // Single post response
          posts.add(_parsePostFromJson(jsonResponse['post']));
        } else if (jsonResponse['posts'] != null) {
          // List of posts response
          posts = (jsonResponse['posts'] as List)
              .map((item) => _parsePostFromJson(item))
              .toList();
        }

        return PostsManagementListResponse(
          success: true,
          message: jsonResponse['message'] ?? 'Posts retrieved successfully',
          posts: posts,
          total: jsonResponse['total'] ?? posts.length,
          limit: jsonResponse['limit'] ?? limit,
          offset: jsonResponse['offset'] ?? offset,
        );
      }

      return PostsManagementListResponse(
        success: false,
        message: jsonResponse['error'] ?? jsonResponse['message'] ?? 'Failed to retrieve posts',
        posts: [],
        total: 0,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      print('PostsManagementService: Error retrieving posts: $e');
      return PostsManagementListResponse(
        success: false,
        message: 'Error retrieving posts: $e',
        posts: [],
        total: 0,
        limit: limit,
        offset: offset,
      );
    }
  }

  /// Delete a post
  static Future<PostsManagementResponse> deletePost({
    required String token,
    required String postId,
  }) async {
    try {
      print('PostsManagementService: Deleting post: $postId');

      final response = await http.delete(
        Uri.parse('$baseUrl/delete?postId=$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('PostsManagementService: Delete response status: ${response.statusCode}');
      print('PostsManagementService: Delete response body: ${response.body}');

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return PostsManagementResponse(
          success: true,
          message: jsonResponse['message'] ?? 'Post deleted successfully',
        );
      }

      return PostsManagementResponse(
        success: false,
        message: jsonResponse['error'] ?? jsonResponse['message'] ?? 'Failed to delete post',
      );
    } catch (e) {
      print('PostsManagementService: Error deleting post: $e');
      return PostsManagementResponse(
        success: false,
        message: 'Error deleting post: $e',
      );
    }
  }

  /// Like a post
  static Future<PostsManagementResponse> likePost({
    required String token,
    required String postId,
  }) async {
    try {
      print('PostsManagementService: Liking post: $postId');

      final response = await http.post(
        Uri.parse('$baseUrl/like?postId=$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('PostsManagementService: Like response status: ${response.statusCode}');
      print('PostsManagementService: Like response body: ${response.body}');

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return PostsManagementResponse(
          success: true,
          message: jsonResponse['message'] ?? 'Post liked successfully',
          likesCount: jsonResponse['likesCount'] ?? 0,
          isLiked: jsonResponse['isLiked'] ?? true,
        );
      }

      return PostsManagementResponse(
        success: false,
        message: jsonResponse['error'] ?? jsonResponse['message'] ?? 'Failed to like post',
      );
    } catch (e) {
      print('PostsManagementService: Error liking post: $e');
      return PostsManagementResponse(
        success: false,
        message: 'Error liking post: $e',
      );
    }
  }

  /// Unlike a post
  static Future<PostsManagementResponse> unlikePost({
    required String token,
    required String postId,
  }) async {
    try {
      print('PostsManagementService: Unliking post: $postId');

      final response = await http.delete(
        Uri.parse('$baseUrl/unlike?postId=$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('PostsManagementService: Unlike response status: ${response.statusCode}');
      print('PostsManagementService: Unlike response body: ${response.body}');

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return PostsManagementResponse(
          success: true,
          message: jsonResponse['message'] ?? 'Post unliked successfully',
          likesCount: jsonResponse['likesCount'] ?? 0,
          isLiked: jsonResponse['isLiked'] ?? false,
        );
      }

      return PostsManagementResponse(
        success: false,
        message: jsonResponse['error'] ?? jsonResponse['message'] ?? 'Failed to unlike post',
      );
    } catch (e) {
      print('PostsManagementService: Error unliking post: $e');
      return PostsManagementResponse(
        success: false,
        message: 'Error unliking post: $e',
      );
    }
  }

  /// Parse post from JSON response
  static Post _parsePostFromJson(Map<String, dynamic> json) {
    // Determine media type
    final mediaType = json['mediaType'] ?? 'image';
    PostType postType = PostType.image;
    if (mediaType == 'video') {
      postType = PostType.video;
    } else if (mediaType == 'reel') {
      postType = PostType.reel;
    }

    // Parse media path
    final mediaPath = json['mediaPath'] ?? '';
    final baseUrl = 'http://103.14.120.163:8081';
    final fullMediaPath = mediaPath.startsWith('http') ? mediaPath : '$baseUrl$mediaPath';

    return Post(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      userAvatar: json['userAvatar'] ?? '',
      caption: json['caption'] ?? '',
      imageUrl: postType == PostType.image ? fullMediaPath : null,
      videoUrl: postType == PostType.video || postType == PostType.reel ? fullMediaPath : null,
      type: postType,
      likes: json['likesCount'] ?? 0,
      likesCount: json['likesCount'] ?? 0,
      comments: json['commentsCount'] ?? 0,
      shares: 0,
      isLiked: json['isLikedByUser'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      hashtags: [],
      isReel: postType == PostType.reel,
      isPrivate: json['isPublic'] == false,
    );
  }
}

class PostsManagementResponse {
  final bool success;
  final String message;
  final Post? post;
  final int? likesCount;
  final bool? isLiked;

  PostsManagementResponse({
    required this.success,
    required this.message,
    this.post,
    this.likesCount,
    this.isLiked,
  });
}

class PostsManagementListResponse {
  final bool success;
  final String message;
  final List<Post> posts;
  final int total;
  final int limit;
  final int offset;

  PostsManagementListResponse({
    required this.success,
    required this.message,
    required this.posts,
    required this.total,
    required this.limit,
    required this.offset,
  });
}

