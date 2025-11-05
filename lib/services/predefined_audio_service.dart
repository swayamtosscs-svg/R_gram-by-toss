/// Service to manage predefined audio files from assets
class PredefinedAudioService {
  /// List of predefined audio files available in assets
  static const List<Map<String, String>> predefinedAudios = [
    {
      'path': 'assets/audio/bhajan-sorts-trendingshorts-sorts-shorts-religious-viralreels-reels-reel-reel-128-ytshorts.savetube.me.mp3',
      'name': 'Bhajan - Religious',
      'id': 'bhajan_religious',
    },
    {
      'path': 'assets/audio/om-namo-bhagavate-vasudevaya-lyrical-video-hindi-hombale-films-kleem-productions-sam-cs-128-ytshorts.savetube.me.mp3',
      'name': 'Om Namo Bhagavate Vasudevaya',
      'id': 'om_namo_bhagavate',
    },
  ];

  /// Get all predefined audio files
  static List<Map<String, String>> getAllPredefinedAudios() {
    return List.from(predefinedAudios);
  }

  /// Get audio by ID
  static Map<String, String>? getAudioById(String id) {
    try {
      return predefinedAudios.firstWhere(
        (audio) => audio['id'] == id,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if a path is a predefined audio (asset path)
  static bool isPredefinedAudio(String? path) {
    if (path == null || path.isEmpty) return false;
    return path.startsWith('assets/audio/');
  }

  /// Get audio name from path
  static String getAudioNameFromPath(String path) {
    if (isPredefinedAudio(path)) {
      final audio = predefinedAudios.firstWhere(
        (audio) => audio['path'] == path,
        orElse: () => {'name': 'Unknown Audio', 'path': path},
      );
      return audio['name'] ?? 'Unknown Audio';
    }
    // Extract filename from path
    final parts = path.split('/');
    return parts.last.split('.').first;
  }
}

