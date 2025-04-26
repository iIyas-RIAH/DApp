import 'package:flutter/material.dart';
import '../core/localization/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('privacy_policy'.tr(context))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'privacy_policy'.tr(context),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            _buildSection(
              context,
              'information_collection'.tr(context),
              'information_collection_content'.tr(context),
            ),

            _buildSection(
              context,
              'data_usage'.tr(context),
              'data_usage_content'.tr(context),
            ),

            _buildSection(
              context,
              'location_data'.tr(context),
              'location_data_content'.tr(context),
            ),

            _buildSection(
              context,
              'media_storage'.tr(context),
              'media_storage_content'.tr(context),
            ),

            _buildSection(
              context,
              'data_sharing'.tr(context),
              'data_sharing_content'.tr(context),
            ),

            _buildSection(
              context,
              'data_security'.tr(context),
              'data_security_content'.tr(context),
            ),

            _buildSection(
              context,
              'policy_updates'.tr(context),
              'policy_updates_content'.tr(context),
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                '${'last_updated'.tr(context)}: 2023-06-01',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(content),
        ],
      ),
    );
  }
}
