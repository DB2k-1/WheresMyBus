import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wheres_my_bus/models/bus_arrival.dart';

/// TfL's Countdown feed (instant_V1). Each response line is a JSON array:
/// the first is the feed version ([4, ...]), then [0, ...] for a stop and
/// [1, ...] for each prediction. Fields always come back in TfL's own fixed
/// order, whatever order they're requested in, so they're read by position
/// for the exact field lists below.
class TflApiService {
  static const String _baseUrl = 'https://countdown.api.tfl.gov.uk/interfaces/ura/instant_V1';

  // Stop row:       [0, StopPointName, Towards, StopPointIndicator]
  // Prediction row: [1, StopPointName, Towards, StopPointIndicator,
  //                  LineName, DestinationText, VehicleID, EstimatedTime]
  static const String _stopFields =
      'StopPointName,StopPointIndicator,Towards,LineName,DestinationText,VehicleID,EstimatedTime';

  // Prediction row: [1, StopPointName, StopCode2, StopPointIndicator, EstimatedTime]
  static const String _vehicleFields =
      'StopPointName,StopCode2,StopPointIndicator,EstimatedTime';

  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'User-Agent': 'WheresMyBus/1.0',
  };

  /// Arrivals at a stop (by Naptan code), soonest first.
  static Future<List<BusArrival>> getBusArrivals(String stopCode) async {
    return (await getStopArrivals(stopCode)).arrivals;
  }

  /// Arrivals at a stop plus how the stop is labelled on the street (its
  /// letter and "towards" text), which comes back even when no buses are due.
  static Future<StopArrivals> getStopArrivals(String stopCode) async {
    final body = await _get(
        '$_baseUrl?StopCode2=${Uri.encodeQueryComponent(stopCode)}&StopAlso=True&ReturnList=$_stopFields');
    return parseStopArrivals(body, stopCode);
  }

  /// The stops a bus still has to reach, soonest first. The first is the
  /// stop it's heading for now.
  static Future<List<VehicleStop>> getVehicleStops(String vehicleId) async {
    final body = await _get(
        '$_baseUrl?VehicleID=${Uri.encodeQueryComponent(vehicleId)}&ReturnList=$_vehicleFields');
    return parseVehicleStops(body);
  }

  static Future<String> _get(String url) async {
    try {
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) return response.body;
      throw Exception('TfL returned ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Iterable<List<dynamic>> _rows(String body) sync* {
    for (final line in const LineSplitter().convert(body)) {
      if (line.trim().isEmpty) continue;
      try {
        final row = jsonDecode(line.trim());
        if (row is List && row.isNotEmpty) yield row;
      } catch (_) {
        // Skip malformed lines
      }
    }
  }

  static String? _text(dynamic value) {
    // Collapse runs of spaces (TfL has "Warren Street Station  / Euston Road").
    final text = value?.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    return text == null || text.isEmpty || text == 'null' ? null : text;
  }

  static DateTime? _time(dynamic value) {
    final millis = int.tryParse(value?.toString() ?? '');
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  @visibleForTesting
  static StopArrivals parseStopArrivals(String body, String stopCode) {
    StopInfo? stop;
    final arrivals = <BusArrival>[];
    for (final row in _rows(body)) {
      if (row[0] == 0 && row.length >= 4) {
        stop = StopInfo(
          name: _text(row[1]) ?? '',
          towards: _text(row[2]),
          indicator: _text(row[3]),
        );
      } else if (row[0] == 1 && row.length >= 8) {
        final expected = _time(row[7]);
        final line = _text(row[4]);
        if (expected == null || line == null) continue;
        stop ??= StopInfo(
          name: _text(row[1]) ?? '',
          towards: _text(row[2]),
          indicator: _text(row[3]),
        );
        arrivals.add(BusArrival(
          routeId: line,
          lineName: line,
          destination: _text(row[5]) ?? '',
          vehicleId: _text(row[6]) ?? '',
          direction: _text(row[2]) ?? '',
          platformName: _text(row[3]) ?? '',
          currentStopCode: stopCode,
          expectedArrival: expected,
        ));
      }
    }
    arrivals.sort((a, b) => a.expectedArrival.compareTo(b.expectedArrival));
    return StopArrivals(stop: stop, arrivals: arrivals);
  }

  @visibleForTesting
  static List<VehicleStop> parseVehicleStops(String body) {
    final stops = <VehicleStop>[];
    for (final row in _rows(body)) {
      if (row[0] != 1 || row.length < 5) continue;
      final expected = _time(row[4]);
      final naptan = _text(row[2]);
      if (expected == null || naptan == null) continue;
      stops.add(VehicleStop(
        name: _text(row[1]) ?? '',
        naptanAtco: naptan,
        indicator: _text(row[3]),
        expectedArrival: expected,
      ));
    }
    stops.sort((a, b) => a.expectedArrival.compareTo(b.expectedArrival));
    return stops;
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
