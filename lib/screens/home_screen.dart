import 'package:flutter/material.dart';
import 'package:wheres_my_bus/screens/tfl_buses_tab.dart';
import 'package:wheres_my_bus/screens/santander_cycles_tab.dart';
import 'package:wheres_my_bus/utils/constants.dart';
import 'package:wheres_my_bus/widgets/logo_placeholder.dart';
import 'package:wheres_my_bus/widgets/banner_ad_placeholder.dart';
import 'package:wheres_my_bus/widgets/data_status_banner.dart';
import 'package:wheres_my_bus/services/app_rating_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Where\'s My Bus?',
      applicationVersion: '1.04.1',
      applicationIcon: const Icon(
        Icons.directions_bus,
        size: 48,
        color: AppColors.londonRed,
      ),
      children: [
        const Text(
          'London bus tracking app - find your nearest bus stops and real-time arrivals.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Features:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Text('• Real-time bus arrivals'),
        const Text('• Nearby bus stops'),
        const Text('• Santander Cycles integration'),
        const Text('• Offline bus stop data'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text(
          'Where\'s My Bus?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.londonRed,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'rate_app':
                  await AppRatingService.requestRatingManually(context);
                  break;
                case 'about':
                  _showAboutDialog(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'rate_app',
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('Rate App'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('About'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Logo placeholder at top
          const LogoPlaceholder(),
          
          // Data status banner
          const DataStatusBanner(),
          
          // Main content area with tabs
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
                  // Tab bar
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.darkGrey.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.londonRed,
                      unselectedLabelColor: AppColors.darkGrey.withValues(alpha: 0.6),
                      indicatorColor: AppColors.londonRed,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.directions_bus),
                          text: 'TfL Buses',
                          iconMargin: EdgeInsets.only(bottom: 4),
                        ),
                        Tab(
                          icon: Icon(Icons.pedal_bike),
                          text: 'Santander Cycles',
                          iconMargin: EdgeInsets.only(bottom: 4),
                        ),
                      ],
                    ),
                  ),
                  
                  // Tab views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: const [
                        TflBusesTab(),
                        SantanderCyclesTab(),
                      ],
                    ),
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
}
