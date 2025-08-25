import 'package:flutter/material.dart';
import 'package:wheres_my_bus/services/weather_service.dart';
import 'package:wheres_my_bus/utils/constants.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  WeatherData? _weatherData;
  bool _isLoading = false;
  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();
    _checkLocationAndLoadWeather();
  }

  Future<void> _checkLocationAndLoadWeather() async {
    // Check if we have location permission by trying to get weather
    setState(() {
      _isLoading = true;
    });

    try {
      final weather = await WeatherService.getCurrentWeather();
      if (mounted) {
        setState(() {
          _weatherData = weather;
          _hasLocationPermission = weather != null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weatherData = null;
          _hasLocationPermission = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if no location permission
    if (!_hasLocationPermission) {
      return const SizedBox.shrink();
    }

    // Show loading indicator
    if (_isLoading) {
      return Container(
        width: 24,
        height: 24,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    // Show weather data
    if (_weatherData != null) {
      return GestureDetector(
        onTap: _refreshWeather,
        child: Container(
          width: 56, // Same width as FloatingActionButton
          height: 56, // Same height as FloatingActionButton
          decoration: BoxDecoration(
            color: _getWeatherBackgroundColor(),
            borderRadius: BorderRadius.circular(28), // Same radius as FloatingActionButton
          ),
          child: Center(
            child: _weatherData!.isRainApproaching
                ? Text(
                    _weatherData!.displayText,
                    style: TextStyle(
                      color: _getWeatherTextColor(),
                      fontSize: 14, // Smaller text for rain warnings
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  )
                : Image.asset(
                    _weatherData!.imagePath,
                    width: 32, // Appropriate size for the container
                    height: 32,
                    fit: BoxFit.contain,
                  ),
          ),
        ),
      );
    }

    // Fallback - show nothing
    return const SizedBox.shrink();
  }

  Color _getWeatherBackgroundColor() {
    // Clean white background for all weather conditions
    return Colors.white;
  }



  Color _getWeatherTextColor() {
    // Black text for clean, readable appearance
    return Colors.black87;
  }

  Future<void> _refreshWeather() async {
    // Clear cache and reload weather
    WeatherService.clearCache();
    await _checkLocationAndLoadWeather();
  }
}
