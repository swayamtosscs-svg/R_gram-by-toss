import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/post_model.dart';

class ReelsManagementService {
  static const String baseUrl = 'http://103.14.120.163:8081/api/reels-management';

  /// Upload a reel with video
  static Future<ReelsManagementResponse> uploadReel({
    required String token,
    required File video,
    String? caption,
    bool isPublic = true,
  }) async {
    try {
      print('ReelsManagementService: Uploading reel...');
      
      if (!await video.exists()) {
        return ReelsManagementResponse(
          success: false,
          message: 'Video file does not exist',
        );
      }

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

      // Add video file - field name must be 'video'
      final fileExtension = video.path.split('.').last.toLowerCase();
      final contentType = MediaType('video', fileExtension);

      request.files.add(
        await http.MultipartFile.fromPath(
          'video',
          video.path,
          contentType: contentType,
        ),
      );

      print('ReelsManagementService: Sending request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('ReelsManagementService: Response status: ${response.statusCode}');
      print('ReelsManagementService: Response body: ${response.body}');

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (jsonResponse['success'] == true && jsonResponse['reel'] != null) {
          return ReelsManagementResponse(
            success: true,
            message: jsonResponse['message'] ?? 'Reel uploaded successfully',
            reel: _parseReelFromJson(jsonResponse['reel']),
          );
        }
      }

      return ReelsManagementResponse(
        success: false,
        message: jsonResponse['error'] ?? jsonResponse['message'] ?? 'Failed to upload reel',
      );
    } catch (e) {
      print('ReelsManagementService: Error uploading reel: $e');
      return ReelsManagementResponse(
        success: false,
        message: 'Error uploading reel: $e',
      );
    }
  }

  /// Retrieve reels with optional filters
  static Future<ReelsManagementListResponse> retrieveReels({
    required String token,
    String? reelId,
    String? userId,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      print('ReelsManagementService: Retrieving reels...');
      
      final queryParams = <String, String>{};
      if (reelId != null) queryParams['reelId'] = reelId;
      if (userId != null) queryParams['userId'] = userId;
      queryParams['limit'] = limit.toString();
      queryParams['offset'] = offset.toString();

      final uri = Uri.parse('$baseUrl/retrieve').replace(queryParameters: queryParams);
      
      print('ReelsManagementService: Request URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('ReelsManagementService: Response status: ${response.statusCode}');
      print('ReelsManagementService: Response body: ${response.body}');

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        List<Post> reels = [];
        
        if (jsonResponse['reel'] != null) {
          // Single reel response
          reels.add(_parseReelFromJson(jsonResponse['reel']));
        } else if (jsonResponse['reels'] != null) {
          // List of reels response
          reels = (jsonResponse['reels'] as List)
              .map((item) => _parseReelFromJson(item))
              .toList();
        }

        return ReelsManagementListResponse(
          success: true,
          message: jsonResponse['message'] ?? 'Reels retrieved successfully',
          reels: reels,
          total: jsonResponse['total'] ?? reels.length,
          limit: jsonResponse['limit'] ?? limit,
          offset: jsonResponse['offset'] ?? offset,
        );
      }

      return ReelsManagementListResponse(
        success: false,
        message: jsonResponse['error'] ?? jsonResponse['message'] ?? 'Failed to retrieve reels',
        reels: [],
        total: 0,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      print('ReelsManagementService: Error retrieving reels: $e');
      return ReelsManagementListResponse(
        success: false,
        message: 'Error retrieving reels: $e',
        reels: [],
        total: 0,
        limit: limit,
        offset: offset,
      );
    }
  }

  /// Delete a reel
  static Future<ReelsManagementResponse> deleteReel({
    required String token,
    required String reelId,
  }) async {
    try {
      print('ReelsManagementService: Deleting reel: $reelId');

      final response = await http.delete(
        Uri.parse('$baseUrl/delete?reelId=$reelId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('ReelsManagementService: Delete response status: ${response.statusCode}');
      print('ReelsManagementService: Delete response body: ${response.body}');

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return ReelsManagementResponse(
          success: true,
          message: jsonResponse['message'] ?? 'Reel deleted successfully',
        );
      }

      return ReelsManagementResponse(
        success: false,
        message: jsonResponse['error'] ?? jsonResponse['message'] ?? 'Failed to delete reel',
      );
    } catch (e) {
      print('ReelsManagementService: Error deleting reel: $e');
      return ReelsManagementResponse(
        success: false,
        message: 'Error deleting reel: $e',
      );
    }
  }

  /// Like a reel
  static Future<ReelsManagementResponse> likeReel({
    required String token,
    required String reelId,
  }) async {
    try {
      print('ReelsManagementService: Liking reel: $reelId');

      final response = await http.post(
        Uri.parse('$baseUrl/like?reelId=$reelId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('ReelsManagementService: Like response status: ${response.statusCode}');
      print('ReelsManagementService: Like response body: ${response.body}');

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return ReelsManagementResponse(
          success: true,
          message: jsonResponse['message'] ?? 'Reel liked successfully',
          likesCount: jsonResponse['likesCount'] ?? 0,
          isLiked: jsonResponse['isLiked'] ?? true,
        );
      }

      return ReelsManagementResponse(
        success: false,
        message: jsonResponse['error'] ?? jsonResponse['message'] ?? 'Failed to like reel',
      );
    } catch (e) {
      print('ReelsManagementService: Error liking reel: $e');
      return ReelsManagementResponse(
        success: false,
        message: 'Error liking reel: $e',
      );
    }
  }

  /// Unlike a reel
  static Future<ReelsManagementResponse> unlikeReel({
    required String token,
    required String reelId,
  }) async {
    try {
      print('ReelsManagementService: Unliking reel: $reelId');

      final response = await http.delete(
        Uri.parse('$baseUrl/unlike?reelId=$reelId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('ReelsManagementService: Unlike response status: ${response.statusCode}');
      print('ReelsManagementService: Unlike response body: ${response.body}');

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['success'] == true) {
        return ReelsManagementResponse(
          success: true,
          message: jsonResponse['message'] ?? 'Reel unliked successfully',
          likesCount: jsonResponse['likesCount'] ?? 0,
          isLiked: jsonResponse['isLiked'] ?? false,
        );
      }

      return ReelsManagementResponse(
        success: false,
        message: jsonResponse['error'] ?? jsonResponse['message'] ?? 'Failed to unlike reel',
      );
    } catch (e) {
      print('ReelsManagementService: Error unliking reel: $e');
      return ReelsManagementResponse(
        success: false,
        message: 'Error unliking reel: $e',
      );
    }
  }

  /// Parse reel from JSON response
  static Post _parseReelFromJson(Map<String, dynamic> json) {
    // Parse media path
    final mediaPath = json['mediaPath'] ?? '';
    final baseUrl = 'http://103.14.120.163:8081';
    final fullMediaPath = mediaPath.startsWith('http') ? mediaPath : '$baseUrl$mediaPath';

    // Parse thumbnail path
    final thumbnailPath = json['thumbnailPath'] ?? '';
    final fullThumbnailPath = thumbnailPath.startsWith('http')
        ? thumbnailPath
        : (thumbnailPath.isNotEmpty ? '$baseUrl$thumbnailPath' : null);

    return Post(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      userAvatar: json['userAvatar'] ?? '',
      caption: json['caption'] ?? '',
      imageUrl: fullThumbnailPath,
      videoUrl: fullMediaPath,
      type: PostType.reel,
      likes: json['likesCount'] ?? 0,
      likesCount: json['likesCount'] ?? 0,
      comments: json['commentsCount'] ?? 0,
      shares: 0,
      isLiked: json['isLikedByUser'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      hashtags: [],
      isReel: true,
      isPrivate: json['isPublic'] == false,
      thumbnailUrl: fullThumbnailPath,
    );
  }
}

class ReelsManagementResponse {
  final bool success;
  final String message;
  final Post? reel;
  final int? likesCount;
  final bool? isLiked;

  ReelsManagementResponse({
    required this.success,
    required this.message,
    this.reel,
    this.likesCount,
    this.isLiked,
  });
}

class ReelsManagementListResponse {
  final bool success;
  final String message;
  final List<Post> reels;
  final int total;
  final int limit;
  final int offset;

  ReelsManagementListResponse({
    required this.success,
    required this.message,
    required this.reels,
    required this.total,
    required this.limit,
    required this.offset,
  });
}

