import 'dart:math';
import 'package:wheres_my_bus/utils/direction_helper.dart';
import 'package:wheres_my_bus/services/custom_direction_service.dart';

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

  // Convert UK grid coordinates to approximate lat/lng
  Map<String, double> getLatLng() {
    // This is a simplified conversion - for production use a proper UK grid converter
    // UK grid coordinates are in meters from a reference point
    const double gridOriginLat = 49.0;
    const double gridOriginLng = -2.0;
    
    // Rough conversion (this is simplified)
    final lat = gridOriginLat + (locationNorthing / 111000.0);
    final lng = gridOriginLng + (locationEasting / 111000.0);
    
    return {'lat': lat, 'lng': lng};
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
