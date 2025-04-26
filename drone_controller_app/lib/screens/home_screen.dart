import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/drone_connection_provider.dart';
import '../core/localization/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final droneProvider = Provider.of<DroneConnectionProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('home_title'.tr(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection status card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'connection_status'.tr(context),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            droneProvider.status == ConnectionStatus.connected
                                ? Icons.check_circle
                                : Icons.error_outline,
                            color: droneProvider.status == ConnectionStatus.connected
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            droneProvider.status == ConnectionStatus.connected
                                ? 'status_connected'.tr(context)
                                : 'status_disconnected'.tr(context),
                          ),
                        ],
                      ),
                      if (droneProvider.status == ConnectionStatus.connected) ...[  
                        const SizedBox(height: 16),
                        Text('${'battery_level'.tr(context)}: ${droneProvider.batteryLevel}%'),
                        const SizedBox(height: 8),
                        Text('${'signal_strength'.tr(context)}: ${droneProvider.signalStrength}%'),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Main action buttons
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildActionCard(
                      context,
                      'control_drone'.tr(context),
                      Icons.gamepad,
                      () => Navigator.pushNamed(context, '/control'),
                      Colors.blue,
                    ),
                    _buildActionCard(
                      context,
                      'view_map'.tr(context),
                      Icons.map,
                      () => Navigator.pushNamed(context, '/map'),
                      Colors.green,
                    ),
                    _buildActionCard(
                      context,
                      'media_gallery'.tr(context),
                      Icons.photo_library,
                      () => Navigator.pushNamed(context, '/media'),
                      Colors.orange,
                    ),
                    _buildActionCard(
                      context,
                      'flight_planning'.tr(context),
                      Icons.flight_takeoff,
                      () => Navigator.pushNamed(context, '/flight-planning'),
                      Colors.amber,
                    ),
                    _buildActionCard(
                      context,
                      'missions'.tr(context),
                      Icons.list_alt,
                      () => Navigator.pushNamed(context, '/missions'),
                      Colors.indigo,
                    ),
                    _buildActionCard(
                      context,
                      droneProvider.status == ConnectionStatus.connected
                          ? 'disconnect'.tr(context)
                          : 'connect'.tr(context),
                      droneProvider.status == ConnectionStatus.connected
                          ? Icons.link_off
                          : Icons.link,
                      () => _handleConnectionToggle(context),
                      droneProvider.status == ConnectionStatus.connected
                          ? Colors.red
                          : Colors.purple,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon,
      VoidCallback onTap, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleConnectionToggle(BuildContext context) {
    final droneProvider = Provider.of<DroneConnectionProvider>(context, listen: false);
    
    if (droneProvider.status == ConnectionStatus.connected) {
      droneProvider.disconnectDrone();
    } else {
      // Show a dialog to connect to a specific drone
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('connect_to_drone'.tr(context)),
          content: TextField(
            decoration: InputDecoration(
              hintText: 'drone_id'.tr(context),
            ),
            onSubmitted: (value) {
              Navigator.pop(context);
              droneProvider.connectToDrone(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr(context)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                droneProvider.connectToDrone('DJI-Phantom-123'); // Default ID
              },
              child: Text('connect'.tr(context)),
            ),
          ],
        ),
      );
    }
  }
}