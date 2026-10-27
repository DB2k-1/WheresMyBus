import 'package:flutter_test/flutter_test.dart';
import 'package:wheres_my_bus/services/tfl_api_service.dart';

// Response shapes captured from the live Countdown feed (Oct 2026).
const stopBody = '''[4,"1.0",1793113887326]
[1,"Trafalgar Square / Charing Cross Stn","Westminster","D","29","Trafalgar Sq",919,1793115261000]
[0,"Trafalgar Square / Charing Cross Stn","Westminster","D"]
[1,"Trafalgar Square / Charing Cross Stn","Westminster","D","24","Pimlico",16432,1793114149000]
''';

const vehicleBody = '''[4,"1.0",1793113887093]
[1,"St Martin's Place","490016161S","K",1793114326000]
[1,"Goodge Street Station","490005084Z","D",1793113907000]
[1,"Horse Guards Parade","490008376S",null,1793114900000]
''';

void main() {
  test('stop arrivals: real destination, letter, towards, vehicle, sorted', () {
    final result = TflApiService.parseStopArrivals(stopBody, '490013767D');
    expect(result.stop?.indicator, 'D');
    expect(result.stop?.towards, 'Westminster');
    expect(result.arrivals.map((a) => a.lineName), ['24', '29']);
    final first = result.arrivals.first;
    expect(first.destination, 'Pimlico');
    expect(first.vehicleId, '16432');
    expect(first.platformName, 'D');
    expect(first.expectedArrival.millisecondsSinceEpoch, 1793114149000);
  });

  test('stop info comes back with no buses due', () {
    final result = TflApiService.parseStopArrivals(
        '[4,"1.0",1]\n[0,"Quiet Road","Somewhere","Q"]\n', 'X');
    expect(result.arrivals, isEmpty);
    expect(result.stop?.indicator, 'Q');
  });

  test('vehicle stops sorted soonest first, missing letter allowed', () {
    final stops = TflApiService.parseVehicleStops(vehicleBody);
    expect(stops.map((s) => s.name),
        ['Goodge Street Station', "St Martin's Place", 'Horse Guards Parade']);
    expect(stops.first.naptanAtco, '490005084Z');
    expect(stops.last.indicator, isNull);
  });
}
