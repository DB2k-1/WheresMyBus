import 'package:flutter/material.dart';
import 'package:wheres_my_bus/utils/stop_name.dart';

/// Small badges for what you can change to at a stop: Tube, Overground,
/// Rail, DLR, Tram, River. Shows nothing when there are none.
class InterchangeBadges extends StatelessWidget {
  final Set<Interchange> interchanges;

  /// Slightly larger on the stop screen than on list cards.
  final bool large;

  const InterchangeBadges({
    super.key,
    required this.interchanges,
    this.large = false,
  });

  static const Map<Interchange, (String, IconData, Color)> _styles = {
    Interchange.tube: ('Tube', Icons.subway, Color(0xFF0019A8)), // Underground blue
    Interchange.overground: ('Overground', Icons.directions_railway, Color(0xFFC65A00)), // Overground orange (darkened for white text)
    Interchange.rail: ('Rail', Icons.train, Color(0xFFB0261C)), // National Rail red
    Interchange.dlr: ('DLR', Icons.directions_railway_filled, Color(0xFF00797B)), // DLR teal (darkened)
    Interchange.tram: ('Tram', Icons.tram, Color(0xFF4E7A0B)), // Tram green (darkened)
    Interchange.river: ('River', Icons.directions_boat, Color(0xFF0072A8)), // River blue
  };

  @override
  Widget build(BuildContext context) {
    if (interchanges.isEmpty) return const SizedBox.shrink();
    final double fontSize = large ? 13 : 11;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final interchange in Interchange.values)
          if (interchanges.contains(interchange))
            Semantics(
              label: 'Change for ${_styles[interchange]!.$1}',
              excludeSemantics: true,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: large ? 8 : 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _styles[interchange]!.$3,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_styles[interchange]!.$2, size: fontSize + 2, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(
                      _styles[interchange]!.$1,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
