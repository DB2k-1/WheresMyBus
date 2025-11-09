import 'package:wheres_my_bus/models/bus_stop.dart';

class JourneyStop {
  JourneyStop({
    required this.label,
    required this.candidates,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final List<BusStop> candidates;
}

