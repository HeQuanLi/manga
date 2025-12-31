import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/anime_provider.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/common_widgets.dart' as common;
import '../detail/detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  String _lastQuery = '';
  Timer? _debounce;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    // 加载搜索历史
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnimeProvider>().loadSearchHistory();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(isNewSearch: true);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _performSearch({bool isNewSearch = false}) {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    if (isNewSearch) {
      _currentPage = 1;
      _lastQuery = query;
      // 添加到搜索历史
      context.read<AnimeProvider>().addToSearchHistory(query);
      context.read<AnimeProvider>().searchAnime(query, _currentPage);
    }
  }

  void _loadMore() {
    final provider = context.read<AnimeProvider>();
    if (!provider.isLoading && !provider.hasReachedMax && _lastQuery.isNotEmpty) {
      _currentPage++;
      provider.loadMoreSearch(_lastQuery, _currentPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            autofocus: false,
            enableInteractiveSelection: true,
            decoration: InputDecoration(
              hintText: '搜索动漫...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[600]),
                      onPressed: () {
                        // 取消防抖
                        _debounce?.cancel();
                        // 清空输入框
                        _searchController.clear();
                        // 重置状态
                        setState(() {
                          _lastQuery = '';
                          _currentPage = 1;
                        });
                        // 清空搜索结果
                        context.read<AnimeProvider>().clearSearchResults();
                        // 取消焦点，收起键盘
                        _focusNode.unfocus();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            style: const TextStyle(color: Colors.black87, fontSize: 16),
          ),
        ),
      ),
      body: Consumer<AnimeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.searchResults.isEmpty) {
            return const common.LoadingWidget();
          }

          if (provider.error != null && provider.searchResults.isEmpty) {
            return common.ErrorWidget(
              message: provider.error!,
              onRetry: () => _performSearch(isNewSearch: true),
            );
          }

          if (provider.searchResults.isEmpty && _lastQuery.isEmpty) {
            return _buildSearchHistory();
          }

          if (provider.searchResults.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    '未找到 "$_lastQuery" 相关的动漫',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: provider.searchResults.length,
                  itemBuilder: (context, index) {
                    final anime = provider.searchResults[index];
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
              if (provider.isLoading && provider.searchResults.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              if (!provider.isLoading &&
                  provider.searchResults.isNotEmpty &&
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

  Widget _buildSearchHistory() {
    return Consumer<AnimeProvider>(
      builder: (context, provider, child) {
        if (provider.searchHistory.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '输入关键词搜索动漫',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 搜索历史头部
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '搜索历史',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('确认清空'),
                          content: const Text('确定要清空所有搜索历史吗?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('确定'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && mounted) {
                        await provider.clearSearchHistory();
                      }
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('清空'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ),
            // 搜索历史列表
            Expanded(
              child: ListView.builder(
                itemCount: provider.searchHistory.length,
                itemBuilder: (context, index) {
                  final query = provider.searchHistory[index];
                  return ListTile(
                    leading: Icon(
                      Icons.history,
                      color: Colors.grey[600],
                    ),
                    title: Text(query),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      onPressed: () {
                        provider.removeSearchHistory(query);
                      },
                    ),
                    onTap: () {
                      // 取消防抖，避免重复搜索
                      _debounce?.cancel();
                      // 设置搜索文本
                      _searchController.text = query;
                      // 执行搜索
                      _performSearch(isNewSearch: true);
                      // 请求焦点，让用户可以继续编辑
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (mounted) {
                          _focusNode.requestFocus();
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
