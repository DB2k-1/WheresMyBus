import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wheres_my_bus/models/cycle_hire_station.dart';
import 'package:wheres_my_bus/utils/constants.dart';

class CycleStationDetailScreen extends StatelessWidget {
  final CycleHireStation station;

  const CycleStationDetailScreen({
    super.key,
    required this.station,
  });

  Future<void> _openInMaps(BuildContext context) async {
    // Create Google Maps URL with directions
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${station.latitude},${station.longitude}'
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open maps'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Station Details'),
        backgroundColor: AppColors.londonRed,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.directions),
            onPressed: () => _openInMaps(context),
            tooltip: 'Get directions',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Station name header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.darkGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (station.distance != null) ...[
                    const SizedBox(height: AppSizes.paddingSmall),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: AppColors.darkGrey.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          station.formattedDistance,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.darkGrey.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSizes.paddingMedium),

            // Availability section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Availability',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.darkGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),
                  
                  // Bikes available
                  _buildInfoRow(
                    context,
                    icon: Icons.pedal_bike,
                    label: 'Bikes Available',
                    value: station.nbBikes.toString(),
                    color: station.nbBikes > 0 ? Colors.green : Colors.red,
                  ),
                  
                  const SizedBox(height: AppSizes.paddingMedium),
                  
                  // Empty docks
                  _buildInfoRow(
                    context,
                    icon: Icons.storage,
                    label: 'Empty Docks',
                    value: station.nbEmptyDocks.toString(),
                    color: station.nbEmptyDocks > 0 ? Colors.green : Colors.red,
                  ),
                  
                  const SizedBox(height: AppSizes.paddingMedium),
                  
                  // Total docks
                  _buildInfoRow(
                    context,
                    icon: Icons.apps,
                    label: 'Total Docks',
                    value: station.nbDocks.toString(),
                    color: AppColors.londonBlue,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.paddingMedium),

            // Status section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
              padding: const EdgeInsets.all(AppSizes.paddingLarge),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Station Status',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.darkGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingLarge),
                  
                  _buildStatusRow(
                    context,
                    label: 'Installed',
                    isActive: station.installed,
                  ),
                  
                  const SizedBox(height: AppSizes.paddingSmall),
                  
                  _buildStatusRow(
                    context,
                    label: 'Locked',
                    isActive: station.locked,
                    isNegative: true,
                  ),
                  
                  const SizedBox(height: AppSizes.paddingSmall),
                  
                  _buildStatusRow(
                    context,
                    label: 'Temporary',
                    isActive: station.temporary,
                    isNegative: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.paddingMedium),

            // Get Directions button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openInMaps(context),
                icon: const Icon(Icons.directions),
                label: const Text('Get Directions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.londonBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingMedium),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSizes.paddingMedium),

            // Overall status message
            if (!station.isAvailable)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMedium),
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                  border: Border.all(
                    color: Colors.orange,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: AppSizes.paddingSmall),
                    Expanded(
                      child: Text(
                        'This station may not be fully operational',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: AppSizes.paddingLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSizes.paddingMedium),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.darkGrey,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(
    BuildContext context, {
    required String label,
    required bool isActive,
    bool isNegative = false,
  }) {
    final color = isNegative
        ? (isActive ? Colors.red : Colors.green)
        : (isActive ? Colors.green : Colors.grey);
    
    return Row(
      children: [
        Icon(
          isActive ? Icons.check_circle : Icons.cancel,
          color: color,
          size: 20,
        ),
        const SizedBox(width: AppSizes.paddingSmall),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.darkGrey,
          ),
        ),
      ],
    );
  }
}

