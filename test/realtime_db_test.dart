import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_project/services/realtime_db.dart';

void main() {
  group('RealtimeDb.parseScans', () {
    test('null / non-map value => empty list', () {
      expect(RealtimeDb.parseScans(null), isEmpty);
      expect(RealtimeDb.parseScans('garbage'), isEmpty);
      expect(RealtimeDb.parseScans(42), isEmpty);
    });

    test('maps each push entry and injects its key', () {
      final value = {
        '-Aaa': {'name': 'Apple', 'ecoGrade': 'a', 'timestamp': 100},
      };
      final scans = RealtimeDb.parseScans(value);
      expect(scans, hasLength(1));
      expect(scans.first['key'], '-Aaa');
      expect(scans.first['name'], 'Apple');
      expect(scans.first['ecoGrade'], 'a');
    });

    test('sorts ascending by timestamp', () {
      final value = {
        '-B': {'name': 'second', 'timestamp': 200},
        '-A': {'name': 'first', 'timestamp': 100},
        '-C': {'name': 'third', 'timestamp': 300},
      };
      final scans = RealtimeDb.parseScans(value);
      expect(scans.map((s) => s['name']).toList(),
          ['first', 'second', 'third']);
    });

    test('skips non-map children and tolerates missing timestamp', () {
      final value = {
        '-A': {'name': 'ok', 'timestamp': 100},
        '-B': 'not-a-map',
        '-C': {'name': 'no-ts'}, // missing timestamp => treated as 0
      };
      final scans = RealtimeDb.parseScans(value);
      expect(scans, hasLength(2));
      // the entry without a timestamp sorts first (0)
      expect(scans.first['name'], 'no-ts');
    });
  });
}
