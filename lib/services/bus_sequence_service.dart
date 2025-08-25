import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:wheres_my_bus/services/data_update_service.dart';

class BusSequenceService {
  static List<Map<String, dynamic>>? _sequences;
  
  static Future<void> initialize() async {
    if (_sequences != null) return;
    
    try {
      final String data = await DataUpdateService.getBusSequencesData();
      final List<String> lines = data.split('\n');
      
      // Skip header line
      final List<String> dataLines = lines.skip(1).where((line) => line.trim().isNotEmpty).toList();
      
      _sequences = dataLines.map((line) {
        try {
          // Handle CSV with commas in stop names by using a more robust approach
          final values = _parseCsvLine(line);
          if (values.length >= 7) {
            return {
              'route': values[0],
              'run': values[1],
              'sequence': int.tryParse(values[2]) ?? 0,
              'stopCodeLBSL': values[3],
              'busStopCode': values[4],
              'stopName': values[6],
            };
          }
        } catch (e) {
          // Skip malformed lines
          print('Skipping malformed line: $line');
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
        (seq) => seq['route'] == route && seq['busStopCode'] == currentStopCode,
        orElse: () => {},
      );
      
      if (currentStop.isEmpty) {
        print('BusSequenceService: Current stop not found');
        return [];
      }
      
      final currentSequence = currentStop['sequence'] as int;
      final currentRun = currentStop['run'] as String;
      print('BusSequenceService: Found current stop at sequence $currentSequence, run $currentRun');
      
      // Find the final destination (highest sequence number for this route AND run)
      final allStopsForRouteAndRun = _sequences!.where((seq) => 
        seq['route'] == route && seq['run'] == currentRun
      ).toList();
      if (allStopsForRouteAndRun.isEmpty) {
        print('BusSequenceService: No stops found for route $route, run $currentRun');
        return [];
      }
      
      // Sort by sequence and get the last stop
      allStopsForRouteAndRun.sort((a, b) => (a['sequence'] as int).compareTo(b['sequence'] as int));
      final finalStop = allStopsForRouteAndRun.last;
      
      // Clean up the stop name by removing <> symbols
      String cleanStopName = finalStop['stopName'] as String;
      cleanStopName = cleanStopName.replaceAll('<>', '').trim();
      
      print('BusSequenceService: Final destination is $cleanStopName at sequence ${finalStop['sequence']} for run $currentRun');
      
      return [cleanStopName];
    } catch (e) {
      print('Error getting final destination: $e');
      return [];
    }
  }
  
  static void dispose() {
    _sequences = null;
  }
  
  static List<String> _parseCsvLine(String line) {
    final List<String> result = [];
    final StringBuffer current = StringBuffer();
    bool inQuotes = false;
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString().trim());
        current.clear();
      } else {
        current.write(char);
      }
    }
    
    // Add the last field
    result.add(current.toString().trim());
    
    return result;
  }
}
