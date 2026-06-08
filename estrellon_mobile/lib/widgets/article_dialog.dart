import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/article_model.dart';
import '../services/article_service.dart';
import '../utils/loading.dart';
import 'custom_text.dart';

class ArticleDialog extends StatefulWidget {
  final Article? article;
  final Function(Article) onSave;

  const ArticleDialog({
    super.key,
    this.article,
    required this.onSave,
  });

  @override
  State<ArticleDialog> createState() => _ArticleDialogState();
}

class _ArticleDialogState extends State<ArticleDialog> {
  final ArticleService _articleService = ArticleService();

  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.article?.name ?? '');
    _titleController = TextEditingController(text: widget.article?.title ?? '');
    _contentController = TextEditingController(
      text: widget.article?.content.join('\n') ?? '',
    );
    _isActive = widget.article?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_nameController.text.isEmpty ||
        _titleController.text.isEmpty ||
        _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required')),
      );
      return;
    }

    Loading.show(context, message: 'Saving article...');

    try {
      final articleData = {
        'name': _nameController.text,
        'title': _titleController.text,
        'content': _contentController.text.split('\n'),
        'isActive': _isActive,
      };

      late Map response;
      if (widget.article != null) {
        response = await _articleService.updateArticle(
          widget.article!.aid,
          articleData,
        );
      } else {
        response = await _articleService.createArticle(articleData);
      }

      Loading.hide(context);

      final newArticle = Article.fromJson(Map<String, dynamic>.from(response));
      widget.onSave(newArticle);

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.article != null ? 'Article updated!' : 'Article created!',
          ),
        ),
      );
    } catch (e) {
      Loading.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: CustomText(
        text: widget.article != null ? 'Edit Article' : 'Create Article',
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Content',
                hintText: 'Separate multiple lines with line breaks',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                CustomText(text: 'Active: ', fontSize: 14.sp),
                Switch(
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(widget.article != null ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
