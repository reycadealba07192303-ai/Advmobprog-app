import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/article_model.dart';
import '../services/article_service.dart';
import '../utils/article_helpers.dart';
import '../utils/loading.dart';

class AddArticleDialog extends StatefulWidget {
  const AddArticleDialog({super.key});

  static Future<Article?> show(BuildContext context) {
    return showDialog<Article>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddArticleDialog(),
    );
  }

  @override
  State<AddArticleDialog> createState() => _AddArticleDialogState();
}

class _AddArticleDialogState extends State<AddArticleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _contentController = TextEditingController();
  final _articleService = ArticleService();

  bool _isSaving = false;
  bool _isActive = true;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    Loading.show(context, message: 'Adding article...');

    final payload = {
      'title': _titleController.text.trim(),
      'name': _authorController.text.trim(),
      'content': parseContentInput(_contentController.text),
      'isActive': _isActive,
    };

    Article article;
    try {
      final res = await _articleService.createArticle(payload);
      final created = res['article'] ?? res;
      article = Article.fromJson(Map<String, dynamic>.from(created));
    } catch (_) {
      article = Article(
        aid: DateTime.now().millisecondsSinceEpoch.toString(),
        title: payload['title'] as String,
        name: payload['name'] as String,
        content: payload['content'] as List<String>,
        isActive: _isActive,
      );
    } finally {
      if (mounted) Loading.hide(context);
    }

    if (!mounted) return;
    Navigator.of(context).pop(article);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Article'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
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
                controller: _authorController,
                textInputAction: TextInputAction.next,
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
                minLines: 3,
                maxLines: 6,
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? SizedBox(
                  width: 16.w,
                  height: 16.h,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(_isSaving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}
