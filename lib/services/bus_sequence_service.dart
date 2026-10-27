import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:wheres_my_bus/services/data_update_service.dart';
import 'package:wheres_my_bus/utils/csv_line.dart';

class BusSequenceService {
  static List<Map<String, dynamic>>? _sequences;
  
  static Future<void> initialize() async {
    if (_sequences != null) return;
    
    try {
      final String data = await DataUpdateService.getBusSequencesData();
      // Stop names can contain quoted commas and line breaks.
      final List<List<String>> rows = parseCsv(data);

      // Skip header row
      _sequences = rows.skip(1).map((values) {
        try {
          if (values.length >= 7) {
            return {
              'route': values[0],
              'run': values[1],
              'sequence': int.tryParse(values[2]) ?? 0,
              'stopCodeLBSL': values[3],
              'naptanAtco': values[5],
              'stopName': values[6],
            };
          }
        } catch (e) {
          // Skip malformed lines
          print('Skipping malformed line: ${values.join(',')}');
        }
        return null;
      }).where((seq) => seq != null).cast<Map<String, dynamic>>().toList();
      
      print('BusSequenceService: Loaded ${_sequences!.length} sequences');
    } catch (e) {
      print('Error loading bus sequences: $e');
      _sequences = [];
    }
  }
  
  static List<String> getFinalDestination(String route, String currentStopCode) {
    if (_sequences == null) return [];
    
    try {
      print('BusSequenceService: Looking for route $route, stop $currentStopCode');
      
      // Find the current stop in the sequence
      final currentStop = _sequences!.firstWhere(
        (seq) => seq['route'] == route && seq['naptanAtco'] == currentStopCode,
        orElse: () => {},
      );
      
      if (currentStop.isEmpty) {
        print('BusSequenceService: Current stop not found');
        return [];
      }
      
      final currentSequence = currentStop['sequence'] as int;
      final currentRun = currentStop['run'] as String;
      print('BusSequenceService: Found current stop at sequence $currentSequence, run $currentRun');
      
      final finalStopName = _findFinalStopForRouteRun(route, currentRun);
      if (finalStopName == null) {
        print('BusSequenceService: No stops found for route $route, run $currentRun');
        return [];
      }
      
      print('BusSequenceService: Final destination is $finalStopName for run $currentRun');
      
      return [finalStopName];
    } catch (e) {
      print('Error getting final destination: $e');
      return [];
    }
  }

  /// Returns unique final destinations for any routes that serve [busStopCode].
  static List<String> getFinalDestinationsForStop(String naptanAtco) {
    if (_sequences == null) return [];

    try {
      final matchingSequences = _sequences!
          .where((seq) => seq['naptanAtco'] == naptanAtco)
          .toList();

      if (matchingSequences.isEmpty) {
        return [];
      }

      final destinations = <String>{};
      for (final seq in matchingSequences) {
        final route = seq['route'] as String?;
        final run = seq['run'] as String?;
        if (route == null || run == null) continue;

        final destination = _findFinalStopForRouteRun(route, run);
        if (destination != null && destination.isNotEmpty) {
          destinations.add(destination);
        }
      }

      final sorted = destinations.toList()..sort();
      return sorted;
    } catch (e) {
      print('Error getting destinations for stop $naptanAtco: $e');
      return [];
    }
  }
  
  static void dispose() {
    _sequences = null;
  }

  static String? _findFinalStopForRouteRun(String route, String run) {
    if (_sequences == null) return null;

    final stopsForRouteRun = _sequences!
        .where((seq) => seq['route'] == route && seq['run'] == run)
        .toList();

    if (stopsForRouteRun.isEmpty) return null;

    stopsForRouteRun.sort(
      (a, b) => (a['sequence'] as int).compareTo(b['sequence'] as int),
    );

    final finalStop = stopsForRouteRun.last['stopName'] as String?;
    if (finalStop == null) return null;

    return finalStop.replaceAll('<>', '').trim();
  }
  
}
