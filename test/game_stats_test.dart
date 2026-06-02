import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_project/models/game_stats.dart';

void main() {
  group('GameStats.fromScans', () {
    test('24 scans => XP 240, Level 5', () {
      final ts = List.generate(24, (_) => DateTime(2026, 5, 1, 10));
      final s = GameStats.fromScans(ts, now: DateTime(2026, 5, 31));
      expect(s.scanCount, 24);
      expect(s.xp, 240); // 24 * 10
      expect(s.level, 5); // 240 ~/ 50 + 1
      expect(s.xpToNextLevel, 10); // 50 - (240 % 50)
    });

    test('empty => zeros, level 1, no streak, no badges', () {
      final s = GameStats.fromScans([], now: DateTime(2026, 5, 31));
      expect(s.xp, 0);
      expect(s.level, 1);
      expect(s.streak, 0);
      expect(s.badges, isEmpty);
    });

    test('sustainable scans add +15 bonus each', () {
      final ts = [DateTime(2026, 5, 1), DateTime(2026, 5, 1)];
      final s = GameStats.fromScans(ts,
          sustainableScans: 1, now: DateTime(2026, 5, 31));
      expect(s.scanCount, 2);
      expect(s.xp, 2 * 10 + 1 * 15); // 35
    });

    test('badge thresholds: 1 -> first_scan, 5 -> eco_shopper, not yet eco_warrior',
        () {
      final s = GameStats.fromScans(
        List.generate(5, (_) => DateTime(2026, 5, 1)),
        now: DateTime(2026, 5, 31),
      );
      expect(s.badges, containsAll(<String>['first_scan', 'eco_shopper']));
      expect(s.badges, isNot(contains('eco_warrior')));
    });

    test('10 scans unlocks eco_warrior', () {
      final s = GameStats.fromScans(
        List.generate(10, (_) => DateTime(2026, 5, 1)),
        now: DateTime(2026, 5, 31),
      );
      expect(s.badges, contains('eco_warrior'));
    });

    test('3 sustainable scans unlock green_choice', () {
      final s = GameStats.fromScans(
        List.generate(3, (_) => DateTime(2026, 5, 1)),
        sustainableScans: 3,
        now: DateTime(2026, 5, 31),
      );
      expect(s.badges, contains('green_choice'));
    });

    test('3 consecutive days ending today => streak 3 + streak_3 badge', () {
      final now = DateTime(2026, 5, 31, 12);
      final ts = [
        DateTime(2026, 5, 31, 9),
        DateTime(2026, 5, 30, 9),
        DateTime(2026, 5, 29, 9),
      ];
      final s = GameStats.fromScans(ts, now: now);
      expect(s.streak, 3);
      expect(s.badges, contains('streak_3'));
    });

    test('a gap breaks the streak', () {
      final now = DateTime(2026, 5, 31, 12);
      final ts = [DateTime(2026, 5, 31, 9), DateTime(2026, 5, 28, 9)];
      final s = GameStats.fromScans(ts, now: now);
      expect(s.streak, 1);
    });

    test('streak survives via yesterday fallback (none today)', () {
      final now = DateTime(2026, 5, 31, 12);
      final ts = [DateTime(2026, 5, 30, 9), DateTime(2026, 5, 29, 9)];
      final s = GameStats.fromScans(ts, now: now);
      expect(s.streak, 2); // counts 30 + 29, ending yesterday
    });

    test('weekly count includes this week, excludes 2 weeks ago', () {
      final now = DateTime(2026, 5, 31, 12);
      final ts = [now, now.subtract(const Duration(days: 14))];
      final s = GameStats.fromScans(ts, now: now);
      expect(s.weeklyCount, 1);
    });

    test('exact level boundary: 50 XP => level 2, 50 XP to next', () {
      final ts = List.generate(5, (_) => DateTime(2026, 5, 1)); // 5 * 10 = 50
      final s = GameStats.fromScans(ts, now: DateTime(2026, 5, 31));
      expect(s.xp, 50);
      expect(s.level, 2);
      expect(s.xpToNextLevel, 50);
    });

    test('persisted badges are sticky even with 0 scans', () {
      final s = GameStats.fromScans(
        [],
        persistedBadges: {'eco_shopper'},
        now: DateTime(2026, 5, 31),
      );
      expect(s.badges, contains('eco_shopper'));
    });

    test('reaching the weekly goal unlocks madrid_verde', () {
      final now = DateTime(2026, 5, 31, 12); // Sunday
      final ts = List.generate(
          GameStats.weeklyGoalDefault, (_) => DateTime(2026, 5, 26, 9));
      final s = GameStats.fromScans(ts, now: now);
      expect(s.weeklyCount, GameStats.weeklyGoalDefault);
      expect(s.weeklyDone, isTrue);
      expect(s.badges, contains('madrid_verde'));
    });

    test('scans only two days ago (not today/yesterday) => streak 0', () {
      final now = DateTime(2026, 5, 31, 12);
      final ts = [DateTime(2026, 5, 29, 9)];
      final s = GameStats.fromScans(ts, now: now);
      expect(s.streak, 0);
    });
  });
}
