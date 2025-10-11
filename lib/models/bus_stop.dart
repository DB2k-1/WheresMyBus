import 'dart:math';
import 'package:wheres_my_bus/utils/direction_helper.dart';
import 'package:wheres_my_bus/services/custom_direction_service.dart';
import 'package:latlong_to_osgrid/latlong_to_osgrid.dart';

class BusStop {
  final String stopCodeLbsl;
  final String busStopCode;
  final String naptanAtco;
  final String stopName;
  final double locationEasting;
  final double locationNorthing;
  final int heading;
  final String stopArea;
  final bool virtualBusStop;
  final double? distance; // Distance from user location

  BusStop({
    required this.stopCodeLbsl,
    required this.busStopCode,
    required this.naptanAtco,
    required this.stopName,
    required this.locationEasting,
    required this.locationNorthing,
    required this.heading,
    required this.stopArea,
    required this.virtualBusStop,
    this.distance,
  });

  factory BusStop.fromCsv(List<String> csvRow) {
    return BusStop(
      stopCodeLbsl: csvRow[0],
      busStopCode: csvRow[1],
      naptanAtco: csvRow[2],
      stopName: csvRow[3],
      locationEasting: double.tryParse(csvRow[4]) ?? 0.0,
      locationNorthing: double.tryParse(csvRow[5]) ?? 0.0,
      heading: int.tryParse(csvRow[6]) ?? 0,
      stopArea: csvRow[7],
      virtualBusStop: csvRow[8] == '1',
    );
  }

  // Calculate distance from user location using UK grid coordinates
  double calculateDistance(double userEasting, double userNorthing) {
    final dx = locationEasting - userEasting;
    final dy = locationNorthing - userNorthing;
    return sqrt(dx * dx + dy * dy);
  }

  // Convert UK grid coordinates (OSGB36) to lat/lng (WGS84) using proven package
  Map<String, double> getLatLng() {
    try {
      final LatLongConverter converter = LatLongConverter();
      
      // Convert easting/northing to lat/lng (handles OSGB36 to WGS84 conversion)
      final LatLong latLong = converter.getLatLongFromOSGB(
        locationEasting.round(), 
        locationNorthing.round()
      );
      
      return {
        'latitude': latLong.lat,
        'longitude': latLong.long,
      };
    } catch (e) {
      // Fallback to approximate conversion if package fails
      print('Coordinate conversion error: $e');
      return {
        'latitude': 51.5074, // Default to London center
        'longitude': -0.1278,
      };
    }
  }

  /// Get user-friendly direction description
  String get userFriendlyDirection => DirectionHelper.getBusStopDirection(heading.toDouble());
  
  /// Get short direction indicator
  String get shortDirection => DirectionHelper.getShortDirection(heading.toDouble());
  
  /// Get direction badge text
  String get directionBadge => DirectionHelper.getDirectionBadge(heading.toDouble());

  /// Get display direction (custom if available, otherwise original)
  Future<String> getDisplayDirection() async {
    final customDirection = await CustomDirectionService.getCustomDirection(naptanAtco);
    return customDirection ?? userFriendlyDirection;
  }

  @override
  String toString() {
    return 'BusStop(name: $stopName, code: $busStopCode, direction: $userFriendlyDirection, distance: ${distance?.toStringAsFixed(0)}m)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusStop && other.naptanAtco == naptanAtco;
  }

  @override
  int get hashCode => naptanAtco.hashCode;
}
