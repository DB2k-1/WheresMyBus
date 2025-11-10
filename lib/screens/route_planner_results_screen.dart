import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wheres_my_bus/models/bus_stop.dart';
import 'package:wheres_my_bus/models/journey_stop.dart';
import 'package:wheres_my_bus/models/route_plan.dart';
import 'package:wheres_my_bus/services/route_planner_service.dart';
import 'package:wheres_my_bus/services/tfl_api_service.dart';
import 'package:wheres_my_bus/utils/constants.dart';

class RoutePlannerResultsScreen extends StatefulWidget {
  const RoutePlannerResultsScreen({
    super.key,
    required this.origin,
    required this.destination,
  });

  final JourneyStop origin;
  final JourneyStop destination;

  @override
  State<RoutePlannerResultsScreen> createState() =>
      _RoutePlannerResultsScreenState();
}

class _RoutePlannerResultsScreenState
    extends State<RoutePlannerResultsScreen> {
  late Future<RouteSearchResult> _routeFuture;
  DateTime _searchTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _routeFuture = _loadRoutes();
  }

  Future<RouteSearchResult> _loadRoutes() async {
    _searchTime = DateTime.now();

    for (final originStop in widget.origin.candidates) {
      for (final destinationStop in widget.destination.candidates) {
        final plans = await RoutePlannerService.planRoute(
          originNaptan: originStop.naptanAtco,
          destinationNaptan: destinationStop.naptanAtco,
          desiredDepartureTime: _searchTime,
        );

        if (plans.isEmpty) continue;

        final departures = await _loadNextDepartures(plans);
        final viablePlans = plans.where((plan) {
          if (plan.legs.isEmpty) return false;
          for (final leg in plan.legs) {
            final key = '${leg.origin.busStopCode}|${leg.routeId}';
            final legDepartures = departures[key];
            if (legDepartures == null || legDepartures.isEmpty) {
              return false;
            }
          }
          return true;
        }).toList();

        if (viablePlans.isEmpty) {
          continue;
        }

        final filteredDepartures = <String, List<DateTime>>{};
        for (final plan in viablePlans) {
          for (final leg in plan.legs) {
            final key = '${leg.origin.busStopCode}|${leg.routeId}';
            final legDepartures = departures[key];
            if (legDepartures != null && legDepartures.isNotEmpty) {
              filteredDepartures[key] = legDepartures;
            }
          }
        }

        return RouteSearchResult(
          plans: viablePlans,
          resolvedOrigin: originStop,
          resolvedDestination: destinationStop,
          nextDepartures: filteredDepartures,
        );
      }
    }

    return RouteSearchResult(
      plans: const [],
      resolvedOrigin: widget.origin.candidates.isNotEmpty
          ? widget.origin.candidates.first
          : null,
      resolvedDestination: widget.destination.candidates.isNotEmpty
          ? widget.destination.candidates.first
          : null,
      nextDepartures: const <String, List<DateTime>>{},
    );
  }

  Future<Map<String, List<DateTime>>> _loadNextDepartures(
    List<RoutePlan> plans,
  ) async {
    final requiredLookups = <String, _StopRouteKey>{};

    for (final plan in plans) {
      for (final leg in plan.legs) {
        final key = '${leg.origin.busStopCode}|${leg.routeId}';
        requiredLookups.putIfAbsent(
          key,
          () => _StopRouteKey(
            stop: leg.origin,
            routeId: leg.routeId,
          ),
        );
      }
    }

    final results = <String, List<DateTime>>{};

    for (final entry in requiredLookups.entries) {
      results[entry.key] = await _fetchNextDeparture(
        entry.value.stop,
        entry.value.routeId,
      );
    }

    return results;
  }

  Future<List<DateTime>> _fetchNextDeparture(
    BusStop stop,
    String routeId,
  ) async {
    try {
      final arrivals = await TflApiService.getBusArrivals(stop.busStopCode);
      if (arrivals.isEmpty) return const [];

      final now = DateTime.now();
      final matching = arrivals.where((arrival) {
        final route = arrival.routeId.toLowerCase();
        final line = arrival.lineName.toLowerCase();
        final target = routeId.toLowerCase();
        return route == target || line == target;
      }).toList();

      if (matching.isEmpty) return const [];

      matching.sort(
        (a, b) => a.timeToStation.compareTo(b.timeToStation),
      );

      final times = <DateTime>[];
      for (final arrival in matching.take(3)) {
        if (arrival.timeToStation <= 0) {
          times.add(now);
        } else {
          times.add(now.add(Duration(seconds: arrival.timeToStation)));
        }
      }
      return times;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _routeFuture = _loadRoutes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Planner'),
        backgroundColor: AppColors.londonRed,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.cream,
      body: FutureBuilder<RouteSearchResult>(
        future: _routeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: 'We couldn\'t plan that journey right now.',
              onRetry: _refresh,
            );
          }

          final result = snapshot.data;
          final plans = result?.plans ?? [];
          final nextDepartures =
              result?.nextDepartures ?? const <String, List<DateTime>>{};
          if (plans.isEmpty) {
            return _ErrorState(
              message:
                  'No routes were found between these stops.\nTry relaxing transfer limits or choosing nearby stops.',
              onRetry: _refresh,
            );
          }

          return RefreshIndicator(
            color: AppColors.londonRed,
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              itemCount: plans.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _JourneyHeader(
                    origin: widget.origin,
                    destination: widget.destination,
                    planCount: plans.length,
                    resolvedOrigin: result?.resolvedOrigin,
                    resolvedDestination: result?.resolvedDestination,
                    searchTime: _searchTime,
                  );
                }
                final plan = plans[index - 1];
                return _RoutePlanCard(
                  plan: plan,
                  searchTime: _searchTime,
                  nextDepartures: nextDepartures,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _JourneyHeader extends StatelessWidget {
  const _JourneyHeader({
    required this.origin,
    required this.destination,
    required this.searchTime,
    required this.planCount,
    this.resolvedOrigin,
    this.resolvedDestination,
  });

  final JourneyStop origin;
  final JourneyStop destination;
  final DateTime searchTime;
  final int planCount;
  final BusStop? resolvedOrigin;
  final BusStop? resolvedDestination;

  @override
  Widget build(BuildContext context) {
    final optionsLabel =
        '$planCount Route Option${planCount == 1 ? '' : 's'}';
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            optionsLabel,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGrey,
                ),
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            'Departing around ${_formatTime(searchTime)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkGrey.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          _StopSummary(
            label: 'Start',
            selection: origin,
            resolvedStop: resolvedOrigin,
            showMapLink: true,
            showSubtitle: true,
            icon: Icons.play_arrow_rounded,
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          _StopSummary(
            label: 'Destination',
            selection: destination,
            resolvedStop: resolvedDestination,
            showMapLink: false,
            showSubtitle: false,
            icon: Icons.flag,
          ),
        ],
      ),
    );
  }
}

class _StopSummary extends StatelessWidget {
  const _StopSummary({
    required this.label,
    required this.selection,
    required this.icon,
    this.resolvedStop,
    this.showMapLink = false,
    this.showSubtitle = true,
  });

  final String label;
  final JourneyStop selection;
  final BusStop? resolvedStop;
  final IconData icon;
  final bool showMapLink;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    final mapStop =
        resolvedStop ?? (selection.candidates.isNotEmpty ? selection.candidates.first : null);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.londonRed),
        const SizedBox(width: AppSizes.paddingSmall),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGrey.withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                selection.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.darkGrey,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (showSubtitle && (selection.subtitle ?? '').isNotEmpty)
                Text(
                  selection.subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.darkGrey.withOpacity(0.7),
                      ),
                ),
            ],
          ),
        ),
        if (showMapLink && mapStop != null)
          IconButton(
            icon: Icon(
              Icons.map_outlined,
              color: AppColors.londonBlue,
            ),
            tooltip: 'Open in Google Maps',
            onPressed: () => _openInMaps(mapStop),
          ),
      ],
    );
  }

  Future<void> _openInMaps(BusStop stop) async {
    final latLng = stop.getLatLng();
    final lat = latLng['latitude'];
    final lng = latLng['longitude'];

    if (lat == null || lng == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _StopRouteKey {
  const _StopRouteKey({
    required this.stop,
    required this.routeId,
  });

  final BusStop stop;
  final String routeId;
}

class _RoutePlanCard extends StatelessWidget {
  const _RoutePlanCard({
    required this.plan,
    required this.searchTime,
    required this.nextDepartures,
  });

  final RoutePlan plan;
  final DateTime searchTime;
  final Map<String, List<DateTime>> nextDepartures;

  @override
  Widget build(BuildContext context) {
    final arrivalTime = plan.estimatedArrivalTime;
    final durationLabel = _formatDuration(plan.totalTravelMinutes);
    final firstLeg = plan.legs.isNotEmpty ? plan.legs.first : null;
    final firstLegKey = firstLeg != null
        ? '${firstLeg.origin.busStopCode}|${firstLeg.routeId}'
        : null;
    final firstLegDepartures = firstLegKey != null
        ? nextDepartures[firstLegKey] ?? const <DateTime>[]
        : const <DateTime>[];
    final firstDeparture =
        firstLegDepartures.isNotEmpty ? firstLegDepartures.first : null;
    final secondDeparture =
        firstLegDepartures.length > 1 ? firstLegDepartures[1] : null;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingSmall,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.londonRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    plan.totalTransfers == 0
                        ? 'Direct route'
                        : '${plan.totalTransfers} transfer${plan.totalTransfers == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.londonRed,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Travel time: $durationLabel',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGrey,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            ...plan.legs.map(
              (leg) => _RouteLegTile(
                leg: leg,
                departures: nextDepartures[
                    '${leg.origin.busStopCode}|${leg.routeId}'],
              ),
            ),
            if (plan.legs.isEmpty)
              Text(
                'Origin and destination are the same stop.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkGrey,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RouteLegTile extends StatelessWidget {
  const _RouteLegTile({
    required this.leg,
    required this.departures,
  });

  final RouteLeg leg;
  final List<DateTime>? departures;

  @override
  Widget build(BuildContext context) {
    final stopCount = leg.stopCount;
    final list = departures ?? const <DateTime>[];
    final primary = list.isNotEmpty ? list.first : null;
    final secondary = list.length > 1 ? list[1] : null;
    final tertiary = list.length > 2 ? list[2] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.londonRed.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(
          color: AppColors.londonRed.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.londonRed.withOpacity(0.3),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  leg.routeId,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.londonRed,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(width: AppSizes.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${leg.origin.stopName} → ${leg.destination.stopName}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkGrey,
                          ),
                    ),
                    Text(
                      '$stopCount stop${stopCount == 1 ? '' : 's'}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGrey.withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          if (primary != null || secondary != null || tertiary != null)
            const SizedBox(height: AppSizes.paddingSmall),
          if (primary != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Next bus: ${_formatTime(primary)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.londonRed,
                      ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Arrival: ${leg.estimatedArrivalTime != null ? _formatTime(leg.estimatedArrivalTime!) : '—'}',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkGrey,
                              ),
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              'Arrival: ${leg.estimatedArrivalTime != null ? _formatTime(leg.estimatedArrivalTime!) : '—'}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGrey,
                  ),
            ),
          if (secondary != null)
            Text(
              'Following bus: ${_formatTime(secondary)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGrey,
                  ),
            ),
          if (tertiary != null)
            Text(
              'Later bus: ${_formatTime(tertiary)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGrey.withOpacity(0.7),
                  ),
            ),
        ],
      ),
    );
  }
}

class RouteSearchResult {
  RouteSearchResult({
    required this.plans,
    this.resolvedOrigin,
    this.resolvedDestination,
    required this.nextDepartures,
  });

  final List<RoutePlan> plans;
  final BusStop? resolvedOrigin;
  final BusStop? resolvedDestination;
  final Map<String, List<DateTime>> nextDepartures;
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bus_outlined,
              size: 64,
              color: AppColors.londonRed.withOpacity(0.4),
            ),
            const SizedBox(height: AppSizes.paddingLarge),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.darkGrey,
                  ),
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.londonRed,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

String _formatDuration(double minutes) {
  final totalSeconds = (minutes * 60).round().clamp(0, 24 * 60 * 60);
  final duration = Duration(seconds: totalSeconds);

  final hours = duration.inHours;
  final mins = duration.inMinutes.remainder(60);

  if (hours > 0) {
    return '${hours}h ${mins}m';
  }
  return '${mins}m';
}

