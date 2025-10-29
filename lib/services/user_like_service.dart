import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserLikeService {
  static const String _likesKey = 'user_post_likes';

  /// Get liked posts from local storage
  static Future<Set<String>> getLikedPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final likedPostsJson = prefs.getString(_likesKey);
      if (likedPostsJson != null) {
        final List<dynamic> likedPostsList = jsonDecode(likedPostsJson);
        return likedPostsList.map((e) => e.toString()).toSet();
      }
      return <String>{};
    } catch (e) {
      print('Error getting liked posts: $e');
      return <String>{};
    }
  }

  /// Save liked posts to local storage
  static Future<void> saveLikedPosts(Set<String> likedPosts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_likesKey, jsonEncode(likedPosts.toList()));
    } catch (e) {
      print('Error saving liked posts: $e');
    }
  }

  /// Check if a post is liked locally
  static Future<bool> isPostLiked(String postId) async {
    final likedPosts = await getLikedPosts();
    return likedPosts.contains(postId);
  }

  /// Like a user post - DISABLED: This functionality has been removed
  @deprecated
  static Future<Map<String, dynamic>> likeUserPost({
    required String postId,
    required String token,
    required String userId,
  }) async {
    // Like functionality has been disabled - return success with no-op
    print('UserLikeService: Like functionality is disabled');
    return {
      'success': false,
      'message': 'Like functionality has been disabled',
      'data': {'likesCount': 0},
    };
  }

  /// Unlike a user post - DISABLED: This functionality has been removed
  @deprecated
  static Future<Map<String, dynamic>> unlikeUserPost({
    required String postId,
    required String token,
    required String userId,
  }) async {
    // Unlike functionality has been disabled - return success with no-op
    print('UserLikeService: Unlike functionality is disabled');
    return {
      'success': false,
      'message': 'Unlike functionality has been disabled',
      'data': {'likesCount': 0},
    };
  }

  /// Toggle like/unlike - DISABLED: This functionality has been removed
  @deprecated
  static Future<Map<String, dynamic>> toggleUserPostLike({
    required String postId,
    required String token,
    required String userId,
    required bool isCurrentlyLiked,
  }) async {
    // Toggle like functionality has been disabled - return no-op
    print('UserLikeService: Toggle like functionality is disabled');
    return {
      'success': false,
      'message': 'Toggle like functionality has been disabled',
      'data': {'likesCount': 0},
    };
  }

  /// Local like
  static Map<String, dynamic> _fallbackLike(String postId) {
    return {
      'success': true,
      'message': 'Post liked locally (offline mode)',
      'data': {'likesCount': 1},
    };
  }

  /// Local unlike
  static Map<String, dynamic> _fallbackUnlike(String postId) {
    return {
      'success': true,
      'message': 'Post unliked locally (offline mode)',
      'data': {'likesCount': 0},
    };
  }
}
