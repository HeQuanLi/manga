import 'package:flutter/material.dart';
import '../dto/anime_bean.dart';
import '../dto/anime_detail_bean.dart';
import '../dto/home_bean.dart';
import '../dto/video_bean.dart';
import '../parse/mxdm_source.dart';

class AnimeProvider with ChangeNotifier {
  final MxdmSource _source = MxdmSource();

  List<HomeBean> _homeSections = [];
  Map<int, List<AnimeBean>> _weekData = {};
  List<AnimeBean> _searchResults = [];
  AnimeDetailBean? _currentDetail;
  VideoBean? _currentVideo;

  bool _isLoading = false;
  String? _error;
  bool _hasReachedMax = false;

  List<HomeBean> get homeSections => _homeSections;
  Map<int, List<AnimeBean>> get weekData => _weekData;
  List<AnimeBean> get searchResults => _searchResults;
  AnimeDetailBean? get currentDetail => _currentDetail;
  VideoBean? get currentVideo => _currentVideo;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasReachedMax => _hasReachedMax;

  Future<void> loadHomeData() async {
    _setLoading(true);
    _error = null;

    try {
      _homeSections = await _source.getHomeData();
      notifyListeners();
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadWeekData() async {
    _setLoading(true);
    _error = null;

    try {
      _weekData = await _source.getWeekData();
      notifyListeners();
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchAnime(String query, int page) async {
    _setLoading(true);
    _error = null;
    _hasReachedMax = false;

    try {
      _searchResults = await _source.getSearchData(query, page);
      // 如果返回的结果少于预期，说明已经到达最后一页
      if (_searchResults.isEmpty) {
        _hasReachedMax = true;
      }
      notifyListeners();
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMoreSearch(String query, int page) async {
    if (_isLoading || _hasReachedMax) return;

    _setLoading(true);

    try {
      final newResults = await _source.getSearchData(query, page);
      if (newResults.isEmpty) {
        _hasReachedMax = true;
      } else {
        _searchResults.addAll(newResults);
      }
      notifyListeners();
    } catch (e) {
      // 加载更多时出错，不清空已有结果，只显示错误信息
      _error = '加载更多失败：${_parseError(e)}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAnimeDetail(String detailUrl) async {
    _setLoading(true);
    _error = null;

    try {
      _currentDetail = await _source.getAnimeDetail(detailUrl);
      notifyListeners();
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadVideoData(String episodeUrl) async {
    _setLoading(true);
    _error = null;

    try {
      _currentVideo = await _source.getVideoData(episodeUrl);
      notifyListeners();
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void clearSearchResults() {
    _searchResults = [];
    _hasReachedMax = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _parseError(dynamic error) {
    final errorStr = error.toString();
    if (errorStr.contains('Failed host lookup') ||
        errorStr.contains('SocketException') ||
        errorStr.contains('NetworkException')) {
      return '网络连接失败，请检查网络设置';
    } else if (errorStr.contains('TimeoutException') ||
               errorStr.contains('timed out')) {
      return '请求超时，请稍后重试';
    } else if (errorStr.contains('404')) {
      return '未找到相关内容';
    } else if (errorStr.contains('500') || errorStr.contains('502')) {
      return '服务器错误，请稍后重试';
    } else {
      return '搜索失败，请重试';
    }
  }
}
