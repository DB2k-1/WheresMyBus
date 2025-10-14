import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheres_my_bus/services/app_rating_service.dart';

void main() {
  group('AppRatingService Tests', () {
    setUpAll(() {
      // Initialize Flutter binding for tests
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      // Mock SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
    });

    test('should increment launch count correctly', () async {
      // Initialize the service
      await AppRatingService.initialize();
      
      // Check initial count
      int count = await AppRatingService.getLaunchCount();
      expect(count, equals(1));
      
      // Initialize again to increment
      await AppRatingService.initialize();
      count = await AppRatingService.getLaunchCount();
      expect(count, equals(2));
    });

    test('should show rating dialog on 5th launch', () async {
      // Reset preferences
      await AppRatingService.resetRatingPreferences();
      
      // Simulate 4 launches
      for (int i = 0; i < 4; i++) {
        await AppRatingService.initialize();
      }
      
      // Should not show rating dialog yet
      bool shouldShow = await AppRatingService.shouldShowRatingDialog();
      expect(shouldShow, equals(false));
      
      // 5th launch - should show rating dialog
      await AppRatingService.initialize();
      shouldShow = await AppRatingService.shouldShowRatingDialog();
      expect(shouldShow, equals(true));
    });

    test('should not show rating dialog after user rated 4+ stars', () async {
      // Reset preferences
      await AppRatingService.resetRatingPreferences();
      
      // Simulate 5 launches to trigger rating dialog
      for (int i = 0; i < 5; i++) {
        await AppRatingService.initialize();
      }
      
      // Should show rating dialog
      bool shouldShow = await AppRatingService.shouldShowRatingDialog();
      expect(shouldShow, equals(true));
      
      // Mark as rated with 4 stars
      await AppRatingService.markAsRated(ratingValue: 4);
      
      // Should not show rating dialog anymore
      shouldShow = await AppRatingService.shouldShowRatingDialog();
      expect(shouldShow, equals(false));
    });

    test('should show rating dialog again after 10 uses for low rating', () async {
      // Reset preferences
      await AppRatingService.resetRatingPreferences();
      
      // Simulate 5 launches to trigger rating dialog
      for (int i = 0; i < 5; i++) {
        await AppRatingService.initialize();
      }
      
      // Mark as rated with 3 stars (low rating)
      await AppRatingService.markAsRated(ratingValue: 3);
      
      // Should not show immediately
      bool shouldShow = await AppRatingService.shouldShowRatingDialog();
      expect(shouldShow, equals(false));
      
      // Simulate 10 more launches
      for (int i = 0; i < 10; i++) {
        await AppRatingService.initialize();
      }
      
      // Should show rating dialog again
      shouldShow = await AppRatingService.shouldShowRatingDialog();
      expect(shouldShow, equals(true));
    });

    test('should continue showing rating dialog after user declined (every 5 uses)', () async {
      // Reset preferences
      await AppRatingService.resetRatingPreferences();
      
      // Simulate 5 launches to trigger rating dialog
      for (int i = 0; i < 5; i++) {
        await AppRatingService.initialize();
      }
      
      // Should show rating dialog
      bool shouldShow = await AppRatingService.shouldShowRatingDialog();
      expect(shouldShow, equals(true));
      
      // Mark as declined
      await AppRatingService.markAsDeclined();
      
      // Should not show immediately after declining (but will show on next 5th launch)
      shouldShow = await AppRatingService.shouldShowRatingDialog();
      expect(shouldShow, equals(false));
      
      // Add 4 more launches (9 total)
      for (int i = 0; i < 4; i++) {
        await AppRatingService.initialize();
      }
      
      // Should still not show
      shouldShow = await AppRatingService.shouldShowRatingDialog();
      expect(shouldShow, equals(false));
      
      // Add 1 more launch (10 total) - this should trigger the dialog again
      await AppRatingService.initialize();
      
      shouldShow = await AppRatingService.shouldShowRatingDialog();
      expect(shouldShow, equals(true));
    });

    test('should reset preferences correctly', () async {
      // Initialize and mark as rated
      await AppRatingService.initialize();
      await AppRatingService.markAsRated();
      
      // Should not show rating dialog
      bool shouldShow = await AppRatingService.shouldShowRatingDialog();
      expect(shouldShow, equals(false));
      
      // Reset preferences
      await AppRatingService.resetRatingPreferences();
      
      // Should show rating dialog again (after 5 launches)
      for (int i = 0; i < 5; i++) {
        await AppRatingService.initialize();
      }
      
      shouldShow = await AppRatingService.shouldShowRatingDialog();
      expect(shouldShow, equals(true));
    });
  });
}
