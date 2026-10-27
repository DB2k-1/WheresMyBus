import 'package:flutter/material.dart';
import 'package:wheres_my_bus/models/bus_stop.dart';
import 'package:wheres_my_bus/models/cycle_hire_station.dart';
import 'package:wheres_my_bus/screens/bus_stop_detail_screen.dart';
import 'package:wheres_my_bus/screens/cycle_station_detail_screen.dart';
import 'package:wheres_my_bus/screens/tfl_buses_tab.dart';
import 'package:wheres_my_bus/screens/santander_cycles_tab.dart';
import 'package:wheres_my_bus/utils/constants.dart';
import 'package:wheres_my_bus/utils/pane_layout.dart';
import 'package:wheres_my_bus/utils/screenshot_mode.dart';
import 'package:wheres_my_bus/widgets/detail_pane_scope.dart';
import 'package:wheres_my_bus/widgets/logo_placeholder.dart';
import 'package:wheres_my_bus/widgets/banner_ad_placeholder.dart';
import 'package:wheres_my_bus/widgets/data_status_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Keeps the tabs (their lists, scroll position and loading state) when the
  // layout switches between one column and two panes.
  final GlobalKey _listColumnKey = GlobalKey();

  // What the detail pane shows for each tab in two-pane / tabletop.
  BusStop? _selectedBusStop;
  CycleHireStation? _selectedCycleStation;
  int _detailRevision = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: screenshotView == 'cycles' ? 1 : 0,
    );
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PaneLayout layout = PaneLayout.of(context);

    return DetailPaneScope(
      hasDetailPane: layout.twoPane,
      selectedBusStopId: layout.twoPane ? _selectedBusStop?.naptanAtco : null,
      selectedCycleStationId: layout.twoPane ? _selectedCycleStation?.id : null,
      revision: _detailRevision,
      onSelectBusStop: (stop) => setState(() => _selectedBusStop = stop),
      onSelectCycleStation: (station) =>
          setState(() => _selectedCycleStation = station),
      onBusStopRemoved: (id) {
        if (_selectedBusStop?.naptanAtco == id) {
          setState(() => _selectedBusStop = null);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: layout.isTabletop
            ? _buildTabletop(context, layout)
            : layout.twoPane
            ? _buildSideBySide(context, layout)
            : _buildListColumn(adPlacement: 'bottom'),
      ),
    );
  }

  /// Stop list on the left, selected stop on the right.
  Widget _buildSideBySide(BuildContext context, PaneLayout layout) {
    final EdgeInsets insets = MediaQuery.paddingOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: insets.left + layout.leading,
          child: MediaQuery.removePadding(
            context: context,
            removeRight: true,
            child: _buildListColumn(adPlacement: 'side'),
          ),
        ),
        SizedBox(width: layout.gap),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            child: _buildDetailPane(),
          ),
        ),
      ],
    );
  }

  /// Half-folded with the fold across the screen: selected stop in the top
  /// half, stop list and ad in the bottom half.
  Widget _buildTabletop(BuildContext context, PaneLayout layout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: layout.tabletopTop,
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: _buildDetailPane(),
          ),
        ),
        SizedBox(height: layout.gap),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: _buildListColumn(adPlacement: 'tabletop', compact: true),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailPane() {
    final bool busesTab = _tabController.index == 0;
    final BusStop? busStop = _selectedBusStop;
    final CycleHireStation? station = _selectedCycleStation;

    if (busesTab && busStop != null) {
      return BusStopDetailScreen(
        key: ValueKey('bus-${busStop.naptanAtco}'),
        busStop: busStop,
        embedded: true,
        onDirectionChanged: () => setState(() => _detailRevision++),
      );
    }
    if (!busesTab && station != null) {
      return CycleStationDetailScreen(
        key: ValueKey('cycle-${station.id}'),
        station: station,
        embedded: true,
      );
    }
    return _buildEmptyDetail(busesTab);
  }

  Widget _buildEmptyDetail(bool busesTab) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                busesTab ? Icons.directions_bus_outlined : Icons.pedal_bike,
                size: 64,
                color: AppColors.londonRed.withValues(alpha: 0.5),
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              Text(
                busesTab
                    ? 'Choose a bus stop to see its arrivals'
                    : 'Choose a station to see bikes and docks',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.darkGrey.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Logo, data status, tabs and the banner ad. The whole screen on a phone,
  /// the leading pane in two-pane, the bottom half in tabletop.
  ///
  /// [adPlacement] gives the banner a new identity when it moves between
  /// layouts, so a fresh ad is loaded for its new slot rather than moving a
  /// live ad view around the tree.
  Widget _buildListColumn({required String adPlacement, bool compact = false}) {
    return Column(
      key: _listColumnKey,
      children: [
        LogoPlaceholder(compact: compact),

        const DataStatusBanner(),

        // Main content area with tabs
        Expanded(
          child: SafeArea(
            top: false,
            bottom: false,
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
                      unselectedLabelColor: AppColors.darkGrey.withValues(
                        alpha: 0.6,
                      ),
                      indicatorColor: AppColors.londonRed,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      // Labels shrink to fit a narrow pane.
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.directions_bus),
                          iconMargin: EdgeInsets.only(bottom: 4),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('TfL Buses'),
                          ),
                        ),
                        Tab(
                          icon: Icon(Icons.pedal_bike),
                          iconMargin: EdgeInsets.only(bottom: 4),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Santander Cycles'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: const [TflBusesTab(), SantanderCyclesTab()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Banner ad at the bottom of the list
        BannerAdPlaceholder(
          key: ValueKey('banner-$adPlacement'),
          allowLarge: !compact,
        ),
      ],
    );
  }
}
