class HistoryBean {
  final String animeTitle;
  final String animeImg;
  final String animeUrl;
  final String episodeName;
  final String episodeUrl;
  final DateTime watchedAt;

  HistoryBean({
    required this.animeTitle,
    required this.animeImg,
    required this.animeUrl,
    required this.episodeName,
    required this.episodeUrl,
    required this.watchedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'animeTitle': animeTitle,
      'animeImg': animeImg,
      'animeUrl': animeUrl,
      'episodeName': episodeName,
      'episodeUrl': episodeUrl,
      'watchedAt': watchedAt.toIso8601String(),
    };
  }

  factory HistoryBean.fromJson(Map<String, dynamic> json) {
    return HistoryBean(
      animeTitle: json['animeTitle'] ?? '',
      animeImg: json['animeImg'] ?? '',
      animeUrl: json['animeUrl'] ?? '',
      episodeName: json['episodeName'] ?? '',
      episodeUrl: json['episodeUrl'] ?? '',
      watchedAt: DateTime.parse(json['watchedAt']),
    );
  }

  @override
  String toString() {
    return 'HistoryBean{animeTitle: $animeTitle, episodeName: $episodeName, watchedAt: $watchedAt}';
  }
}
