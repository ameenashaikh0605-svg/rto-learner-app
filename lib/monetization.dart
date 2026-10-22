import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'config.dart';
import 'progress.dart';

/// Ads: a banner on some screens and an occasional full-screen ad between
/// quizzes. Turned off once the user has unlocked the app, and on platforms
/// without AdMob (the web preview).
class Ads {
  Ads(this._progress);

  final Progress _progress;
  bool _ready = false;
  InterstitialAd? _interstitial;
  DateTime _lastShown = DateTime.fromMillisecondsSinceEpoch(0);

  bool get enabled => _ready && !_progress.unlocked;

  Future<void> init() async {
    if (!AppConfig.supportsStore) return;
    // Ask for ad consent where the law requires it (EU/UK), then start AdMob.
    final consentDone = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired((_) => consentDone.complete()),
      (_) => consentDone.complete(),
    );
    await consentDone.future;
    if (!await ConsentInformation.instance.canRequestAds()) return;
    await MobileAds.instance.initialize();
    _ready = true;
    _loadInterstitial();
  }

  void _loadInterstitial() {
    if (!enabled) return;
    InterstitialAd.load(
      adUnitId: AppConfig.interstitialAdUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Call when a quiz ends. Shows a full-screen ad if one is loaded and the
  /// last one was a while ago.
  void maybeShowInterstitial() {
    final ad = _interstitial;
    if (!enabled || ad == null) return;
    if (DateTime.now().difference(_lastShown) < AppConfig.interstitialGap) return;
    _lastShown = DateTime.now();
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
  }
}

/// A banner ad that hides itself when ads are off or none loads.
class BannerSlot extends StatefulWidget {
  const BannerSlot({super.key, required this.ads});

  final Ads ads;

  @override
  State<BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<BannerSlot> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (!widget.ads.enabled) return;
    _banner = BannerAd(
      size: AdSize.banner,
      adUnitId: AppConfig.bannerAdUnit,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _loaded = true),
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (!_loaded || banner == null || !widget.ads.enabled) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: banner.size.width.toDouble(),
        height: banner.size.height.toDouble(),
        child: AdWidget(ad: banner),
      ),
    );
  }
}

/// The one-time "unlock everything" purchase.
class Store extends ChangeNotifier {
  Store(this._progress);

  final Progress _progress;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  ProductDetails? product;
  bool available = false;
  bool busy = false;
  String? error;

  Future<void> init() async {
    if (!AppConfig.supportsStore) return;
    final iap = InAppPurchase.instance;
    _sub = iap.purchaseStream.listen(_onPurchases, onError: (Object e) {
      error = 'Purchase failed. Please try again.';
      busy = false;
      notifyListeners();
    });
    available = await iap.isAvailable();
    if (available) {
      final res = await iap.queryProductDetails({AppConfig.unlockProductId});
      if (res.productDetails.isNotEmpty) product = res.productDetails.first;
      // Picks up a purchase made earlier on this account, e.g. after a reinstall.
      await iap.restorePurchases();
    }
    notifyListeners();
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != AppConfig.unlockProductId) continue;
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _progress.setUnlocked(true);
          error = null;
          busy = false;
        case PurchaseStatus.error:
          error = 'Purchase failed. Please try again.';
          busy = false;
        case PurchaseStatus.canceled:
          busy = false;
        case PurchaseStatus.pending:
          busy = true;
      }
      if (p.pendingCompletePurchase) await InAppPurchase.instance.completePurchase(p);
    }
    notifyListeners();
  }

  Future<void> buy() async {
    final pd = product;
    if (pd == null) return;
    busy = true;
    error = null;
    notifyListeners();
    final started = await InAppPurchase.instance
        .buyNonConsumable(purchaseParam: PurchaseParam(productDetails: pd));
    if (!started) {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> restore() => InAppPurchase.instance.restorePurchases();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
