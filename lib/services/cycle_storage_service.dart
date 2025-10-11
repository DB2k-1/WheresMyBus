import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheres_my_bus/models/cycle_hire_station.dart';

class CycleStorageService {
  static const String _savedStationsKey = 'saved_cycle_stations';

  /// Save a cycle hire station to favorites
  static Future<void> addStation(CycleHireStation station) async {
    final prefs = await SharedPreferences.getInstance();
    final savedStations = await loadSavedStations();
    
    // Check if station already exists
    if (savedStations.any((s) => s.id == station.id)) {
      return; // Already saved
    }
    
    savedStations.add(station);
    await _saveStations(prefs, savedStations);
  }

  /// Remove a cycle hire station from favorites
  static Future<void> removeStation(String stationId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedStations = await loadSavedStations();
    
    savedStations.removeWhere((station) => station.id == stationId);
    await _saveStations(prefs, savedStations);
  }

  /// Load all saved cycle hire stations
  static Future<List<CycleHireStation>> loadSavedStations() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_savedStationsKey);
    
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => CycleHireStation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading saved cycle stations: $e');
      return [];
    }
  }

  /// Check if a station is saved
  static Future<bool> isStationSaved(String stationId) async {
    final savedStations = await loadSavedStations();
    return savedStations.any((station) => station.id == stationId);
  }

  /// Get list of saved station IDs
  static Future<List<String>> getSavedStationIds() async {
    final savedStations = await loadSavedStations();
    return savedStations.map((s) => s.id).toList();
  }

  /// Clear all saved stations
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedStationsKey);
  }

  /// Internal helper to save stations list
  static Future<void> _saveStations(
    SharedPreferences prefs,
    List<CycleHireStation> stations,
  ) async {
    final jsonList = stations.map((station) => station.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await prefs.setString(_savedStationsKey, jsonString);
  }
}

