import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/flight_planning_provider.dart';
import '../core/providers/drone_connection_provider.dart';
import '../core/localization/app_localizations.dart';
import 'flight_planning_screen.dart';

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('missions'.tr(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FlightPlanningScreen()),
              );
            },
            tooltip: 'create_new_mission'.tr(context),
          ),
        ],
      ),
      body: Consumer<FlightPlanningProvider>(
        builder: (context, provider, child) {
          if (provider.missions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flight_takeoff,
                    size: 64,
                    color: Colors.grey.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'no_missions'.tr(context),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FlightPlanningScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: Text('create_first_mission'.tr(context)),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: provider.missions.length,
            itemBuilder: (context, index) {
              final mission = provider.missions[index];
              return Dismissible(
                key: Key(mission.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('confirm_delete'.tr(context)),
                        content: Text('delete_mission_confirmation'.tr(context)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('cancel'.tr(context)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text('delete'.tr(context)),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  provider.deleteMission(mission.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('mission_deleted'.tr(context))),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    leading: _getMissionTypeIcon(mission.type),
                    title: Text(mission.name),
                    subtitle: Text(
                      '${_getMissionTypeText(context, mission.type)} • '
                      '${mission.points.length} ${mission.points.length == 1 ? "point".tr(context) : "points".tr(context)} • '
                      '${_formatDate(context, mission.createdAt)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.map),
                          onPressed: () {
                            // View mission on map
                            _showMissionDetails(context, mission);
                          },
                          tooltip: 'view_on_map'.tr(context),
                        ),
                        IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () {
                            // Execute mission
                            _executeMission(context, provider, mission);
                          },
                          tooltip: 'execute_mission'.tr(context),
                        ),
                      ],
                    ),
                    onTap: () {
                      _showMissionDetails(context, mission);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _getMissionTypeIcon(MissionType type) {
    switch (type) {
      case MissionType.waypoint:
        return const Icon(Icons.route);
      case MissionType.gridScan:
        return const Icon(Icons.grid_on);
      case MissionType.areaScan:
        return const Icon(Icons.crop_free);
      case MissionType.returnToHome:
        return const Icon(Icons.home);
      default:
        return const Icon(Icons.flight);
    }
  }
  
  String _getMissionTypeText(BuildContext context, MissionType type) {
    switch (type) {
      case MissionType.waypoint:
        return 'waypoint_mission'.tr(context);
      case MissionType.gridScan:
        return 'grid_scan_mission'.tr(context);
      case MissionType.areaScan:
        return 'area_scan_mission'.tr(context);
      case MissionType.returnToHome:
        return 'return_to_home'.tr(context);
      default:
        return 'unknown_mission_type'.tr(context);
    }
  }
  
  String _formatDate(BuildContext context, DateTime date) {
    // Simple date formatting - in a real app, use intl package for localization
    return '${date.day}/${date.month}/${date.year}';
  }
  
  void _showMissionDetails(BuildContext context, Mission mission) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getMissionTypeText(context, mission.type),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'mission_details'.tr(context),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('${'points_count'.tr(context)}: ${mission.points.length}'),
                    if (mission.parameters != null) ...[  
                      const SizedBox(height: 8),
                      Text('${'parameters'.tr(context)}:'),
                      const SizedBox(height: 4),
                      ...mission.parameters!.entries.map((entry) {
                        return Text('${entry.key}: ${entry.value}');
                      }),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'waypoints'.tr(context),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: mission.points.length,
                      itemBuilder: (context, index) {
                        final point = mission.points[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text('${index + 1}'),
                          ),
                          title: Text(
                            'Lat: ${point.latitude.toStringAsFixed(6)}, '
                            'Lng: ${point.longitude.toStringAsFixed(6)}',
                          ),
                          subtitle: Text('Alt: ${point.altitude}m'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  void _executeMission(BuildContext context, FlightPlanningProvider provider, Mission mission) {
    final droneProvider = Provider.of<DroneConnectionProvider>(context, listen: false);
    
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
          title: Text('execute_mission'.tr(context)),
          content: Text('execute_mission_confirmation'.tr(context)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('cancel'.tr(context)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final success = await provider.startMission(mission.id);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('mission_started'.tr(context))),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${'error_starting_mission'.tr(context)}: $e')),
                  );
                }
              },
              child: Text('execute'.tr(context)),
            ),
          ],
        );
      },
    );
  }
}