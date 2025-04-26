import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/media_provider.dart';
import '../core/localization/app_localizations.dart';

class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Refresh media items when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MediaProvider>(context, listen: false).refreshMediaItems();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('media_gallery'.tr(context)),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'photos'.tr(context)),
            Tab(text: 'videos'.tr(context)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<MediaProvider>(context, listen: false).refreshMediaItems();
            },
          ),
        ],
      ),
      body: Consumer<MediaProvider>(
        builder: (context, mediaProvider, child) {
          if (mediaProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          return TabBarView(
            controller: _tabController,
            children: [
              // Photos tab
              _buildMediaGrid(
                context,
                mediaProvider.getMediaItemsByType(MediaType.photo),
              ),
              
              // Videos tab
              _buildMediaGrid(
                context,
                mediaProvider.getMediaItemsByType(MediaType.video),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMediaGrid(BuildContext context, List<MediaItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Text('no_media_found'.tr(context)),
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildMediaItem(context, item);
      },
    );
  }

  Widget _buildMediaItem(BuildContext context, MediaItem item) {
    return GestureDetector(
      onTap: () => _showMediaDetails(context, item),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Media thumbnail (placeholder for now)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                item.type == MediaType.photo ? Icons.photo : Icons.videocam,
                size: 36,
                color: Colors.grey[600],
              ),
            ),
          ),
          
          // Video duration indicator
          if (item.type == MediaType.video)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '1:20', // Placeholder duration
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          
          // Date indicator
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatDate(item.timestamp),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showMediaDetails(BuildContext context, MediaItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
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
                  // Media preview
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          item.type == MediaType.photo ? Icons.photo : Icons.videocam,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Media info
                  Text(
                    item.type == MediaType.photo ? 'photo_details'.tr(context) : 'video_details'.tr(context),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(context, 'date'.tr(context), _formatDate(item.timestamp)),
                  _buildInfoRow(context, 'time'.tr(context), '${item.timestamp.hour}:${item.timestamp.minute}'),
                  if (item.metadata != null && item.metadata!['location'] != null) ...[  
                    _buildInfoRow(
                      context, 
                      'location'.tr(context), 
                      '${item.metadata!['location']['lat']}, ${item.metadata!['location']['lng']}',
                    ),
                  ],
                  if (item.metadata != null && item.metadata!['altitude'] != null) ...[  
                    _buildInfoRow(
                      context, 
                      'altitude'.tr(context), 
                      '${item.metadata!['altitude']}m',
                    ),
                  ],
                  if (item.type == MediaType.video && 
                      item.metadata != null && 
                      item.metadata!['duration'] != null) ...[  
                    _buildInfoRow(
                      context, 
                      'duration'.tr(context), 
                      '${(item.metadata!['duration'] as Duration).inMinutes}:${(item.metadata!['duration'] as Duration).inSeconds % 60}',
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        context,
                        Icons.share,
                        'share'.tr(context),
                        () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('sharing_not_implemented'.tr(context))),
                          );
                        },
                      ),
                      _buildActionButton(
                        context,
                        Icons.download,
                        'download'.tr(context),
                        () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('download_not_implemented'.tr(context))),
                          );
                        },
                      ),
                      _buildActionButton(
                        context,
                        Icons.delete,
                        'delete'.tr(context),
                        () => _confirmDelete(context, item),
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MediaItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('confirm_delete'.tr(context)),
        content: Text('delete_media_confirmation'.tr(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr(context)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
              
              // Delete the item
              Provider.of<MediaProvider>(context, listen: false).deleteMediaItem(item.id);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('media_deleted'.tr(context))),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr(context)),
          ),
        ],
      ),
    );
  }
}