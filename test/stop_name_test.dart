import 'package:flutter_test/flutter_test.dart';
import 'package:wheres_my_bus/utils/stop_name.dart';

void main() {
  test('tube and rail markers become badges', () {
    final s = StopName.parse('Trafalgar Square / Charing Cross Stn <>#');
    expect(s.name, 'Trafalgar Square / Charing Cross Stn');
    expect(s.interchanges, {Interchange.tube, Interchange.rail});
  });

  test('marker in the middle of a name', () {
    final s = StopName.parse('Westminster Stn <> / Parliament Square');
    expect(s.name, 'Westminster Stn / Parliament Square');
    expect(s.interchanges, {Interchange.tube});
  });

  test('DLR', () {
    final s = StopName.parse('Limehouse Station # [dlr]');
    expect(s.name, 'Limehouse Station');
    expect(s.interchanges, {Interchange.rail, Interchange.dlr});
  });

  test('plain names are untouched', () {
    final s = StopName.parse('Piccadilly Circus');
    expect(s.name, 'Piccadilly Circus');
    expect(s.interchanges, isEmpty);
  });

  test('Overground, tram and river markers', () {
    expect(StopName.parse('Kilburn High Road Station>lol<').interchanges, {Interchange.overground});
    expect(StopName.parse('Kilburn High Road Station>lol<').name, 'Kilburn High Road Station');
    final b = StopName.parse('Beckenham Junction Station # >t<');
    expect(b.name, 'Beckenham Junction Station');
    expect(b.interchanges, {Interchange.rail, Interchange.tram});
    expect(StopName.parse('Putney Pier >r<').interchanges, {Interchange.river});
  });
}
