import 'package:flutter/material.dart';
import 'package:wheres_my_bus/models/bus_stop.dart';
import 'package:wheres_my_bus/models/cycle_hire_station.dart';
import 'package:wheres_my_bus/screens/bus_stop_detail_screen.dart';
import 'package:wheres_my_bus/screens/cycle_station_detail_screen.dart';
import 'package:wheres_my_bus/utils/pane_layout.dart';

/// Lets the tabs open a stop or station. When the home screen has a detail
/// pane (two-pane or tabletop) it's shown there; otherwise it's pushed as a
/// full screen, as on a normal phone.
class DetailPaneScope extends InheritedWidget {
  /// True when the selected stop is shown alongside the list.
  final bool hasDetailPane;
  final String? selectedBusStopId;
  final String? selectedCycleStationId;

  /// Bumped when the detail pane changes something the list shows (e.g. a
  /// custom direction), so the list rebuilds.
  final int revision;

  final ValueChanged<BusStop> onSelectBusStop;
  final ValueChanged<CycleHireStation> onSelectCycleStation;
  final ValueChanged<String> onBusStopRemoved;

  const DetailPaneScope({
    super.key,
    required this.hasDetailPane,
    required this.selectedBusStopId,
    required this.selectedCycleStationId,
    required this.revision,
    required this.onSelectBusStop,
    required this.onSelectCycleStation,
    required this.onBusStopRemoved,
    required super.child,
  });

  static DetailPaneScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DetailPaneScope>();

  /// Shows [busStop] in the detail pane, or pushes it. Completes when the
  /// pushed screen is closed (immediately in the detail pane).
  ///
  /// The selection is kept either way, so if the window later gets a detail
  /// pane (rotating, unfolding, half-folding) the pushed screen closes and the
  /// stop carries on in the pane; see [closeIfPaneShown].
  static Future<void> openBusStop(BuildContext context, BusStop busStop) async {
    final scope = context.getInheritedWidgetOfExactType<DetailPaneScope>();
    scope?.onSelectBusStop(busStop);
    if (scope != null && scope.hasDetailPane) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BusStopDetailScreen(busStop: busStop)),
    );
  }

  static Future<void> openCycleStation(
    BuildContext context,
    CycleHireStation station,
  ) async {
    final scope = context.getInheritedWidgetOfExactType<DetailPaneScope>();
    scope?.onSelectCycleStation(station);
    if (scope != null && scope.hasDetailPane) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CycleStationDetailScreen(station: station),
      ),
    );
  }

  /// Called from a pushed (full-screen) detail screen's build: once the
  /// window has room for the home screen's detail pane, closes it so the
  /// same stop shows in the pane instead.
  static void closeIfPaneShown(BuildContext context) {
    if (!PaneLayout.of(context).twoPane) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final route = ModalRoute.of(context);
      // Leave it if something (e.g. the edit direction dialog) is on top.
      if (route != null && route.isCurrent) Navigator.of(context).pop();
    });
  }

  @override
  bool updateShouldNotify(DetailPaneScope oldWidget) =>
      hasDetailPane != oldWidget.hasDetailPane ||
      selectedBusStopId != oldWidget.selectedBusStopId ||
      selectedCycleStationId != oldWidget.selectedCycleStationId ||
      revision != oldWidget.revision;
}
