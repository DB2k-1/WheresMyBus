import 'package:flutter/material.dart';
import 'package:wheres_my_bus/models/bus_stop.dart';
import 'package:wheres_my_bus/models/journey_stop.dart';
import 'package:wheres_my_bus/screens/route_planner_results_screen.dart';
import 'package:wheres_my_bus/services/bus_sequence_service.dart';
import 'package:wheres_my_bus/services/bus_stop_service.dart';
import 'package:wheres_my_bus/utils/constants.dart';

class RoutePlannerCard extends StatefulWidget {
  const RoutePlannerCard({super.key});

  @override
  State<RoutePlannerCard> createState() => _RoutePlannerCardState();
}

class _RoutePlannerCardState extends State<RoutePlannerCard>
    with SingleTickerProviderStateMixin {
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  final FocusNode _originFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();

  List<JourneyStop> _currentSuggestions = [];
  bool _isSearching = false;
  bool _isExpanded = false;
  bool _showSuggestions = false;
  double _suggestionHeight = 0;

  JourneyStop? _selectedOrigin;
  JourneyStop? _selectedDestination;

  String _activeField = '';
  int _searchToken = 0;

  @override
  void initState() {
    super.initState();
    _originFocusNode.addListener(_handleFocusChange);
    _destinationFocusNode.addListener(_handleFocusChange);
    BusSequenceService.initialize();
  }

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _originFocusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _destinationFocusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_originFocusNode.hasFocus) {
      setState(() {
        _activeField = 'origin';
        _showSuggestions = _originController.text.trim().length >= 2;
      });
      _performSearch(_originController.text, isOrigin: true);
      _updateSuggestionHeight();
    } else if (_destinationFocusNode.hasFocus) {
      setState(() {
        _activeField = 'destination';
        _showSuggestions = _destinationController.text.trim().length >= 2;
      });
      _performSearch(_destinationController.text, isOrigin: false);
      _updateSuggestionHeight();
    } else {
      setState(() {
        _showSuggestions = false;
        _activeField = '';
        _suggestionHeight = 0;
      });
    }
  }

  Future<void> _performSearch(String query, {required bool isOrigin}) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _currentSuggestions = [];
        _isSearching = false;
        _suggestionHeight = 0;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _activeField = isOrigin ? 'origin' : 'destination';
    });

    final currentToken = ++_searchToken;

    try {
      await BusSequenceService.initialize();
      final rawResults = await BusStopService.searchBusStops(trimmed);
      if (!mounted || currentToken != _searchToken) return;

      final groupedResults = _groupStops(rawResults);
      final height = _calculateSuggestionHeight(groupedResults.length);
      setState(() {
        _currentSuggestions = groupedResults;
        _isSearching = false;
        _showSuggestions = true;
        _suggestionHeight = height;
      });
    } catch (e) {
      if (!mounted || currentToken != _searchToken) return;
      setState(() {
        _currentSuggestions = [];
        _isSearching = false;
        _showSuggestions = false;
        _suggestionHeight = 0;
      });
    }
  }

  void _onStopSelected(JourneyStop stop, {required bool isOrigin}) {
    final displayLabel = _formatStopLabel(stop);
    setState(() {
      if (isOrigin) {
        _selectedOrigin = stop;
        _originController.text = displayLabel;
      } else {
        _selectedDestination = stop;
        _destinationController.text = displayLabel;
      }
      _currentSuggestions = [];
      _showSuggestions = false;
    });

    if (isOrigin) {
      _destinationFocusNode.requestFocus();
    } else {
      _destinationFocusNode.unfocus();
    }
  }

  String _formatStopLabel(JourneyStop stop) {
    if (stop.subtitle == null || stop.subtitle!.isEmpty) {
      return stop.label;
    }
    return '${stop.label} · ${stop.subtitle}';
  }

  bool get _canSubmit =>
      (_selectedOrigin?.candidates.isNotEmpty ?? false) &&
      (_selectedDestination?.candidates.isNotEmpty ?? false);

  Future<void> _onSubmit() async {
    if (!_canSubmit) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please choose both start and destination stops'),
          backgroundColor: AppColors.londonRed,
        ),
      );
      return;
    }

    final originStops = _selectedOrigin!.candidates;
    final destinationStops = _selectedDestination!.candidates;

    final hasSharedNaptan = originStops.any((origin) => destinationStops
        .any((destination) => destination.naptanAtco == origin.naptanAtco));

    if (hasSharedNaptan) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please choose two stops on different sides'),
          backgroundColor: AppColors.londonRed,
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoutePlannerResultsScreen(
          origin: _selectedOrigin!,
          destination: _selectedDestination!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingMedium,
        AppSizes.paddingMedium,
        AppSizes.paddingMedium,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
                if (!_isExpanded) {
                  _originFocusNode.unfocus();
                  _destinationFocusNode.unfocus();
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLarge,
                vertical: AppSizes.paddingMedium,
              ),
              decoration: BoxDecoration(
                color: AppColors.londonRed,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.londonRed.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.alt_route, color: Colors.white),
                      const SizedBox(width: AppSizes.paddingSmall),
                      Text(
                        'Route Planner',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildExpandedContent(context),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSizes.paddingMedium),
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Plan a journey using live TfL bus data.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkGrey.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          _buildStopField(
            label: 'Starting stop',
            controller: _originController,
            focusNode: _originFocusNode,
            onChanged: (value) => _performSearch(
              value,
              isOrigin: true,
            ),
            onClear: () {
              setState(() {
                _originController.clear();
                _selectedOrigin = null;
                _currentSuggestions = [];
        _suggestionHeight = 0;
              });
              _originFocusNode.requestFocus();
            },
          ),
          const SizedBox(height: AppSizes.paddingMedium),
          _buildStopField(
            label: 'Destination stop',
            controller: _destinationController,
            focusNode: _destinationFocusNode,
            onChanged: (value) => _performSearch(
              value,
              isOrigin: false,
            ),
            onClear: () {
              setState(() {
                _destinationController.clear();
                _selectedDestination = null;
                _currentSuggestions = [];
        _suggestionHeight = 0;
              });
              _destinationFocusNode.requestFocus();
            },
          ),
          _buildSuggestionsList(),
          const SizedBox(height: AppSizes.paddingLarge),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSubmit ? _onSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.londonRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSizes.paddingMedium,
                ),
                textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              child: const Text('Where\'s My Bus?'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction:
          label == 'Starting stop' ? TextInputAction.next : TextInputAction.done,
      onChanged: onChanged,
      onTap: () {
        setState(() {
          _activeField = label == 'Starting stop' ? 'origin' : 'destination';
          _showSuggestions = controller.text.trim().length >= 2;
        });
        _performSearch(
          controller.text,
          isOrigin: label == 'Starting stop',
        );
      },
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.lightGrey.withOpacity(0.2),
        suffixIcon: controller.text.isEmpty
            ? const Icon(Icons.search)
            : IconButton(
                icon: const Icon(Icons.clear),
                onPressed: onClear,
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          borderSide: BorderSide(
            color: AppColors.lightGrey,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          borderSide: BorderSide(
            color: AppColors.londonRed,
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (!_showSuggestions || _currentSuggestions.isEmpty) {
      if (_isSearching) {
        return const Padding(
          padding: EdgeInsets.only(top: AppSizes.paddingSmall),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      return const SizedBox.shrink();
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final double fallbackHeight = (screenHeight * 0.35).clamp(140.0, 280.0);
    final maxHeight =
        _suggestionHeight > 0 ? _suggestionHeight : fallbackHeight;

    return Container(
      margin: const EdgeInsets.only(top: AppSizes.paddingSmall / 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight.clamp(140.0, 260.0),
        ),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            final stop = _currentSuggestions[index];
            return ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMedium,
                vertical: 6,
              ),
              leading: CircleAvatar(
                backgroundColor: AppColors.londonRed.withOpacity(0.1),
                foregroundColor: AppColors.londonRed,
                child: const Icon(Icons.directions_bus),
              ),
              title: Text(
                stop.label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              subtitle: Text(
                stop.subtitle ?? 'Multiple routes available',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.darkGrey.withOpacity(0.7),
                    ),
              ),
              onTap: () => _onStopSelected(
                stop,
                isOrigin: _activeField == 'origin',
              ),
            );
          },
          separatorBuilder: (_, __) => Divider(
            color: AppColors.lightGrey.withOpacity(0.4),
            height: 1,
          ),
          itemCount: _currentSuggestions.length,
        ),
      ),
    );
  }

  void _updateSuggestionHeight() {
    final height = _calculateSuggestionHeight(_currentSuggestions.length);
    if (_suggestionHeight != height) {
      setState(() {
        _suggestionHeight = height;
      });
    }
  }

  double _calculateSuggestionHeight(int resultCount) {
    if (!mounted || resultCount <= 0) return 0;

    final mediaQuery = MediaQuery.of(context);
    final focusNode =
        _activeField == 'origin' ? _originFocusNode : _destinationFocusNode;
    final contextForField = focusNode.context;

    double availableSpace;
    if (contextForField == null) {
      availableSpace = mediaQuery.size.height * 0.35;
    } else {
      final renderObject = contextForField.findRenderObject();
      if (renderObject is RenderBox) {
        final fieldOffset = renderObject.localToGlobal(Offset.zero);
        final fieldHeight = renderObject.size.height;
        availableSpace = mediaQuery.size.height -
            mediaQuery.padding.bottom -
            fieldOffset.dy -
            fieldHeight -
            80;
      } else {
        availableSpace = mediaQuery.size.height * 0.35;
      }
    }

    if (!availableSpace.isFinite || availableSpace <= 0) {
      availableSpace = mediaQuery.size.height * 0.35;
    }

    const double itemHeight = 64.0;
    const double paddingAllowance = 12.0;
    final contentHeight = (resultCount * itemHeight) + paddingAllowance;

    if (contentHeight <= availableSpace) {
      return contentHeight;
    }

    final maxHeight = availableSpace.clamp(96.0, 320.0);
    return maxHeight;
  }

  List<JourneyStop> _groupStops(List<BusStop> stops) {
    final Map<String, _StopGroupBuilder> groups = {};

    for (final stop in stops) {
      final key =
          '${stop.stopName.toLowerCase()}|${stop.stopArea.toLowerCase()}';
      final builder = groups.putIfAbsent(
        key,
        () => _StopGroupBuilder(stop.stopName, stop.stopArea),
      );
      builder.add(stop);
    }

    final suggestions = groups.values
        .map((builder) => builder.build())
        .where((stop) => stop != null)
        .cast<JourneyStop>()
        .toList();

    suggestions.sort((a, b) => a.label.compareTo(b.label));
    return suggestions;
  }
}

class _StopGroupBuilder {
  _StopGroupBuilder(this.name, this.area);

  final String name;
  final String area;
  final List<BusStop> _stops = [];
  final Set<String> _destinations = {};

  void add(BusStop stop) {
    _stops.add(stop);
    final destinations =
        BusSequenceService.getFinalDestinationsForStop(stop.busStopCode);
    _destinations.addAll(destinations);
  }

  JourneyStop? build() {
    if (_stops.isEmpty) return null;

    String? subtitle;
    final sortedDestinations = _destinations.toList()..sort();
    if (sortedDestinations.isNotEmpty) {
      if (sortedDestinations.length == 1) {
        subtitle = 'Towards ${sortedDestinations.first}';
      } else {
        subtitle =
            'Towards ${sortedDestinations.take(3).join(', ')}${sortedDestinations.length > 3 ? '…' : ''}';
      }
    } else if (area.isNotEmpty) {
      subtitle = area;
    }

    return JourneyStop(
      label: name,
      subtitle: subtitle,
      candidates: List<BusStop>.unmodifiable(_stops),
    );
  }
}

