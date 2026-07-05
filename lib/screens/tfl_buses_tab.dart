import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wheres_my_bus/models/bus_stop.dart';
import 'package:wheres_my_bus/screens/add_bus_stops_screen.dart';
import 'package:wheres_my_bus/screens/bus_stop_detail_screen.dart';
import 'package:wheres_my_bus/services/location_service.dart';
import 'package:wheres_my_bus/services/storage_service.dart';
import 'package:wheres_my_bus/utils/constants.dart';
import 'package:wheres_my_bus/widgets/bus_stop_card.dart';
import 'package:wheres_my_bus/widgets/weather_widget.dart';
import 'package:wheres_my_bus/widgets/route_planner_card.dart';

enum BusStopSortMode { added, nearest }

class TflBusesTab extends StatefulWidget {
  const TflBusesTab({super.key});

  @override
  State<TflBusesTab> createState() => _TflBusesTabState();
}

class _TflBusesTabState extends State<TflBusesTab> {
  // Source of truth: order added, or the user's last drag-and-drop order.
  List<BusStop> _userBusStops = [];
  // What's actually rendered - a distance-sorted copy when in "nearest" mode.
  List<BusStop> _displayedBusStops = [];
  BusStopSortMode _sortMode = BusStopSortMode.added;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserBusStops();
  }

  Future<void> _loadUserBusStops() async {
    setState(() => _isLoading = true);

    try {
      final stops = await StorageService.loadBusStops();
      final savedMode = await StorageService.loadSortMode();
      if (mounted) {
        setState(() {
          _userBusStops = stops;
          _sortMode = savedMode == 'nearest' ? BusStopSortMode.nearest : BusStopSortMode.added;
          _isLoading = false;
        });
        await _updateDisplayedBusStops();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userBusStops = [];
          _displayedBusStops = [];
          _isLoading = false;
        });
      }
    }
  }

  // Recomputes the rendered list for the current sort mode. In "nearest"
  // mode this is a sorted copy; the stored order is left untouched so it
  // can be restored when switching back to "added".
  Future<void> _updateDisplayedBusStops() async {
    if (_sortMode == BusStopSortMode.added) {
      if (mounted) setState(() => _displayedBusStops = List.of(_userBusStops));
      return;
    }

    try {
      final gridCoords = await LocationService.getUKGridCoordinates();
      final easting = gridCoords['easting']!;
      final northing = gridCoords['northing']!;
      final sorted = List<BusStop>.of(_userBusStops)
        ..sort((a, b) => a
            .calculateDistance(easting, northing)
            .compareTo(b.calculateDistance(easting, northing)));
      if (mounted) setState(() => _displayedBusStops = sorted);
    } catch (e) {
      // Fall back to the stored order if location isn't available
      if (mounted) setState(() => _displayedBusStops = List.of(_userBusStops));
    }
  }

  Future<void> _onSortModeChanged(BusStopSortMode? mode) async {
    if (mode == null || mode == _sortMode) return;
    setState(() => _sortMode = mode);
    await StorageService.saveSortMode(mode == BusStopSortMode.nearest ? 'nearest' : 'added');
    await _updateDisplayedBusStops();
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      final stop = _userBusStops.removeAt(oldIndex);
      _userBusStops.insert(newIndex, stop);
      _displayedBusStops = List.of(_userBusStops);
    });
    await StorageService.reorderBusStops(_userBusStops);
  }

  Future<void> _removeBusStop(BusStop busStop) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final busStopName = busStop.stopName;

    await StorageService.removeBusStop(busStop.naptanAtco);
    setState(() {
      _userBusStops.removeWhere((stop) => stop.naptanAtco == busStop.naptanAtco);
      _displayedBusStops.removeWhere((stop) => stop.naptanAtco == busStop.naptanAtco);
    });

    if (mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Removed $busStopName'),
          backgroundColor: AppColors.londonRed,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white,
            onPressed: () async {
              await StorageService.addBusStop(busStop);
              _loadUserBusStops();
            },
          ),
        ),
      );
    }
  }

  void _navigateToAddBusStops() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddBusStopsScreen(),
      ),
    );

    if (result == true) {
      _loadUserBusStops();
    }
  }

  void _navigateToBusStopDetail(dynamic busStop) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusStopDetailScreen(busStop: busStop),
      ),
    );
    // Force a rebuild to refresh custom directions
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // const SliverToBoxAdapter(
        //   child: RoutePlannerCard(),
        // ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.myBusStops,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.darkGrey,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const WeatherWidget(),
                const SizedBox(width: AppSizes.paddingSmall),
                FloatingActionButton(
                  key: const ValueKey('add_bus_stops_button'),
                  onPressed: _navigateToAddBusStops,
                  backgroundColor: AppColors.londonRed,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  mini: true,
                  child: const Icon(Icons.add, size: 20),
                ),
              ],
            ),
          ),
        ),
        if (!_isLoading && _userBusStops.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLarge,
              ),
              child: Align(
                alignment: Alignment.center,
                child: CupertinoSlidingSegmentedControl<BusStopSortMode>(
                  groupValue: _sortMode,
                  backgroundColor: AppColors.lightGrey,
                  onValueChanged: _onSortModeChanged,
                  children: const {
                    BusStopSortMode.added: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text('Order Added'),
                    ),
                    BusStopSortMode.nearest: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Text('Nearest to Me'),
                    ),
                  },
                ),
              ),
            ),
          ),
        if (!_isLoading && _userBusStops.isNotEmpty)
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSizes.paddingMedium),
          ),
        if (_isLoading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.londonRed,
              ),
            ),
          )
        else if (_userBusStops.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(),
          )
        else if (_sortMode == BusStopSortMode.added)
          _buildReorderableBusStopsList()
        else
          _buildStaticBusStopsList(),
      ],
    );
  }

  Widget _buildReorderableBusStopsList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
      sliver: SliverReorderableList(
        onReorderItem: _onReorder,
        itemBuilder: (context, index) {
          final busStop = _displayedBusStops[index];
          return Padding(
            key: ValueKey(busStop.naptanAtco),
            padding: EdgeInsets.only(
              bottom: index == _displayedBusStops.length - 1
                  ? AppSizes.paddingLarge
                  : 0,
            ),
            child: ReorderableDelayedDragStartListener(
              index: index,
              child: _buildDismissibleBusStop(busStop),
            ),
          );
        },
        itemCount: _displayedBusStops.length,
      ),
    );
  }

  Widget _buildStaticBusStopsList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final busStop = _displayedBusStops[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == _displayedBusStops.length - 1
                    ? AppSizes.paddingLarge
                    : 0,
              ),
              child: _buildDismissibleBusStop(busStop),
            );
          },
          childCount: _displayedBusStops.length,
        ),
      ),
    );
  }

  Widget _buildDismissibleBusStop(BusStop busStop) {
    return Dismissible(
      key: ValueKey('dismiss-${busStop.naptanAtco}'),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _removeBusStop(busStop),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSizes.paddingLarge),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 30,
        ),
      ),
      child: BusStopCard(
        busStop: busStop,
        onTap: () => _navigateToBusStopDetail(busStop),
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
            color: AppColors.londonRed.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSizes.paddingLarge),
          Text(
            AppStrings.noBusStops,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.darkGrey,
                ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          Text(
            AppStrings.addBusStopsMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkGrey.withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

