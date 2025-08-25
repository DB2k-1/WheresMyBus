class DirectionHelper {
  /// Convert heading degrees to cardinal direction
  static String getCardinalDirection(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'Northbound';
    if (heading >= 22.5 && heading < 67.5) return 'Northeast bound';
    if (heading >= 67.5 && heading < 112.5) return 'Eastbound';
    if (heading >= 112.5 && heading < 157.5) return 'Southeast bound';
    if (heading >= 157.5 && heading < 202.5) return 'Southbound';
    if (heading >= 202.5 && heading < 247.5) return 'Southwest bound';
    if (heading >= 247.5 && heading < 292.5) return 'Westbound';
    if (heading >= 292.5 && heading < 337.5) return 'Northwest bound';
    return 'Unknown direction';
  }

  /// Get a more natural direction description
  static String getNaturalDirection(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'heading North';
    if (heading >= 22.5 && heading < 67.5) return 'heading Northeast';
    if (heading >= 67.5 && heading < 112.5) return 'heading East';
    if (heading >= 112.5 && heading < 157.5) return 'heading Southeast';
    if (heading >= 157.5 && heading < 202.5) return 'heading South';
    if (heading >= 202.5 && heading < 247.5) return 'heading Southwest';
    if (heading >= 247.5 && heading < 292.5) return 'heading West';
    if (heading >= 292.5 && heading < 337.5) return 'heading Northwest';
    return 'direction unknown';
  }

  /// Get a short direction indicator
  static String getShortDirection(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'N';
    if (heading >= 22.5 && heading < 67.5) return 'NE';
    if (heading >= 67.5 && heading < 112.5) return 'E';
    if (heading >= 112.5 && heading < 157.5) return 'SE';
    if (heading >= 157.5 && heading < 202.5) return 'S';
    if (heading >= 202.5 && heading < 247.5) return 'SW';
    if (heading >= 247.5 && heading < 292.5) return 'W';
    if (heading >= 292.5 && heading < 337.5) return 'NW';
    return '?';
  }

  /// Get a user-friendly direction description for bus stops
  static String getBusStopDirection(double heading) {
    final cardinal = getCardinalDirection(heading);
    
    // Make it more natural for bus stops
    switch (cardinal) {
      case 'Northbound':
        return 'Northbound';
      case 'Northeast bound':
        return 'Northeast bound';
      case 'Eastbound':
        return 'Eastbound';
      case 'Southeast bound':
        return 'Southeast bound';
      case 'Southbound':
        return 'Southbound';
      case 'Southwest bound':
        return 'Southwest bound';
      case 'Westbound':
        return 'Westbound';
      case 'Northwest bound':
        return 'Northwest bound';
      default:
        return 'Unknown direction';
    }
  }

  /// Get a compact direction badge text
  static String getDirectionBadge(double heading) {
    final short = getShortDirection(heading);
    final cardinal = getCardinalDirection(heading);
    return '$short ($cardinal)';
  }
}
