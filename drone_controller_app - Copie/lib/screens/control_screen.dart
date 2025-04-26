import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import '../core/providers/drone_connection_provider.dart';
import '../core/providers/flight_planning_provider.dart';
import '../core/localization/app_localizations.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  // Joystick values
  double _movementX = 0;
  double _movementY = 0;
  double _rotationX = 0;
  double _altitudeY = 0;

  // Camera active
  bool _cameraActive = false;
  bool _recordingVideo = false;

  @override
  void initState() {
    super.initState();
    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Reset orientation when leaving this screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final droneProvider = Provider.of<DroneConnectionProvider>(context);

    return Scaffold(
      // No AppBar as requested
      body:
          droneProvider.status != ConnectionStatus.connected
              ? _buildNotConnectedView(context)
              : _buildControlView(context, droneProvider),
    );
  }

  Widget _buildNotConnectedView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link_off, size: 64, color: Colors.red.withOpacity(0.7)),
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

  Widget _buildControlView(
    BuildContext context,
    DroneConnectionProvider droneProvider,
  ) {
    return Stack(
      children: [
        // Full screen camera preview (placeholder) - occupying entire screen as requested
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: Center(
            child:
                _cameraActive
                    ? const Text(
                      'LIVE CAMERA FEED',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    )
                    : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videocam_off,
                          size: 48,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'camera_inactive'.tr(context),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _cameraActive = true;
                            });
                          },
                          child: Text('activate_camera'.tr(context)),
                        ),
                      ],
                    ),
          ),
        ),

        // Overlay controls optimized for landscape orientation
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Column(
              children: [
                // Top bar with telemetry data - rearranged for landscape
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      // Telemetry items in a row - compact for landscape
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildTelemetryItem(
                              context,
                              'battery'.tr(context),
                              '${droneProvider.batteryLevel}%',
                              Icons.battery_full,
                              _getBatteryColor(droneProvider.batteryLevel),
                            ),
                            _buildTelemetryItem(
                              context,
                              'altitude'.tr(context),
                              '${droneProvider.altitude.toStringAsFixed(1)}m',
                              Icons.height,
                              Colors.blue,
                            ),
                            _buildTelemetryItem(
                              context,
                              'speed'.tr(context),
                              '${droneProvider.speed.toStringAsFixed(1)}m/s',
                              Icons.speed,
                              Colors.orange,
                            ),
                            _buildTelemetryItem(
                              context,
                              'signal'.tr(context),
                              '${droneProvider.signalStrength}%',
                              Icons.network_cell,
                              _getSignalColor(droneProvider.signalStrength),
                            ),
                          ],
                        ),
                      ),
                      // Control buttons in header
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Emergency stop button
                          IconButton(
                            icon: const Icon(Icons.stop_circle, color: Colors.red),
                            onPressed: () => _showEmergencyStopConfirmation(context),
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'emergency_stop'.tr(context),
                          ),
                          const SizedBox(width: 8),
                          // Return home button
                          IconButton(
                            icon: const Icon(Icons.home, color: Colors.blue),
                            onPressed:
                                () => _showReturnHomeConfirmation(
                                  context,
                                  droneProvider,
                                  Provider.of<FlightPlanningProvider>(
                                    context,
                                    listen: false,
                                  ),
                                ),
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'return_to_home'.tr(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main content area with joysticks - optimized for landscape
                Expanded(
                  child: Row(
                    children: [
                      // Left joystick (rotation and altitude)
                      Container(
                        width: 120,
                        height: 120,
                        margin: const EdgeInsets.only(left: 8.0, top: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'rotation_altitude'.tr(context),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Joystick(
                                mode: JoystickMode.all,
                                listener: (details) {
                                  setState(() {
                                    _rotationX = details.x;
                                    _altitudeY = details.y;
                                  });
                                  // Send commands to drone
                                  droneProvider.rotateDrone(_rotationX);
                                  droneProvider.changeAltitude(_altitudeY);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Center(
                          child:
                              _cameraActive
                                  ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Camera controls
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black38,
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.camera_alt,
                                                color: Colors.white,
                                              ),
                                              onPressed: () {
                                                droneProvider.takePhoto();
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'photo_taken'.tr(context),
                                                    ),
                                                  ),
                                                );
                                              },
                                              iconSize: 36,
                                            ),
                                            const SizedBox(width: 16),
                                            IconButton(
                                              icon: Icon(
                                                _recordingVideo
                                                    ? Icons.stop
                                                    : Icons.videocam,
                                                color:
                                                    _recordingVideo
                                                        ? Colors.red
                                                        : Colors.white,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _recordingVideo =
                                                      !_recordingVideo;
                                                });
                                                droneProvider
                                                    .toggleVideoRecording();
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      _recordingVideo
                                                          ? 'video_recording_started'
                                                              .tr(context)
                                                          : 'video_recording_stopped'
                                                              .tr(context),
                                                    ),
                                                  ),
                                                );
                                              },
                                              iconSize: 36,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                  : Container(),
                        ),
                      ),

                      // Right joystick (movement)
                      Container(
                        width: 120,
                        height: 120,
                        margin: const EdgeInsets.only(right: 8.0, top: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'movement'.tr(context),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Joystick(
                                mode: JoystickMode.all,
                                listener: (details) {
                                  setState(() {
                                    _movementX = details.x;
                                    _movementY = details.y;
                                  });
                                  // Send commands to drone
                                  droneProvider.moveDrone(
                                    _movementX,
                                    _movementY,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom area - now empty since emergency button moved to top bar

              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 10),
            ),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Color _getBatteryColor(int level) {
    if (level > 50) return Colors.green;
    if (level > 20) return Colors.orange;
    return Colors.red;
  }

  Color _getSignalColor(int level) {
    if (level > 70) return Colors.green;
    if (level > 30) return Colors.orange;
    return Colors.red;
  }

  void _showReturnHomeConfirmation(
    BuildContext context,
    DroneConnectionProvider droneProvider,
    FlightPlanningProvider flightPlanningProvider,
  ) {
    if (droneProvider.status != ConnectionStatus.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('drone_not_connected'.tr(context))),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('return_to_home'.tr(context)),
          content: Text('confirm_return_to_home'.tr(context)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('cancel'.tr(context)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  // Create and execute a return-to-home mission
                  final mission = await flightPlanningProvider
                      .createReturnToHomeMission(
                        droneProvider.latitude,
                        droneProvider.longitude,
                        droneProvider.altitude,
                      );

                  await flightPlanningProvider.startMission(mission.id);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('returning_to_home'.tr(context))),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${'error_returning_home'.tr(context)}: $e',
                      ),
                    ),
                  );
                }
              },
              child: Text('confirm'.tr(context)),
            ),
          ],
        );
      },
    );
  }

  void _showEmergencyStopConfirmation(BuildContext context) {
    final droneProvider = Provider.of<DroneConnectionProvider>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('emergency_stop'.tr(context)),
            content: Text('confirm_emergency_stop'.tr(context)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr(context)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  droneProvider.emergencyStop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('emergency_stop_activated'.tr(context)),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('confirm'.tr(context)),
              ),
            ],
          ),
    );
  }
}
