import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/live_stream_model.dart';

class LiveStreamService {
  // Base URL for live streaming API
  static const String baseUrl = 'https://new-live-api.onrender.com';
  // Alternative base URL if needed
  static const String altBaseUrl = 'http://103.14.120.163:8443/api';

  /// Create a new live room
  static Future<Map<String, dynamic>> createLiveRoom({
    required String title,
    required String hostName,
    String? description,
    String? category,
    List<String>? tags,
    bool isPrivate = false,
    int maxViewers = 100,
    bool allowChat = true,
    bool allowViewerSpeak = false,
    String? thumbnail,
  }) async {
    try {
      final request = LiveRoomCreationRequest(
        title: title,
        hostName: hostName,
        description: description,
        category: category,
        tags: tags,
        isPrivate: isPrivate,
        maxViewers: maxViewers,
        allowChat: allowChat,
        allowViewerSpeak: allowViewerSpeak,
        thumbnail: thumbnail,
      );

      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': data['message'] ?? 'Room created successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to create room: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Start a live stream
  static Future<Map<String, dynamic>> startLiveStream({
    required String roomId,
    required String streamKey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms/$roomId/start'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'streamKey': streamKey,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': data['message'] ?? 'Live stream started',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to start stream: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Stop a live stream
  static Future<Map<String, dynamic>> stopLiveStream({
    required String roomId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms/$roomId/stop'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': data['message'] ?? 'Live stream stopped',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to stop stream: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get room status
  static Future<Map<String, dynamic>> getRoomStatus(String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/rooms/$roomId/status'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get room status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get room analytics
  static Future<Map<String, dynamic>> getRoomAnalytics(String roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/rooms/$roomId/analytics'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get analytics: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Join a room as viewer
  static Future<Map<String, dynamic>> joinRoom({
    required String roomId,
    required String userName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms/$roomId/join'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userName': userName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': data['message'] ?? 'Joined room successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to join room: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Leave a room
  static Future<Map<String, dynamic>> leaveRoom({
    required String roomId,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/rooms/$roomId/leave'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'message': data['message'] ?? 'Left room successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to leave room: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  /// Get all active streams
  static Future<Map<String, dynamic>> getStreams() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/streams'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get streams: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}


