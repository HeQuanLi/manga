import 'anime_bean.dart';

class HomeBean {
  final String title;
  final String moreUrl;
  final List<AnimeBean> animes;

  HomeBean({
    required this.title,
    required this.moreUrl,
    required this.animes,
  });

  @override
  String toString() {
    return 'HomeBean{title: $title, moreUrl: $moreUrl, animes: ${animes.length} items}';
  }
}
