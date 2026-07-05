import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheres_my_bus/models/bus_stop.dart';
import 'package:wheres_my_bus/services/custom_direction_service.dart';

class StorageService {
  static const String _busStopsKey = 'user_bus_stops';
  static const String _lastRefreshKey = 'last_refresh_time';
  static const String _sortModeKey = 'bus_stop_sort_mode';

  // Save user's selected bus stops
  static Future<void> saveBusStops(List<BusStop> busStops) async {
    final prefs = await SharedPreferences.getInstance();
    final busStopsJson = busStops.map((stop) => {
      'stopCodeLbsl': stop.stopCodeLbsl,
      'busStopCode': stop.busStopCode,
      'naptanAtco': stop.naptanAtco,
      'stopName': stop.stopName,
      'locationEasting': stop.locationEasting,
      'locationNorthing': stop.locationNorthing,
      'heading': stop.heading,
      'stopArea': stop.stopArea,
      'virtualBusStop': stop.virtualBusStop,
    }).toList();

    await prefs.setString(_busStopsKey, jsonEncode(busStopsJson));
  }

  // Load user's selected bus stops
  static Future<List<BusStop>> loadBusStops() async {
    final prefs = await SharedPreferences.getInstance();
    final busStopsJson = prefs.getString(_busStopsKey);
    
    if (busStopsJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(busStopsJson);
      return decoded.map((json) => BusStop(
        stopCodeLbsl: json['stopCodeLbsl'],
        busStopCode: json['busStopCode'],
        naptanAtco: json['naptanAtco'],
        stopName: json['stopName'],
        locationEasting: json['locationEasting'].toDouble(),
        locationNorthing: json['locationNorthing'].toDouble(),
        heading: json['heading'],
        stopArea: json['stopArea'],
        virtualBusStop: json['virtualBusStop'],
      )).toList();
    } catch (e) {
      // If there's an error parsing, return empty list
      return [];
    }
  }

  // Add a bus stop to user's list
  static Future<void> addBusStop(BusStop busStop) async {
    final currentStops = await loadBusStops();
    
    // Check if stop already exists
    if (!currentStops.any((stop) => stop.naptanAtco == busStop.naptanAtco)) {
      currentStops.add(busStop);
      await saveBusStops(currentStops);
    }
  }

  // Remove a bus stop from user's list
  static Future<void> removeBusStop(String naptanCode) async {
    final currentStops = await loadBusStops();
    currentStops.removeWhere((stop) => stop.naptanAtco == naptanCode);
    await saveBusStops(currentStops);

    // Clear any custom direction label so re-adding this stop later
    // shows the original TfL direction, not a stale edit.
    await CustomDirectionService.removeCustomDirection(naptanCode);
  }

  // Persist a manually-dragged order for the user's bus stops
  static Future<void> reorderBusStops(List<BusStop> busStops) async {
    await saveBusStops(busStops);
  }

  // Save the user's chosen sort mode ('added' or 'nearest')
  static Future<void> saveSortMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortModeKey, mode);
  }

  // Load the user's chosen sort mode, defaults to 'added'
  static Future<String> loadSortMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sortModeKey) ?? 'added';
  }

  // Check if a bus stop is in user's list
  static Future<bool> hasBusStop(String naptanCode) async {
    final currentStops = await loadBusStops();
    return currentStops.any((stop) => stop.naptanAtco == naptanCode);
  }

  // Load just the bus stop codes (more efficient for filtering)
  static Future<List<String>> loadBusStopCodes() async {
    final currentStops = await loadBusStops();
    return currentStops.map((stop) => stop.naptanAtco).toList();
  }

  // Save last refresh time
  static Future<void> saveLastRefreshTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastRefreshKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Get last refresh time
  static Future<DateTime?> getLastRefreshTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastRefreshKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  // Clear all stored data
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_busStopsKey);
    await prefs.remove(_lastRefreshKey);
  }
}
