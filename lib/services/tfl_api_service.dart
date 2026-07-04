import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wheres_my_bus/models/bus_arrival.dart';

class TflApiService {
  static const String _baseUrl = 'https://countdown.api.tfl.gov.uk/interfaces/ura/instant_V1';
  
  // Fetch bus arrivals for a specific stop
  static Future<List<BusArrival>> getBusArrivals(String stopCode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?StopCode2=$stopCode'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'WheresMyBus/1.0',
        },
      );

      if (response.statusCode == 200) {
        return _parseApiResponse(response.body, stopCode);
      } else {
        throw Exception('Failed to load bus arrivals: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Parse the TfL API response
  static List<BusArrival> _parseApiResponse(String responseBody, String stopCode) {
    try {
      // The API returns data in a specific format
      // Remove the first line which contains metadata
      final lines = responseBody.split('\n');
      if (lines.isEmpty) return [];

      final arrivals = <BusArrival>[];
      
      for (final line in lines.skip(1)) {
        if (line.trim().isEmpty) continue;
        
        try {
          // Parse the line which should contain arrival data
          // Format: [1, "Stop Name", "Route", timestamp]
          final data = jsonDecode(line.trim());
          if (data is List && data.length >= 4) {
            final arrival = BusArrival.fromTflApi(data, stopCode);
            if (arrival.timeToStation >= 0) {
              arrivals.add(arrival);
            }
          }
        } catch (e) {
          // Skip malformed lines
          continue;
        }
      }

      // Sort by arrival time
      arrivals.sort((a, b) => a.timeToStation.compareTo(b.timeToStation));
      
      return arrivals;
    } catch (e) {
      throw Exception('Failed to parse API response: $e');
    }
  }

  // Get bus arrivals for multiple stops
  static Future<Map<String, List<BusArrival>>> getBusArrivalsForStops(
    List<String> stopCodes,
  ) async {
    final results = <String, List<BusArrival>>{};
    
    // Fetch arrivals for each stop concurrently
    final futures = stopCodes.map((stopCode) async {
      try {
        final arrivals = await getBusArrivals(stopCode);
        return MapEntry(stopCode, arrivals);
      } catch (e) {
        return MapEntry(stopCode, <BusArrival>[]);
      }
    });

    final completed = await Future.wait(futures);
    for (final entry in completed) {
      results[entry.key] = entry.value;
    }

    return results;
  }

  // Refresh bus arrivals data
  static Future<List<BusArrival>> refreshBusArrivals(String stopCode) async {
    return await getBusArrivals(stopCode);
  }
}
