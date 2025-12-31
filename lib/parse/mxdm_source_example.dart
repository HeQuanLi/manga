import 'package:manga/parse/mxdm_source.dart';

void main() async {
  // 获取 MxdmSource 单例实例
  final source = MxdmSource();

  try {
    // 1. 获取首页数据
    print('Fetching home data...');
    final homeData = await source.getHomeData();
    print('Home sections: ${homeData.length}');
    for (var section in homeData) {
      print('Section: ${section.title}, Animes: ${section.animes.length}');
    }

    // 2. 获取每周更新数据
    print('\nFetching week data...');
    final weekData = await source.getWeekData();
    print('Week data: ${weekData.length} days');

    // 3. 搜索动漫
    print('\nSearching for anime...');
    final searchResults = await source.getSearchData('仙逆', 1);
    print('Search results: ${searchResults.length}');
    if (searchResults.isNotEmpty) {
      print('First result: ${searchResults[0].title}');
      print('First result: ${searchResults[0].url}');
    }

    // 4. 获取动漫详情（需要真实的 detailUrl）
    final detail = await source.getAnimeDetail(searchResults[0].url);
    print('Anime detail: ${detail.title}');

    // 5. 获取视频数据（需要真实的 episodeUrl）
    final video = await source.getVideoData('/dongmanplay/8404-1-1.html');
    print('Video URL: ${video.videoUrl}');
  } catch (e) {
    print('Error: $e');
  }
}
