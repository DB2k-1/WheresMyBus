import 'package:flutter/material.dart';
import 'package:wheres_my_bus/utils/constants.dart';
import 'package:wheres_my_bus/services/custom_direction_service.dart';

class BusStopCard extends StatefulWidget {
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
  State<BusStopCard> createState() => _BusStopCardState();
}

class _BusStopCardState extends State<BusStopCard> {
  String _displayDirection = '';

  @override
  void initState() {
    super.initState();
    _loadDisplayDirection();
  }

  @override
  void didUpdateWidget(BusStopCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload direction when widget updates (e.g., when returning from edit)
    if (oldWidget.busStop.naptanAtco != widget.busStop.naptanAtco) {
      _loadDisplayDirection();
    } else {
      // Even if it's the same bus stop, reload to check for custom direction changes
      _loadDisplayDirection();
    }
  }

  Future<void> _loadDisplayDirection() async {
    final customDirection = await CustomDirectionService.getCustomDirection(widget.busStop.naptanAtco);
    if (mounted) {
      setState(() {
        _displayDirection = customDirection ?? widget.busStop.userFriendlyDirection;
      });
    }
  }

  /// Refresh the display direction - can be called externally
  Future<void> refreshDirection() async {
    await _loadDisplayDirection();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: InkWell(
        onTap: widget.onTap,
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
                            widget.busStop.stopName,
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
                              if (widget.busStop.busStopCode.isNotEmpty && widget.busStop.busStopCode != 'NONE')
                                Text(
                                  'Code: ${widget.busStop.busStopCode}',
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
                                  _displayDirection.isEmpty 
                                      ? widget.busStop.userFriendlyDirection 
                                      : _displayDirection,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.londonRed,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (widget.busStop.distance != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              '${(widget.busStop.distance! * 0.000621371).toStringAsFixed(1)} miles away',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.londonRed,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.showAddButton && widget.onAdd != null)
                      GestureDetector(
                        onTap: widget.onAdd,
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
