import 'package:flutter/foundation.dart';

/// Settings to change before publishing.
///
/// The ad unit IDs below are Google's public test IDs, which always show test
/// ads. Replace them with your own from the AdMob dashboard before release
/// (and the app IDs in AndroidManifest.xml and Info.plist).
class AppConfig {
  /// Product ID of the one-time "unlock everything" purchase. Create a
  /// one-time product with this exact ID in Google Play Console.
  static const unlockProductId = 'unlock_all';

  static const privacyPolicyUrl = 'https://example.com/privacy';

  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get supportsStore => isAndroid || isIOS;

  static String get bannerAdUnit => isIOS
      ? 'ca-app-pub-3940256099942544/2934735716'
      : 'ca-app-pub-3940256099942544/6300978111';

  static String get interstitialAdUnit => isIOS
      ? 'ca-app-pub-3940256099942544/4411468910'
      : 'ca-app-pub-3940256099942544/1033173712';

  /// Show a full-screen ad at most this often, and only between quizzes.
  static const interstitialGap = Duration(minutes: 3);
}
