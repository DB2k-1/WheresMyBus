import 'package:flutter/material.dart';
import 'package:wheres_my_bus/models/bus_stop.dart';
import 'package:wheres_my_bus/services/location_service.dart';
import 'package:wheres_my_bus/services/storage_service.dart';
import 'package:wheres_my_bus/utils/constants.dart';
import 'package:wheres_my_bus/widgets/bus_stop_card.dart';

class AddBusStopsScreen extends StatefulWidget {
  const AddBusStopsScreen({super.key});

  @override
  State<AddBusStopsScreen> createState() => _AddBusStopsScreenState();
}

class _AddBusStopsScreenState extends State<AddBusStopsScreen> {
  List<BusStop> _nearbyBusStops = [];
  bool _isLoading = false;
  bool _hasLocationPermission = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    // Automatically find bus stops if we have permission
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hasLocationPermission) {
        _findNearbyBusStops();
      }
    });
  }

  Future<void> _requestLocationPermission() async {
    try {
      final hasPermission = await LocationService.requestLocationPermission();
      setState(() => _hasLocationPermission = hasPermission);
      
      // If permission granted, automatically find bus stops
      if (hasPermission) {
        _findNearbyBusStops();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error requesting location permission: $e');
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      final hasPermission = await LocationService.hasLocationPermission();
      setState(() => _hasLocationPermission = hasPermission);
      
      // If we have permission, automatically find bus stops
      if (hasPermission) {
        _findNearbyBusStops();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error checking location permission: $e');
    }
  }

  Future<void> _findNearbyBusStops() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Request location permission if not already granted
      if (!_hasLocationPermission) {
        await LocationService.requestLocationPermission();
        setState(() => _hasLocationPermission = true);
      }

      // Get more bus stops to ensure we always have 6 available
      final nearestStops = await LocationService.getNearestBusStops(20);
      
      // Filter out bus stops that are already in user's list
      final userBusStops = await StorageService.loadBusStopCodes();
      final userStopCodes = userBusStops.toSet();
      
      final availableStops = nearestStops.where((stop) => 
        !userStopCodes.contains(stop.naptanAtco)
      ).cast<BusStop>().toList();
      
      // Take the first 6 available stops
      final displayStops = availableStops.take(6).toList();
      
      setState(() {
        _nearbyBusStops = displayStops;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error finding nearby bus stops: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _findMoreBusStops() async {
    try {
      // Get more bus stops to fill up to 6
      final nearestStops = await LocationService.getNearestBusStops(30);
      
      // Filter out bus stops that are already in user's list
      final userBusStops = await StorageService.loadBusStopCodes();
      final userStopCodes = userBusStops.toSet();
      
      final availableStops = nearestStops.where((stop) => 
        !userStopCodes.contains(stop.naptanAtco) &&
        !_nearbyBusStops.any((existing) => existing.naptanAtco == stop.naptanAtco)
      ).cast<BusStop>().toList();
      
      // Add new stops to fill up to 6
      final neededStops = 6 - _nearbyBusStops.length;
      final newStops = availableStops.take(neededStops).toList();
      
      setState(() {
        _nearbyBusStops.addAll(newStops);
      });
    } catch (e) {
      // Silently handle errors when fetching more stops
    }
  }

  Future<void> _addBusStop(BusStop busStop) async {
    try {
      await StorageService.addBusStop(busStop);
      
      // Remove the added bus stop from the nearby list
      setState(() {
        _nearbyBusStops.removeWhere((stop) => stop.naptanAtco == busStop.naptanAtco);
      });
      
      // If we have fewer than 6 stops, try to fetch more
      if (_nearbyBusStops.length < 6) {
        _findMoreBusStops();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${busStop.stopName}'),
            backgroundColor: AppColors.londonRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding bus stop: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text(AppStrings.addBusStops),
        backgroundColor: AppColors.londonRed,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () {
              // Return true to indicate bus stops were added
              Navigator.of(context).pop(true);
            },
            child: const Text(
              'Done',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Location permission status
          if (!_hasLocationPermission)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              margin: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                border: Border.all(color: Colors.orange),
              ),
              child: Column(
                children: [
                  const Icon(Icons.location_off, color: Colors.orange),
                  const SizedBox(height: AppSizes.paddingSmall),
                  Text(
                    AppStrings.locationPermissionTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingSmall),
                  Text(
                    AppStrings.locationPermissionMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.orange),
                  ),
                ],
              ),
            ),



          // Error message
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: AppSizes.paddingSmall),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _errorMessage = null),
                    icon: const Icon(Icons.close, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // Bus stops list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _nearbyBusStops.isEmpty
                    ? _buildPermissionRequest()
                    : _buildBusStopsList(),
          ),
          
          // Show count of remaining bus stops
          if (_nearbyBusStops.isNotEmpty && !_isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              color: AppColors.lightGrey,
              child: Text(
                '${_nearbyBusStops.length} bus stop${_nearbyBusStops.length == 1 ? '' : 's'} available to add',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on,
            size: 80,
            color: AppColors.londonRed.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSizes.paddingLarge),
          Text(
            'Location Permission Required',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.darkGrey,
            ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          Text(
            'This app needs location access to find nearby bus stops',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.darkGrey.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.paddingLarge),
          ElevatedButton.icon(
            onPressed: _requestLocationPermission,
            icon: const Icon(Icons.location_on),
            label: const Text('Grant Location Permission'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.londonRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusStopsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      itemCount: _nearbyBusStops.length,
      itemBuilder: (context, index) {
        final busStop = _nearbyBusStops[index];
        return BusStopCard(
          busStop: busStop,
          onTap: () => _addBusStop(busStop),
          showAddButton: true,
          onAdd: () => _addBusStop(busStop),
        );
      },
    );
  }
}
