import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wheres_my_bus/utils/constants.dart';
import 'package:wheres_my_bus/services/data_update_service.dart';
import 'package:wheres_my_bus/widgets/data_status_banner.dart';

class LogoPlaceholder extends StatefulWidget {
  /// Forces the short header (e.g. the bottom half of a half-folded phone).
  final bool compact;

  const LogoPlaceholder({super.key, this.compact = false});

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
    String shareMessage;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      String appStoreUrl = 'https://apps.apple.com/us/app/wheres-my-bus/id6751463363';
      shareMessage = 'Get Where\'s My Bus? from the Apple App Store: $appStoreUrl';
    } else {
      String playStoreUrl = 'https://play.google.com/store/apps/details?id=co.uk.vidbeamish.wheresmybus';
      shareMessage = 'Get Where\'s My Bus? from the Google Play Store: $playStoreUrl';
    }
    
    // Use native share functionality
    await SharePlus.instance.share(
      ShareParams(
        text: shareMessage,
        subject: 'Check out Where\'s My Bus!',
      ),
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
    final EdgeInsets insets = MediaQuery.paddingOf(context);
    // Compact on short windows (landscape, the bottom half of a half-folded
    // phone) so the stop list keeps most of the height.
    final bool compact =
        widget.compact || MediaQuery.sizeOf(context).height < 500;
    final double logoSize = compact ? 36 : 50;
    final double padding = compact ? AppSizes.paddingSmall : AppSizes.paddingMedium;

    return Container(
      width: double.infinity,
      // Clear of the status bar / Dynamic Island and any side insets.
      padding: EdgeInsets.fromLTRB(
        AppSizes.paddingMedium + insets.left,
        insets.top + padding,
        AppSizes.paddingMedium + insets.right,
        padding,
      ),
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
      child: SizedBox(
        height: compact ? 44 : 68,
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
                      height: logoSize,
                      width: logoSize,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to bus icon if logo fails to load
                        return Icon(
                          Icons.directions_bus,
                          color: Colors.white,
                          size: logoSize,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Where\'s My Bus?',
                            style: (compact
                                    ? Theme.of(context).textTheme.titleLarge
                                    : Theme.of(context).textTheme.headlineMedium)
                                ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!compact)
                            Text(
                              'London Bus Tracker',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                            ),
                        ],
                      ),
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
