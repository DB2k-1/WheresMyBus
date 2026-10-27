class BusArrival {
  final String routeId;

  /// Where the bus is going, e.g. "Pimlico".
  final String destination;
  final String vehicleId;
  final String lineName;

  /// The stop's "towards" text, e.g. "Westminster".
  final String direction;

  /// The stop letter on the pole, e.g. "D".
  final String platformName;
  final String currentStopCode;
  final DateTime expectedArrival;

  BusArrival({
    required this.routeId,
    required this.destination,
    required this.vehicleId,
    required this.lineName,
    required this.direction,
    required this.platformName,
    required this.currentStopCode,
    required this.expectedArrival,
  });

  /// Seconds until the bus arrives, counting down live from the prediction.
  int get timeToStation {
    final seconds = expectedArrival.difference(DateTime.now()).inSeconds;
    return seconds > 0 ? seconds : 0;
  }

  String get formattedTime => formatWait(timeToStation);

  /// "Due", "1m" ... "59m", "1h".
  static String formatWait(int seconds) {
    if (seconds < 30) return 'Due';
    if (seconds < 90) return '1m';
    if (seconds < 3600) return '${(seconds / 60).round()}m';
    return '${(seconds / 3600).round()}h';
  }

  @override
  String toString() {
    return 'BusArrival(route: $lineName, destination: $destination, time: $formattedTime)';
  }
}

/// A stop as it's labelled on the street.
class StopInfo {
  final String name;

  /// The letter on the stop flag, e.g. "D". Not every stop has one.
  final String? indicator;

  /// e.g. "Westminster", printed on the flag as "towards Westminster".
  final String? towards;

  const StopInfo({required this.name, this.indicator, this.towards});
}

class StopArrivals {
  final StopInfo? stop;
  final List<BusArrival> arrivals;

  const StopArrivals({required this.stop, required this.arrivals});
}

/// One stop still ahead of a particular bus.
class VehicleStop {
  final String name;
  final String naptanAtco;
  final String? indicator;
  final DateTime expectedArrival;

  const VehicleStop({
    required this.name,
    required this.naptanAtco,
    required this.indicator,
    required this.expectedArrival,
  });

  int get timeToStation {
    final seconds = expectedArrival.difference(DateTime.now()).inSeconds;
    return seconds > 0 ? seconds : 0;
  }
}
