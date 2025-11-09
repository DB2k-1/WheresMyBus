import 'package:flutter/material.dart';
import 'package:wheres_my_bus/models/bus_stop.dart';
import 'package:wheres_my_bus/models/journey_stop.dart';
import 'package:wheres_my_bus/models/route_plan.dart';
import 'package:wheres_my_bus/services/route_planner_service.dart';
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

        if (plans.isNotEmpty) {
          return RouteSearchResult(
            plans: plans,
            resolvedOrigin: originStop,
            resolvedDestination: destinationStop,
          );
        }
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
    );
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
                    resolvedOrigin: result?.resolvedOrigin,
                    resolvedDestination: result?.resolvedDestination,
                    searchTime: _searchTime,
                  );
                }
                final plan = plans[index - 1];
                return _RoutePlanCard(
                  plan: plan,
                  searchTime: _searchTime,
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
    this.resolvedOrigin,
    this.resolvedDestination,
  });

  final JourneyStop origin;
  final JourneyStop destination;
  final DateTime searchTime;
  final BusStop? resolvedOrigin;
  final BusStop? resolvedDestination;

  @override
  Widget build(BuildContext context) {
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
            'Route options',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGrey,
                ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          _StopSummary(
            label: 'Start',
            selection: origin,
            resolvedStop: resolvedOrigin,
            icon: Icons.play_arrow_rounded,
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          _StopSummary(
            label: 'Destination',
            selection: destination,
            resolvedStop: resolvedDestination,
            icon: Icons.flag,
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          Text(
            'Departing around ${_formatTime(searchTime)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkGrey.withOpacity(0.7),
                ),
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
  });

  final String label;
  final JourneyStop selection;
  final BusStop? resolvedStop;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
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
              if ((selection.subtitle ?? '').isNotEmpty)
                Text(
                  selection.subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.darkGrey.withOpacity(0.7),
                      ),
                ),
              if (resolvedStop != null)
                Text(
                  'Stop code: ${resolvedStop!.busStopCode}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.darkGrey.withOpacity(0.6),
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoutePlanCard extends StatelessWidget {
  const _RoutePlanCard({
    required this.plan,
    required this.searchTime,
  });

  final RoutePlan plan;
  final DateTime searchTime;

  @override
  Widget build(BuildContext context) {
    final arrivalTime = plan.estimatedArrivalTime;
    final durationLabel = _formatDuration(plan.totalTravelMinutes);

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
                  durationLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGrey,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            Text(
              'Arrive around ${arrivalTime != null ? _formatTime(arrivalTime) : '—'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkGrey.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            ...plan.legs.map(
              (leg) => _RouteLegTile(
                leg: leg,
                departureFallback: _formatTime(searchTime),
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
    required this.departureFallback,
  });

  final RouteLeg leg;
  final String departureFallback;

  @override
  Widget build(BuildContext context) {
    final departureTime =
        leg.estimatedDepartureTime != null ? _formatTime(leg.estimatedDepartureTime!) : departureFallback;
    final arrivalTime = leg.estimatedArrivalTime != null
        ? _formatTime(leg.estimatedArrivalTime!)
        : '—';
    final stopCount = leg.stopCount;

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
                      '$stopCount stop${stopCount == 1 ? '' : 's'} · depart around $departureTime · arrive around $arrivalTime',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.darkGrey.withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          Container(
            padding: const EdgeInsets.all(AppSizes.paddingSmall),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.borderRadius / 2),
              border: Border.all(
                color: AppColors.londonRed.withOpacity(0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next buses (estimate)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkGrey,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Live options will appear here once countdown lookups are added.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.darkGrey.withOpacity(0.6),
                      ),
                ),
              ],
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
  });

  final List<RoutePlan> plans;
  final BusStop? resolvedOrigin;
  final BusStop? resolvedDestination;
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

