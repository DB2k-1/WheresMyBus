class BusArrival {
  final String routeId;
  final String destination;
  final int timeToStation; // in seconds
  final String vehicleId;
  final String lineName;
  final String direction;
  final String platformName;
  final String currentStopCode;

  BusArrival({
    required this.routeId,
    required this.destination,
    required this.timeToStation,
    required this.vehicleId,
    required this.lineName,
    required this.direction,
    required this.platformName,
    required this.currentStopCode,
  });

  factory BusArrival.fromTflApi(List<dynamic> apiData, String currentStopCode) {
    // TfL API format: [1, "Stop Name", "Route", timestamp]
    // We'll need to parse this based on the actual API response structure
    return BusArrival(
      routeId: apiData[2]?.toString() ?? '',
      destination: apiData[1]?.toString() ?? '',
      timeToStation: _parseTimeToStation(apiData[3]),
      vehicleId: '', // Not provided in this API format
      lineName: apiData[2]?.toString() ?? '',
      direction: '', // Not provided in this API format
      platformName: '', // Not provided in this API format
      currentStopCode: currentStopCode,
    );
  }

  static int _parseTimeToStation(dynamic timestamp) {
    if (timestamp == null) return 0;
    
    try {
      final timestampInt = int.tryParse(timestamp.toString());
      if (timestampInt != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final arrivalTime = timestampInt;
        final timeDiff = (arrivalTime - now) / 1000; // Convert to seconds
        return timeDiff > 0 ? timeDiff.round() : 0;
      }
    } catch (e) {
      // Handle parsing errors
    }
    return 0;
  }

  String get formattedTime {
    if (timeToStation <= 0) return 'Due';
    if (timeToStation < 60) return 'Under 1m';
    if (timeToStation < 3600) return '${(timeToStation / 60).round()}m';
    return '${(timeToStation / 3600).round()}h';
  }

  @override
  String toString() {
    return 'BusArrival(route: $lineName, destination: $destination, time: $formattedTime)';
  }
}
