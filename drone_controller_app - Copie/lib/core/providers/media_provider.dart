import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class MediaItem {
  final String id;
  final String path;
  final DateTime timestamp;
  final MediaType type;
  final String? thumbnailPath;
  final Map<String, dynamic>? metadata;

  MediaItem({
    required this.id,
    required this.path,
    required this.timestamp,
    required this.type,
    this.thumbnailPath,
    this.metadata,
  });
}

enum MediaType { photo, video }

class MediaProvider extends ChangeNotifier {
  List<MediaItem> _mediaItems = [];
  List<MediaItem> get mediaItems => _mediaItems;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  MediaProvider() {
    _loadMediaItems();
  }
  
  // Load media items from storage
  Future<void> _loadMediaItems() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // In a real app, this would load actual media files from storage
      // For now, we'll create some dummy data
      await Future.delayed(const Duration(seconds: 1));
      
      final List<MediaItem> items = [];
      final now = DateTime.now();
      
      // Add some dummy photos
      for (int i = 1; i <= 5; i++) {
        items.add(MediaItem(
          id: 'photo_$i',
          path: 'assets/images/sample_photo_$i.jpg',
          timestamp: now.subtract(Duration(days: i)),
          type: MediaType.photo,
          metadata: {
            'location': {'lat': 37.7749 + (i * 0.01), 'lng': -122.4194 - (i * 0.01)},
            'altitude': 100.0 + (i * 10),
          },
        ));
      }
      
      // Add some dummy videos
      for (int i = 1; i <= 3; i++) {
        items.add(MediaItem(
          id: 'video_$i',
          path: 'assets/videos/sample_video_$i.mp4',
          timestamp: now.subtract(Duration(days: i + 5)),
          type: MediaType.video,
          metadata: {
            'location': {'lat': 37.7749 - (i * 0.01), 'lng': -122.4194 + (i * 0.01)},
            'altitude': 150.0 - (i * 10),
            'duration': Duration(minutes: 1, seconds: i * 20),
          },
        ));
      }
      
      _mediaItems = items;
    } catch (e) {
      // Handle error
      debugPrint('Error loading media items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Refresh media items
  Future<void> refreshMediaItems() async {
    await _loadMediaItems();
  }
  
  // Add new media item
  Future<void> addMediaItem(MediaType type, String path, Map<String, dynamic>? metadata) async {
    final id = 'media_${DateTime.now().millisecondsSinceEpoch}';
    final newItem = MediaItem(
      id: id,
      path: path,
      timestamp: DateTime.now(),
      type: type,
      metadata: metadata,
    );
    
    _mediaItems.insert(0, newItem);
    notifyListeners();
    
    // In a real app, you would save this to persistent storage
  }
  
  // Delete media item
  Future<void> deleteMediaItem(String id) async {
    _mediaItems.removeWhere((item) => item.id == id);
    notifyListeners();
    
    // In a real app, you would delete the file from storage
  }
  
  // Get media item by ID
  MediaItem? getMediaItemById(String id) {
    try {
      return _mediaItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Filter media items by type
  List<MediaItem> getMediaItemsByType(MediaType type) {
    return _mediaItems.where((item) => item.type == type).toList();
  }
}