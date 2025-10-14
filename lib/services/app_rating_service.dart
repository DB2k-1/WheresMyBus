import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRatingService {
  static const String _launchCountKey = 'app_launch_count';
  static const String _hasRatedKey = 'has_rated_app';
  static const String _hasDeclinedKey = 'has_declined_rating';
  static const int _launchThreshold = 5; // Show rating popup every 5th launch

  static Future<void> initialize() async {
    await _incrementLaunchCount();
  }

  static Future<void> _incrementLaunchCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_launchCountKey) ?? 0;
    await prefs.setInt(_launchCountKey, currentCount + 1);
  }

  static Future<int> getLaunchCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_launchCountKey) ?? 0;
  }

  static Future<bool> shouldShowRatingDialog() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Don't show if user has already rated or declined
    if (prefs.getBool(_hasRatedKey) == true || 
        prefs.getBool(_hasDeclinedKey) == true) {
      return false;
    }

    final launchCount = await getLaunchCount();
    return launchCount % _launchThreshold == 0 && launchCount > 0;
  }

  static Future<void> markAsRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasRatedKey, true);
  }

  static Future<void> markAsDeclined() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasDeclinedKey, true);
  }

  static Future<void> showRatingDialog(BuildContext context) async {
    if (!context.mounted) return;

    // Check if in-app review is available
    final InAppReview inAppReview = InAppReview.instance;
    final isAvailable = await inAppReview.isAvailable();

    if (isAvailable) {
      // Use native in-app review if available
      await inAppReview.requestReview();
      await markAsRated();
    } else {
      // Fallback to custom dialog if native review isn't available
      if (context.mounted) {
        await _showCustomRatingDialog(context);
      }
    }
  }

  static Future<void> _showCustomRatingDialog(BuildContext context) async {
    if (!context.mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber[600],
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text(
                'Rate Wheres My Bus',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you enjoying using Wheres My Bus? We\'d love to hear your feedback!',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await markAsDeclined();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                'Not Now',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                await markAsDeclined();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                // Launch app store for manual rating
                await _launchAppStore();
              },
              child: const Text(
                'Maybe Later',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await markAsRated();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                // Launch app store for rating
                await _launchAppStore();
              },
              icon: const Icon(Icons.star, color: Colors.white),
              label: const Text(
                'Rate App',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _launchAppStore() async {
    final InAppReview inAppReview = InAppReview.instance;
    await inAppReview.openStoreListing();
  }

  // Method to manually trigger rating (can be called from settings or other places)
  static Future<void> requestRatingManually(BuildContext context) async {
    if (!context.mounted) return;

    final InAppReview inAppReview = InAppReview.instance;
    final isAvailable = await inAppReview.isAvailable();

    if (isAvailable) {
      await inAppReview.requestReview();
    } else {
      await _launchAppStore();
    }
  }

  // Reset rating preferences (useful for testing)
  static Future<void> resetRatingPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasRatedKey);
    await prefs.remove(_hasDeclinedKey);
    await prefs.remove(_launchCountKey);
  }
}
