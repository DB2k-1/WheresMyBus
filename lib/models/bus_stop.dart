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

  // Convert UK grid coordinates (OSGB36) to lat/lng (WGS84)
  Map<String, double> getLatLng() {
    // British National Grid to WGS84 conversion
    // This uses an approximate conversion suitable for mapping purposes
    
    final double E = locationEasting;
    final double N = locationNorthing;
    
    // Constants for OSGB36
    const double a = 6377563.396;      // Semi-major axis
    const double b = 6356256.909;      // Semi-minor axis
    const double F0 = 0.9996012717;    // Scale factor on central meridian
    const double lat0 = 49.0 * pi / 180;  // Latitude of true origin
    const double lon0 = -2.0 * pi / 180;  // Longitude of true origin
    const double N0 = -100000.0;       // Northing of true origin
    const double E0 = 400000.0;        // Easting of true origin
    const double e2 = 1 - (b * b) / (a * a);  // Eccentricity squared
    
    double lat = lat0;
    double M = 0;
    
    // Iterate to find latitude
    do {
      lat = (N - N0 - M) / (a * F0) + lat;
      
      final double Ma = (1 + e2 + (5.0 / 4.0) * e2 * e2) * (lat - lat0);
      final double Mb = (3 * e2 + 3 * e2 * e2) * sin(lat - lat0) * cos(lat + lat0);
      final double Mc = ((15.0 / 8.0) * e2 * e2) * sin(2 * (lat - lat0)) * cos(2 * (lat + lat0));
      M = b * F0 * (Ma - Mb + Mc);
    } while (N - N0 - M >= 0.001);
    
    final double cosLat = cos(lat);
    final double sinLat = sin(lat);
    final double nu = a * F0 / sqrt(1 - e2 * sinLat * sinLat);
    final double rho = a * F0 * (1 - e2) / pow(1 - e2 * sinLat * sinLat, 1.5);
    final double eta2 = nu / rho - 1;
    
    final double VII = tan(lat) / (2 * rho * nu);
    final double VIII = tan(lat) / (24 * rho * pow(nu, 3)) * (5 + 3 * tan(lat) * tan(lat) + eta2 - 9 * tan(lat) * tan(lat) * eta2);
    final double IX = tan(lat) / (720 * rho * pow(nu, 5)) * (61 + 90 * tan(lat) * tan(lat) + 45 * pow(tan(lat), 4));
    final double X = 1 / (cosLat * nu);
    final double XI = 1 / (6 * pow(cosLat, 3) * (nu / rho + 2 * tan(lat) * tan(lat)));
    final double XII = 1 / (120 * pow(cosLat, 5) * nu) * (5 + 28 * tan(lat) * tan(lat) + 24 * pow(tan(lat), 4));
    
    final double dE = E - E0;
    
    lat = lat - VII * pow(dE, 2) + VIII * pow(dE, 4) - IX * pow(dE, 6);
    double lon = lon0 + X * dE - XI * pow(dE, 3) + XII * pow(dE, 5);
    
    // Convert from OSGB36 to WGS84 (approximate shift)
    lat = lat + 0.00015; // ~50m north
    lon = lon + 0.00015; // ~50m east
    
    return {
      'latitude': lat * 180 / pi,
      'longitude': lon * 180 / pi,
    };
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
