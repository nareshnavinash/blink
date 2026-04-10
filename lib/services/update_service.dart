import 'dart:convert';
import 'dart:io';
import 'package:blink/core/app_constants.dart';

class AppUpdate {
  final String version;
  final String downloadUrl;
  final String? changelog;
  final bool isRequired;

  const AppUpdate({
    required this.version,
    required this.downloadUrl,
    this.changelog,
    this.isRequired = false,
  });

  factory AppUpdate.fromJson(Map<String, dynamic> json) => AppUpdate(
    version: json['version'] as String,
    downloadUrl: json['downloadUrl'] as String,
    changelog: json['changelog'] as String?,
    isRequired: json['isRequired'] as bool? ?? false,
  );
}

class UpdateService {
  static const _checkUrl = 'https://api.github.com/repos/blinkapp/blink/releases/latest';

  Future<AppUpdate?> checkForUpdate() async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(_checkUrl));
      request.headers.set('Accept', 'application/vnd.github.v3+json');
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      client.close();

      if (response.statusCode != 200) return null;

      final data = jsonDecode(body) as Map<String, dynamic>;
      final latestVersion = (data['tag_name'] as String).replaceFirst('v', '');

      if (_isNewer(latestVersion, AppConstants.appVersion)) {
        // Find the right asset for this platform
        final assets = data['assets'] as List<dynamic>? ?? [];
        final downloadUrl = _findAssetUrl(assets);

        return AppUpdate(
          version: latestVersion,
          downloadUrl: downloadUrl ?? '',
          changelog: data['body'] as String?,
        );
      }
    } catch (_) {
      // Network error or parse error — silently fail
    }
    return null;
  }

  String? _findAssetUrl(List<dynamic> assets) {
    final platformKey = Platform.isMacOS
        ? 'macos'
        : Platform.isWindows
            ? 'windows'
            : Platform.isLinux
                ? 'linux'
                : null;

    if (platformKey == null) return null;

    for (final asset in assets) {
      final name = (asset['name'] as String).toLowerCase();
      if (name.contains(platformKey)) {
        return asset['browser_download_url'] as String?;
      }
    }
    return null;
  }

  bool _isNewer(String remote, String local) {
    final remoteParts = remote.split('.').map(int.tryParse).toList();
    final localParts = local.split('.').map(int.tryParse).toList();

    for (var i = 0; i < 3; i++) {
      final r = i < remoteParts.length ? (remoteParts[i] ?? 0) : 0;
      final l = i < localParts.length ? (localParts[i] ?? 0) : 0;
      if (r > l) return true;
      if (r < l) return false;
    }
    return false;
  }
}
