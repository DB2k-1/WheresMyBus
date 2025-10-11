import 'package:flutter/material.dart';
import 'package:wheres_my_bus/screens/tfl_buses_tab.dart';
import 'package:wheres_my_bus/screens/santander_cycles_tab.dart';
import 'package:wheres_my_bus/utils/constants.dart';
import 'package:wheres_my_bus/widgets/logo_placeholder.dart';
import 'package:wheres_my_bus/widgets/banner_ad_placeholder.dart';
import 'package:wheres_my_bus/widgets/data_status_banner.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
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
                        ),
                        Tab(
                          icon: Icon(Icons.pedal_bike),
                          text: 'Santander Cycles',
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
