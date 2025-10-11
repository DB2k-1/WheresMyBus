import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wheres_my_bus/models/cycle_hire_station.dart';
import 'package:wheres_my_bus/services/cycle_hire_service.dart';
import 'package:wheres_my_bus/services/cycle_storage_service.dart';
import 'package:wheres_my_bus/services/location_service.dart';
import 'package:wheres_my_bus/utils/constants.dart';
import 'package:wheres_my_bus/widgets/cycle_station_card.dart';

class AddCycleStationsScreen extends StatefulWidget {
  const AddCycleStationsScreen({super.key});

  @override
  State<AddCycleStationsScreen> createState() => _AddCycleStationsScreenState();
}

class _AddCycleStationsScreenState extends State<AddCycleStationsScreen> {
  List<CycleHireStation> _nearbyStations = [];
  List<String> _savedStationIds = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load saved station IDs
      final savedIds = await CycleStorageService.getSavedStationIds();
      
      // Get user location and find nearby stations
      final position = await LocationService.getCurrentLocation();
      final stations = await CycleHireService.findNearestStations(
        latitude: position.latitude,
        longitude: position.longitude,
        count: 20, // Show more stations for selection
      );

      if (mounted) {
        setState(() {
          _savedStationIds = savedIds;
          _nearbyStations = stations;
          _userPosition = position;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading stations: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleStation(CycleHireStation station) async {
    final isSaved = _savedStationIds.contains(station.id);
    
    if (isSaved) {
      await CycleStorageService.removeStation(station.id);
      setState(() {
        _savedStationIds.remove(station.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${station.name}'),
            backgroundColor: AppColors.londonRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      await CycleStorageService.addStation(station);
      setState(() {
        _savedStationIds.add(station.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${station.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  List<CycleHireStation> get _filteredStations {
    if (_searchQuery.isEmpty) {
      return _nearbyStations;
    }
    
    final query = _searchQuery.toLowerCase();
    return _nearbyStations.where((station) {
      return station.name.toLowerCase().contains(query) ||
             station.id.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Add Cycle Stations'),
        backgroundColor: AppColors.londonRed,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingMedium),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search stations...',
                prefixIcon: const Icon(Icons.search, color: AppColors.londonRed),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  borderSide: BorderSide(color: AppColors.londonRed.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  borderSide: const BorderSide(color: AppColors.londonRed, width: 2),
                ),
                filled: true,
                fillColor: AppColors.cream,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Loading or error state
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.londonRed,
                ),
              ),
            )
          else if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSizes.paddingMedium),
                    Text(
                      _errorMessage!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.paddingLarge),
                    ElevatedButton(
                      onPressed: _loadData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.londonRed,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else
            // Stations list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                itemCount: _filteredStations.length,
                itemBuilder: (context, index) {
                  final station = _filteredStations[index];
                  final isSaved = _savedStationIds.contains(station.id);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
                    child: ListTile(
                      leading: Icon(
                        isSaved ? Icons.check_circle : Icons.add_circle_outline,
                        color: isSaved ? Colors.green : AppColors.londonRed,
                        size: 32,
                      ),
                      title: Text(
                        station.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.pedal_bike,
                                size: 16,
                                color: station.nbBikes > 0 ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text('${station.nbBikes} bikes'),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.storage,
                                size: 16,
                                color: station.nbEmptyDocks > 0 ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 4),
                              Text('${station.nbEmptyDocks} docks'),
                            ],
                          ),
                          if (station.distance != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              station.formattedDistance,
                              style: TextStyle(
                                color: AppColors.londonBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          isSaved ? Icons.remove_circle : Icons.add_circle,
                          color: isSaved ? Colors.red : Colors.green,
                        ),
                        onPressed: () => _toggleStation(station),
                      ),
                      onTap: () => _toggleStation(station),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

