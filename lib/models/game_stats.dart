class GameStats {
  static const int xpPerScan = 10;
  static const int sustainableBonus = 15;
  static const int xpPerLevel = 50;
  static const int weeklyGoalDefault = 5;

  static const Map<String, String> badgeLabels = {
    'first_scan': 'First Scan',
    'eco_shopper': 'Eco Shopper · 5 scans',
    'eco_warrior': 'Eco Warrior · 10 scans',
    'green_choice': 'Green Choice · 3 sustainable',
    'streak_3': '3-Day Streak',
    'madrid_verde': 'Madrid Verde · weekly goal',
  };

  final int scanCount;
  final int xp;
  final int level;
  final int streak;
  final int weeklyCount;
  final int weeklyGoal;
  final int xpIntoLevel;
  final int xpToNextLevel;
  final Set<String> badges;

  const GameStats({
    required this.scanCount,
    required this.xp,
    required this.level,
    required this.streak,
    required this.weeklyCount,
    required this.weeklyGoal,
    required this.xpIntoLevel,
    required this.xpToNextLevel,
    required this.badges,
  });

  bool get weeklyDone => weeklyCount >= weeklyGoal;

  factory GameStats.fromScans(
    List<DateTime> scanTimestamps, {
    int sustainableScans = 0,
    Set<String> persistedBadges = const <String>{},
    int weeklyGoal = weeklyGoalDefault,
    DateTime? now,
  }) {
    final ref = now ?? DateTime.now();
    final scanCount = scanTimestamps.length;
    final xp = scanCount * xpPerScan + sustainableScans * sustainableBonus;
    final level = xp ~/ xpPerLevel + 1;
    final xpIntoLevel = xp % xpPerLevel;
    final xpToNextLevel = xpPerLevel - xpIntoLevel;

    final dayKeys = scanTimestamps.map(_dayKey).toSet();
    final streak = _computeStreak(dayKeys, ref);

    final weekStart = _startOfWeek(ref);
    final weeklyCount = scanTimestamps
        .where((t) => !t.isBefore(weekStart) && !t.isAfter(ref))
        .length;

    final earned = <String>{...persistedBadges};
    if (scanCount >= 1) earned.add('first_scan');
    if (scanCount >= 5) earned.add('eco_shopper');
    if (scanCount >= 10) earned.add('eco_warrior');
    if (sustainableScans >= 3) earned.add('green_choice');
    if (streak >= 3) earned.add('streak_3');
    if (weeklyCount >= weeklyGoal) earned.add('madrid_verde');

    return GameStats(
      scanCount: scanCount,
      xp: xp,
      level: level,
      streak: streak,
      weeklyCount: weeklyCount,
      weeklyGoal: weeklyGoal,
      xpIntoLevel: xpIntoLevel,
      xpToNextLevel: xpToNextLevel,
      badges: earned,
    );
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // consecutive days ending today or yesterday
  static int _computeStreak(Set<String> dayKeys, DateTime ref) {
    if (dayKeys.isEmpty) return 0;
    var cursor = DateTime(ref.year, ref.month, ref.day);
    if (!dayKeys.contains(_dayKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!dayKeys.contains(_dayKey(cursor))) return 0;
    }
    var streak = 0;
    while (dayKeys.contains(_dayKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // monday of the week
  static DateTime _startOfWeek(DateTime ref) {
    final day = DateTime(ref.year, ref.month, ref.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }
}
