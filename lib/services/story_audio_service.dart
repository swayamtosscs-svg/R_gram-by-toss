import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to store and retrieve audio file paths for stories locally
class StoryAudioService {
  static const String _audioMapKey = 'story_audio_map';

  /// Store audio path and name for a story
  static Future<void> storeStoryAudio({
    required String storyId,
    required String? audioPath,
    required String? audioName,
  }) async {
    try {
      if (audioPath == null || audioPath.isEmpty) {
        return; // Don't store if no audio
      }

      final prefs = await SharedPreferences.getInstance();
      final audioMapJson = prefs.getString(_audioMapKey) ?? '{}';
      final Map<String, dynamic> audioMap = Map<String, dynamic>.from(
        jsonDecode(audioMapJson),
      );

      // Store audio info
      audioMap[storyId] = {
        'songPath': audioPath,
        'songName': audioName ?? 'Unknown Song',
      };

      await prefs.setString(_audioMapKey, jsonEncode(audioMap));
      print('StoryAudioService: Stored audio for story $storyId: $audioName');
    } catch (e) {
      print('StoryAudioService: Error storing audio: $e');
    }
  }

  /// Get audio path and name for a story
  static Future<Map<String, String?>> getStoryAudio(String storyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final audioMapJson = prefs.getString(_audioMapKey) ?? '{}';
      final Map<String, dynamic> audioMap = Map<String, dynamic>.from(
        jsonDecode(audioMapJson),
      );

      if (audioMap.containsKey(storyId)) {
        final audioInfo = audioMap[storyId] as Map<String, dynamic>;
        return {
          'songPath': audioInfo['songPath'] as String?,
          'songName': audioInfo['songName'] as String?,
        };
      }

      return {'songPath': null, 'songName': null};
    } catch (e) {
      print('StoryAudioService: Error getting audio: $e');
      return {'songPath': null, 'songName': null};
    }
  }

  /// Remove audio for a story (when story is deleted)
  static Future<void> removeStoryAudio(String storyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final audioMapJson = prefs.getString(_audioMapKey) ?? '{}';
      final Map<String, dynamic> audioMap = Map<String, dynamic>.from(
        jsonDecode(audioMapJson),
      );

      audioMap.remove(storyId);
      await prefs.setString(_audioMapKey, jsonEncode(audioMap));
      print('StoryAudioService: Removed audio for story $storyId');
    } catch (e) {
      print('StoryAudioService: Error removing audio: $e');
    }
  }

  /// Get all story audio paths
  static Future<Map<String, Map<String, String?>>> getAllStoryAudio() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final audioMapJson = prefs.getString(_audioMapKey) ?? '{}';
      final Map<String, dynamic> audioMap = Map<String, dynamic>.from(
        jsonDecode(audioMapJson),
      );

      final Map<String, Map<String, String?>> result = {};
      audioMap.forEach((storyId, audioInfo) {
        if (audioInfo is Map<String, dynamic>) {
          result[storyId] = {
            'songPath': audioInfo['songPath'] as String?,
            'songName': audioInfo['songName'] as String?,
          };
        }
      });

      return result;
    } catch (e) {
      print('StoryAudioService: Error getting all audio: $e');
      return {};
    }
  }
}

