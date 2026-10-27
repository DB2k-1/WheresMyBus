import 'package:flutter/material.dart';
import 'package:wheres_my_bus/models/bus_arrival.dart';
import 'package:wheres_my_bus/utils/constants.dart';
import 'package:wheres_my_bus/services/bus_sequence_service.dart';
import 'package:wheres_my_bus/utils/stop_name.dart';

/// Groups arrivals into one list per route and destination, in order of the
/// next bus on each.
List<List<BusArrival>> groupArrivalsByRoute(List<BusArrival> arrivals) {
  final Map<String, List<BusArrival>> groups = {};
  for (final arrival in arrivals) {
    groups
        .putIfAbsent('${arrival.lineName}|${arrival.destination}', () => [])
        .add(arrival);
  }
  final list = groups.values.toList();
  for (final group in list) {
    group.sort((a, b) => a.expectedArrival.compareTo(b.expectedArrival));
  }
  list.sort((a, b) => a.first.expectedArrival.compareTo(b.first.expectedArrival));
  return list;
}

/// One route at a stop: the next bus large, the ones after it alongside.
/// Tapping it shows where the bus is now.
class RouteArrivalsCard extends StatelessWidget {
  /// Buses on the same route and destination, soonest first.
  final List<BusArrival> arrivals;
  final VoidCallback? onTap;

  const RouteArrivalsCard({super.key, required this.arrivals, this.onTap});

  @override
  Widget build(BuildContext context) {
    final BusArrival next = arrivals.first;
    final List<BusArrival> later = arrivals.skip(1).take(3).toList();
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: Row(
            children: [
              // Route number
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: AppColors.londonRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(22.5),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        next.lineName,
                        style: const TextStyle(
                          color: AppColors.londonRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppSizes.paddingMedium),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      next.destination.isNotEmpty
                          ? 'To ${next.destination}'
                          : 'Route ${next.lineName}',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.darkGrey,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    _buildFinalDestination(context, next.lineName, next.currentStopCode),
                    if (later.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Then ${later.map((a) => a.formattedTime).join(', ')}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.darkGrey.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                    if (next.vehicleId.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.my_location,
                              size: 14, color: AppColors.londonBlue),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Where is it now?',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.londonBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: AppSizes.paddingSmall),

              // Next bus
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMedium,
                  vertical: AppSizes.paddingSmall,
                ),
                decoration: BoxDecoration(
                  color: waitColor(next.timeToStation),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                ),
                child: Text(
                  next.formattedTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color waitColor(int seconds) {
    if (seconds < 30) return Colors.green;
    if (seconds < 300) return Colors.orange; // Less than 5 minutes
    return AppColors.londonRed;
  }

  Widget _buildFinalDestination(BuildContext context, String route, String currentStopCode) {
    final finalDestination = BusSequenceService.getFinalDestination(route, currentStopCode);

    if (finalDestination.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        'Final stop: ${StopName.clean(finalDestination.first)}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.darkGrey.withValues(alpha: 0.6),
              fontSize: 12,
            ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
