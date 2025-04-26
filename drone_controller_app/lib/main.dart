import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Core modules
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'core/providers/app_state_provider.dart';
import 'core/providers/drone_connection_provider.dart';
import 'core/providers/media_provider.dart';
import 'core/providers/flight_planning_provider.dart';

// Screens
import 'screens/home_screen.dart';
import 'screens/control_screen.dart';
import 'screens/media_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/map_screen.dart';
import 'screens/flight_planning_screen.dart';
import 'screens/missions_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/privacy_policy_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => DroneConnectionProvider()),
        ChangeNotifierProvider(create: (_) => MediaProvider()),
        ChangeNotifierProvider(create: (_) => FlightPlanningProvider()),
      ],
      child: Consumer<AppStateProvider>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: 'Drone Controller',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.themeMode,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''), // English
              Locale('fr', ''), // French
            ],
            locale: appState.locale,
            home: const HomeScreen(),
            routes: {
              '/control': (context) => const ControlScreen(),
              '/media': (context) => const MediaScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/map': (context) => const MapScreen(),
              '/flight-planning': (context) => const FlightPlanningScreen(),
              '/missions': (context) => const MissionsScreen(),
              '/help-support': (context) => const HelpSupportScreen(),
              '/privacy-policy': (context) => const PrivacyPolicyScreen(),
            },
          );
        },
      ),
    );
  }
}
