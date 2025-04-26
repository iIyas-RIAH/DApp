import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum MissionType { waypoint, gridScan, areaScan, returnToHome }

class MissionPoint {
  final double latitude;
  final double longitude;
  final double altitude;
  final String? action; // Optional action to perform at this point

  MissionPoint({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    this.action,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'action': action,
    };
  }

  // Create from JSON
  factory MissionPoint.fromJson(Map<String, dynamic> json) {
    return MissionPoint(
      latitude: json['latitude'],
      longitude: json['longitude'],
      altitude: json['altitude'],
      action: json['action'],
    );
  }
}

class Mission {
  String id;
  String name;
  MissionType type;
  List<MissionPoint> points;
  Map<String, dynamic>? parameters; // Additional parameters for specific mission types
  DateTime createdAt;

  Mission({
    required this.id,
    required this.name,
    required this.type,
    required this.points,
    this.parameters,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'points': points.map((point) => point.toJson()).toList(),
      'parameters': parameters,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'],
      name: json['name'],
      type: MissionType.values[json['type']],
      points: (json['points'] as List)
          .map((point) => MissionPoint.fromJson(point))
          .toList(),
      parameters: json['parameters'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class FlightPlanningProvider extends ChangeNotifier {
  List<Mission> _missions = [];
  List<Mission> get missions => _missions;

  Mission? _activeMission;
  Mission? get activeMission => _activeMission;

  bool _isExecutingMission = false;
  bool get isExecutingMission => _isExecutingMission;

  // Constructor
  FlightPlanningProvider() {
    _loadMissions();
  }

  // Load missions from SharedPreferences
  Future<void> _loadMissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final missionsJson = prefs.getStringList('missions') ?? [];
      
      _missions = missionsJson
          .map((json) => Mission.fromJson(jsonDecode(json)))
          .toList();
      
      // Sort missions by creation date (newest first)
      _missions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading missions: $e');
    }
  }

  // Save missions to SharedPreferences
  Future<void> _saveMissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final missionsJson = _missions
          .map((mission) => jsonEncode(mission.toJson()))
          .toList();
      
      await prefs.setStringList('missions', missionsJson);
    } catch (e) {
      debugPrint('Error saving missions: $e');
    }
  }

  // Create a new mission
  Future<Mission> createMission({
    required String name,
    required MissionType type,
    List<MissionPoint>? points,
    Map<String, dynamic>? parameters,
  }) async {
    final mission = Mission(
      id: 'mission_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: type,
      points: points ?? [],
      parameters: parameters,
    );

    _missions.insert(0, mission);
    await _saveMissions();
    notifyListeners();
    
    return mission;
  }

  // Update an existing mission
  Future<void> updateMission(Mission mission) async {
    final index = _missions.indexWhere((m) => m.id == mission.id);
    if (index >= 0) {
      _missions[index] = mission;
      await _saveMissions();
      notifyListeners();
    }
  }

  // Delete a mission
  Future<void> deleteMission(String id) async {
    _missions.removeWhere((mission) => mission.id == id);
    await _saveMissions();
    notifyListeners();
  }

  // Set active mission
  void setActiveMission(Mission? mission) {
    _activeMission = mission;
    notifyListeners();
  }

  // Start mission execution
  Future<bool> startMission(String missionId) async {
    final mission = _missions.firstWhere(
      (m) => m.id == missionId,
      orElse: () => throw Exception('Mission not found'),
    );

    // In a real app, this would communicate with the drone
    // For now, we'll just set the active mission and status
    _activeMission = mission;
    _isExecutingMission = true;
    notifyListeners();
    
    return true;
  }

  // Stop mission execution
  void stopMission() {
    _isExecutingMission = false;
    notifyListeners();
  }

  // Create a return-to-home mission
  Future<Mission> createReturnToHomeMission(double homeLatitude, double homeLongitude, double altitude) async {
    return createMission(
      name: 'Return to Home',
      type: MissionType.returnToHome,
      points: [
        MissionPoint(
          latitude: homeLatitude,
          longitude: homeLongitude,
          altitude: altitude,
        ),
      ],
    );
  }

  // Create a grid scan mission
  Future<Mission> createGridScanMission({
    required String name,
    required double topLeftLat,
    required double topLeftLng,
    required double bottomRightLat,
    required double bottomRightLng,
    required double altitude,
    required double spacing,
  }) async {
    // Calculate grid points
    final List<MissionPoint> points = [];
    
    // Simple grid pattern calculation
    final latDiff = (bottomRightLat - topLeftLat).abs();
    final lngDiff = (bottomRightLng - topLeftLng).abs();
    
    final latSteps = (latDiff / spacing).ceil();
    final lngSteps = (lngDiff / spacing).ceil();
    
    final latStep = latDiff / latSteps;
    final lngStep = lngDiff / lngSteps;
    
    for (int i = 0; i <= latSteps; i++) {
      final lat = topLeftLat + (i * latStep);
      
      // Alternate direction for each row (lawn mower pattern)
      if (i % 2 == 0) {
        for (int j = 0; j <= lngSteps; j++) {
          final lng = topLeftLng + (j * lngStep);
          points.add(MissionPoint(
            latitude: lat,
            longitude: lng,
            altitude: altitude,
          ));
        }
      } else {
        for (int j = lngSteps; j >= 0; j--) {
          final lng = topLeftLng + (j * lngStep);
          points.add(MissionPoint(
            latitude: lat,
            longitude: lng,
            altitude: altitude,
          ));
        }
      }
    }
    
    return createMission(
      name: name,
      type: MissionType.gridScan,
      points: points,
      parameters: {
        'spacing': spacing,
        'altitude': altitude,
        'boundaries': {
          'topLeft': {'lat': topLeftLat, 'lng': topLeftLng},
          'bottomRight': {'lat': bottomRightLat, 'lng': bottomRightLng},
        },
      },
    );
  }
}