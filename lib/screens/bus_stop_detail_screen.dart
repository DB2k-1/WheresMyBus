import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wheres_my_bus/models/bus_arrival.dart';
import 'package:wheres_my_bus/services/tfl_api_service.dart';
import 'package:wheres_my_bus/services/custom_direction_service.dart';
import 'package:wheres_my_bus/services/location_service.dart';
import 'package:wheres_my_bus/utils/constants.dart';
import 'package:wheres_my_bus/widgets/bus_arrival_card.dart';
import 'package:wheres_my_bus/widgets/banner_ad_placeholder.dart';
import 'package:wheres_my_bus/widgets/bus_tracker_sheet.dart';
import 'package:wheres_my_bus/widgets/detail_pane_scope.dart';
import 'package:wheres_my_bus/widgets/edit_direction_dialog.dart';
import 'package:wheres_my_bus/utils/stop_name.dart';
import 'package:wheres_my_bus/widgets/interchange_badges.dart';

class BusStopDetailScreen extends StatefulWidget {
  final dynamic busStop;

  /// Shown in the home screen's detail pane rather than pushed: no back
  /// button, and no banner (the list pane has one).
  final bool embedded;

  /// Called when the user changes this stop's direction label.
  final VoidCallback? onDirectionChanged;

  const BusStopDetailScreen({
    super.key,
    required this.busStop,
    this.embedded = false,
    this.onDirectionChanged,
  });

  @override
  State<BusStopDetailScreen> createState() => _BusStopDetailScreenState();
}

class _BusStopDetailScreenState extends State<BusStopDetailScreen> {
  List<BusArrival> _busArrivals = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;
  // Redraws the countdowns between refreshes.
  Timer? _tickTimer;
  String _displayDirection = '';
  // How the stop is labelled on the street (letter, "towards").
  StopInfo? _stopInfo;
  // Where the stop is from the user, when their location is available.
  double? _distanceMetres;
  double? _bearingDegrees;

  @override
  void initState() {
    super.initState();
    _loadDisplayDirection();
    _loadBusArrivals();
    _loadDistance();
    _startAutoRefresh();
  }

  Future<void> _loadDisplayDirection() async {
    final customDirection = await CustomDirectionService.getCustomDirection(widget.busStop.naptanAtco);
    if (!mounted) return;
    setState(() {
      _displayDirection = customDirection ?? widget.busStop.userFriendlyDirection;
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadBusArrivals();
        _loadDistance();
      }
    });
    _tickTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted && _busArrivals.isNotEmpty) setState(() {});
    });
  }

  /// Distance and compass direction from the user to the stop. Left blank
  /// if their location isn't available.
  Future<void> _loadDistance() async {
    try {
      final grid = await LocationService.getUKGridCoordinates();
      final double dE = widget.busStop.locationEasting - grid['easting']!;
      final double dN = widget.busStop.locationNorthing - grid['northing']!;
      final double bearing = (math.atan2(dE, dN) * 180 / math.pi + 360) % 360;
      if (!mounted) return;
      setState(() {
        _distanceMetres = math.sqrt(dE * dE + dN * dN);
        _bearingDegrees = bearing;
      });
    } catch (_) {
      // No location: the distance line just isn't shown.
    }
  }

  Future<void> _loadBusArrivals() async {
    if (!mounted) return;
    
    // Only the first load shows a spinner; refreshes update the list in
    // place instead of flashing it.
    if (_busArrivals.isEmpty) setState(() => _isLoading = true);

    try {
      final result = await TflApiService.getStopArrivals(widget.busStop.naptanAtco);
      if (mounted) {
        setState(() {
          _busArrivals = result.arrivals;
          _stopInfo = result.stop ?? _stopInfo;
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

    if (result != null && mounted) {
      setState(() {
        _displayDirection = result;
      });
      widget.onDirectionChanged?.call();
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
    if (!widget.embedded) DetailPaneScope.closeIfPaneShown(context);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Where\'s My Bus?'),
        backgroundColor: AppColors.londonRed,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: !widget.embedded,
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
            child: SafeArea(
              top: false,
              // The banner keeps clear of the bottom inset when there is one.
              bottom: widget.embedded,
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
                            _buildStopFlag(),
                            const SizedBox(width: AppSizes.paddingSmall),
                            Expanded(
                              child: Text(
                                widget.busStop.displayName,
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.darkGrey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.paddingSmall),
                        // Wraps onto two lines in a narrow pane.
                        Wrap(
                          spacing: AppSizes.paddingMedium,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (widget.busStop.busStopCode.isNotEmpty && widget.busStop.busStopCode != 'NONE')
                              Text(
                                'Stop Code: ${widget.busStop.busStopCode}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.darkGrey.withValues(alpha: 0.7),
                                ),
                              ),
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
                        if ((widget.busStop.interchanges as Set).isNotEmpty) ...[
                          const SizedBox(height: AppSizes.paddingSmall),
                          InterchangeBadges(
                            interchanges: widget.busStop.interchanges as Set<Interchange>,
                            large: true,
                          ),
                        ],
                        if (_stopInfo?.towards != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Towards ${_stopInfo!.towards}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.darkGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (_distanceMetres != null) ...[
                          const SizedBox(height: AppSizes.paddingSmall),
                          _buildDistance(),
                        ],
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
                        if (_distanceMetres == null && widget.busStop.distance != null) ...[
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
          ),
          
          // Banner advert at the bottom
          if (!widget.embedded) const BannerAdPlaceholder(),
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
      children: [
        for (final group in groupArrivalsByRoute(_busArrivals))
          RouteArrivalsCard(
            arrivals: group,
            onTap: () => showBusTrackerSheet(
              context,
              arrivals: group,
              stopNaptan: widget.busStop.naptanAtco,
            ),
          ),
      ],
    );
  }

  /// The stop's letter in a red roundel, as on the flag at the stop, or a
  /// bus icon for stops without a letter.
  Widget _buildStopFlag() {
    final String? letter = _stopInfo?.indicator;
    if (letter == null || letter.length > 3) {
      return const Icon(Icons.directions_bus, color: AppColors.londonRed, size: 24);
    }
    return Semantics(
      label: 'Stop $letter',
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.londonRed,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// "120 m away · north-east", with an arrow pointing that way (north up).
  Widget _buildDistance() {
    final double metres = _distanceMetres!;
    final double bearing = _bearingDegrees ?? 0;
    final String distance = metres < 1000
        ? '${(metres / 10).round() * 10} m away'
        : '${(metres * 0.000621371).toStringAsFixed(1)} miles away';
    const List<String> compass = [
      'north', 'north-east', 'east', 'south-east',
      'south', 'south-west', 'west', 'north-west',
    ];
    final String direction = compass[((bearing + 22.5) % 360 ~/ 45)];
    return Row(
      children: [
        Transform.rotate(
          angle: bearing * math.pi / 180,
          child: const Icon(Icons.navigation, size: 18, color: AppColors.londonBlue),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            metres < 25 ? 'You\'re at this stop' : '$distance · $direction',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.darkGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
