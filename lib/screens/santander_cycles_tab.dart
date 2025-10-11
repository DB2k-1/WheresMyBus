import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wheres_my_bus/models/cycle_hire_station.dart';
import 'package:wheres_my_bus/services/cycle_hire_service.dart';
import 'package:wheres_my_bus/services/cycle_storage_service.dart';
import 'package:wheres_my_bus/services/location_service.dart';
import 'package:wheres_my_bus/screens/cycle_station_detail_screen.dart';
import 'package:wheres_my_bus/screens/add_cycle_stations_screen.dart';
import 'package:wheres_my_bus/utils/constants.dart';
import 'package:wheres_my_bus/widgets/cycle_station_card.dart';

class SantanderCyclesTab extends StatefulWidget {
  const SantanderCyclesTab({super.key});

  @override
  State<SantanderCyclesTab> createState() => _SantanderCyclesTabState();
}

class _SantanderCyclesTabState extends State<SantanderCyclesTab> {
  List<CycleHireStation> _savedStations = [];
  List<CycleHireStation> _nearestStations = [];
  bool _isLoadingSaved = true;
  bool _isLoadingNearest = true;
  String? _errorMessage;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadSavedStations(),
      _loadNearestStations(),
    ]);
  }

  Future<void> _loadSavedStations() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingSaved = true;
      _errorMessage = null;
    });

    try {
      // Load saved station IDs
      final savedIds = await CycleStorageService.getSavedStationIds();
      
      if (savedIds.isEmpty) {
        if (mounted) {
          setState(() {
            _savedStations = [];
            _isLoadingSaved = false;
          });
        }
        return;
      }

      // Fetch fresh data for saved stations
      final stations = await CycleHireService.refreshStationsByIds(savedIds);
      
      if (mounted) {
        setState(() {
          _savedStations = stations;
          _isLoadingSaved = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading saved stations: $e';
          _isLoadingSaved = false;
        });
      }
    }
  }

  Future<void> _loadNearestStations() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingNearest = true;
    });

    try {
      // Get user location
      final position = await LocationService.getCurrentLocation();
      
      if (!mounted) return;
      
      // Fetch nearest stations
      final stations = await CycleHireService.findNearestStations(
        latitude: position.latitude,
        longitude: position.longitude,
        count: 5,
      );
      
      if (mounted) {
        setState(() {
          _userPosition = position;
          _nearestStations = stations;
          _isLoadingNearest = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading nearest stations: $e';
          _isLoadingNearest = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    CycleHireService.clearCache();
    await _loadData();
  }

  void _navigateToAddStations() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddCycleStationsScreen(),
      ),
    );

    if (result == true) {
      await _loadSavedStations();
    }
  }

  void _navigateToStationDetail(CycleHireStation station) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CycleStationDetailScreen(station: station),
      ),
    );
  }

  Future<void> _removeSavedStation(CycleHireStation station) async {
    await CycleStorageService.removeStation(station.id);
    await _loadSavedStations();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.londonRed,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            child: Text(
              'Santander Cycles',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.darkGrey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Error message
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: AppSizes.paddingSmall),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
              children: [
                // Saved stations section
                if (_isLoadingSaved)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSizes.paddingLarge),
                      child: CircularProgressIndicator(
                        color: AppColors.londonRed,
                      ),
                    ),
                  )
                else if (_savedStations.isNotEmpty) ...[
                  Text(
                    'My Stations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.darkGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingSmall),
                  ..._savedStations.map((station) => CycleStationCard(
                    station: station,
                    onTap: () => _navigateToStationDetail(station),
                    onAddRemove: () => _removeSavedStation(station),
                    isSaved: true,
                  )),
                  const SizedBox(height: AppSizes.paddingMedium),
                  const Divider(thickness: 2),
                  const SizedBox(height: AppSizes.paddingMedium),
                ],

                // Nearest stations section
                Text(
                  'Nearest Stations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.darkGrey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.paddingSmall),
                
                if (_isLoadingNearest)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSizes.paddingLarge),
                      child: CircularProgressIndicator(
                        color: AppColors.londonRed,
                      ),
                    ),
                  )
                else if (_nearestStations.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingLarge),
                      child: Text(
                        'No stations found nearby',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.darkGrey.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  )
                else
                  ..._nearestStations.where((station) {
                    // Filter out stations that are already saved
                    return !_savedStations.any((s) => s.id == station.id);
                  }).map((station) {
                    return CycleStationCard(
                      station: station,
                      onTap: () => _navigateToStationDetail(station),
                      onAddRemove: () async {
                        await CycleStorageService.addStation(station);
                        await _loadSavedStations();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added ${station.name}'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      isSaved: false,
                    );
                  }),

                const SizedBox(height: AppSizes.paddingLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

