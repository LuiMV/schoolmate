import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/course.dart';
import '../../models/resource.dart';
import '../../services/database_service.dart';
import '../teacher/upload_resource_screen.dart';
import '../teacher/comprehension_scores_screen.dart';
import '../teacher/ai_feedback_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
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
        backgroundColor: const Color.fromARGB(255, 120, 166, 164),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeader(course),
                  const SizedBox(height: 24),
                  _buildActionCards(course),
                  const SizedBox(height: 24),
                  Text('Resources', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                  const SizedBox(height: 12),
                  if (_resources.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text('No resources yet', style: TextStyle(color: Colors.grey[500])),
                      ),
                    )
                  else
                    ..._resources.map((r) => _buildResourceCard(r)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color.fromARGB(255, 120, 166, 164),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file),
        label: const Text('Add Resource'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => UploadResourceScreen(course: course)),
          );
          _load();
        },
      ),
    );
  }

  Widget _buildHeader(Course course) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color.fromARGB(255, 41, 94, 17), Color.fromARGB(255, 15, 178, 42)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(course.subject, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(course.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Grade ${course.grade} · Section ${course.section}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          if (course.description != null && course.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(course.description!, style: const TextStyle(color: Colors.white60, fontSize: 13)),
            ),
          if (course.inviteCode != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.vpn_key_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Invite Code: ',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                  ),
                  Text(
                    course.inviteCode!,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 3),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: course.inviteCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied!'), duration: Duration(seconds: 1)),
                      );
                    },
                    child: Icon(Icons.copy_rounded, color: Colors.white.withValues(alpha: 0.6), size: 18),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCards(Course course) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.analytics_rounded,
            label: 'Scores',
            color: const Color(0xFF1565C0),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ComprehensionScoresScreen(course: course)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.auto_awesome_rounded,
            label: 'AI Feedback',
            color: const Color(0xFF7B1FA2),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AiFeedbackScreen(course: course)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
            ],
          ),
        ),
      ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: (colorMap[resource.type] ?? Colors.grey).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(iconMap[resource.type] ?? Icons.file_copy, color: colorMap[resource.type] ?? Colors.grey),
        ),
        title: Text(resource.title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(resource.type, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async {
            await _dbService.deleteResource(resource.id);
            _load();
          },
        ),
        onTap: () {},
      ),
    );
  }
}
