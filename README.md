# WheresMyBus

A London bus tracking Flutter app that helps users find nearby bus stops and view real-time bus arrivals.

## Features

- **GPS Location Access**: Automatically detects user's location and converts to UK grid coordinates
- **Nearby Bus Stops**: Finds the 6 closest bus stops to the user's location
- **Personal Bus Stop List**: Save and manage your favorite bus stops
- **Real-time Bus Arrivals**: View live bus arrival times using the TfL API
- **London Bus Theme**: Beautiful red color scheme matching London bus branding
- **Mobile-only**: Optimized for iOS and Android in portrait mode
- **Google AdMob**: Banner advertisements for monetization

## How It Works

1. **Location Permission**: App requests GPS access to find nearby bus stops
2. **Find Stops**: Tap the + button to discover bus stops within your area
3. **Add to Profile**: Select which bus stops you want to track
4. **View Arrivals**: Tap on a bus stop to see real-time bus arrival information
5. **Auto-refresh**: Bus arrival times update automatically every 30 seconds

## Technical Details

- **Flutter**: Cross-platform mobile development framework
- **TfL API**: Integration with Transport for London's real-time bus data
- **GPS Services**: Location detection and UK grid coordinate conversion
- **Local Storage**: Saves user's selected bus stops locally
- **Bus Stop Data**: Comprehensive London bus stop database (20,000+ stops)

## Getting Started

1. Clone the repository
2. Install Flutter dependencies: `flutter pub get`
3. Run the app: `flutter run`

## Dependencies

- `geolocator`: GPS location services
- `permission_handler`: Location permission management
- `http`: TfL API communication
- `shared_preferences`: Local data storage
- `flutter_staggered_grid_view`: UI layout components
- `google_mobile_ads`: Google AdMob integration

## API Reference

The app uses the TfL Countdown API:
- **Endpoint**: `https://countdown.api.tfl.gov.uk/interfaces/ura/instant_V1`
- **Format**: Real-time bus arrival data for specific stop codes
- **Rate Limiting**: Respects TfL API usage guidelines

## AdMob Configuration

The app integrates Google AdMob for banner advertisements:

**Production Ad Unit IDs:**
- **iOS App ID**: `ca-app-pub-9701853219520589~7607461387`
- **Android App ID**: `ca-app-pub-9701853219520589~1205704563`
- **iOS Banner Ad Unit**: `ca-app-pub-9701853219520589/6701573822`
- **Android Banner Ad Unit**: `ca-app-pub-9701853219520589/8944593785`

**Debug/Test Ad Unit IDs (Currently Active):**
- **iOS Test Ad Unit**: `ca-app-pub-3940256099942544/2934735716`
- **Android Test Ad Unit**: `ca-app-pub-3940256099942544/6300978111`

*Note: Test ads are currently configured for development. Switch to production ad unit IDs before release.*

## License

This project is for educational and personal use. Please respect TfL's API terms of service.
