import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static WeatherData? _currentWeather;
  static DateTime? _lastUpdate;
  static const Duration _updateInterval = Duration(minutes: 30);
  
  /// Get current weather data for the user's location
  static Future<WeatherData?> getCurrentWeather() async {
    try {
      // Check if we need to update
      if (_currentWeather != null && _lastUpdate != null) {
        final timeSinceUpdate = DateTime.now().difference(_lastUpdate!);
        if (timeSinceUpdate < _updateInterval) {
          return _currentWeather;
        }
      }
      
      // Get current location
      final position = await _getCurrentLocation();
      if (position == null) return null;
      
      // Create weather data based on time and basic conditions
      final weatherData = _createBasicWeatherData(position);
      
      if (weatherData != null) {
        _currentWeather = weatherData;
        _lastUpdate = DateTime.now();
      }
      
      return weatherData;
    } catch (e) {
      print('WeatherService: Error getting weather: $e');
      return null;
    }
  }
  
  /// Get current location (reuse from bus stop service)
  static Future<Position?> _getCurrentLocation() async {
    try {
      // Check if location permission is granted
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return null;
      }
      
      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      print('WeatherService: Error getting location: $e');
      return null;
    }
  }
  
  /// Create basic weather data based on time and season
  static WeatherData _createBasicWeatherData(Position position) {
    final now = DateTime.now();
    final hour = now.hour;
    final month = now.month;
    
    // Determine if it's day or night
    final isDay = hour >= 6 && hour <= 20;
    
    // Determine season (rough approximation for London)
    final isSummer = month >= 6 && month <= 8;
    final isWinter = month == 12 || month <= 2;
    
    // Basic weather conditions based on time and season
    WeatherCondition condition;
    String imagePath;
    String description;
    
    if (isDay) {
      if (isSummer) {
        condition = WeatherCondition.clear;
        imagePath = 'assets/images/weather/sunny.png';
        description = 'Sunny day';
      } else if (isWinter) {
        condition = WeatherCondition.clouds;
        imagePath = 'assets/images/weather/partially_sunny.png';
        description = 'Cloudy day';
      } else {
        condition = WeatherCondition.clear;
        imagePath = 'assets/images/weather/partially_sunny.png';
        description = 'Partly cloudy';
      }
    } else {
      condition = WeatherCondition.clear;
      imagePath = 'assets/images/weather/clear_night.png';
      description = 'Clear night';
    }
    
    // Estimate temperature based on season and time
    double temperature;
    if (isSummer) {
      temperature = isDay ? 22.0 : 15.0;
    } else if (isWinter) {
      temperature = isDay ? 8.0 : 3.0;
    } else {
      temperature = isDay ? 16.0 : 10.0;
    }
    
    // Estimate humidity based on season
    int humidity = isSummer ? 65 : 80;
    
    // Simulate rain prediction for testing (you can replace this with real data later)
    int? rainInMinutes;
    if (month >= 10 || month <= 3) { // Rainy season (October to March)
      if (hour >= 14 && hour <= 18) { // Afternoon rain
        rainInMinutes = 30;
      }
    }
    
    return WeatherData(
      temperature: temperature,
      condition: condition,
      imagePath: imagePath,
      description: description,
      humidity: humidity,
      windSpeed: 0.0,
      rainInMinutes: rainInMinutes,
    );
  }
  
  /// Clear cached weather data
  static void clearCache() {
    _currentWeather = null;
    _lastUpdate = null;
  }
}

/// Weather data model
class WeatherData {
  final double temperature;
  final WeatherCondition condition;
  final String imagePath;
  final String description;
  final int humidity;
  final double windSpeed;
  final int? rainInMinutes; // null if no rain predicted
  
  WeatherData({
    required this.temperature,
    required this.condition,
    required this.imagePath,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    this.rainInMinutes,
  });
  
  /// Get display text for the weather widget
  String get displayText {
    if (rainInMinutes != null) {
      if (rainInMinutes! <= 5) return 'Rain now';
      if (rainInMinutes! <= 15) return 'Rain in ${rainInMinutes}m';
      if (rainInMinutes! <= 30) return 'Rain in ${rainInMinutes}m';
      return 'Rain in ${rainInMinutes}m';
    }
    
    return ''; // Empty string when showing image
  }
  
  /// Check if rain is approaching soon
  bool get isRainApproaching => rainInMinutes != null && rainInMinutes! <= 30;
}

/// Weather condition enum
enum WeatherCondition {
  thunderstorm,
  drizzle,
  rain,
  snow,
  atmosphere,
  clear,
  clouds,
  unknown,
}
