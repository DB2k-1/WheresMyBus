import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wheres_my_bus/models/bus_arrival.dart';
import 'package:wheres_my_bus/services/tfl_api_service.dart';
import 'package:wheres_my_bus/services/custom_direction_service.dart';
import 'package:wheres_my_bus/utils/constants.dart';
import 'package:wheres_my_bus/widgets/bus_arrival_card.dart';
import 'package:wheres_my_bus/widgets/banner_ad_placeholder.dart';
import 'package:wheres_my_bus/widgets/edit_direction_dialog.dart';

class BusStopDetailScreen extends StatefulWidget {
  final dynamic busStop;

  const BusStopDetailScreen({super.key, required this.busStop});

  @override
  State<BusStopDetailScreen> createState() => _BusStopDetailScreenState();
}

class _BusStopDetailScreenState extends State<BusStopDetailScreen> {
  List<BusArrival> _busArrivals = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;
  String _displayDirection = '';

  @override
  void initState() {
    super.initState();
    _loadDisplayDirection();
    _loadBusArrivals();
    _startAutoRefresh();
  }

  Future<void> _loadDisplayDirection() async {
    final customDirection = await CustomDirectionService.getCustomDirection(widget.busStop.naptanAtco);
    setState(() {
      _displayDirection = customDirection ?? widget.busStop.userFriendlyDirection;
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadBusArrivals();
      }
    });
  }

  Future<void> _loadBusArrivals() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final arrivals = await TflApiService.getBusArrivals(widget.busStop.naptanAtco);
      if (mounted) {
        setState(() {
          _busArrivals = arrivals;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading bus arrivals: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshArrivals() async {
    await _loadBusArrivals();
  }

  Future<void> _editDirection() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => EditDirectionDialog(
        naptanAtco: widget.busStop.naptanAtco,
        currentDirection: _displayDirection,
        originalDirection: widget.busStop.userFriendlyDirection,
      ),
    );

    if (result != null) {
      setState(() {
        _displayDirection = result;
      });
    }
  }

  Future<void> _openInMaps() async {
    // Convert UK grid coordinates to approximate lat/lng for the bus stop
    final latLng = widget.busStop.getLatLng();
    final lat = latLng['latitude'];
    final lng = latLng['longitude'];
    
    // Create Google Maps URL with directions
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng'
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open maps'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening maps: $e'),
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
        title: const Text('Where\'s My Bus?'),
        backgroundColor: AppColors.londonRed,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _refreshArrivals,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Main scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
              child: Column(
                children: [
                  // Bus stop info header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.paddingLarge),
                    margin: const EdgeInsets.all(AppSizes.paddingMedium),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.directions_bus,
                              color: AppColors.londonRed,
                              size: 24,
                            ),
                            const SizedBox(width: AppSizes.paddingSmall),
                            Expanded(
                              child: Text(
                                widget.busStop.stopName,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.darkGrey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.paddingSmall),
                        Row(
                          children: [
                            if (widget.busStop.busStopCode.isNotEmpty && widget.busStop.busStopCode != 'NONE')
                              Text(
                                'Stop Code: ${widget.busStop.busStopCode}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.darkGrey.withValues(alpha: 0.7),
                                ),
                              ),
                            const SizedBox(width: AppSizes.paddingMedium),
                            GestureDetector(
                              onTap: _editDirection,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.paddingSmall,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.londonRed.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.londonRed.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _displayDirection.isEmpty 
                                          ? widget.busStop.userFriendlyDirection 
                                          : _displayDirection,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppColors.londonRed,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.edit,
                                      size: 14,
                                      color: AppColors.londonRed.withValues(alpha: 0.7),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.paddingSmall),
                        GestureDetector(
                          onTap: _openInMaps,
                          child: Row(
                            children: [
                              Icon(
                                Icons.map,
                                size: 16,
                                color: AppColors.londonBlue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Open in Google Maps',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.londonBlue,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.busStop.distance != null) ...[
                          const SizedBox(height: AppSizes.paddingSmall),
                          Text(
                            'Distance: ${(widget.busStop.distance! * 0.000621371).toStringAsFixed(1)} miles',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.darkGrey.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Bus arrivals section
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSizes.paddingMedium),
                          child: Text(
                            'Bus Arrivals',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.darkGrey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        // Error message
                        if (_errorMessage != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSizes.paddingMedium),
                            margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
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
                                TextButton(
                                  onPressed: _refreshArrivals,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),

                        // Bus arrivals list
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _busArrivals.isEmpty
                                ? _buildEmptyState()
                                : _buildBusArrivalsList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Banner advert at the bottom
          const BannerAdPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 80,
            color: AppColors.londonRed.withOpacity(0.5),
          ),
          const SizedBox(height: AppSizes.paddingLarge),
          Text(
            AppStrings.noBuses,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.darkGrey,
            ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          Text(
            'No buses are currently scheduled to arrive at this stop',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.darkGrey.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBusArrivalsList() {
    return Column(
      children: _busArrivals.map((arrival) => BusArrivalCard(arrival: arrival)).toList(),
    );
  }
}
