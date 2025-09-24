import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CustomDirectionService {
  static const String _customDirectionsKey = 'custom_directions';

  /// Save a custom direction for a bus stop
  static Future<void> saveCustomDirection(String naptanAtco, String customDirection) async {
    final prefs = await SharedPreferences.getInstance();
    final customDirections = await getCustomDirections();
    
    if (customDirection.trim().isEmpty) {
      // If empty, remove the custom direction (revert to original)
      customDirections.remove(naptanAtco);
    } else {
      // Save the custom direction
      customDirections[naptanAtco] = customDirection.trim();
    }
    
    await prefs.setString(_customDirectionsKey, jsonEncode(customDirections));
  }

  /// Get custom direction for a specific bus stop
  static Future<String?> getCustomDirection(String naptanAtco) async {
    final customDirections = await getCustomDirections();
    return customDirections[naptanAtco];
  }

  /// Get all custom directions
  static Future<Map<String, String>> getCustomDirections() async {
    final prefs = await SharedPreferences.getInstance();
    final customDirectionsJson = prefs.getString(_customDirectionsKey);
    
    if (customDirectionsJson == null) return {};
    
    try {
      final Map<String, dynamic> decoded = jsonDecode(customDirectionsJson);
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      return {};
    }
  }

  /// Check if a bus stop has a custom direction
  static Future<bool> hasCustomDirection(String naptanAtco) async {
    final customDirections = await getCustomDirections();
    return customDirections.containsKey(naptanAtco);
  }

  /// Remove custom direction for a bus stop
  static Future<void> removeCustomDirection(String naptanAtco) async {
    await saveCustomDirection(naptanAtco, '');
  }
}
