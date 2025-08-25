import 'package:flutter/material.dart';
import 'package:wheres_my_bus/screens/add_bus_stops_screen.dart';
import 'package:wheres_my_bus/screens/bus_stop_detail_screen.dart';
import 'package:wheres_my_bus/services/storage_service.dart';
import 'package:wheres_my_bus/utils/constants.dart';
import 'package:wheres_my_bus/widgets/bus_stop_card.dart';
import 'package:wheres_my_bus/widgets/logo_placeholder.dart';
import 'package:wheres_my_bus/widgets/banner_ad_placeholder.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _userBusStops = [];

  @override
  void initState() {
    super.initState();
    _loadUserBusStops();
  }

  Future<void> _loadUserBusStops() async {
    try {
      final stops = await StorageService.loadBusStops();
      setState(() {
        _userBusStops = stops;
      });
    } catch (e) {
      // Silently handle errors - just show empty state
      setState(() {
        _userBusStops = [];
      });
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

  void _navigateToBusStopDetail(dynamic busStop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BusStopDetailScreen(busStop: busStop),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          // Logo placeholder at top
          const LogoPlaceholder(),
          
          // Main content area
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Header with + button
                  Container(
                    padding: const EdgeInsets.all(AppSizes.paddingLarge),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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

                      ],
                    ),
                  ),
                  
                  // Bus stops list or empty state
                  Expanded(
                    child: _userBusStops.isEmpty
                        ? _buildEmptyState()
                        : _buildBusStopsList(),
                  ),
                ],
              ),
            ),
          ),
          
          // Banner ad placeholder at bottom
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

  Widget _buildBusStopsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
      itemCount: _userBusStops.length,
      itemBuilder: (context, index) {
        final busStop = _userBusStops[index];
        return Dismissible(
          key: ValueKey(busStop.naptanAtco),
          direction: DismissDirection.endToStart, // Right to left swipe

          onDismissed: (direction) async {
            // Store context before async operation
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            final busStopName = busStop.stopName;
            
            // Remove the bus stop
            await StorageService.removeBusStop(busStop.naptanAtco);
            // Update the local list immediately for smooth UI
            setState(() {
              _userBusStops.removeAt(index);
            });
            // Show confirmation message
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
                      // Add the bus stop back
                      await StorageService.addBusStop(busStop);
                      // Refresh the list
                      _loadUserBusStops();
                    },
                  ),
                ),
              );
            }
          },
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
            // Remove the onRemove since we're using swipe now
          ),
        );
      },
    );
  }
}
