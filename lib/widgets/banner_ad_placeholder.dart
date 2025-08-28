import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wheres_my_bus/utils/constants.dart';

class BannerAdPlaceholder extends StatefulWidget {
  const BannerAdPlaceholder({super.key});

  @override
  State<BannerAdPlaceholder> createState() => _BannerAdPlaceholderState();
}

class _BannerAdPlaceholderState extends State<BannerAdPlaceholder> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    final adUnitId = _getAdUnitId();
    print('BannerAd: Loading ad with unit ID: $adUnitId');
    print('BannerAd: Debug mode: $kDebugMode');
    print('BannerAd: Target platform: $defaultTargetPlatform');
    
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('BannerAd: Ad loaded successfully');
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('BannerAd: Ad failed to load: ${error.message}');
          print('BannerAd: Error code: ${error.code}');
          print('BannerAd: Error domain: ${error.domain}');
          ad.dispose();
        },
      ),
    );

    try {
      _bannerAd!.load();
      print('BannerAd: Ad load request sent');
    } catch (e) {
      print('BannerAd: Exception during ad load: $e');
    }
  }

  String _getAdUnitId() {
    // Use production ad unit IDs in release mode, test ad unit IDs in debug mode
    if (kDebugMode) {
      // Test ad unit IDs for development
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return 'ca-app-pub-3940256099942544/2934735716'; // iOS test ad unit ID
      } else {
        return 'ca-app-pub-3940256099942544/6300978111'; // Android test ad unit ID
      }
    } else {
      // Production ad unit IDs for release
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return 'ca-app-pub-9701853219520589/6701573822'; // iOS production banner ad unit ID
      } else {
        return 'ca-app-pub-9701853219520589/8944593785'; // Android production banner ad unit ID
      }
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null) {
      return Container(
        width: double.infinity,
        height: AppSizes.bannerHeight,
        child: AdWidget(ad: _bannerAd!),
      );
    }

    // Fallback placeholder while ad loads or if it fails
    return Container(
      width: double.infinity,
      height: AppSizes.bannerHeight,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        border: Border(
          top: BorderSide(
            color: AppColors.darkGrey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Center(
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
      ),
    );
  }
}
