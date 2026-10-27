import 'package:flutter_test/flutter_test.dart';
import 'package:latlong_to_osgrid/latlong_to_osgrid.dart';
import 'package:wheres_my_bus/services/bus_stop_service.dart';

void main() {
  // Stop locations from bus-stops.csv: Trafalgar Square D, Westminster,
  // Guy Earl of Warwick (outer London), Bromley.
  const stops = [
    (530076, 180468),
    (530144, 179768),
    (547058, 175714),
    (540585, 169449),
  ];

  test('a phone standing at a stop is placed at that stop', () {
    for (final (easting, northing) in stops) {
      final gps = LatLongConverter().getLatLongFromOSGB(easting, northing);
      final grid = BusStopService.gpsToUKGrid(
          gps.lat.toDouble(), gps.long.toDouble());
      expect(grid['easting']!, closeTo(easting, 5), reason: '$easting,$northing');
      expect(grid['northing']!, closeTo(northing, 5), reason: '$easting,$northing');
    }
  });
}
