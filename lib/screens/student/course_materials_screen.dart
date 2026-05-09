import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../models/resource.dart';
import '../../services/database_service.dart';

class CourseMaterialsScreen extends StatefulWidget {
  final Course course;
  const CourseMaterialsScreen({super.key, required this.course});

  @override
  State<CourseMaterialsScreen> createState() => _CourseMaterialsScreenState();
}

class _CourseMaterialsScreenState extends State<CourseMaterialsScreen> {
  final _dbService = DatabaseService();
  List<Resource> _resources = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final resources = await _dbService.getCourseResources(widget.course.id);
    if (!mounted) return;
    setState(() {
      _resources = resources;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    return Scaffold(
      appBar: AppBar(
        title: Text(course.name),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(course),
                Expanded(child: _buildResourceList()),
              ],
            ),
    );
  }

  Widget _buildHeader(Course course) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(course.subject, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(course.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          if (course.description != null && course.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(course.description!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ),
          const SizedBox(height: 8),
          Text('${_resources.length} resources', style: const TextStyle(color: Colors.white60, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildResourceList() {
    if (_resources.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('No materials shared yet', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _resources.length,
      itemBuilder: (_, i) => _buildResourceCard(_resources[i]),
    );
  }

  Widget _buildResourceCard(Resource resource) {
    final iconMap = {
      'document': Icons.description_rounded,
      'video': Icons.play_circle_rounded,
      'image': Icons.image_rounded,
      'url': Icons.link_rounded,
    };
    final colorMap = {
      'document': const Color(0xFF1565C0),
      'video': const Color(0xFFE65100),
      'image': const Color(0xFF2E7D32),
      'url': const Color(0xFF7B1FA2),
    };
    final labelMap = {
      'document': 'Document',
      'video': 'Video',
      'image': 'Image',
      'url': 'Link',
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (resource.type == 'url' && resource.url != null) {
            _showResourceDialog(resource);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (colorMap[resource.type] ?? Colors.grey).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconMap[resource.type] ?? Icons.file_copy,
                    color: colorMap[resource.type] ?? Colors.grey, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(resource.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (colorMap[resource.type] ?? Colors.grey).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(labelMap[resource.type] ?? resource.type,
                              style: TextStyle(fontSize: 11, color: colorMap[resource.type] ?? Colors.grey)),
                        ),
                        if (resource.fileName != null) ...[
                          const SizedBox(width: 8),
                          Text(resource.fileName!, style: TextStyle(fontSize: 11, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded, size: 18, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showResourceDialog(Resource resource) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(resource.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${resource.type}', style: TextStyle(color: Colors.grey[600])),
            if (resource.url != null) ...[
              const SizedBox(height: 8),
              Text(resource.url!, style: const TextStyle(color: Color(0xFF1565C0)), maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          if (resource.url != null)
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opening: ${resource.url}')),
                );
              },
              icon: const Icon(Icons.open_in_browser, size: 18),
              label: const Text('Open'),
            ),
        ],
      ),
    );
  }
}
