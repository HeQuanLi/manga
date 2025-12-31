import 'anime_bean.dart';
import 'episode_bean.dart';

class AnimeDetailBean {
  final String title;
  final String imgUrl;
  final String desc;
  final List<String> tags;
  final List<AnimeBean> relatedAnimes;
  final Map<int, List<EpisodeBean>> channels;

  AnimeDetailBean(
    this.title,
    this.imgUrl,
    this.desc,
    this.tags,
    this.relatedAnimes, {
    required this.channels,
  });

  @override
  String toString() {
    return 'AnimeDetailBean{title: $title, imgUrl: $imgUrl, tags: $tags, channels: ${channels.length}}';
  }
}
