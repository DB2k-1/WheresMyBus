import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wheres_my_bus/models/bus_arrival.dart';
import 'package:wheres_my_bus/services/tfl_api_service.dart';
import 'package:wheres_my_bus/utils/constants.dart';
import 'package:wheres_my_bus/utils/stop_name.dart';

/// Shows where a bus on this route is now: how many stops away it is, the
/// stop it's heading for, and the stops between it and yours.
Future<void> showBusTrackerSheet(
  BuildContext context, {
  required List<BusArrival> arrivals,
  required String stopNaptan,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: BoxConstraints(
      maxWidth: 600,
      maxHeight: MediaQuery.sizeOf(context).height * 0.85,
    ),
    builder: (_) => BusTrackerSheet(arrivals: arrivals, stopNaptan: stopNaptan),
  );
}

class BusTrackerSheet extends StatefulWidget {
  /// Buses on one route and destination, soonest first.
  final List<BusArrival> arrivals;
  final String stopNaptan;

  const BusTrackerSheet({
    super.key,
    required this.arrivals,
    required this.stopNaptan,
  });

  @override
  State<BusTrackerSheet> createState() => _BusTrackerSheetState();
}

class _BusTrackerSheetState extends State<BusTrackerSheet> {
  late final List<BusArrival> _buses =
      widget.arrivals.where((a) => a.vehicleId.isNotEmpty).take(4).toList();
  int _selected = 0;
  List<VehicleStop>? _stops;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_buses.isEmpty) return;
    final String vehicleId = _buses[_selected].vehicleId;
    try {
      final stops = await TflApiService.getVehicleStops(vehicleId);
      if (!mounted || _buses[_selected].vehicleId != vehicleId) return;
      setState(() {
        _stops = stops;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Couldn\'t get this bus\'s position. Trying again shortly.');
    }
  }

  void _select(int index) {
    if (index == _selected) return;
    setState(() {
      _selected = index;
      _stops = null;
      _error = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final BusArrival first = widget.arrivals.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingLarge,
        0,
        AppSizes.paddingLarge,
        AppSizes.paddingLarge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            first.destination.isNotEmpty
                ? '${first.lineName} to ${first.destination}'
                : 'Route ${first.lineName}',
            style: textTheme.titleLarge?.copyWith(
              color: AppColors.darkGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_buses.length > 1) ...[
            const SizedBox(height: AppSizes.paddingSmall),
            Wrap(
              spacing: AppSizes.paddingSmall,
              runSpacing: AppSizes.paddingSmall,
              children: [
                for (int i = 0; i < _buses.length; i++)
                  ChoiceChip(
                    label: Text(i == 0
                        ? 'Next bus · ${_buses[i].formattedTime}'
                        : _buses[i].formattedTime),
                    selected: i == _selected,
                    onSelected: (_) => _select(i),
                    selectedColor: AppColors.londonRed.withValues(alpha: 0.15),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSizes.paddingMedium),
          Flexible(child: _buildBody(textTheme)),
        ],
      ),
    );
  }

  Widget _buildBody(TextTheme textTheme) {
    if (_buses.isEmpty) {
      return _message(textTheme, 'Live position isn\'t available for this bus.');
    }
    if (_error != null) return _message(textTheme, _error!);
    final List<VehicleStop>? stops = _stops;
    if (stops == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSizes.paddingLarge),
        child: Center(child: CircularProgressIndicator(color: AppColors.londonRed)),
      );
    }

    final int yours = stops.indexWhere((s) => s.naptanAtco == widget.stopNaptan);
    if (stops.isEmpty || yours < 0) {
      // TfL drops a stop from the bus's list once it has reached it.
      return _message(
        textTheme,
        _buses[_selected].timeToStation < 120
            ? 'This bus is at your stop or has just left it.'
            : 'TfL isn\'t showing where this bus is right now.',
      );
    }

    final VehicleStop heading = stops.first;
    final String headline = switch (yours) {
      0 => 'Your stop is next',
      1 => '1 stop away',
      _ => '$yours stops away',
    };
    final String detail = yours == 0
        ? (heading.timeToStation < 60 ? 'Arriving now' : 'Arriving in ${BusArrival.formatWait(heading.timeToStation)}')
        : heading.timeToStation < 60
            ? 'Arriving at ${StopName.clean(heading.name)}'
            : 'Heading for ${StopName.clean(heading.name)}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headline,
          style: textTheme.headlineSmall?.copyWith(
            color: AppColors.londonRed,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          detail,
          style: textTheme.bodyLarge?.copyWith(color: AppColors.darkGrey),
        ),
        const SizedBox(height: AppSizes.paddingMedium),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: yours + 1,
            itemBuilder: (context, i) => _TimelineRow(
              stop: stops[i],
              isBus: i == 0,
              isYours: i == yours,
              isLast: i == yours,
            ),
          ),
        ),
      ],
    );
  }

  Widget _message(TextTheme textTheme, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingMedium),
      child: Text(
        text,
        style: textTheme.bodyLarge?.copyWith(color: AppColors.darkGrey),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final VehicleStop stop;
  final bool isBus;
  final bool isYours;
  final bool isLast;

  const _TimelineRow({
    required this.stop,
    required this.isBus,
    required this.isYours,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color lineColor = AppColors.londonRed.withValues(alpha: 0.3);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Expanded(
                  child: Container(width: 3, color: isBus ? Colors.transparent : lineColor),
                ),
                if (isBus)
                  const Icon(Icons.directions_bus, color: AppColors.londonRed, size: 22)
                else
                  Container(
                    width: isYours ? 16 : 10,
                    height: isYours ? 16 : 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isYours ? AppColors.londonRed : Colors.white,
                      border: Border.all(color: AppColors.londonRed, width: 2),
                    ),
                  ),
                Expanded(
                  child: Container(width: 3, color: isLast ? Colors.transparent : lineColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.paddingSmall),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        StopName.clean(stop.name),
                        if (stop.indicator != null) '(${stop.indicator})',
                      ].join(' '),
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.darkGrey,
                        fontWeight: isYours || isBus ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingSmall),
                  Text(
                    isYours ? 'Your stop · ${BusArrival.formatWait(stop.timeToStation)}'
                        : BusArrival.formatWait(stop.timeToStation),
                    style: textTheme.bodyMedium?.copyWith(
                      color: isYours ? AppColors.londonRed : AppColors.darkGrey.withValues(alpha: 0.7),
                      fontWeight: isYours ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
