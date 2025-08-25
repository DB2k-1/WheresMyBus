import 'package:flutter/material.dart';
import 'package:wheres_my_bus/models/bus_arrival.dart';
import 'package:wheres_my_bus/utils/constants.dart';
import 'package:wheres_my_bus/services/bus_sequence_service.dart';

class BusArrivalCard extends StatelessWidget {
  final BusArrival arrival;

  const BusArrivalCard({super.key, required this.arrival});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Row(
          children: [
            // Bus route icon
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: AppColors.londonRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(22.5),
              ),
              child: Center(
                child: Text(
                  arrival.lineName,
                  style: TextStyle(
                    color: AppColors.londonRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: AppSizes.paddingMedium),
            
            // Bus arrival details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Route ${arrival.lineName}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.darkGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingSmall),
                  if (arrival.destination.isNotEmpty) ...[
                    Text(
                      'To: ${arrival.destination}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.darkGrey.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildFinalDestination(context, arrival.lineName, arrival.currentStopCode),
                  ],
                ],
              ),
            ),
            
            // Arrival time
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMedium,
                vertical: AppSizes.paddingSmall,
              ),
              decoration: BoxDecoration(
                color: _getTimeColor(),
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              ),
              child: Text(
                arrival.formattedTime,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTimeColor() {
    if (arrival.timeToStation <= 0) return Colors.green;
    if (arrival.timeToStation < 300) return Colors.orange; // Less than 5 minutes
    return AppColors.londonRed;
  }
  
  Widget _buildFinalDestination(BuildContext context, String route, String currentStopCode) {
    final finalDestination = BusSequenceService.getFinalDestination(route, currentStopCode);
    
    if (finalDestination.isEmpty) return const SizedBox.shrink();
    
    return Text(
      'Final Stop: ${finalDestination.first}',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.darkGrey.withValues(alpha: 0.6),
        fontSize: 12,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
