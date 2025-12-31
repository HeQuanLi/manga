class AnimeBean {
  final String title;
  final String img;
  final String url;
  final String episodeName;

  AnimeBean({
    required this.title,
    required this.img,
    required this.url,
    this.episodeName = '',
  });

  @override
  String toString() {
    return 'AnimeBean{title: $title, img: $img, url: $url, episodeName: $episodeName}';
  }
}
