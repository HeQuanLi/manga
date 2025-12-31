class HistoryBean {
  final String animeTitle;
  final String animeImg;
  final String animeUrl;
  final String lastEpisodeName;
  final DateTime watchedAt;

  HistoryBean({
    required this.animeTitle,
    required this.animeImg,
    required this.animeUrl,
    required this.lastEpisodeName,
    required this.watchedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'animeTitle': animeTitle,
      'animeImg': animeImg,
      'animeUrl': animeUrl,
      'lastEpisodeName': lastEpisodeName,
      'watchedAt': watchedAt.toIso8601String(),
    };
  }

  factory HistoryBean.fromJson(Map<String, dynamic> json) {
    return HistoryBean(
      animeTitle: json['animeTitle'] ?? '',
      animeImg: json['animeImg'] ?? '',
      animeUrl: json['animeUrl'] ?? '',
      lastEpisodeName: json['lastEpisodeName'] ?? json['episodeName'] ?? '',
      watchedAt: DateTime.parse(json['watchedAt']),
    );
  }

  @override
  String toString() {
    return 'HistoryBean{animeTitle: $animeTitle, lastEpisodeName: $lastEpisodeName, watchedAt: $watchedAt}';
  }
}
