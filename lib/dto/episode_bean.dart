class EpisodeBean {
  final String name;
  final String url;

  EpisodeBean(this.name, this.url);

  @override
  String toString() {
    return 'EpisodeBean{name: $name, url: $url}';
  }
}
