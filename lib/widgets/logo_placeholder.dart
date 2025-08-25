import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wheres_my_bus/utils/constants.dart';
import 'package:wheres_my_bus/services/data_update_service.dart';
import 'package:wheres_my_bus/widgets/data_status_banner.dart';

class LogoPlaceholder extends StatefulWidget {
  const LogoPlaceholder({super.key});

  @override
  State<LogoPlaceholder> createState() => _LogoPlaceholderState();
}

class _LogoPlaceholderState extends State<LogoPlaceholder> {
  int _tapCount = 0;
  DateTime? _lastTapTime;
  static const Duration _tapTimeout = Duration(seconds: 3);

  /// Get platform-specific share icon
  IconData _getShareIcon() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return Icons.ios_share; // iOS share icon
    } else {
      return Icons.share; // Android/other platforms share icon
    }
  }

  /// Handle app sharing with native share functionality
  Future<void> _shareApp() async {
    String appStoreUrl = 'https://apps.apple.com/us/app/wheres-my-bus/id6751463363';
    
    String shareMessage;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      shareMessage = 'Get Where\'s My Bus? from the Apple App Store: $appStoreUrl';
    } else {
      shareMessage = 'Get Where\'s My Bus? from the Google Play Store: $appStoreUrl';
    }
    
    // Use native share functionality
    await Share.share(
      shareMessage,
      subject: 'Check out Where\'s My Bus!',
    );
  }

  /// Handle logo taps for manual data refresh
  void _handleLogoTap() {
    final now = DateTime.now();
    
    // Reset tap count if too much time has passed
    if (_lastTapTime != null && now.difference(_lastTapTime!) > _tapTimeout) {
      _tapCount = 0;
    }
    
    _tapCount++;
    _lastTapTime = now;
    
    // Check if we've reached 5 taps
    if (_tapCount >= 5) {
      _tapCount = 0; // Reset for next time
      _forceDataRefresh();
    }
  }

  /// Force a manual data refresh
  Future<void> _forceDataRefresh() async {
    try {
      // Show manual update progress in banner
      DataStatusBanner.showManualUpdate();
      
      // Force a data update check
      await DataUpdateService.forceUpdate();
      
      // Refresh the data status banner to show updated status
      DataStatusBanner.refreshAll();
      
      print('DataUpdateService: Manual update completed successfully');
    } catch (e) {
      print('DataUpdateService: Manual update failed: $e');
      // Refresh banner to show current status (which might be outdated)
      DataStatusBanner.refreshAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: AppSizes.logoHeight + 60, // Extend height to include top area
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.londonRed,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
              child: Padding(
          padding: const EdgeInsets.only(top: 60), // Push content down to avoid dynamic island
          child: Row(
            children: [
              // Logo and app info (left side)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _handleLogoTap,
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to bus icon if logo fails to load
                          return Icon(
                            Icons.directions_bus,
                            color: Colors.white,
                            size: 50,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingMedium),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Where\'s My Bus?',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'London Bus Tracker',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Share button (right side)
              GestureDetector(
                onTap: _shareApp,
                child: Icon(
                  _getShareIcon(),
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
    );
  }
}
