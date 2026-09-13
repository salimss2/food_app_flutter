import 'dart:io' show Platform;
import '../api/endpoints.dart';

class ImageUrlHelper {
  static String normalize(String? path) {
    if (path == null || path.trim().isEmpty) {
      return 'https://via.placeholder.com/300?text=No+Image'; 
    }

    String url = path.trim();

    if (url.startsWith('/storage') || url.startsWith('storage/') || 
        url.startsWith('/uploads') || url.startsWith('uploads/')) {
      final String baseDomain = Endpoints.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
      if (!url.startsWith('/')) url = '/$url';
      url = '$baseDomain$url';
    }

    try {
      if (Platform.isAndroid) {
        if (url.contains('localhost')) {
          url = url.replaceAll('localhost', '10.0.2.2');
        } else if (url.contains('127.0.0.1')) {
          url = url.replaceAll('127.0.0.1', '10.0.2.2');
        }
      }
    } catch (_) {
    }

    url = url.replaceAll(RegExp(r'(?<!:)/{2,}'), '/');

    return url;
  }
}
