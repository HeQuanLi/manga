import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/anime_provider.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/common_widgets.dart' as common;
import '../detail/detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnimeProvider>().loadHomeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AnimeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.homeSections.isEmpty) {
            return const common.LoadingWidget();
          }

          if (provider.error != null && provider.homeSections.isEmpty) {
            return common.ErrorWidget(
              message: provider.error!,
              onRetry: () => provider.loadHomeData(),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadHomeData(),
            child: ListView.builder(
              itemCount: provider.homeSections.length,
              itemBuilder: (context, index) {
                final section = provider.homeSections[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            section.title
                                .replaceAll(RegExp(r'[^\w\u4e00-\u9fa5]'), ''),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (section.moreUrl.isNotEmpty)
                            const Text(
                              '更多>',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 167,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: section.animes.length,
                        itemBuilder: (context, animeIndex) {
                          final anime = section.animes[animeIndex];
                          return Container(
                            margin: EdgeInsets.only(left: 4),
                            width: 120,
                            child: AnimeCard(
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
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
