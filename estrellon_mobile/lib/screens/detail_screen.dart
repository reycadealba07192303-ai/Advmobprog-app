import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/article_model.dart';
import '../services/article_service.dart';
import '../utils/article_helpers.dart';
import '../utils/loading.dart';
import '../widgets/custom_text.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _articleService = ArticleService();

  late Article _article;
  late TextEditingController _titleController;
  late TextEditingController _nameController;
  late TextEditingController _contentController;

  bool _isEditMode = false;
  bool _isSaving = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _article = widget.article;
    _syncControllers();
  }

  void _syncControllers() {
    _titleController = TextEditingController(text: _article.title);
    _nameController = TextEditingController(text: _article.name);
    _contentController = TextEditingController(
      text: formatContentForInput(_article.content),
    );
    _isActive = _article.isActive;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      if (_isEditMode) {
        _titleController.text = _article.title;
        _nameController.text = _article.name;
        _contentController.text = formatContentForInput(_article.content);
        _isActive = _article.isActive;
        _isEditMode = false;
      } else {
        _isEditMode = true;
      }
    });
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    Loading.show(context, message: 'Updating article...');

    final payload = {
      'title': _titleController.text.trim(),
      'name': _nameController.text.trim(),
      'content': parseContentInput(_contentController.text),
      'isActive': _isActive,
    };

    Article updated;
    try {
      final res = await _articleService.updateArticle(_article.aid, payload);
      final data = res['article'] ?? res;
      updated = Article.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      updated = Article(
        aid: _article.aid,
        title: payload['title'] as String,
        name: payload['name'] as String,
        content: payload['content'] as List<String>,
        isActive: _isActive,
      );
    } finally {
      if (mounted) Loading.hide(context);
    }

    if (!mounted) return;

    setState(() {
      _article = updated;
      _isEditMode = false;
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Article updated.')),
    );
  }

  Widget _statusChip(bool active) {
    return Chip(
      label: Text(active ? 'Active' : 'Inactive'),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: active ? Colors.green : Colors.grey),
    );
  }

  Widget _buildViewMode() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 250.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                color: Colors.grey[300],
              ),
              child: const Placeholder(),
            ),
            SizedBox(height: 20.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomText(
                    text: _article.title.isEmpty ? 'Untitled' : _article.title,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                _statusChip(_article.isActive),
              ],
            ),
            SizedBox(height: 8.h),
            CustomText(
              text: _article.name,
              fontSize: 14.sp,
              fontStyle: FontStyle.italic,
            ),
            SizedBox(height: 16.h),
            ..._article.content.map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(text: '• ', fontSize: 16.sp),
                    Expanded(
                      child: CustomText(
                        text: item,
                        fontSize: 16.sp,
                      ),
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

  Widget _buildEditMode() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _nameController,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Author / Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _contentController,
                minLines: 4,
                maxLines: 8,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Content (one item per line or comma-separated)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  final list = parseContentInput(v ?? '');
                  return list.isEmpty ? 'At least one content item' : null;
                },
              ),
              SizedBox(height: 8.h),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _isActive,
                onChanged: _isSaving
                    ? null
                    : (val) => setState(() => _isActive = val),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _toggleEditMode,
                      child: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveChanges,
                      icon: _isSaving
                          ? SizedBox(
                              width: 16.w,
                              height: 16.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.pop(context, _article),
        ),
        title: CustomText(
          text: _article.title.isEmpty ? 'Untitled' : _article.title,
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEditMode,
            ),
        ],
      ),
      body: _isEditMode ? _buildEditMode() : _buildViewMode(),
    );
  }
}
