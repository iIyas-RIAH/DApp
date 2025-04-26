import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/app_state_provider.dart';
import '../core/providers/drone_connection_provider.dart';
import '../core/localization/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final droneProvider = Provider.of<DroneConnectionProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr(context)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // App Settings Section
          _buildSectionHeader(context, 'app_settings'.tr(context)),
          
          // Theme Setting
          _buildSettingItem(
            context,
            'theme'.tr(context),
            Icons.brightness_6,
            trailing: DropdownButton<ThemeMode>(
              value: appState.themeMode,
              underline: Container(),
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) {
                  appState.setThemeMode(newValue);
                }
              },
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('theme_system'.tr(context)),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('theme_light'.tr(context)),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('theme_dark'.tr(context)),
                ),
              ],
            ),
          ),
          
          // Language Setting
          _buildSettingItem(
            context,
            'language'.tr(context),
            Icons.language,
            trailing: DropdownButton<Locale>(
              value: appState.locale,
              underline: Container(),
              onChanged: (Locale? newValue) {
                if (newValue != null) {
                  appState.setLocale(newValue);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: Locale('en', ''),
                  child: Text('English'),
                ),
                DropdownMenuItem(
                  value: Locale('fr', ''),
                  child: Text('Français'),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Drone Settings Section
          _buildSectionHeader(context, 'drone_settings'.tr(context)),
          
          // Connection Status
          _buildSettingItem(
            context,
            'connection_status'.tr(context),
            Icons.link,
            subtitle: droneProvider.status == ConnectionStatus.connected
                ? '${'connected_to'.tr(context)}: ${droneProvider.droneId}'
                : 'disconnected'.tr(context),
            trailing: Switch(
              value: droneProvider.status == ConnectionStatus.connected,
              onChanged: (value) {
                if (value) {
                  // Show dialog to connect
                  _showConnectDialog(context);
                } else {
                  // Disconnect
                  droneProvider.disconnectDrone();
                }
              },
            ),
          ),
          
          // Battery Level (only shown when connected)
          if (droneProvider.status == ConnectionStatus.connected)
            _buildSettingItem(
              context,
              'battery_level'.tr(context),
              Icons.battery_full,
              subtitle: '${droneProvider.batteryLevel}%',
              trailing: Icon(
                _getBatteryIcon(droneProvider.batteryLevel),
                color: _getBatteryColor(droneProvider.batteryLevel),
              ),
            ),
          
          const Divider(),
          
          // About Section
          _buildSectionHeader(context, 'about'.tr(context)),
          
          // App Version
          _buildSettingItem(
            context,
            'app_version'.tr(context),
            Icons.info_outline,
            subtitle: '1.0.0',
          ),
          
          // Help & Support
          _buildSettingItem(
            context,
            'help_support'.tr(context),
            Icons.help_outline,
            onTap: () {
              Navigator.pushNamed(context, '/help-support');
            },
          ),
          
          // Privacy Policy
          _buildSettingItem(
            context,
            'privacy_policy'.tr(context),
            Icons.privacy_tip_outlined,
            onTap: () {
              Navigator.pushNamed(context, '/privacy-policy');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String title,
    IconData icon, {
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }

  IconData _getBatteryIcon(int level) {
    if (level > 80) return Icons.battery_full;
    if (level > 60) return Icons.battery_6_bar;
    if (level > 40) return Icons.battery_4_bar;
    if (level > 20) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }

  Color _getBatteryColor(int level) {
    if (level > 50) return Colors.green;
    if (level > 20) return Colors.orange;
    return Colors.red;
  }

  void _showConnectDialog(BuildContext context) {
    final droneProvider = Provider.of<DroneConnectionProvider>(context, listen: false);
    
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