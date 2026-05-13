import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/course.dart';
import '../../models/resource.dart';
import '../../models/resource_analysis.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import 'ai_assistant_screen.dart';
import 'flashcards_screen.dart';
import 'ai_quiz_screen.dart';

class CourseMaterialsScreen extends StatefulWidget {
  final Course course;
  const CourseMaterialsScreen({super.key, required this.course});

  @override
  State<CourseMaterialsScreen> createState() => _CourseMaterialsScreenState();
}

class _CourseMaterialsScreenState extends State<CourseMaterialsScreen> {
  final _dbService = DatabaseService();
  final _storageService = StorageService();
  final Set<String> _expandedIds = {};
  List<Resource> _resources = [];
  final Map<String, ResourceAnalysis> _analysisMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final resources = await _dbService.getCourseResources(widget.course.id);
    final analysisMap = <String, ResourceAnalysis>{};
    for (final r in resources) {
      final analysis = await _dbService.getResourceAnalysis(r.id);
      if (analysis != null) analysisMap[r.id] = analysis;
    }
    if (!mounted) return;
    setState(() {
      _resources = resources;
      _analysisMap
        ..clear()
        ..addAll(analysisMap);
      _isLoading = false;
    });
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  Future<void> _download(Resource resource) async {
    final url = _storageService.getDownloadUrl(resource);
    if (url.isEmpty) return;

    if (!mounted) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _askAi(Resource resource) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiAssistantScreen(
          subjects: [widget.course.subject],
          initialSubject: widget.course.subject,
          resourceTitle: resource.title,
          resourceType: resource.type,
          resourceUrl: resource.url,
          courseId: widget.course.id,
          resourceId: resource.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.name),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildResourceList()),
              ],
            ),
    );
  }

  Widget _buildHeader() {
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
          Text(widget.course.subject, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(widget.course.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          if (widget.course.description != null && widget.course.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(widget.course.description!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
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

  Map<String, dynamic> _resourceStyle(Resource resource) {
    final map = {
      'document': {
        'icon': Icons.description_rounded,
        'color': const Color(0xFF1565C0),
        'label': 'Document',
      },
      'video': {
        'icon': Icons.play_circle_rounded,
        'color': const Color(0xFFE65100),
        'label': 'Video',
      },
      'image': {
        'icon': Icons.image_rounded,
        'color': const Color(0xFF2E7D32),
        'label': 'Image',
      },
      'url': {
        'icon': Icons.link_rounded,
        'color': const Color(0xFF7B1FA2),
        'label': 'Link',
      },
    };
    return map[resource.type] ??
        {'icon': Icons.file_copy, 'color': Colors.grey, 'label': resource.type};
  }

  Widget _buildResourceCard(Resource resource) {
    final style = _resourceStyle(resource);
    final icon = style['icon'] as IconData;
    final color = style['color'] as Color;
    final label = style['label'] as String;
    final isExpanded = _expandedIds.contains(resource.id);
    final url = _storageService.getDownloadUrl(resource);
    final hasUrl = url.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: isExpanded ? Radius.zero : const Radius.circular(14),
              bottomRight: isExpanded ? Radius.zero : const Radius.circular(14),
            ),
            onTap: () => _toggleExpand(resource.id),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(resource.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(label,
                                  style: TextStyle(fontSize: 11, color: color)),
                            ),
                            if (resource.fileName != null) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(resource.fileName!,
                                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildSummaryPanel(resource, color, hasUrl),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  void _viewFlashcards(ResourceAnalysis analysis) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardsScreen(analysis: analysis),
      ),
    );
  }

  void _takeQuiz(Resource resource) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiQuizScreen(course: widget.course, resourceId: resource.id),
      ),
    );
  }

  Widget _buildSummaryPanel(Resource resource, Color color, bool hasUrl) {
    final analysis = _analysisMap[resource.id];

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Colors.grey[200], height: 8),
          const SizedBox(height: 8),
          _summaryRow(Icons.info_outline, 'Title', resource.title),
          _summaryRow(Icons.category_outlined, 'Type', resource.type),
          if (resource.fileName != null)
            _summaryRow(Icons.insert_drive_file_outlined, 'File', resource.fileName!),
          if (hasUrl)
            _summaryRow(Icons.link_outlined, 'URL', resource.url!, maxLines: 2),
          if (analysis?.summary != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Summary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                  const SizedBox(height: 4),
                  Text(analysis!.summary!, style: const TextStyle(fontSize: 13, height: 1.4)),
                ],
              ),
            ),
          ],
          if (analysis?.tags != null && analysis!.tags!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: analysis.tags!.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7B1FA2).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(t, style: const TextStyle(fontSize: 12, color: Color(0xFF7B1FA2))),
              )).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasUrl ? () => _download(resource) : null,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _askAi(resource),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('Ask AI'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7B1FA2),
                    side: BorderSide(color: const Color(0xFF7B1FA2).withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          if (analysis != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (analysis.flashcards != null && analysis.flashcards!.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewFlashcards(analysis),
                      icon: const Icon(Icons.style_rounded, size: 18),
                      label: Text('Flashcards (${analysis.flashcards!.length})'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        side: BorderSide(color: const Color(0xFF2E7D32).withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                if (analysis.flashcards != null && analysis.flashcards!.isNotEmpty && analysis.quiz != null)
                  const SizedBox(width: 10),
                if (analysis.quiz != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _takeQuiz(resource),
                      icon: const Icon(Icons.quiz_rounded, size: 18),
                      label: const Text('Take Quiz'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE65100),
                        side: BorderSide(color: const Color(0xFFE65100).withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
