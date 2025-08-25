import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wheres_my_bus/utils/constants.dart';

class LogoPlaceholder extends StatelessWidget {
  const LogoPlaceholder({super.key});

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
                    Image.asset(
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
