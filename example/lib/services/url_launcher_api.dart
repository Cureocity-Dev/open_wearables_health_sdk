import 'package:url_launcher/url_launcher.dart';

/// Thin wrapper around `url_launcher` for test injection.
class UrlLauncherApi {
  const UrlLauncherApi();

  Future<bool> launch(String url) async {
    final uri = Uri.parse(url);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
