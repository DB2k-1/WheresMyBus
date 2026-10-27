import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wheres_my_bus/models/bus_stop.dart';
import 'package:wheres_my_bus/utils/csv_line.dart';

void main() {
  test('plain fields', () {
    expect(parseCsvLine('150,73476,490000179F,Piccadilly Circus,529391'),
        ['150', '73476', '490000179F', 'Piccadilly Circus', '529391']);
  });

  test('quoted field keeps its comma', () {
    final values = parseCsvLine(
        '25819,58564,490007611E,"Guy, Earl of Warwick",547058,175714,109,E908,0');
    expect(values, hasLength(9));
    expect(values[3], 'Guy, Earl of Warwick');
    expect(values[4], '547058');
  });

  test('line break inside a quoted field stays in one row', () {
    expect(parseCsv('h1,h2\r\n1,"Sidcup / Carlton Road\r\n",2\r\n\r\n3,x,4\r\n'), [
      ['h1', 'h2'],
      ['1', 'Sidcup / Carlton Road', '2'],
      ['3', 'x', '4'],
    ]);
  });

  test('doubled quote inside a quoted field', () {
    expect(parseCsvLine('a,"say ""hi"", ok",b'), ['a', 'say "hi", ok', 'b']);
  });

  test('every bundled bus stop has 9 fields and a clean name', () {
    final rows = parseCsv(File('assets/bus-stops.csv').readAsStringSync());
    expect(rows.first.first, 'Stop_Code_LBSL');
    for (final values in rows.skip(1)) {
      final String row = values.join(',');
      expect(values.length, 9, reason: row);
      final stop = BusStop.fromCsv(values);
      expect(stop.stopName, isNot(contains('"')), reason: row);
      expect(stop.stopName, isNot(contains('\n')), reason: row);
      expect(stop.locationEasting, greaterThan(0), reason: row);
    }
    final names = rows.skip(1).map((v) => v[3]);
    expect(names, contains('Guy, Earl of Warwick'));
    expect(names, contains('Sidcup / Carlton Road'));
  });

  test('every bundled route sequence row has 11 fields', () {
    final rows = parseCsv(File('assets/bus-sequences.csv').readAsStringSync());
    for (final values in rows.skip(1)) {
      expect(values.length, 11, reason: values.join(','));
    }
  });
}
