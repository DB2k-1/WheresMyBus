import 'package:wheres_my_bus/models/bus_stop.dart';

/// Represents a full journey between two bus stops consisting of one or more legs.
class RoutePlan {
  RoutePlan({
    required this.origin,
    required this.destination,
    required this.legs,
    required this.totalTravelMinutes,
    this.estimatedDepartureTime,
  });

  final BusStop origin;
  final BusStop destination;
  final List<RouteLeg> legs;
  final double totalTravelMinutes;
  final DateTime? estimatedDepartureTime;

  DateTime? get estimatedArrivalTime {
    if (estimatedDepartureTime == null) return null;
    if (legs.isEmpty) return estimatedDepartureTime;
    return legs.last.estimatedArrivalTime;
  }

  int get totalTransfers => legs.isEmpty ? 0 : legs.length - 1;
}

/// Represents a continuous segment of travel on a single bus route/run.
class RouteLeg {
  RouteLeg({
    required this.routeId,
    required this.runId,
    required this.origin,
    required this.destination,
    required this.stops,
    required this.travelMinutes,
    this.estimatedDepartureTime,
  });

  final String routeId;
  final String runId;
  final BusStop origin;
  final BusStop destination;
  final List<BusStop> stops;
  final double travelMinutes;
  final DateTime? estimatedDepartureTime;

  DateTime? get estimatedArrivalTime {
    if (estimatedDepartureTime == null) return null;
    return estimatedDepartureTime!.add(Duration(
      seconds: (travelMinutes * 60).round(),
    ));
  }

  int get stopCount => stops.length;
}

