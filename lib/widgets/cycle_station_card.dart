import 'package:flutter/material.dart';
import 'package:wheres_my_bus/models/cycle_hire_station.dart';
import 'package:wheres_my_bus/utils/constants.dart';

class CycleStationCard extends StatelessWidget {
  final CycleHireStation station;
  final VoidCallback? onTap;
  final VoidCallback? onAddRemove;
  final bool isSaved;

  const CycleStationCard({
    super.key,
    required this.station,
    this.onTap,
    this.onAddRemove,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingSmall),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Station name with +/- button
              Row(
                children: [
                  Expanded(
                    child: Text(
                      station.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.darkGrey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (onAddRemove != null)
                    IconButton(
                      icon: Icon(
                        isSaved ? Icons.remove_circle : Icons.add_circle,
                        color: isSaved ? Colors.red : Colors.green,
                        size: 28,
                      ),
                      onPressed: onAddRemove,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              
              const SizedBox(height: AppSizes.paddingMedium),
              
              // Availability info with distance
              Row(
                children: [
                  // Bikes available
                  Expanded(
                    child: _buildCompactInfoChip(
                      context,
                      icon: Icons.pedal_bike,
                      label: 'Bikes',
                      value: station.nbBikes.toString(),
                      color: station.nbBikes > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingSmall),
                  
                  // Empty docks
                  Expanded(
                    child: _buildCompactInfoChip(
                      context,
                      icon: Icons.storage,
                      label: 'Docks',
                      value: station.nbEmptyDocks.toString(),
                      color: station.nbEmptyDocks > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  
                  const SizedBox(width: AppSizes.paddingSmall),
                  
                  // Distance
                  if (station.distance != null)
                    Expanded(
                      child: _buildCompactInfoChip(
                        context,
                        icon: Icons.location_on,
                        label: 'Distance',
                        value: station.formattedDistance,
                        color: AppColors.londonBlue,
                      ),
                    ),
                ],
              ),

              // Status warnings
              if (!station.isAvailable) ...[
                const SizedBox(height: AppSizes.paddingSmall),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Limited availability',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.darkGrey.withValues(alpha: 0.7),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

