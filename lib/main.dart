import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wheres_my_bus/screens/home_screen.dart';
import 'package:wheres_my_bus/utils/constants.dart';
import 'package:wheres_my_bus/utils/screenshot_mode.dart';
import 'package:wheres_my_bus/services/bus_sequence_service.dart';
import 'package:wheres_my_bus/services/data_update_service.dart';
import 'package:wheres_my_bus/services/app_rating_service.dart';

void main() async {
  // Initialize Flutter bindings first
  WidgetsFlutterBinding.ensureInitialized();
  
  // Portrait and landscape, so the app fills foldables, iPhone Duo's inner
  // display and landscape phones. Upside-down portrait stays off.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Configure system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Initialize Google Mobile Ads
  await MobileAds.instance.initialize();
  
  // Initialize Data Update Service
  await DataUpdateService.initialize();
  
  // Initialize Bus Sequence Service
  await BusSequenceService.initialize();
  
  // Initialize App Rating Service
  await AppRatingService.initialize();
  
  runApp(const WheresMyBusApp());
}

class WheresMyBusApp extends StatefulWidget {
  const WheresMyBusApp({super.key});

  @override
  State<WheresMyBusApp> createState() => _WheresMyBusAppState();
}

class _WheresMyBusAppState extends State<WheresMyBusApp> {
  // The rating dialog needs a context below MaterialApp (for its Navigator
  // and localizations); this widget's own context sits above it.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Check for rating opportunity after a short delay to ensure UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForRatingOpportunity();
    });
  }

  Future<void> _checkForRatingOpportunity() async {
    if (screenshotMode) return;
    // Add a small delay to ensure the home screen is fully loaded
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted || !await AppRatingService.shouldShowRatingDialog()) return;
    final BuildContext? navigatorContext = _navigatorKey.currentContext;
    if (navigatorContext != null && navigatorContext.mounted) {
      await AppRatingService.showRatingDialog(navigatorContext);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'WheresMyBus',
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: false,
      showSemanticsDebugger: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.londonRed,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.londonRed,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.londonRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
