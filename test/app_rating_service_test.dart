import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheres_my_bus/services/app_rating_service.dart';

void main() {
  group('AppRatingService Tests', () {
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

    test('should not show rating dialog after user rated', () async {
      // Reset preferences
      await AppRatingService.resetRatingPreferences();
      
      // Simulate 5 launches to trigger rating dialog
      for (int i = 0; i < 5; i++) {
        await AppRatingService.initialize();
      }
      
      // Should show rating dialog
      bool shouldShow = await AppRatingService.shouldShowRatingDialog();
      expect(shouldShow, equals(true));
      
      // Mark as rated
      await AppRatingService.markAsRated();
      
      // Should not show rating dialog anymore
      shouldShow = await AppRatingService.shouldShowRatingDialog();
      expect(shouldShow, equals(false));
    });

    test('should not show rating dialog after user declined', () async {
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
      
      // Should not show rating dialog anymore
      shouldShow = await AppRatingService.shouldShowRatingDialog();
      expect(shouldShow, equals(false));
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
