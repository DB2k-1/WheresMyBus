import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:wheres_my_bus/models/bus_stop.dart';

class BusStopService {
  static List<BusStop>? _allBusStops;
  static bool _isLoading = false;

  // Load all bus stops from CSV file
  static Future<List<BusStop>> loadAllBusStops() async {
    if (_allBusStops != null) return _allBusStops!;
    if (_isLoading) {
      // Wait for current loading to complete
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _allBusStops!;
    }

    _isLoading = true;
    try {
      final String csvData = await rootBundle.loadString('assets/bus-stops.csv');
      final List<String> lines = const LineSplitter().convert(csvData);
      
      // Skip header row and parse each line
      _allBusStops = lines.skip(1).map((line) {
        final values = line.split(',');
        if (values.length >= 9) {
          return BusStop.fromCsv(values);
        }
        return null;
      }).whereType<BusStop>().toList();
      
      _isLoading = false;
      return _allBusStops!;
    } catch (e) {
      _isLoading = false;
      throw Exception('Failed to load bus stops: $e');
    }
  }

  // Find nearest bus stops to user location
  static Future<List<BusStop>> findNearestBusStops(
    double userEasting,
    double userNorthing,
    int count,
  ) async {
    final allStops = await loadAllBusStops();
    
    // Calculate distances and sort by nearest
    final stopsWithDistance = allStops.map((stop) {
      final distance = stop.calculateDistance(userEasting, userNorthing);
      return BusStop(
        stopCodeLbsl: stop.stopCodeLbsl,
        busStopCode: stop.busStopCode,
        naptanAtco: stop.naptanAtco,
        stopName: stop.stopName,
        locationEasting: stop.locationEasting,
        locationNorthing: stop.locationNorthing,
        heading: stop.heading,
        stopArea: stop.stopArea,
        virtualBusStop: stop.virtualBusStop,
        distance: distance,
      );
    }).toList();

    stopsWithDistance.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));
    
    return stopsWithDistance.take(count).toList();
  }

  // Convert GPS coordinates to UK grid coordinates using a more accurate approach
  static Map<String, double> gpsToUKGrid(double latitude, double longitude) {
    // The bus-stops.csv uses UK National Grid coordinates (OSGB36)
    // We need to convert from WGS84 (GPS) to OSGB36 (UK Grid)
    
    // For London area, use a more accurate conversion
    // The key insight is that UK grid coordinates are in meters from a specific reference point
    // and the conversion factors need to be much more precise
    
    // For London area (roughly 51.0°N to 52.0°N, -1.0°W to 0.5°E)
    if (latitude >= 51.0 && latitude <= 52.0 && longitude >= -1.0 && longitude <= 0.5) {
      // London area - use more accurate conversion factors
      // These factors are based on the actual UK grid system for the London area
      
      // The conversion from WGS84 to OSGB36 is complex, but we can use a simplified approach
      // that's much more accurate than the previous version
      
      // For London, the conversion factors are roughly:
      // 1 degree of latitude ≈ 111,000 meters
      // 1 degree of longitude ≈ 69,000 meters (at London's latitude)
      
      // Central London reference point (Trafalgar Square)
      const double londonLat = 51.5080;
      const double londonLon = -0.1280;
      const double londonEasting = 530000.0;
      const double londonNorthing = 180000.0;
      
      // Convert from WGS84 to approximate OSGB36
      // Use more accurate conversion factors for the London area
      final double easting = londonEasting + (longitude - londonLon) * 69000.0;
      final double northing = londonNorthing + (latitude - londonLat) * 111000.0;
      
      return {
        'easting': easting,
        'northing': northing,
      };
    } else {
      // Outside London area - use general UK conversion
      // UK grid coordinates are in meters from a reference point
      final double easting = (longitude + 2.0) * 111000.0;
      final double northing = (latitude - 49.0) * 111000.0;
      
      return {
        'easting': easting,
        'northing': northing,
      };
    }
  }

  // Search bus stops by name
  static Future<List<BusStop>> searchBusStops(String query) async {
    if (query.isEmpty) return [];
    
    final allStops = await loadAllBusStops();
    final lowercaseQuery = query.toLowerCase();
    
    return allStops.where((stop) {
      return stop.stopName.toLowerCase().contains(lowercaseQuery) ||
             stop.busStopCode.toLowerCase().contains(lowercaseQuery);
    }).take(20).toList(); // Limit results
  }

  // Get bus stop by NAPTAN code
  static Future<BusStop?> getBusStopByNaptan(String naptanCode) async {
    final allStops = await loadAllBusStops();
    try {
      return allStops.firstWhere((stop) => stop.naptanAtco == naptanCode);
    } catch (e) {
      return null;
    }
  }
}
