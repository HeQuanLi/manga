import 'package:http/http.dart' as http;

class DownloadManager {
  static Future<String> getHtml(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to load HTML: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to download HTML: $e');
    }
  }
}
