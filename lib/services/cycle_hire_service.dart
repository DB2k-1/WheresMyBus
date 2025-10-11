import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:wheres_my_bus/models/cycle_hire_station.dart';

class CycleHireService {
  static const String _feedUrl = 'http://www.tfl.gov.uk/tfl/syndication/feeds/cycle-hire/livecyclehireupdates.xml';
  
  static List<CycleHireStation>? _cachedStations;
  static DateTime? _lastFetchTime;
  static const Duration _cacheExpiry = Duration(minutes: 1);

  /// Fetch all cycle hire stations from TfL feed
  static Future<List<CycleHireStation>> fetchAllStations() async {
    // Return cached data if still valid
    if (_cachedStations != null && 
        _lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheExpiry) {
      return _cachedStations!;
    }

    try {
      final response = await http.get(
        Uri.parse(_feedUrl),
        headers: {
          'User-Agent': 'WheresMyBus/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final stations = _parseXmlResponse(response.body);
        _cachedStations = stations;
        _lastFetchTime = DateTime.now();
        return stations;
      } else {
        throw Exception('Failed to load cycle hire data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error fetching cycle hire data: $e');
    }
  }

  /// Parse XML response from TfL
  static List<CycleHireStation> _parseXmlResponse(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      final stations = <CycleHireStation>[];

      // Find all station elements
      final stationElements = document.findAllElements('station');

      for (final element in stationElements) {
        try {
          final stationData = <String, dynamic>{};
          
          // Extract all child elements
          for (final child in element.children.whereType<XmlElement>()) {
            stationData[child.name.local] = child.innerText;
          }

          final station = CycleHireStation.fromXml(stationData);
          stations.add(station);
        } catch (e) {
          // Skip malformed station entries
          continue;
        }
      }

      return stations;
    } catch (e) {
      throw Exception('Failed to parse XML: $e');
    }
  }

  /// Find nearest stations to user location
  static Future<List<CycleHireStation>> findNearestStations({
    required double latitude,
    required double longitude,
    int count = 5,
  }) async {
    final allStations = await fetchAllStations();
    
    // Calculate distances and sort
    final stationsWithDistance = allStations.map((station) {
      final distance = station.calculateDistance(latitude, longitude);
      return station.copyWith(distance: distance);
    }).toList();

    stationsWithDistance.sort((a, b) => 
      (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity)
    );

    return stationsWithDistance.take(count).toList();
  }

  /// Get a specific station by ID
  static Future<CycleHireStation?> getStationById(String id) async {
    final allStations = await fetchAllStations();
    try {
      return allStations.firstWhere((station) => station.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Refresh a list of stations by their IDs (for saved stations)
  static Future<List<CycleHireStation>> refreshStationsByIds(List<String> ids) async {
    final allStations = await fetchAllStations();
    final refreshedStations = <CycleHireStation>[];

    for (final id in ids) {
      try {
        final station = allStations.firstWhere((s) => s.id == id);
        refreshedStations.add(station);
      } catch (e) {
        // Station not found, skip it
        continue;
      }
    }

    return refreshedStations;
  }

  /// Clear cache to force fresh data
  static void clearCache() {
    _cachedStations = null;
    _lastFetchTime = null;
  }
}

