import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../dto/anime_bean.dart';
import '../dto/anime_detail_bean.dart';
import '../dto/episode_bean.dart';
import '../dto/home_bean.dart';
import '../dto/video_bean.dart';
import '../util/download_manager.dart';
import '../util/crypto_utils.dart';
import 'anime_source.dart';

class MxdmSource implements AnimeSource {
  static final MxdmSource _instance = MxdmSource._internal();

  factory MxdmSource() => _instance;

  MxdmSource._internal();

  @override
  String get defaultDomain => 'https://www.mxdm.tv';

  String _baseUrl = getDefaultDomain();

  @override
  String get baseUrl => _baseUrl;

  @override
  set baseUrl(String url) => _baseUrl = url;

  @override
  Future<List<HomeBean>> getHomeData() async {
    final source = await DownloadManager.getHtml(baseUrl);
    final document = html_parser.parse(source);

    final homeBeanList = <HomeBean>[];
    final modules = document.querySelectorAll('div.module');

    for (var i = 0; i < modules.length && i < 6; i++) {
      final element = modules[i];
      final title = element.querySelector('h2')?.text ?? '';
      final moreUrl = element.querySelector('a.more')?.attributes['href'] ?? '';

      final moduleItems = element.querySelectorAll('div.module-item');
      final homeItemBeanList = _getAnimeList(moduleItems);

      homeBeanList.add(HomeBean(
        title: title,
        moreUrl: moreUrl,
        animes: homeItemBeanList,
      ));
    }

    return homeBeanList;
  }

  @override
  Future<AnimeDetailBean> getAnimeDetail(String detailUrl) async {
    final source = await DownloadManager.getHtml('$baseUrl/$detailUrl');
    final document = html_parser.parse(source);

    final main = document.querySelector('main');
    if (main == null) {
      throw Exception('Failed to parse anime detail: main element not found');
    }

    final title = main.querySelector('h1')?.text ?? '';
    final desc = main.querySelector('div.video-info-content')?.text ?? '';
    final imgUrl = main.querySelector('div.module-item-pic > img')?.attributes['data-src'] ?? '';
    final tags = main.querySelectorAll('div.tag-link > a').map((e) => e.text).toList();
    final channels = _getAnimeEpisodes(main);

    final moduleItems = main.querySelectorAll('div.module-items');
    final relatedAnimes = moduleItems.isNotEmpty
        ? _getAnimeList(moduleItems[0].querySelectorAll('div.module-item'))
        : <AnimeBean>[];

    return AnimeDetailBean(
      title,
      imgUrl,
      desc,
      tags,
      relatedAnimes,
      channels: channels,
    );
  }

  @override
  Future<VideoBean> getVideoData(String episodeUrl) async {
    final source = await DownloadManager.getHtml('$baseUrl/$episodeUrl');
    final document = html_parser.parse(source);

    final videoUrl = await _getVideoUrl(document);

    return VideoBean(videoUrl);
  }

  @override
  Future<List<AnimeBean>> getSearchData(String query, int page) async {
    final source = await DownloadManager.getHtml('$baseUrl/search/$query----------$page---.html');
    final document = html_parser.parse(source);

    final animeList = <AnimeBean>[];
    final searchItems = document.querySelectorAll('div.module-search-item');

    for (var el in searchItems) {
      final title = el.querySelector('h3')?.text ?? '';
      final url = el.querySelector('h3 > a')?.attributes['href'] ?? '';
      final imgUrl = el.querySelector('img')?.attributes['data-src'] ?? '';
      animeList.add(AnimeBean(title: title, img: imgUrl, url: url));
    }

    return animeList;
  }

  @override
  Future<Map<int, List<AnimeBean>>> getWeekData() async {
    final source = await DownloadManager.getHtml(baseUrl);
    final document = html_parser.parse(source);

    final elements = document.querySelectorAll('ul.mxoneweek-list');
    final weekMap = <int, List<AnimeBean>>{};

    for (var index = 0; index < elements.length; index++) {
      final element = elements[index];
      final dayList = <AnimeBean>[];

      final items = element.querySelectorAll('li');
      for (var el in items) {
        final spans = el.querySelectorAll('a > span');
        final title = spans.isNotEmpty ? spans[0].text : '';
        final episodeName = spans.length > 1 ? spans[1].text : '';
        final url = el.querySelector('a')?.attributes['href'] ?? '';
        dayList.add(AnimeBean(title: title, img: '', url: url, episodeName: episodeName));
      }

      weekMap[index] = dayList;
    }

    return weekMap;
  }

  List<AnimeBean> _getAnimeList(List<Element> elements) {
    final animeList = <AnimeBean>[];

    for (var el in elements) {
      final title = el.querySelector('a')?.attributes['title'] ?? '';
      final url = el.querySelector('a')?.attributes['href'] ?? '';
      final imgUrl = el.querySelector('img')?.attributes['data-src'] ?? '';
      final episodeName = el.querySelector('div.module-item-text')?.text ?? '';

      animeList.add(AnimeBean(
        title: title,
        img: imgUrl,
        url: url,
        episodeName: episodeName,
      ));
    }

    return animeList;
  }

  Map<int, List<EpisodeBean>> _getAnimeEpisodes(Element element) {
    final channels = <int, List<EpisodeBean>>{};
    final scrollContents = element.querySelectorAll('div.module-blocklist > div.scroll-content');

    for (var i = 0; i < scrollContents.length; i++) {
      final episodes = <EpisodeBean>[];
      final links = scrollContents[i].querySelectorAll('a');

      for (var el in links) {
        final name = el.text;
        final url = el.attributes['href'] ?? '';
        episodes.add(EpisodeBean(name, url));
      }

      channels[i] = episodes;
    }

    return channels;
  }

  static const String _baseM3u8 = 'https://danmu.yhdmjx.com/m3u8.php?url=';
  static const String _aesKey = '57A891D97E332A9D';

  Future<String> _getVideoUrl(Document document) async {
    final scripts = document.querySelectorAll('div.player-wrapper > script');
    if (scripts.isEmpty) {
      throw Exception('Failed to find video script');
    }

    final urlTarget = scripts[0].text;
    final urlRegex = RegExp(r'"url":"(.*?)","url_next"');
    final urlMatch = urlRegex.firstMatch(urlTarget);
    if (urlMatch == null) {
      throw Exception('Failed to extract video URL');
    }
    final url = urlMatch.group(1)!;

    final doc = html_parser.parse(await DownloadManager.getHtml(_baseM3u8 + url));
    final headScripts = doc.querySelectorAll('head > script');
    if (headScripts.length < 2) {
      throw Exception('Failed to find IV script');
    }

    final ivTarget = headScripts[1].text;
    final ivRegex = RegExp(r'var bt_token = "(.*?)"');
    final ivMatch = ivRegex.firstMatch(ivTarget);
    if (ivMatch == null) {
      throw Exception('Failed to extract IV');
    }
    final iv = ivMatch.group(1)!;

    final bodyScripts = doc.querySelectorAll('body > script');
    if (bodyScripts.isEmpty) {
      throw Exception('Failed to find encrypted video URL script');
    }

    final videoUrlTarget = bodyScripts[0].text;
    final videoUrlRegex = RegExp(r'getVideoInfo\("(.*?)"');
    final videoUrlMatch = videoUrlRegex.firstMatch(videoUrlTarget);
    if (videoUrlMatch == null) {
      throw Exception('Failed to extract encrypted video URL');
    }
    final encryptedVideoUrl = videoUrlMatch.group(1)!;

    return decryptData(encryptedVideoUrl, key: _aesKey, iv: iv);
  }
}
