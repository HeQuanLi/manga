import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/anime_provider.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/common_widgets.dart' as common;
import '../detail/detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryUrl;
  final String categoryTitle;

  const CategoryScreen({
    super.key,
    required this.categoryUrl,
    required this.categoryTitle,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnimeProvider>().loadCategoryData(widget.categoryUrl, _currentPage);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    // 清空分类结果
    context.read<AnimeProvider>().clearCategoryResults();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    final provider = context.read<AnimeProvider>();
    if (!provider.isLoading && !provider.hasReachedMax) {
      _currentPage++;
      provider.loadMoreCategory(widget.categoryUrl, _currentPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Consumer<AnimeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.categoryResults.isEmpty) {
            return const common.LoadingWidget();
          }

          if (provider.error != null && provider.categoryResults.isEmpty) {
            return common.ErrorWidget(
              message: provider.error!,
              onRetry: () {
                _currentPage = 1;
                provider.loadCategoryData(widget.categoryUrl, _currentPage);
              },
            );
          }

          if (provider.categoryResults.isEmpty) {
            return const Center(
              child: Text(
                '暂无内容',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: provider.categoryResults.length,
                  itemBuilder: (context, index) {
                    final anime = provider.categoryResults[index];
                    return AnimeCard(
                      anime: anime,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailScreen(
                              detailUrl: anime.url,
                              title: anime.title,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (provider.isLoading && provider.categoryResults.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              if (!provider.isLoading &&
                  provider.categoryResults.isNotEmpty &&
                  provider.hasReachedMax)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '没有更多了',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
