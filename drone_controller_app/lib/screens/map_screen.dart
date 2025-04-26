import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/providers/drone_connection_provider.dart';
import '../core/localization/app_localizations.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapController? _mapController;
  final List<Polyline> _flightPath = [];
  final List<Marker> _markers = [];
  final List<LatLng> _flightPathPoints = [];

  // Map type
  String _currentMapType = 'hybrid';

  @override
  void initState() {
    super.initState();
    // Start tracking drone position
    _startPositionTracking();
  }

  void _startPositionTracking() {
    // In a real app, this would subscribe to position updates from the drone
    // For now, we'll just add the current position every second
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      final droneProvider = Provider.of<DroneConnectionProvider>(
        context,
        listen: false,
      );
      if (droneProvider.status == ConnectionStatus.connected) {
        final currentPosition = LatLng(
          droneProvider.latitude,
          droneProvider.longitude,
        );

        setState(() {
          // Add point to flight path
          _flightPathPoints.add(currentPosition);

          // Update flight path polyline
          _flightPath.clear();
          _flightPath.add(
            Polyline(
              points: _flightPathPoints,
              color: Colors.blue,
              strokeWidth: 5.0,
            ),
          );

          // Update drone marker
          _markers.clear();
          _markers.add(
            Marker(
              point: currentPosition,
              width: 80,
              height: 80,
              builder:
                  (context) => Column(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: 30,
                      ),
                      Container(
                        padding: const EdgeInsets.all(2),
                        color: Colors.white.withOpacity(0.8),
                        child: Text(
                          '${'drone'.tr(context)}\n${'altitude'.tr(context)}: ${droneProvider.altitude.toStringAsFixed(1)}m',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
            ),
          );

          // Center map on drone if controller is available
          _mapController?.move(currentPosition, _mapController?.zoom ?? 18);
        });
      }

      // Continue tracking
      _startPositionTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    final droneProvider = Provider.of<DroneConnectionProvider>(context);
    final initialPosition = LatLng(
      droneProvider.latitude,
      droneProvider.longitude,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('map_title'.tr(context)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String type) {
              setState(() {
                _currentMapType = type;
              });
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'streets',
                    child: Text('map_normal'.tr(context)),
                  ),
                  PopupMenuItem<String>(
                    value: 'satellite',
                    child: Text('map_satellite'.tr(context)),
                  ),
                  PopupMenuItem<String>(
                    value: 'terrain',
                    child: Text('map_terrain'.tr(context)),
                  ),
                  PopupMenuItem<String>(
                    value: 'hybrid',
                    child: Text('map_hybrid'.tr(context)),
                  ),
                ],
          ),
        ],
      ),
      body:
          droneProvider.status != ConnectionStatus.connected
              ? _buildNotConnectedView(context)
              : Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController = MapController(),
                    options: MapOptions(
                      center: initialPosition,
                      zoom: 18,
                      interactiveFlags: InteractiveFlag.all,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _getMapUrlTemplate(),
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      PolylineLayer(polylines: _flightPath),
                      MarkerLayer(markers: _markers),
                    ],
                  ),
                  // Telemetry overlay
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildTelemetryItem(
                                  context,
                                  'altitude'.tr(context),
                                  '${droneProvider.altitude.toStringAsFixed(1)}m',
                                ),
                                _buildTelemetryItem(
                                  context,
                                  'speed'.tr(context),
                                  '${droneProvider.speed.toStringAsFixed(1)}m/s',
                                ),
                                _buildTelemetryItem(
                                  context,
                                  'battery'.tr(context),
                                  '${droneProvider.batteryLevel}%',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${'coordinates'.tr(context)}: ${droneProvider.latitude.toStringAsFixed(6)}, ${droneProvider.longitude.toStringAsFixed(6)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      floatingActionButton:
          droneProvider.status == ConnectionStatus.connected
              ? Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: 'center_map',
                    onPressed: () {
                      final currentPosition = LatLng(
                        droneProvider.latitude,
                        droneProvider.longitude,
                      );
                      _mapController?.move(currentPosition, 18);
                    },
                    child: const Icon(Icons.my_location),
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton(
                    heroTag: 'clear_path',
                    onPressed: () {
                      setState(() {
                        _flightPathPoints.clear();
                        _flightPath.clear();
                      });
                    },
                    child: const Icon(Icons.clear),
                  ),
                ],
              )
              : null,
    );
  }

  Widget _buildNotConnectedView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.red.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'drone_not_connected'.tr(context),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('return_to_home_screen'.tr(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  @override
  void dispose() {
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
}
