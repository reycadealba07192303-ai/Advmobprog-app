import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../data/sample_articles.dart';
import '../models/article_model.dart';
import '../services/article_service.dart';
import '../widgets/add_article_dialog.dart';
import '../widgets/custom_text.dart';
import 'detail_screen.dart';

class ArticleScreen extends StatefulWidget {
  const ArticleScreen({super.key});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  late Future<void> _loadFuture;
  List<Article> _allArticles = List<Article>.from(sampleArticles);
  List<Article> _filteredArticles = List<Article>.from(sampleArticles);
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadArticles();
  }

  Future<void> _loadArticles() async {
    try {
      final response = await ArticleService.getAllArticle();
      if (!mounted) return;
      if (response.isNotEmpty) {
        setState(() {
          _allArticles = List<Article>.from(
            response.map(
              (e) => Article.fromJson(Map<String, dynamic>.from(e)),
            ),
          );
          _filterArticles();
        });
      }
    } catch (_) {
      // Keep sample articles when API is unavailable.
    }
  }

  void _filterArticles() {
    final query = _searchController.text;
    if (query.isEmpty) {
      _filteredArticles = _allArticles;
    } else {
      _filteredArticles = _allArticles
          .where((article) =>
              article.title.toLowerCase().contains(query.toLowerCase()) ||
              article.name.toLowerCase().contains(query.toLowerCase()) ||
              article.content
                  .join(' ')
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();
    }
  }

  Future<void> _openAddArticleDialog() async {
    final result = await AddArticleDialog.show(context);

    if (!mounted || result == null) return;

    setState(() {
      _allArticles.insert(0, result);
      _filterArticles();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Article added.')),
    );
  }

  Future<void> _openArticleDetail(Article article) async {
    final updated = await Navigator.push<Article>(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailScreen(article: article),
      ),
    );

    if (!mounted || updated == null) return;

    setState(() {
      final index = _allArticles.indexWhere((a) => a.aid == updated.aid);
      if (index >= 0) {
        _allArticles[index] = updated;
      }
      _filterArticles();
    });
  }

  Widget _statusChip(bool active) {
    return Chip(
      label: Text(active ? 'Active' : 'Inactive'),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: active ? Colors.green : Colors.grey),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddArticleDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: TextField(
                controller: _searchController,
                onChanged: (_) {
                  setState(() {
                    _filterArticles();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search articles...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            FutureBuilder<void>(
              future: _loadFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _filteredArticles.isEmpty) {
                  return SizedBox(
                    height: ScreenUtil().screenHeight * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircularProgressIndicator.adaptive(strokeWidth: 3.sp),
                          SizedBox(height: 10.h),
                          const CustomText(
                            text:
                                'Waiting for the equipment articles to display...',
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (_filteredArticles.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.only(top: 20.h),
                    child: const Center(
                      child: CustomText(
                        text: 'No equipment article to display...',
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  shrinkWrap: true,
                  itemCount: _filteredArticles.length,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final article = _filteredArticles[index];

                    return Card(
                      elevation: 1,
                      child: InkWell(
                        onTap: () => _openArticleDetail(article),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ScreenUtil().setWidth(15),
                            vertical: ScreenUtil().setHeight(15),
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: CustomText(
                                            text: article.title.isEmpty
                                                ? 'Untitled'
                                                : article.title,
                                            fontSize: 24.sp,
                                            fontWeight: FontWeight.bold,
                                            maxLines: 2,
                                          ),
                                        ),
                                        _statusChip(article.isActive),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    CustomText(
                                      text: article.name,
                                      fontSize: 13.sp,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
