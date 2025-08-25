import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class DataUpdateService {
  static const String _lastUpdateKey = 'last_data_update';
  static const String _busStopsUrl = 'https://tfl.gov.uk/tfl/syndication/feeds/bus-stops.csv';
  static const String _busSequencesUrl = 'https://tfl.gov.uk/tfl/syndication/feeds/bus-sequences.csv';
  static const Duration _updateInterval = Duration(days: 7);
  
  static Future<void> initialize() async {
    await _checkAndUpdateIfNeeded();
  }

  /// Force a manual data update check (for testing)
  static Future<void> forceUpdate() async {
    print('DataUpdateService: Manual update requested');
    await _downloadAndUpdateData();
  }
  
  static Future<void> _checkAndUpdateIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getString(_lastUpdateKey);
      
      if (lastUpdate != null) {
        final lastUpdateDate = DateTime.parse(lastUpdate);
        final daysSinceUpdate = DateTime.now().difference(lastUpdateDate).inDays;
        
        if (daysSinceUpdate >= 7) {
          print('DataUpdateService: Weekly update due, checking for new data...');
          await _downloadAndUpdateData();
        } else {
          print('DataUpdateService: Data is current (${7 - daysSinceUpdate} days until next update)');
        }
      } else {
        print('DataUpdateService: First run, downloading initial data...');
        await _downloadAndUpdateData();
      }
    } catch (e) {
      print('DataUpdateService: Error checking for updates: $e');
    }
  }
  
  static Future<void> _downloadAndUpdateData() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dataDir = Directory('${appDir.path}/data');
      if (!await dataDir.exists()) {
        await dataDir.create(recursive: true);
      }
      
      bool hasUpdates = false;
      
      // Download and validate bus-stops.csv
      final busStopsResponse = await http.get(Uri.parse(_busStopsUrl));
      if (busStopsResponse.statusCode == 200) {
        if (await _hasFileChanged('assets/bus-stops.csv', busStopsResponse.body)) {
          final tempPath = '${dataDir.path}/bus-stops-new.csv';
          final currentPath = '${dataDir.path}/bus-stops.csv';
          
          // Write to temporary file first
          await File(tempPath).writeAsBytes(busStopsResponse.bodyBytes);
          
          // Validate the new file
          if (await _validateBusStopsFile(tempPath)) {
            // If current file exists, delete it
            if (await File(currentPath).exists()) {
              await File(currentPath).delete();
            }
            
            // Rename temp to current
            await File(tempPath).rename(currentPath);
            hasUpdates = true;
            print('DataUpdateService: Successfully updated bus-stops.csv');
          } else {
            // Delete invalid temp file
            await File(tempPath).delete();
            print('DataUpdateService: New bus-stops.csv failed validation, keeping current file');
          }
        }
      }
      
      // Download and validate bus-sequences.csv
      final busSequencesResponse = await http.get(Uri.parse(_busSequencesUrl));
      if (busSequencesResponse.statusCode == 200) {
        if (await _hasFileChanged('assets/bus-sequences.csv', busSequencesResponse.body)) {
          final tempPath = '${dataDir.path}/bus-sequences-new.csv';
          final currentPath = '${dataDir.path}/bus-sequences.csv';
          
          // Write to temporary file first
          await File(tempPath).writeAsBytes(busSequencesResponse.bodyBytes);
          
          // Validate the new file
          if (await _validateBusSequencesFile(tempPath)) {
            // If current file exists, delete it
            if (await File(currentPath).exists()) {
              await File(currentPath).delete();
            }
            
            // Rename temp to current
            await File(tempPath).rename(currentPath);
            hasUpdates = true;
            print('DataUpdateService: Successfully updated bus-sequences.csv');
          } else {
            // Delete invalid temp file
            await File(tempPath).delete();
            print('DataUpdateService: New bus-sequences.csv failed validation, keeping current file');
          }
        }
      }
      
      // Clean up any old files to maintain storage limit
      await _cleanupOldFiles(dataDir);
      
      if (hasUpdates) {
        // Update last update timestamp
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
        
        // Notify that data has been updated
        _notifyDataUpdated();
      } else {
        print('DataUpdateService: No updates found, data is current');
        // Update timestamp even if no changes (to reset weekly cycle)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      }
    } catch (e) {
      print('DataUpdateService: Error downloading updates: $e');
    }
  }
  
  static Future<bool> _hasFileChanged(String existingPath, String newContent) async {
    try {
      final existingFile = File(existingPath);
      if (!await existingFile.exists()) return true;
      
      final existingContent = await existingFile.readAsString();
      return existingContent != newContent;
    } catch (e) {
      print('DataUpdateService: Error comparing files: $e');
      return false;
    }
  }
  
  static Future<String> getBusStopsData() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final updatedPath = '${appDir.path}/data/bus-stops.csv';
      
      if (await File(updatedPath).exists()) {
        return await File(updatedPath).readAsString();
      }
    } catch (e) {
      print('DataUpdateService: Error reading updated bus-stops.csv: $e');
    }
    
    // Fallback to bundled asset
    return await rootBundle.loadString('assets/bus-stops.csv');
  }
  
  static Future<String> getBusSequencesData() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final updatedPath = '${appDir.path}/data/bus-sequences.csv';
      
      if (await File(updatedPath).exists()) {
        return await File(updatedPath).readAsString();
      }
    } catch (e) {
      print('DataUpdateService: Error reading updated bus-sequences.csv: $e');
    }
    
    // Fallback to bundled asset
    return await rootBundle.loadString('assets/bus-sequences.csv');
  }
  
  static Future<DateTime?> getLastUpdateTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUpdate = prefs.getString(_lastUpdateKey);
      return lastUpdate != null ? DateTime.parse(lastUpdate) : null;
    } catch (e) {
      print('DataUpdateService: Error getting last update time: $e');
      return null;
    }
  }
  
  static Future<bool> isDataCurrent() async {
    final lastUpdate = await getLastUpdateTime();
    if (lastUpdate == null) return false;
    
    final daysSinceUpdate = DateTime.now().difference(lastUpdate).inDays;
    return daysSinceUpdate < 7;
  }
  
  static void _notifyDataUpdated() {
    // This will be implemented to show a banner notification
    print('DataUpdateService: Data updated successfully');
  }
  
  static Future<bool> _validateBusStopsFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      
      final content = await file.readAsString();
      final lines = content.split('\n');
      
      // Check if file has reasonable structure
      if (lines.length < 10) return false; // Too few lines
      
      // Check header structure
      if (lines.isNotEmpty && !lines[0].contains('Stop_Code_LBSL')) return false;
      
      // Check if we can parse at least a few lines
      int validLines = 0;
      for (int i = 1; i < lines.length && i < 10; i++) {
        if (lines[i].trim().isNotEmpty) {
          final values = lines[i].split(',');
          if (values.length >= 9) validLines++;
        }
      }
      
      return validLines >= 5; // At least 5 valid data lines
    } catch (e) {
      print('DataUpdateService: Error validating bus-stops.csv: $e');
      return false;
    }
  }
  
  static Future<bool> _validateBusSequencesFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      
      final content = await file.readAsString();
      final lines = content.split('\n');
      
      // Check if file has reasonable structure
      if (lines.length < 10) return false; // Too few lines
      
      // Check header structure
      if (lines.isNotEmpty && !lines[0].contains('Route,Run,Sequence')) return false;
      
      // Check if we can parse at least a few lines
      int validLines = 0;
      for (int i = 1; i < lines.length && i < 10; i++) {
        if (lines[i].trim().isNotEmpty) {
          final values = lines[i].split(',');
          if (values.length >= 7) validLines++;
        }
      }
      
      return validLines >= 5; // At least 5 valid data lines
    } catch (e) {
      print('DataUpdateService: Error validating bus-sequences.csv: $e');
      return false;
    }
  }
  
  static Future<void> _cleanupOldFiles(Directory dataDir) async {
    try {
      final files = await dataDir.list().toList();
      final csvFiles = files.where((file) => 
        file is File && 
        file.path.endsWith('.csv') &&
        !file.path.contains('-new.csv') // Don't delete temp files
      ).toList();
      
      // Keep only the 2 main files (bus-stops.csv and bus-sequences.csv)
      if (csvFiles.length > 2) {
        // Sort by modification time, keep newest 2
        csvFiles.sort((a, b) => 
          (a as File).lastModifiedSync().compareTo((b as File).lastModifiedSync())
        );
        
        // Delete older files
        for (int i = 0; i < csvFiles.length - 2; i++) {
          await (csvFiles[i] as File).delete();
          print('DataUpdateService: Cleaned up old file: ${csvFiles[i].path}');
        }
      }
    } catch (e) {
      print('DataUpdateService: Error cleaning up old files: $e');
    }
  }
}
