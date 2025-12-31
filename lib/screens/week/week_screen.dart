import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/anime_provider.dart';
import '../../widgets/common_widgets.dart' as common;
import '../detail/detail_screen.dart';

class WeekScreen extends StatefulWidget {
  const WeekScreen({super.key});

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.index = DateTime.now().weekday - 1;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnimeProvider>().loadWeekData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: false,
            tabs: _weekDays.map((day) => Tab(text: day)).toList(),
            labelStyle:
                const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500),
            // 选中时文字大小 20
            unselectedLabelStyle:
                const TextStyle(fontSize: 11.0, fontWeight: FontWeight.w500),
            // 未选中时文字大小 14
            labelColor: Colors.blue,
            // 选中文字颜色（可选）
            unselectedLabelColor: Colors.black, // 未选中文字颜色（可选）
          ),
          Expanded(
            child: Consumer<AnimeProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.weekData.isEmpty) {
                  return const common.LoadingWidget();
                }

                if (provider.error != null && provider.weekData.isEmpty) {
                  return common.ErrorWidget(
                    message: provider.error!,
                    onRetry: () => provider.loadWeekData(),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: List.generate(7, (index) {
                    final animes = provider.weekData[index] ?? [];
                    if (animes.isEmpty) {
                      return const Center(
                        child: Text('暂无更新'),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => provider.loadWeekData(),
                      child: ListView.builder(
                        itemCount: animes.length,
                        itemBuilder: (context, animeIndex) {
                          final anime = animes[animeIndex];
                          return ListTile(
                            title: Text(anime.title),
                            subtitle: Text(anime.episodeName),
                            trailing: const Icon(Icons.play_circle_outline),
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
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
