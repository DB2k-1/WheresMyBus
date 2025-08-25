import 'package:flutter/material.dart';

class AppColors {
  // Logo-based Red color scheme (updated to match logo.png)
  static const Color londonRed = Color(0xFFDC352D); // Exact red from logo background
  static const Color londonRedLight = Color(0xFFE74C3C);
  static const Color londonRedDark = Color(0xFFB71C1C);
  static const Color cream = Color(0xFFFFF8DC);
  static const Color darkGrey = Color(0xFF2C3E50);
  static const Color lightGrey = Color(0xFFECF0F1);
}

class AppStrings {
  static const String appName = 'WheresMyBus';
  static const String appTagline = 'Find your nearest bus stops';
  static const String locationPermissionTitle = 'Location Permission Required';
  static const String locationPermissionMessage = 'This app needs location access to find nearby bus stops.';
  static const String addBusStops = 'Add Bus Stops';
  static const String myBusStops = 'My Bus Stops';
  static const String noBusStops = 'No bus stops added yet';
  static const String addBusStopsMessage = 'Tap the + button to find and add nearby bus stops';
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String retry = 'Retry';
  static const String noBuses = 'No buses coming soon';
  static const String refresh = 'Refresh';
}

class AppSizes {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadius = 8.0;
  static const double logoHeight = 100.0; // Increased height to accommodate top margin
  static const double bannerHeight = 90.0; // Increased height for proper ad banner size
}
