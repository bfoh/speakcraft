import 'package:flutter/foundation.dart';

Uri? speechApiEndpoint(String rawBaseUrl, String route) {
  final baseUrl = rawBaseUrl.trim();
  if (baseUrl.isEmpty) return null;
  final base = Uri.tryParse(baseUrl);
  if (base == null || !base.hasAuthority || base.userInfo.isNotEmpty) {
    return null;
  }
  final local = ['localhost', '127.0.0.1', '10.0.2.2'].contains(base.host);
  if (base.scheme != 'https' &&
      !(kDebugMode && base.scheme == 'http' && local)) {
    return null;
  }
  return base.replace(
    path: '${base.path.replaceAll(RegExp(r'/$'), '')}$route',
    query: null,
    fragment: null,
  );
}
