import 'package:geolocator/geolocator.dart';
import 'package:wheres_my_bus/services/bus_stop_service.dart';

class LocationService {
  static bool _hasPermission = false;

  // Check and request location permission
  static Future<bool> requestLocationPermission() async {
    if (_hasPermission) return true;

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    // Check permission status
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    _hasPermission = true;
    return true;
  }

  // Get current location
  static Future<Position> getCurrentLocation() async {
    if (!_hasPermission) {
      await requestLocationPermission();
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      throw Exception('Failed to get location: $e');
    }
  }

  // Convert GPS coordinates to UK grid coordinates
  static Future<Map<String, double>> getUKGridCoordinates() async {
    final position = await getCurrentLocation();
    return BusStopService.gpsToUKGrid(
      position.latitude,
      position.longitude,
    );
  }

  // Get nearest bus stops to current location
  static Future<List<dynamic>> getNearestBusStops(int count) async {
    try {
      final gridCoords = await getUKGridCoordinates();
      final nearestStops = await BusStopService.findNearestBusStops(
        gridCoords['easting']!,
        gridCoords['northing']!,
        count,
      );
      return nearestStops;
    } catch (e) {
      throw Exception('Failed to get nearest bus stops: $e');
    }
  }

  // Check if location permission is granted
  static Future<bool> hasLocationPermission() async {
    if (_hasPermission) return true;
    
    LocationPermission permission = await Geolocator.checkPermission();
    _hasPermission = permission == LocationPermission.whileInUse ||
                     permission == LocationPermission.always;
    
    return _hasPermission;
  }

  // Open app settings if permission is permanently denied
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
