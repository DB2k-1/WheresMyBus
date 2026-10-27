import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppRatingService {
  static const String _launchCountKey = 'app_launch_count';
  static const String _hasRatedKey = 'has_rated_app';
  static const String _hasDeclinedKey = 'has_declined_rating';
  static const String _ratingValueKey = 'user_rating_value';
  static const String _lastRatedVersionKey = 'last_rated_version';
  static const String _lowRatingLaunchCountKey = 'low_rating_launch_count';
  // Launch on which the prompt was last answered with "Not Now", so it isn't
  // offered again until the next 5th launch.
  static const String _lastDeclinedLaunchKey = 'last_declined_launch';
  static const int _launchThreshold = 5; // Show rating popup every 5th launch
  static const int _lowRatingThreshold = 10; // Ask again in 10 uses for low ratings

  static Future<void> initialize() async {
    await _incrementLaunchCount();
  }

  static Future<void> _incrementLaunchCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_launchCountKey) ?? 0;
    await prefs.setInt(_launchCountKey, currentCount + 1);
    
    // Also increment low rating launch count if user gave low rating
    final hasRated = prefs.getBool(_hasRatedKey) ?? false;
    final ratingValue = prefs.getInt(_ratingValueKey) ?? 0;
    final currentVersion = await _getCurrentVersion();
    final lastRatedVersion = prefs.getString(_lastRatedVersionKey);
    
    if (hasRated && ratingValue < 4 && lastRatedVersion == currentVersion) {
      final lowRatingCount = prefs.getInt(_lowRatingLaunchCountKey) ?? 0;
      await prefs.setInt(_lowRatingLaunchCountKey, lowRatingCount + 1);
    }
  }

  static Future<int> getLaunchCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_launchCountKey) ?? 0;
  }

  static Future<String> _getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      // Fallback for testing or when PackageInfo is not available
      return '1.0.0';
    }
  }

  /// Every 5th launch until the user rates this version. A rating of 4+
  /// stops the prompt for this version; a lower rating waits 10 launches
  /// before asking again. "Not Now" just skips to the next 5th launch.
  static Future<bool> shouldShowRatingDialog() async {
    final prefs = await SharedPreferences.getInstance();
    final launchCount = await getLaunchCount();
    final currentVersion = await _getCurrentVersion();
    final lastRatedVersion = prefs.getString(_lastRatedVersionKey);

    if (prefs.getBool(_hasRatedKey) == true &&
        lastRatedVersion == currentVersion) {
      final ratingValue = prefs.getInt(_ratingValueKey) ?? 0;
      if (ratingValue >= 4) {
        return false; // Don't ask again for this version
      }
      // Low rating: ask again after 10 more launches
      final lowRatingLaunchCount = prefs.getInt(_lowRatingLaunchCountKey) ?? 0;
      return lowRatingLaunchCount >= _lowRatingThreshold;
    }

    // Not rated (or rated an older version): every 5th launch, but not
    // again on the launch the user just said "Not Now" on.
    if (prefs.getInt(_lastDeclinedLaunchKey) == launchCount) return false;
    return launchCount > 0 && launchCount % _launchThreshold == 0;
  }

  static Future<void> markAsRated({int? ratingValue}) async {
    final prefs = await SharedPreferences.getInstance();
    final currentVersion = await _getCurrentVersion();
    
    await prefs.setBool(_hasRatedKey, true);
    await prefs.setString(_lastRatedVersionKey, currentVersion);
    
    if (ratingValue != null) {
      await prefs.setInt(_ratingValueKey, ratingValue);
      
      // If low rating, reset the low rating launch count
      if (ratingValue < 4) {
        await prefs.setInt(_lowRatingLaunchCountKey, 0);
      }
    }
  }

  static Future<void> markAsDeclined() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasDeclinedKey, true);
    await prefs.setInt(_lastDeclinedLaunchKey, await getLaunchCount());
    // After a low rating, "Not Now" restarts the 10-launch wait rather than
    // leaving the prompt due on every launch.
    await prefs.setInt(_lowRatingLaunchCountKey, 0);
  }

  static Future<void> showRatingDialog(BuildContext context) async {
    if (!context.mounted) return;

    // Always use custom dialog to capture rating value
    await _showCustomRatingDialog(context);
  }

  static Future<void> _showCustomRatingDialog(BuildContext context) async {
    if (!context.mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _RatingDialog();
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
    await prefs.remove(_ratingValueKey);
    await prefs.remove(_lastRatedVersionKey);
    await prefs.remove(_lowRatingLaunchCountKey);
    await prefs.remove(_lastDeclinedLaunchKey);
  }
}

class _RatingDialog extends StatefulWidget {
  @override
  _RatingDialogState createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _selectedRating = 0;

  @override
  Widget build(BuildContext context) {
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
          // Wraps rather than overflowing on narrow screens.
          const Expanded(
            child: Text(
              'Rate Where\'s My Bus?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'How would you rate your experience?',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRating = index + 1;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < _selectedRating ? Icons.star : Icons.star_border,
                    color: Colors.amber[600],
                    size: 32,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await AppRatingService.markAsDeclined();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: const Text(
            'Not Now',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        if (_selectedRating > 0) ...[
          TextButton(
            onPressed: () async {
              await AppRatingService.markAsRated(ratingValue: _selectedRating);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
              // Launch app store for rating
              await AppRatingService._launchAppStore();
            },
            child: Text(
              _selectedRating >= 4 ? 'Rate on Store' : 'Submit Rating',
              style: TextStyle(
                color: _selectedRating >= 4 ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
