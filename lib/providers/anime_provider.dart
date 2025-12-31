import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../dto/anime_bean.dart';
import '../dto/anime_detail_bean.dart';
import '../dto/home_bean.dart';
import '../dto/video_bean.dart';
import '../dto/history_bean.dart';
import '../parse/mxdm_source.dart';

class AnimeProvider with ChangeNotifier {
  final MxdmSource _source = MxdmSource();

  List<HomeBean> _homeSections = [];
  Map<int, List<AnimeBean>> _weekData = {};
  List<AnimeBean> _searchResults = [];
  AnimeDetailBean? _currentDetail;
  VideoBean? _currentVideo;
  List<HistoryBean> _playHistory = [];

  bool _isLoading = false;
  String? _error;
  bool _hasReachedMax = false;

  static const String _historyKey = 'play_history';
  static const int _maxHistoryItems = 100;

  List<HomeBean> get homeSections => _homeSections;
  Map<int, List<AnimeBean>> get weekData => _weekData;
  List<AnimeBean> get searchResults => _searchResults;
  AnimeDetailBean? get currentDetail => _currentDetail;
  VideoBean? get currentVideo => _currentVideo;
  List<HistoryBean> get playHistory => _playHistory;
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

  // 播放历史管理
  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);

      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        _playHistory = historyList
            .map((item) => HistoryBean.fromJson(item))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('加载历史记录失败: $e');
    }
  }

  Future<void> addToHistory({
    required String animeTitle,
    required String animeImg,
    required String animeUrl,
    required String episodeName,
    required String episodeUrl,
  }) async {
    try {
      // 移除相同集数的旧记录
      _playHistory.removeWhere((item) => item.episodeUrl == episodeUrl);

      // 添加新记录到列表开头
      final newHistory = HistoryBean(
        animeTitle: animeTitle,
        animeImg: animeImg,
        animeUrl: animeUrl,
        episodeName: episodeName,
        episodeUrl: episodeUrl,
        watchedAt: DateTime.now(),
      );

      _playHistory.insert(0, newHistory);

      // 限制历史记录数量
      if (_playHistory.length > _maxHistoryItems) {
        _playHistory = _playHistory.sublist(0, _maxHistoryItems);
      }

      // 保存到本地存储
      await _saveHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('添加历史记录失败: $e');
    }
  }

  Future<void> removeHistory(String episodeUrl) async {
    try {
      _playHistory.removeWhere((item) => item.episodeUrl == episodeUrl);
      await _saveHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('删除历史记录失败: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      _playHistory.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
      notifyListeners();
    } catch (e) {
      debugPrint('清空历史记录失败: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(
        _playHistory.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      debugPrint('保存历史记录失败: $e');
    }
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
