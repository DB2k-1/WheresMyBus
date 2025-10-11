import 'dart:math';

class CycleHireStation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int nbBikes;
  final int nbEmptyDocks;
  final int nbDocks;
  final bool installed;
  final bool locked;
  final bool temporary;
  final double? distance; // Distance from user location in meters

  CycleHireStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.nbBikes,
    required this.nbEmptyDocks,
    required this.nbDocks,
    required this.installed,
    required this.locked,
    required this.temporary,
    this.distance,
  });

  factory CycleHireStation.fromXml(Map<String, dynamic> xmlData) {
    return CycleHireStation(
      id: xmlData['id']?.toString() ?? '',
      name: xmlData['name']?.toString() ?? '',
      latitude: double.tryParse(xmlData['lat']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(xmlData['long']?.toString() ?? '0') ?? 0.0,
      nbBikes: int.tryParse(xmlData['nbBikes']?.toString() ?? '0') ?? 0,
      nbEmptyDocks: int.tryParse(xmlData['nbEmptyDocks']?.toString() ?? '0') ?? 0,
      nbDocks: int.tryParse(xmlData['nbDocks']?.toString() ?? '0') ?? 0,
      installed: xmlData['installed']?.toString().toLowerCase() == 'true',
      locked: xmlData['locked']?.toString().toLowerCase() == 'true',
      temporary: xmlData['temporary']?.toString().toLowerCase() == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'nbBikes': nbBikes,
      'nbEmptyDocks': nbEmptyDocks,
      'nbDocks': nbDocks,
      'installed': installed,
      'locked': locked,
      'temporary': temporary,
    };
  }

  factory CycleHireStation.fromJson(Map<String, dynamic> json) {
    return CycleHireStation(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      nbBikes: json['nbBikes'] as int? ?? 0,
      nbEmptyDocks: json['nbEmptyDocks'] as int? ?? 0,
      nbDocks: json['nbDocks'] as int? ?? 0,
      installed: json['installed'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
      temporary: json['temporary'] as bool? ?? false,
    );
  }

  CycleHireStation copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    int? nbBikes,
    int? nbEmptyDocks,
    int? nbDocks,
    bool? installed,
    bool? locked,
    bool? temporary,
    double? distance,
  }) {
    return CycleHireStation(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      nbBikes: nbBikes ?? this.nbBikes,
      nbEmptyDocks: nbEmptyDocks ?? this.nbEmptyDocks,
      nbDocks: nbDocks ?? this.nbDocks,
      installed: installed ?? this.installed,
      locked: locked ?? this.locked,
      temporary: temporary ?? this.temporary,
      distance: distance ?? this.distance,
    );
  }

  // Calculate distance from user location
  double calculateDistance(double userLat, double userLon) {
    const double earthRadius = 6371000; // meters
    
    final double dLat = _toRadians(userLat - latitude);
    final double dLon = _toRadians(userLon - longitude);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(latitude)) * cos(_toRadians(userLat)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  String get formattedDistance {
    if (distance == null) return '';
    if (distance! < 1000) {
      return '${distance!.round()}m';
    }
    return '${(distance! / 1000).toStringAsFixed(1)}km';
  }

  bool get isAvailable {
    return installed && !locked && !temporary;
  }

  @override
  String toString() {
    return 'CycleHireStation(id: $id, name: $name, bikes: $nbBikes, docks: $nbDocks)';
  }
}

