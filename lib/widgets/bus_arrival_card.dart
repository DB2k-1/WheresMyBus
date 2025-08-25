import 'package:flutter/material.dart';
import 'package:wheres_my_bus/models/bus_arrival.dart';
import 'package:wheres_my_bus/utils/constants.dart';

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
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.londonRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  arrival.lineName,
                  style: TextStyle(
                    color: AppColors.londonRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
                  if (arrival.destination.isNotEmpty)
                    Text(
                      'To: ${arrival.destination}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.darkGrey.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
}
