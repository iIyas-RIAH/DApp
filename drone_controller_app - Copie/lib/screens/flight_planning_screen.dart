import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/providers/flight_planning_provider.dart';
import '../core/providers/drone_connection_provider.dart';
import '../core/localization/app_localizations.dart';

class FlightPlanningScreen extends StatefulWidget {
  const FlightPlanningScreen({super.key});

  @override
  State<FlightPlanningScreen> createState() => _FlightPlanningScreenState();
}

class _FlightPlanningScreenState extends State<FlightPlanningScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _altitudeController = TextEditingController(text: '50');
  final _spacingController = TextEditingController(text: '10');
  
  MissionType _selectedMissionType = MissionType.waypoint;
  List<LatLng> _selectedPoints = [];
  List<Polygon> _areaPolygons = [];
  List<Marker> _markers = [];
  List<Polyline> _missionPath = [];
  
  MapController? _mapController;
  bool _isDrawingArea = false;
  String _currentMapType = 'hybrid';
  
  @override
  void initState() {
    super.initState();
    _updateMapDisplay();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _altitudeController.dispose();
    _spacingController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
  
  String _getMapUrlTemplate() {
    switch (_currentMapType) {
      case 'streets':
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case 'satellite':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'terrain':
        return 'https://tile.thunderforest.com/landscape/{z}/{x}/{y}.png';
      case 'hybrid':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      default:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }
  
  void _updateMapDisplay() {
    setState(() {
      // Clear existing markers and paths
      _markers = [];
      _missionPath = [];
      
      // Add markers for each selected point
      for (int i = 0; i < _selectedPoints.length; i++) {
        _markers.add(
          Marker(
            point: _selectedPoints[i],
            width: 60,
            height: 60,
            builder: (context) => Column(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 30),
                Container(
                  padding: const EdgeInsets.all(2),
                  color: Colors.white.withOpacity(0.8),
                  child: Text(
                    'Point ${i + 1}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      
      // Create mission path polyline
      if (_selectedPoints.isNotEmpty) {
        _missionPath.add(
          Polyline(
            points: _selectedPoints,
            color: Colors.blue,
            strokeWidth: 3.0,
          ),
        );
      }
      
      // Create area polygon if in grid/area scan mode
      if (_selectedMissionType == MissionType.gridScan || 
          _selectedMissionType == MissionType.areaScan) {
        if (_selectedPoints.length >= 3) {
          _areaPolygons = [
            Polygon(
              points: _selectedPoints,
              color: Colors.blue.withOpacity(0.3),
              borderColor: Colors.blue,
              borderStrokeWidth: 2.0,
            ),
          ];
        } else {
          _areaPolygons = [];
        }
      } else {
        _areaPolygons = [];
      }
    });
  }
  
  void _onMapTap(LatLng position) {
    if (!_isDrawingArea) return;
    
    setState(() {
      if (_selectedMissionType == MissionType.waypoint) {
        // For waypoint missions, add each tapped point
        _selectedPoints.add(position);
      } else if (_selectedMissionType == MissionType.gridScan || 
                _selectedMissionType == MissionType.areaScan) {
        // For grid/area scans, add points to define the area
        _selectedPoints.add(position);
      }
      
      _updateMapDisplay();
    });
  }
  
  void _clearPoints() {
    setState(() {
      _selectedPoints = [];
      _markers = [];
      _missionPath = [];
      _areaPolygons = [];
    });
  }
  
  Future<void> _saveMission() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_selectedPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('please_select_points'.tr(context))),
      );
      return;
    }
    
    final planningProvider = Provider.of<FlightPlanningProvider>(context, listen: false);
    final name = _nameController.text;
    final altitude = double.parse(_altitudeController.text);
    
    try {
      if (_selectedMissionType == MissionType.waypoint) {
        // Create waypoint mission
        final points = _selectedPoints.map((point) => 
          MissionPoint(
            latitude: point.latitude,
            longitude: point.longitude,
            altitude: altitude,
          )
        ).toList();
        
        await planningProvider.createMission(
          name: name,
          type: MissionType.waypoint,
          points: points,
        );
      } else if (_selectedMissionType == MissionType.gridScan) {
        // Create grid scan mission
        if (_selectedPoints.length < 4) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('need_four_points_for_grid'.tr(context))),
          );
          return;
        }
        
        // Find bounding box of selected points
        double minLat = _selectedPoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
        double maxLat = _selectedPoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
        double minLng = _selectedPoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
        double maxLng = _selectedPoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);
        
        final spacing = double.parse(_spacingController.text);
        
        await planningProvider.createGridScanMission(
          name: name,
          topLeftLat: maxLat,
          topLeftLng: minLng,
          bottomRightLat: minLat,
          bottomRightLng: maxLng,
          altitude: altitude,
          spacing: spacing / 1000, // Convert to degrees (approximate)
        );
      } else if (_selectedMissionType == MissionType.areaScan) {
        // Create area scan mission (similar to grid scan but with custom boundary)
        if (_selectedPoints.length < 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('need_three_points_for_area'.tr(context))),
          );
          return;
        }
        
        final points = _selectedPoints.map((point) => 
          MissionPoint(
            latitude: point.latitude,
            longitude: point.longitude,
            altitude: altitude,
          )
        ).toList();
        
        await planningProvider.createMission(
          name: name,
          type: MissionType.areaScan,
          points: points,
          parameters: {
            'altitude': altitude,
            'boundary': points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
          },
        );
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('mission_saved'.tr(context))),
      );
      
      // Reset form
      _nameController.clear();
      _clearPoints();
      setState(() {
        _isDrawingArea = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'error_saving_mission'.tr(context)}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final droneProvider = Provider.of<DroneConnectionProvider>(context);
    final initialPosition = LatLng(droneProvider.latitude, droneProvider.longitude);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('flight_planning'.tr(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveMission,
            tooltip: 'save_mission'.tr(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Mission type selector
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Mission name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'mission_name'.tr(context),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'please_enter_mission_name'.tr(context);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  
                  // Mission type dropdown
                  DropdownButtonFormField<MissionType>(
                    value: _selectedMissionType,
                    decoration: InputDecoration(
                      labelText: 'mission_type'.tr(context),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: MissionType.waypoint,
                        child: Text('waypoint_mission'.tr(context)),
                      ),
                      DropdownMenuItem(
                        value: MissionType.gridScan,
                        child: Text('grid_scan_mission'.tr(context)),
                      ),
                      DropdownMenuItem(
                        value: MissionType.areaScan,
                        child: Text('area_scan_mission'.tr(context)),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedMissionType = value;
                          _clearPoints();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  
                  // Altitude input
                  TextFormField(
                    controller: _altitudeController,
                    decoration: InputDecoration(
                      labelText: 'altitude_meters'.tr(context),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'please_enter_altitude'.tr(context);
                      }
                      if (double.tryParse(value) == null) {
                        return 'please_enter_valid_number'.tr(context);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  
                  // Spacing input (only for grid scan)
                  if (_selectedMissionType == MissionType.gridScan)
                    TextFormField(
                      controller: _spacingController,
                      decoration: InputDecoration(
                        labelText: 'grid_spacing_meters'.tr(context),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'please_enter_spacing'.tr(context);
                        }
                        if (double.tryParse(value) == null) {
                          return 'please_enter_valid_number'.tr(context);
                        }
                        return null;
                      },
                    ),
                ],
              ),
            ),
          ),
          
          // Map controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Drawing toggle
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isDrawingArea = !_isDrawingArea;
                    });
                  },
                  icon: Icon(_isDrawingArea ? Icons.edit_off : Icons.edit),
                  label: Text(_isDrawingArea 
                    ? 'stop_drawing'.tr(context) 
                    : 'start_drawing'.tr(context)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDrawingArea 
                      ? Colors.red 
                      : Theme.of(context).primaryColor,
                  ),
                ),
                
                // Clear button
                ElevatedButton.icon(
                  onPressed: _clearPoints,
                  icon: const Icon(Icons.clear),
                  label: Text('clear_points'.tr(context)),
                ),
              ],
            ),
          ),
          
          // Map view
          Expanded(
            child: FlutterMap(
              mapController: _mapController = MapController(),
              options: MapOptions(
                center: initialPosition,
                zoom: 18,
                onTap: (tapPosition, point) => _onMapTap(point),
                interactiveFlags: InteractiveFlag.all,
              ),
              children: [
                TileLayer(
                  urlTemplate: _getMapUrlTemplate(),
                  subdomains: const ['a', 'b', 'c'],
                ),
                PolylineLayer(polylines: _missionPath),
                PolygonLayer(polygons: _areaPolygons),
                MarkerLayer(markers: _markers),
              ]
            ),
          ),
        ],
      ),
    );
  }
}