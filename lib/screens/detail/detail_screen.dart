import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/anime_provider.dart';
import '../../widgets/common_widgets.dart' as common;
import '../../widgets/anime_card.dart';
import '../player/player_screen.dart';

class DetailScreen extends StatefulWidget {
  final String detailUrl;
  final String title;

  const DetailScreen({
    super.key,
    required this.detailUrl,
    required this.title,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _selectedChannel = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnimeProvider>().loadAnimeDetail(widget.detailUrl);
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Consumer<AnimeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.currentDetail == null) {
            return const common.LoadingWidget();
          }

          if (provider.error != null && provider.currentDetail == null) {
            return common.ErrorWidget(
              message: provider.error!,
              onRetry: () => provider.loadAnimeDetail(widget.detailUrl),
            );
          }

          final detail = provider.currentDetail;
          if (detail == null) {
            return const Center(child: Text('暂无数据'));
          }

          if (_tabController == null && detail.channels.isNotEmpty) {
            _tabController = TabController(
              length: detail.channels.length,
              vsync: this,
            );
            _tabController!.addListener(() {
              if (!_tabController!.indexIsChanging) {
                setState(() {
                  _selectedChannel = _tabController!.index;
                });
              }
            });
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: detail.imgUrl,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 300,
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 300,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    ),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: detail.tags
                            .map((tag) => Chip(
                                  label: Text(tag),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        detail.desc,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '选集',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (detail.channels.isNotEmpty) ...[
                        if (detail.channels.length > 1)
                          TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            labelColor: Theme.of(context).primaryColor,
                            unselectedLabelColor: Colors.grey,
                            tabs: List.generate(
                              detail.channels.length,
                              (index) => Tab(text: '线路${index + 1}'),
                            ),
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: _buildEpisodeGrid(
                            detail.channels[_selectedChannel] ?? [],
                          ),
                        ),
                      ],
                      if (detail.relatedAnimes.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          '相关推荐',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 240,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: detail.relatedAnimes.length,
                            itemBuilder: (context, index) {
                              final anime = detail.relatedAnimes[index];
                              return SizedBox(
                                width: 140,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: AnimeCard(
                                    anime: anime,
                                    onTap: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DetailScreen(
                                            detailUrl: anime.url,
                                            title: anime.title,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEpisodeGrid(List episodes) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final episode = episodes[index];
        return OutlinedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayerScreen(
                  episodeUrl: episode.url,
                  episodeName: episode.name,
                ),
              ),
            );
          },
          child: Text(
            episode.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        );
      },
    );
  }
}
