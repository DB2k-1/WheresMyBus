import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:wheres_my_bus/services/data_update_service.dart';
import 'package:wheres_my_bus/utils/constants.dart';

class DataStatusBanner extends StatefulWidget {
  const DataStatusBanner({super.key});

  // Static method to refresh all instances
  static void refreshAll() {
    _refreshNotifier.notifyListeners();
  }

  // Static method to show manual update progress
  static void showManualUpdate() {
    _manualUpdateNotifier.notifyListeners();
  }

  @override
  State<DataStatusBanner> createState() => _DataStatusBannerState();
}

// Global notifier for refreshing all DataStatusBanner instances
final _refreshNotifier = ChangeNotifier();

// Global notifier for showing manual update progress
final _manualUpdateNotifier = ChangeNotifier();

class _DataStatusBannerState extends State<DataStatusBanner> {
  bool _isDataCurrent = false;
  DateTime? _lastUpdate;
  bool _isVisible = true;
  bool _isUpdating = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _checkDataStatus();
    _refreshNotifier.addListener(_checkDataStatus);
    _manualUpdateNotifier.addListener(_showManualUpdate);
  }

  @override
  void dispose() {
    _refreshNotifier.removeListener(_checkDataStatus);
    _manualUpdateNotifier.removeListener(_showManualUpdate);
    _hideTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkDataStatus() async {
    final isCurrent = await DataUpdateService.isDataCurrent();
    final lastUpdate = await DataUpdateService.getLastUpdateTime();
    
    if (mounted) {
      setState(() {
        _isDataCurrent = isCurrent;
        _lastUpdate = lastUpdate;
        _isUpdating = false;
      });
      
      // Auto-hide the banner after 1.5 seconds if data is current
      if (isCurrent) {
        _hideTimer?.cancel();
        _hideTimer = Timer(const Duration(milliseconds: 1500), () {
          if (mounted) {
            setState(() {
              _isVisible = false;
            });
          }
        });
      } else {
        // Keep banner visible for outdated data
        _hideTimer?.cancel();
        _isVisible = true;
      }
    }
  }

  void _showManualUpdate() {
    if (mounted) {
      setState(() {
        _isUpdating = true;
        _isVisible = true;
      });
      
      // Cancel any existing hide timer
      _hideTimer?.cancel();
    }
  }

  String _getStatusText() {
    if (_isUpdating) return '🔄 Checking for data updates...';
    if (_lastUpdate == null) return 'Checking data status...';
    
    if (_isDataCurrent) {
      final daysSinceUpdate = DateTime.now().difference(_lastUpdate!).inDays;
      if (daysSinceUpdate == 0) {
        return 'Data updated today';
      } else if (daysSinceUpdate == 1) {
        return 'Data updated yesterday';
      } else {
        return 'Data updated $daysSinceUpdate days ago';
      }
    } else {
      final daysSinceUpdate = DateTime.now().difference(_lastUpdate!).inDays;
      return 'Data may be outdated ($daysSinceUpdate days old)';
    }
  }

  Color _getStatusColor() {
    if (_isUpdating) return Colors.blue;
    if (_lastUpdate == null) return Colors.blue;
    if (_isDataCurrent) return Colors.green;
    return Colors.orange;
  }

  IconData _getStatusIcon() {
    if (_isUpdating) return Icons.sync;
    if (_lastUpdate == null) return Icons.sync;
    if (_isDataCurrent) return Icons.check_circle;
    return Icons.warning;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingMedium,
        vertical: AppSizes.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: _getStatusColor().withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(),
            color: _getStatusColor(),
            size: 16,
          ),
          const SizedBox(width: AppSizes.paddingSmall),
          Expanded(
            child: Text(
              _getStatusText(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getStatusColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _isVisible = false;
              });
            },
            icon: Icon(
              Icons.close,
              color: _getStatusColor(),
              size: 16,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
            ),
          ),
        ],
      ),
    );
  }
}
