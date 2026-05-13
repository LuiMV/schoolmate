import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/course.dart';
import '../../models/resource.dart';
import '../../services/database_service.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../services/edge_function_service.dart';
import '../../services/text_extraction_service.dart';

class UploadResourceScreen extends StatefulWidget {
  final Course course;
  const UploadResourceScreen({super.key, required this.course});

  @override
  State<UploadResourceScreen> createState() => _UploadResourceScreenState();
}

class _UploadResourceScreenState extends State<UploadResourceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _dbService = DatabaseService();
  final _storageService = StorageService();
  final _authService = AuthService();

  String _selectedType = 'document';
  Uint8List? _selectedBytes;
  String? _fileName;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType == 'url' && _urlCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a URL')),
      );
      return;
    }

    if (_selectedType != 'url' && _selectedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? fileUrl;
      String? filePath;

      if (_selectedType != 'url' && _selectedBytes != null && _fileName != null) {
        final user = _authService.currentUser;
        fileUrl = await _storageService.uploadFile(
          user!.id,
          widget.course.id,
          _selectedBytes!,
          _fileName!,
        );
        filePath = _fileName;
      }

      final resource = Resource(
        id: '',
        courseId: widget.course.id,
        teacherId: _authService.currentUser!.id,
        title: _titleCtrl.text.trim(),
        type: _selectedType,
        url: _selectedType == 'url' ? _urlCtrl.text.trim() : fileUrl,
        filePath: filePath,
        fileName: _fileName,
      );

      final created = await _dbService.createResource(resource);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resource uploaded, analyzing with AI...'), backgroundColor: Colors.green),
      );

      if (_selectedType != 'url' && _selectedBytes != null) {
        try {
          final textService = TextExtractionService();
          final fileText = await textService.extractTextFromBytes(_selectedBytes!, _fileName ?? '');
          await EdgeFunctionService().invokeIngestion(
            resourceId: created.id,
            fileText: fileText,
            title: created.title,
          );
        } catch (e) {
          // Ingestion failure is non-critical
        }
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Resource'),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Course: ${widget.course.name}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 24),
              Text('Resource Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800])),
              const SizedBox(height: 12),
              _buildTypeSelector(),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter a descriptive title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              if (_selectedType == 'url') _buildUrlField() else _buildFilePicker(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _submit,
                  icon: _isUploading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cloud_upload_rounded),
                  label: Text(_isUploading ? 'Uploading...' : 'Upload Resource'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    final types = [
      {'type': 'document', 'icon': Icons.description_rounded, 'label': 'Document'},
      {'type': 'video', 'icon': Icons.play_circle_rounded, 'label': 'Video'},
      {'type': 'image', 'icon': Icons.image_rounded, 'label': 'Image'},
      {'type': 'url', 'icon': Icons.link_rounded, 'label': 'URL'},
    ];

    return Row(
      children: types.map((t) {
        final isSelected = _selectedType == t['type'];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: t == types.last ? 0 : 8),
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedType = t['type'] as String;
                _selectedBytes = null;
                _fileName = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE65100).withValues(alpha: 0.1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFE65100) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(t['icon'] as IconData, color: isSelected ? const Color(0xFFE65100) : Colors.grey[600], size: 28),
                    const SizedBox(height: 4),
                    Text(t['label'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFFE65100) : Colors.grey[600])),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUrlField() {
    return TextFormField(
      controller: _urlCtrl,
      keyboardType: TextInputType.url,
      decoration: const InputDecoration(
        labelText: 'URL',
        hintText: 'https://example.com/resource',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.link),
      ),
      validator: (v) {
        if (_selectedType == 'url' && (v == null || v.trim().isEmpty)) return 'URL is required';
        return null;
      },
    );
  }

  Future<void> _pickFile() async {
    try {
      final typeMap = {
        'document': FileType.custom,
        'video': FileType.video,
        'image': FileType.image,
      };

      FilePickerResult? result;

      if (_selectedType == 'document') {
        result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt'],
          withData: true,
        );
      } else {
        result = await FilePicker.pickFiles(
          type: typeMap[_selectedType] ?? FileType.any,
          withData: true,
        );
      }

      if (result == null || result.files.isEmpty) return;
      final picked = result.files.single;

      setState(() {
        _selectedBytes = picked.bytes;
        _fileName = picked.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildFilePicker() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Column(
        children: [
          Icon(
            _selectedType == 'document' ? Icons.description_rounded :
            _selectedType == 'video' ? Icons.video_file_rounded :
            Icons.image_rounded,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            _fileName ?? 'No file selected',
            style: TextStyle(color: _fileName != null ? Colors.black87 : Colors.grey[500]),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.folder_open),
            label: const Text('Browse Files'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Supports: PDF, DOC, MP4, JPG, PNG (max 50MB)',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
