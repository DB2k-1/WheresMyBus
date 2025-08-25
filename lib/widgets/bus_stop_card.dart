import 'package:flutter/material.dart';
import 'package:wheres_my_bus/utils/constants.dart';

class BusStopCard extends StatelessWidget {
  final dynamic busStop;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool showAddButton;
  final VoidCallback? onAdd;

  const BusStopCard({
    super.key,
    required this.busStop,
    this.onTap,
    this.onRemove,
    this.showAddButton = false,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      elevation: 2,
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
              // Bus stop icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.londonRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  Icons.directions_bus,
                  color: AppColors.londonRed,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Bus stop details
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            busStop.stopName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.darkGrey,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1), // Minimal spacing
                          Row(
                            children: [
                              Text(
                                'Code: ${busStop.busStopCode}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.darkGrey.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.paddingSmall,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.londonRed.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.londonRed.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  busStop.userFriendlyDirection,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.londonRed,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (busStop.distance != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              '${(busStop.distance! * 0.000621371).toStringAsFixed(1)} miles away',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.londonRed,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (showAddButton && onAdd != null)
                      GestureDetector(
                        onTap: onAdd,
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: Icon(
                            Icons.add_circle_outline,
                            color: AppColors.londonRed,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
