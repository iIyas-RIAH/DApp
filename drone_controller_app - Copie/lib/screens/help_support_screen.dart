import 'package:flutter/material.dart';
import '../core/localization/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('help_support'.tr(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FAQ Section
            Text(
              'faq'.tr(context),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              context,
              'faq_connection_title'.tr(context),
              'faq_connection_content'.tr(context),
            ),
            _buildFaqItem(
              context,
              'faq_battery_title'.tr(context),
              'faq_battery_content'.tr(context),
            ),
            _buildFaqItem(
              context,
              'faq_flight_planning_title'.tr(context),
              'faq_flight_planning_content'.tr(context),
            ),
            _buildFaqItem(
              context,
              'faq_camera_title'.tr(context),
              'faq_camera_content'.tr(context),
            ),
            
            const SizedBox(height: 32),
            
            // Contact Support Section
            Text(
              'contact_support'.tr(context),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: Text('email'.tr(context)),
                      subtitle: const Text('support@dronecontroller.com'),
                      onTap: () async {
                        final Uri emailLaunchUri = Uri(
                          scheme: 'mailto',
                          path: 'support@dronecontroller.com',
                          queryParameters: {
                            'subject': 'Drone Controller App Support',
                          },
                        );
                        
                        if (await canLaunchUrl(emailLaunchUri)) {
                          await launchUrl(emailLaunchUri);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('could_not_launch_email'.tr(context))),
                            );
                          }
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: Text('phone'.tr(context)),
                      subtitle: const Text('+1 (555) 123-4567'),
                      onTap: () async {
                        final Uri phoneUri = Uri(
                          scheme: 'tel',
                          path: '+15551234567',
                        );
                        
                        if (await canLaunchUrl(phoneUri)) {
                          await launchUrl(phoneUri);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('could_not_launch_phone'.tr(context))),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // User Manual Section
            Text(
              'user_manual'.tr(context),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.book),
                      title: Text('download_manual'.tr(context)),
                      trailing: const Icon(Icons.download),
                      onTap: () async {
                        try {
                          // Show download progress
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('downloading_manual'.tr(context))),
                            );
                          }
                          
                          // URL of the manual PDF
                          const String url = 'https://example.com/drone_controller_manual.pdf';
                          final response = await http.get(Uri.parse(url));
                          
                          // Get the documents directory
                          final directory = await getApplicationDocumentsDirectory();
                          final filePath = '${directory.path}/drone_controller_manual.pdf';
                          final file = File(filePath);
                          await file.writeAsBytes(response.bodyBytes);
                          
                          // Show success message with option to open
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('manual_downloaded'.tr(context)),
                                action: SnackBarAction(
                                  label: 'open'.tr(context),
                                  onPressed: () async {
                                    final Uri fileUri = Uri.file(filePath);
                                    if (await canLaunchUrl(fileUri)) {
                                      await launchUrl(fileUri);
                                    }
                                  },
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('download_failed'.tr(context))),
                            );
                          }
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.video_library),
                      title: Text('video_tutorials'.tr(context)),
                      trailing: const Icon(Icons.play_circle_filled),
                      onTap: () {
                        // Show video tutorials dialog
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('video_tutorials'.tr(context)),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildVideoTutorialItem(
                                      context,
                                      'getting_started'.tr(context),
                                      'https://example.com/tutorials/getting_started',
                                    ),
                                    _buildVideoTutorialItem(
                                      context,
                                      'flight_controls'.tr(context),
                                      'https://example.com/tutorials/flight_controls',
                                    ),
                                    _buildVideoTutorialItem(
                                      context,
                                      'camera_settings'.tr(context),
                                      'https://example.com/tutorials/camera_settings',
                                    ),
                                    _buildVideoTutorialItem(
                                      context,
                                      'advanced_features'.tr(context),
                                      'https://example.com/tutorials/advanced_features',
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('close'.tr(context)),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFaqItem(BuildContext context, String title, String content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ExpansionTile(
        title: Text(title),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(content),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVideoTutorialItem(BuildContext context, String title, String url) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.play_arrow),
      onTap: () async {
        final Uri videoUri = Uri.parse(url);
        if (await canLaunchUrl(videoUri)) {
          await launchUrl(videoUri, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('could_not_launch_video'.tr(context))),
            );
          }
        }
      },
    );
  }
}