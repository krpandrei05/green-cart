import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/game_stats.dart';
import '../models/product.dart';


// All game data lives per-user under users/{uid}/ so the auth gate and the
// security rules (auth != null && auth.uid == $uid) protect it.
class RealtimeDb {
  RealtimeDb._privateConstructor();
  static final RealtimeDb instance = RealtimeDb._privateConstructor();

  final FirebaseDatabase _db = FirebaseDatabase.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DatabaseReference? get _scansRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.ref('users/$uid/scans');
  }

  DatabaseReference? get _badgesRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.ref('users/$uid/badges');
  }

  // Live stream of the user's scans (Read pattern: onValue + StreamBuilder).
  Stream<DatabaseEvent>? get scansStream => _scansRef?.onValue;

  // Insert: ref.push().set({...})
  Future<void> insertScan(Product product,
      {double? latitude, double? longitude}) async {
    final ref = _scansRef;
    if (ref == null) return;
    // timeout so a missing / unreachable RTDB surfaces as an error instead of
    // hanging the scan flow forever (the caller shows "Scan failed").
    await ref.push().set({
      'barcode': product.barcode,
      'name': product.name,
      'ecoGrade': product.ecoGrade,
      'ecoScore': product.ecoScore,
      'nutriGrade': product.nutriGrade,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }).timeout(const Duration(seconds: 8));
  }

  Future<List<Map<String, dynamic>>> getScans() async {
    final ref = _scansRef;
    if (ref == null) return [];
    try {
      final snapshot = await ref.get().timeout(const Duration(seconds: 8));
      return parseScans(snapshot.value);
    } catch (_) {
      // RTDB unavailable / not provisioned / unreachable → degrade to empty
      return [];
    }
  }

  // Turn a raw RTDB value (a JSON map keyed by push id) into a sorted list,
  // each entry carrying its push key for update/delete. Pure → unit-testable.
  static List<Map<String, dynamic>> parseScans(Object? value) {
    final scans = <Map<String, dynamic>>[];
    if (value is Map) {
      value.forEach((key, v) {
        if (v is Map) {
          scans.add({'key': key.toString(), ...Map<String, dynamic>.from(v)});
        }
      });
    }
    scans.sort((a, b) =>
        ((a['timestamp'] ?? 0) as num).compareTo((b['timestamp'] ?? 0) as num));
    return scans;
  }

  // Update: ref.child(key).update({...})
  Future<void> updateScan(String key, String newName) async {
    final ref = _scansRef;
    if (ref == null) return;
    await ref.child(key).update({'name': newName});
  }

  // Delete: ref.child(key).remove()
  Future<void> deleteScan(String key) async {
    final ref = _scansRef;
    if (ref == null) return;
    await ref.child(key).remove();
  }

  Future<Set<String>> _loadBadges() async {
    final ref = _badgesRef;
    if (ref == null) return <String>{};
    try {
      final snapshot = await ref.get().timeout(const Duration(seconds: 8));
      final value = snapshot.value;
      if (value is Map) {
        return value.keys.map((k) => k.toString()).toSet();
      }
    } catch (_) {
      // RTDB unavailable → no badges rather than crash
    }
    return <String>{};
  }

  Future<GameStats> computeGameStats() async {
    final scans = await getScans();
    final timestamps = <DateTime>[];
    var sustainable = 0;
    for (final s in scans) {
      final ms = s['timestamp'];
      if (ms is num) {
        timestamps.add(DateTime.fromMillisecondsSinceEpoch(ms.toInt()));
      }
      final grade = (s['ecoGrade'] ?? '').toString().toLowerCase();
      if (grade == 'a' || grade == 'b') sustainable++;
    }
    final persisted = await _loadBadges();
    return GameStats.fromScans(
      timestamps,
      sustainableScans: sustainable,
      persistedBadges: persisted,
    );
  }

  Future<Set<String>> awardBadges(GameStats stats) async {
    final ref = _badgesRef;
    if (ref == null) return <String>{};
    final persisted = await _loadBadges();
    final clean = stats.badges.intersection(GameStats.badgeLabels.keys.toSet());
    final newly = clean.difference(persisted);
    if (newly.isNotEmpty) {
      final updates = <String, Object?>{for (final id in newly) id: true};
      await ref.update(updates).timeout(const Duration(seconds: 8));
    }
    return newly;
  }
}
