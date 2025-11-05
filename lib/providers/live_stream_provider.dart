import 'package:flutter/foundation.dart';
import '../models/live_stream_model.dart';
import '../services/live_stream_service.dart';

class LiveStreamProvider extends ChangeNotifier {
  List<LiveRoom> _activeRooms = [];
  bool _isLoading = false;
  String? _error;

  List<LiveRoom> get activeRooms => _activeRooms;
  bool get isLoading => _isLoading;
  String? get error => _error;

  LiveStreamProvider() {
    loadActiveRooms();
  }

  Future<void> loadActiveRooms() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await LiveStreamService.getStreams();
      
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        final List<dynamic> streamsList = data['streams'] ?? [];
        
        _activeRooms = streamsList
            .map((json) => LiveRoom.fromJson(json as Map<String, dynamic>))
            .where((room) => room.isLive && room.status == 'live')
            .toList();
      } else {
        _error = result['message'] ?? 'Failed to load streams';
        _activeRooms = [];
      }
    } catch (e) {
      _error = 'Error loading streams: $e';
      _activeRooms = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addRoom(LiveRoom room) {
    if (!_activeRooms.any((r) => r.id == room.id)) {
      _activeRooms.add(room);
      notifyListeners();
    }
  }

  void removeRoom(String roomId) {
    _activeRooms.removeWhere((room) => room.id == roomId);
    notifyListeners();
  }

  void updateRoom(LiveRoom updatedRoom) {
    final index = _activeRooms.indexWhere((room) => room.id == updatedRoom.id);
    if (index != -1) {
      _activeRooms[index] = updatedRoom;
      notifyListeners();
    }
  }
}


