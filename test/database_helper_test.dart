import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_project/db/database_helper.dart';

Position _pos(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime(2026, 5, 29),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  // sqflite has no host implementation; route it through the FFI backend
  // so DatabaseHelper's openDatabase/query/etc. run in a plain `flutter test`.
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  // The singleton caches one DB across tests — clear the table before each.
  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('coordinates');
  });

  test('insertCoordinate then getCoordinates returns the stored row', () async {
    await DatabaseHelper.instance.insertCoordinate(_pos(40.4168, -3.7038));

    final rows = await DatabaseHelper.instance.getCoordinates();
    expect(rows.length, 1);
    expect(rows.first['latitude'], 40.4168);
    expect(rows.first['longitude'], -3.7038);
    expect(rows.first['timestamp'], isA<String>());
  });

  test('multiple inserts accumulate', () async {
    await DatabaseHelper.instance.insertCoordinate(_pos(40.0, -3.0));
    await DatabaseHelper.instance.insertCoordinate(_pos(41.0, -4.0));

    final rows = await DatabaseHelper.instance.getCoordinates();
    expect(rows.length, 2);
  });

  test('updateCoordinate changes latitude/longitude of the row', () async {
    await DatabaseHelper.instance.insertCoordinate(_pos(40.0, -3.0));
    final id = (await DatabaseHelper.instance.getCoordinates()).first['id'] as int;

    await DatabaseHelper.instance.updateCoordinate(id, '41.5', '-4.5');

    final updated = (await DatabaseHelper.instance.getCoordinates()).first;
    // REAL column affinity coerces the String values back to doubles.
    expect(updated['latitude'], 41.5);
    expect(updated['longitude'], -4.5);
  });

  test('deleteCoordinate removes the row', () async {
    await DatabaseHelper.instance.insertCoordinate(_pos(40.0, -3.0));
    final id = (await DatabaseHelper.instance.getCoordinates()).first['id'] as int;

    await DatabaseHelper.instance.deleteCoordinate(id);

    final rows = await DatabaseHelper.instance.getCoordinates();
    expect(rows, isEmpty);
  });

  test('getCoordinates on an empty table returns an empty list', () async {
    final rows = await DatabaseHelper.instance.getCoordinates();
    expect(rows, isEmpty);
  });

  test('updateCoordinate with a non-numeric String falls back to TEXT storage',
      () async {
    await DatabaseHelper.instance.insertCoordinate(_pos(40.0, -3.0));
    final id = (await DatabaseHelper.instance.getCoordinates()).first['id'] as int;

    // The DB layer (verbatim W12 signature) accepts Strings; SQLite keeps a
    // non-numeric value as TEXT even in a REAL column — this is exactly why
    // map_screen reads defensively instead of casting `as double`.
    await DatabaseHelper.instance.updateCoordinate(id, 'abc', '');

    final row = (await DatabaseHelper.instance.getCoordinates()).first;
    expect(row['latitude'], isA<String>());
  });
}
