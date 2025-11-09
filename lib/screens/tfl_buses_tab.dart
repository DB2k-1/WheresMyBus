import 'package:flutter/material.dart';
import 'package:wheres_my_bus/screens/add_bus_stops_screen.dart';
import 'package:wheres_my_bus/screens/bus_stop_detail_screen.dart';
import 'package:wheres_my_bus/services/storage_service.dart';
import 'package:wheres_my_bus/utils/constants.dart';
import 'package:wheres_my_bus/widgets/bus_stop_card.dart';
import 'package:wheres_my_bus/widgets/weather_widget.dart';
import 'package:wheres_my_bus/widgets/route_planner_card.dart';

class TflBusesTab extends StatefulWidget {
  const TflBusesTab({super.key});

  @override
  State<TflBusesTab> createState() => _TflBusesTabState();
}

class _TflBusesTabState extends State<TflBusesTab> {
  List<dynamic> _userBusStops = [];
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
      if (mounted) {
        setState(() {
          _userBusStops = stops;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userBusStops = [];
          _isLoading = false;
        });
      }
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
        const SliverToBoxAdapter(
          child: RoutePlannerCard(),
        ),
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
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final busStop = _userBusStops[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == _userBusStops.length - 1
                          ? AppSizes.paddingLarge
                          : AppSizes.paddingMedium,
                    ),
                    child: Dismissible(
                      key: ValueKey(busStop.naptanAtco),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final busStopName = busStop.stopName;
                        
                        await StorageService.removeBusStop(busStop.naptanAtco);
                        setState(() {
                          _userBusStops.removeAt(index);
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
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding:
                            const EdgeInsets.only(right: AppSizes.paddingLarge),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius:
                              BorderRadius.circular(AppSizes.borderRadius),
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
                    ),
                  );
                },
                childCount: _userBusStops.length,
              ),
            ),
          ),
      ],
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

