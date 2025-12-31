import '../dto/anime_bean.dart';
import '../dto/anime_detail_bean.dart';
import '../dto/home_bean.dart';
import '../dto/video_bean.dart';

abstract class AnimeSource {
  String get defaultDomain;
  String get baseUrl;
  set baseUrl(String url);

  Future<List<HomeBean>> getHomeData();
  Future<AnimeDetailBean> getAnimeDetail(String detailUrl);
  Future<VideoBean> getVideoData(String episodeUrl);
  Future<List<AnimeBean>> getSearchData(String query, int page);
  Future<Map<int, List<AnimeBean>>> getWeekData();
}
