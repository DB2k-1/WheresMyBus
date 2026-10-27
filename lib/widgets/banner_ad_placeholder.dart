import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wheres_my_bus/utils/constants.dart';
import 'package:wheres_my_bus/utils/screenshot_mode.dart';

/// Banner ad along the bottom of a screen or pane.
///
/// Uses the 320x100 banner where the window is tall enough, otherwise an
/// anchored adaptive banner sized to the available width. When the width or
/// height changes (rotation, opening or folding a phone, moving into a pane)
/// a new ad is requested; the current one stays on screen until it arrives.
class BannerAdPlaceholder extends StatefulWidget {
  /// False where vertical space is tight (e.g. the bottom half of a
  /// half-folded phone), so the short adaptive banner is always used.
  final bool allowLarge;

  const BannerAdPlaceholder({super.key, this.allowLarge = true});

  @override
  State<BannerAdPlaceholder> createState() => _BannerAdPlaceholderState();
}

typedef _Slot = ({int width, bool large});

class _BannerAdPlaceholderState extends State<BannerAdPlaceholder> {
  // Below this window height the 320x100 banner takes too much room from the
  // stop list (landscape, short displays).
  static const double _largeBannerMinHeight = 600;

  BannerAd? _bannerAd;
  AdSize? _bannerAdSize;
  // The slot most recently requested; a load for any other slot is dropped.
  _Slot? _requestedSlot;
  // Expected height of the requested slot, so the space doesn't jump while
  // the ad loads.
  double? _requestedHeight;
  Timer? _reloadTimer;

  void _scheduleLoad(_Slot slot) {
    if (slot.width <= 0 || slot == _requestedSlot) return;
    // The large banner doesn't depend on width, so a width change alone
    // doesn't need a new one, unless the shown ad no longer fits.
    final bool stillFits =
        _bannerAdSize == null || _bannerAdSize!.width <= slot.width;
    if (slot.large && _requestedSlot?.large == true && stillFits) return;
    final bool firstLoad = _requestedSlot == null;
    _requestedSlot = slot;
    _requestedHeight = slot.large ? AdSize.largeBanner.height.toDouble() : null;
    _reloadTimer?.cancel();
    // Debounced so a resize only reloads once.
    _reloadTimer = Timer(
      firstLoad ? Duration.zero : const Duration(milliseconds: 500),
      () => _loadBannerAd(slot),
    );
  }

  Future<void> _loadBannerAd(_Slot slot) async {
    final AdSize size = slot.large
        ? AdSize.largeBanner
        // ignore: deprecated_member_use
        : await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
                slot.width) ??
            AdSize.banner;
    if (!mounted || slot != _requestedSlot) return;
    if (_requestedHeight != size.height.toDouble()) {
      setState(() => _requestedHeight = size.height.toDouble());
    }

    BannerAd(
      adUnitId: _getAdUnitId(large: slot.large),
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || slot != _requestedSlot) {
            ad.dispose();
            return;
          }
          final BannerAd? previous = _bannerAd;
          setState(() {
            _bannerAd = ad as BannerAd;
            _bannerAdSize = size;
          });
          // Dispose after the frame that removes its AdWidget from the tree.
          WidgetsBinding.instance
              .addPostFrameCallback((_) => previous?.dispose());
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            debugPrint('Banner ad failed to load: ${error.code} ${error.message}');
          }
          // Banners refresh themselves, and a failed refresh is reported
          // against the ad already on screen. Its AdWidget is still mounted
          // and showing the last creative, so keep it; disposing it here
          // takes the screen down.
          if (ad == _bannerAd) return;
          ad.dispose();
        },
      ),
    ).load();
  }

  String _getAdUnitId({required bool large}) {
    final bool iOS = defaultTargetPlatform == TargetPlatform.iOS;
    if (kReleaseMode) {
      return iOS
          ? 'ca-app-pub-9701853219520589/6701573822' // iOS production banner
          : 'ca-app-pub-9701853219520589/8944593785'; // Android production banner
    }
    // Google's test units: the fixed-size one for the 320x100 banner, the
    // adaptive one otherwise. The fixed-size unit only serves fixed-size
    // creatives, which leave black bars in an adaptive slot.
    if (large) {
      return iOS
          ? 'ca-app-pub-3940256099942544/2934735716'
          : 'ca-app-pub-3940256099942544/6300978111';
    }
    return iOS
        ? 'ca-app-pub-3940256099942544/2435281174'
        : 'ca-app-pub-3940256099942544/9214589741';
  }

  @override
  void dispose() {
    _reloadTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No ad slot in App Store screenshots.
    if (screenshotMode) return const SizedBox.shrink();
    final double windowHeight = MediaQuery.sizeOf(context).height;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        border: Border(
          top: BorderSide(
            color: AppColors.darkGrey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      // Keep the ad clear of the home indicator / gesture bar and any side
      // insets in landscape.
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final int width = constraints.maxWidth.truncate();
            final bool large = widget.allowLarge &&
                width >= AdSize.largeBanner.width &&
                windowHeight >= _largeBannerMinHeight;
            _scheduleLoad((width: width, large: large));

            final BannerAd? ad = _bannerAd;
            final AdSize? adSize = _bannerAdSize;
            final double height = _requestedHeight ??
                (adSize?.height ?? AdSize.banner.height).toDouble();
            // The ad on screen may have been loaded for a bigger slot; it's
            // only shown while it still fits.
            final bool showAd = ad != null &&
                adSize != null &&
                adSize.width <= width &&
                adSize.height <= height;

            return SizedBox(
              height: height,
              child: showAd
                  ? Center(
                      child: SizedBox(
                        width: adSize.width.toDouble(),
                        height: adSize.height.toDouble(),
                        child: AdWidget(ad: ad),
                      ),
                    )
                  : _buildPlaceholder(context),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.ads_click,
            color: AppColors.darkGrey.withValues(alpha: 0.5),
            size: 20,
          ),
          Text(
            ' Banner Advertisement',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkGrey.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
