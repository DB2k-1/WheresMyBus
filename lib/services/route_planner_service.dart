import 'dart:math' as math;

import 'package:wheres_my_bus/models/bus_stop.dart';
import 'package:wheres_my_bus/models/route_plan.dart';
import 'package:wheres_my_bus/services/bus_stop_service.dart';
import 'package:wheres_my_bus/services/data_update_service.dart';

class RoutePlannerService {
  RoutePlannerService._();

  static bool _initialized = false;

  /// Average in-service bus speed used to derive travel time estimates (km/h).
  static const double _averageBusSpeedKmh = 14.0;

  /// Default buffer time added when transferring between different routes (minutes).
  static const double _transferBufferMinutes = 2.0;

  /// Penalty applied per transfer when ranking candidate routes (minutes).
  static const double _transferPenaltyMinutes = 6.0;

  static final Map<String, BusStop> _stopsByNaptan = {};
  static final Map<String, List<_RouteEdge>> _graph = {};

  /// Ensures the stop catalogue and route graph are ready before routing.
  static Future<void> initialize() async {
    if (_initialized) return;

    final stops = await BusStopService.loadAllBusStops();
    _stopsByNaptan
      ..clear()
      ..addEntries(stops.map((stop) => MapEntry(stop.naptanAtco, stop)));

    final rawSequences = await DataUpdateService.getBusSequencesData();
    _buildGraph(rawSequences);

    _initialized = true;
  }

  /// Compute up to [maxResults] journey options between [originNaptan] and [destinationNaptan].
  ///
  /// [maxTransfers] limits how many route changes are allowed (0 = direct service only).
  static Future<List<RoutePlan>> planRoute({
    required String originNaptan,
    required String destinationNaptan,
    int maxResults = 3,
    int maxTransfers = 2,
    DateTime? desiredDepartureTime,
  }) async {
    await initialize();

    final origin = _stopsByNaptan[originNaptan];
    final destination = _stopsByNaptan[destinationNaptan];

    if (origin == null || destination == null) {
      throw ArgumentError('Unknown origin or destination stop.');
    }

    if (originNaptan == destinationNaptan) {
      return [
        RoutePlan(
          origin: origin,
          destination: destination,
          legs: [],
          totalTravelMinutes: 0,
          estimatedDepartureTime: desiredDepartureTime,
        ),
      ];
    }

    final results = <RoutePlan>[];
    final queue = <_SearchState>[];

    void enqueue(_SearchState state) {
      queue.add(state);
      queue.sort((a, b) => a.priority.compareTo(b.priority));
    }

    final initialState = _SearchState(
      currentStop: originNaptan,
      totalMinutes: 0,
      transfers: 0,
      steps: const <_RouteStep>[],
      visitedStops: {originNaptan},
    );
    enqueue(initialState);

    final Map<String, double> bestCostByKey = {};

    while (queue.isNotEmpty && results.length < maxResults) {
      final state = queue.removeAt(0);

      final costKey = '${state.currentStop}|${state.lastRouteKey}';
      final previousBest = bestCostByKey[costKey];
      if (previousBest != null && state.priority >= previousBest) {
        continue;
      }
      bestCostByKey[costKey] = state.priority;

      if (state.currentStop == destinationNaptan) {
        final plan = _buildRoutePlan(
          state.steps,
          origin,
          destination,
          state.totalMinutes,
          desiredDepartureTime,
        );
        results.add(plan);
        // Continue searching to find alternative journeys.
        continue;
      }

      final outgoingEdges = _graph[state.currentStop];
      if (outgoingEdges == null) continue;

      for (final edge in outgoingEdges) {
        if (state.visitedStops.contains(edge.toNaptan)) {
          // Avoid cycles.
          continue;
        }

        final lastStep = state.steps.isNotEmpty ? state.steps.last : null;
        final sameVehicle = lastStep != null &&
            lastStep.edge.routeId == edge.routeId &&
            lastStep.edge.runId == edge.runId;

        final newTransfers = sameVehicle
            ? state.transfers
            : (state.steps.isEmpty ? 0 : state.transfers + 1);

        if (newTransfers > maxTransfers) continue;

        final transferBuffer =
            !sameVehicle && state.steps.isNotEmpty ? _transferBufferMinutes : 0.0;

        final totalMinutes =
            state.totalMinutes + edge.travelMinutes + transferBuffer;

        final newState = _SearchState(
          currentStop: edge.toNaptan,
          totalMinutes: totalMinutes,
          transfers: newTransfers,
          steps: [
            ...state.steps,
            _RouteStep(edge: edge),
          ],
          visitedStops: {
            ...state.visitedStops,
            edge.toNaptan,
          },
        );

        enqueue(newState);
      }
    }

    return results;
  }

  static void _buildGraph(String csvContent) {
    final lines = csvContent.split('\n');
    if (lines.length <= 1) return;

    // Group sequence stops by route + run.
    final Map<String, List<_SequenceStop>> groupedStops = {};

    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;

      final values = _parseCsvLine(line);
      if (values.length < 7) continue;

      final routeId = values[0];
      final runId = values[1];
      final sequence = int.tryParse(values[2]) ?? 0;
      final stopCode = values[5]; // Naptan_Atco column

      if (!_stopsByNaptan.containsKey(stopCode)) {
        continue;
      }

      final key = '$routeId::$runId';

      groupedStops.putIfAbsent(key, () => []).add(
            _SequenceStop(
              routeId: routeId,
              runId: runId,
              sequence: sequence,
              naptanAtco: stopCode,
            ),
          );
    }

    _graph.clear();

    groupedStops.forEach((_, stops) {
      stops.sort((a, b) => a.sequence.compareTo(b.sequence));

      for (var i = 0; i < stops.length - 1; i++) {
        final current = stops[i];
        final next = stops[i + 1];

        final fromStop = _stopsByNaptan[current.naptanAtco];
        final toStop = _stopsByNaptan[next.naptanAtco];

        if (fromStop == null || toStop == null) continue;

        final distanceMeters = _distanceBetweenStops(fromStop, toStop);
        final travelMinutes = _estimateTravelMinutes(distanceMeters);

        final edge = _RouteEdge(
          routeId: current.routeId,
          runId: current.runId,
          fromNaptan: current.naptanAtco,
          toNaptan: next.naptanAtco,
          distanceMeters: distanceMeters,
          travelMinutes: travelMinutes,
        );

        _graph.putIfAbsent(edge.fromNaptan, () => []).add(edge);
      }
    });
  }

  static RoutePlan _buildRoutePlan(
    List<_RouteStep> steps,
    BusStop origin,
    BusStop destination,
    double totalMinutes,
    DateTime? departureTime,
  ) {
    if (steps.isEmpty) {
      return RoutePlan(
        origin: origin,
        destination: destination,
        legs: const [],
        totalTravelMinutes: totalMinutes,
        estimatedDepartureTime: departureTime,
      );
    }

    final legs = <RouteLeg>[];
    _RouteEdge? currentEdge;
    List<BusStop> currentStops = [];
    double currentLegMinutes = 0.0;
    DateTime? currentDeparture = departureTime;
    DateTime? timelineCursor = departureTime;

    void closeCurrentLeg() {
      if (currentEdge == null || currentStops.isEmpty) return;

      final leg = RouteLeg(
        routeId: currentEdge!.routeId,
        runId: currentEdge!.runId,
        origin: currentStops.first,
        destination: currentStops.last,
        stops: List<BusStop>.unmodifiable(currentStops),
        travelMinutes: currentLegMinutes,
        estimatedDepartureTime: currentDeparture,
      );
      legs.add(leg);

      if (timelineCursor != null) {
        timelineCursor = timelineCursor!.add(Duration(
          seconds: (currentLegMinutes * 60).round(),
        ));
        // Apply transfer buffer for the next leg (if any).
        timelineCursor = timelineCursor!.add(Duration(
          seconds: (_transferBufferMinutes * 60).round(),
        ));
        currentDeparture = timelineCursor;
      }

      currentStops = [];
      currentLegMinutes = 0.0;
      currentEdge = null;
    }

    for (final step in steps) {
      final edge = step.edge;
      final fromStop = _stopsByNaptan[edge.fromNaptan];
      final toStop = _stopsByNaptan[edge.toNaptan];

      if (fromStop == null || toStop == null) {
        continue;
      }

      final continuesCurrentLeg = currentEdge != null &&
          currentEdge!.routeId == edge.routeId &&
          currentEdge!.runId == edge.runId;

      if (!continuesCurrentLeg) {
        // Finish the previous leg (if any).
        closeCurrentLeg();

        currentEdge = edge;
        currentStops = [fromStop, toStop];
        currentLegMinutes = edge.travelMinutes;

        if (legs.isNotEmpty && timelineCursor != null) {
          // Account for transfer buffer already added in the previous leg closure.
          currentDeparture = timelineCursor;
        }
      } else {
        if (currentStops.isEmpty) {
          currentStops = [fromStop, toStop];
        } else {
          if (currentStops.last.naptanAtco != fromStop.naptanAtco) {
            currentStops.add(fromStop);
          }
          currentStops.add(toStop);
        }
        currentLegMinutes += edge.travelMinutes;
      }
    }

    // Close the last leg after iteration completes.
    closeCurrentLeg();

    // Remove the transfer buffer added after the last leg (not needed).
    if (legs.isNotEmpty && timelineCursor != null) {
      timelineCursor = timelineCursor!.subtract(Duration(
        seconds: (_transferBufferMinutes * 60).round(),
      ));
    }

    return RoutePlan(
      origin: origin,
      destination: destination,
      legs: legs,
      totalTravelMinutes: totalMinutes,
      estimatedDepartureTime: departureTime,
    );
  }

  static double _distanceBetweenStops(BusStop a, BusStop b) {
    final dx = a.locationEasting - b.locationEasting;
    final dy = a.locationNorthing - b.locationNorthing;
    return math.sqrt(dx * dx + dy * dy);
  }

  static double _estimateTravelMinutes(double distanceMeters) {
    if (distanceMeters <= 0) return 0;

    final distanceKm = distanceMeters / 1000;
    final hours = distanceKm / _averageBusSpeedKmh;
    return hours * 60;
  }

  static List<String> _parseCsvLine(String line) {
    final results = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        results.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    results.add(buffer.toString().trim());
    return results;
  }
}

class _RouteEdge {
  const _RouteEdge({
    required this.routeId,
    required this.runId,
    required this.fromNaptan,
    required this.toNaptan,
    required this.distanceMeters,
    required this.travelMinutes,
  });

  final String routeId;
  final String runId;
  final String fromNaptan;
  final String toNaptan;
  final double distanceMeters;
  final double travelMinutes;
}

class _RouteStep {
  const _RouteStep({required this.edge});

  final _RouteEdge edge;
}

class _SearchState {
  const _SearchState({
    required this.currentStop,
    required this.totalMinutes,
    required this.transfers,
    required this.steps,
    required this.visitedStops,
  });

  final String currentStop;
  final double totalMinutes;
  final int transfers;
  final List<_RouteStep> steps;
  final Set<String> visitedStops;

  double get priority =>
      totalMinutes + transfers * RoutePlannerService._transferPenaltyMinutes;

  String get lastRouteKey {
    if (steps.isEmpty) return '';
    final lastEdge = steps.last.edge;
    return '${lastEdge.routeId}-${lastEdge.runId}';
  }
}

class _SequenceStop {
  const _SequenceStop({
    required this.routeId,
    required this.runId,
    required this.sequence,
    required this.naptanAtco,
  });

  final String routeId;
  final String runId;
  final int sequence;
  final String naptanAtco;
}

