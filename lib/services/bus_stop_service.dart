import 'package:flutter/services.dart';
import 'package:latlong_to_osgrid/latlong_to_osgrid.dart';
import 'package:wheres_my_bus/models/bus_stop.dart';
import 'package:wheres_my_bus/services/data_update_service.dart';
import 'package:wheres_my_bus/utils/csv_line.dart';

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
      final String csvData = await DataUpdateService.getBusStopsData();
      // Names can contain quoted commas and line breaks, e.g.
      // "Guy, Earl of Warwick", so parse the whole file rather than by line.
      final List<List<String>> rows = parseCsv(csvData);

      // Skip header row and parse each row
      _allBusStops = rows.skip(1).map((values) {
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
  /// GPS (WGS84) to the OS National Grid eastings and northings used by
  /// bus-stops.csv. Uses the proper OSGB36 conversion; the old flat
  /// approximation put central London about 450 m too far south, so
  /// "nearest" stops and distances were off.
  static Map<String, double> gpsToUKGrid(double latitude, double longitude) {
    try {
      final ref = LatLongConverter().getOSGBfromDec(latitude, longitude);
      return {
        'easting': ref.easting.toDouble(),
        'northing': ref.northing.toDouble(),
      };
    } catch (e) {
      return _approximateUKGrid(latitude, longitude);
    }
  }

  // Rough fallback if the conversion above fails.
  static Map<String, double> _approximateUKGrid(double latitude, double longitude) {
    // Trafalgar Square is at 51.5080, -0.1281 and E 529980, N 180480.
    return {
      'easting': 529980.0 + (longitude + 0.1281) * 69300.0,
      'northing': 180480.0 + (latitude - 51.5080) * 111200.0,
    };
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
