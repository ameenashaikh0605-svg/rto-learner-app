import 'package:flutter/foundation.dart';

/// Settings to change before publishing.
///
/// Builds show Google's public test ads unless built with
/// `--dart-define=REAL_ADS=true`, which only the Play Store bundle uses, so
/// test installs never show (or count clicks on) real ads.
class AppConfig {
  /// Product ID of the one-time "unlock everything" purchase. Create a
  /// one-time product with this exact ID in Google Play Console.
  static const unlockProductId = 'unlock_all';

  static const privacyPolicyUrl = 'https://docs.google.com/document/d/1DbF73SOiMluOq4sN4-xCIPmc0dS23r5D_GJDNlMZKz8/view';

  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get supportsStore => isAndroid || isIOS;

  static const realAds = bool.fromEnvironment('REAL_ADS');

  static String get bannerAdUnit => isIOS
      ? 'ca-app-pub-3940256099942544/2934735716'
      : realAds
          ? 'ca-app-pub-8194384991395432/3786706842'
          : 'ca-app-pub-3940256099942544/6300978111';

  static String get interstitialAdUnit => isIOS
      ? 'ca-app-pub-3940256099942544/4411468910'
      : realAds
          ? 'ca-app-pub-8194384991395432/6656412766'
          : 'ca-app-pub-3940256099942544/1033173712';

  /// Show a full-screen ad at most this often, and only between quizzes.
  static const interstitialGap = Duration(minutes: 3);
}
