import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app.dart';
import '../services/realtime_db.dart';
import '../models/game_stats.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  RealtimeDb db = RealtimeDb.instance;
  String _uid = '';
  late Future<GameStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = db.computeGameStats();
    _loadPrefs();
  }

  void _refreshStats() {
    setState(() {
      _statsFuture = db.computeGameStats();
    });
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    if (uid != null) setState(() => _uid = uid);
  }

  // share progress
  void _shareProgress() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.share, color: MyApp.ecoGreen),
              title: const Text('Share my eco-progress'),
              onTap: () async {
                Navigator.pop(context);
                final stats = await db.computeGameStats();
                if (!mounted) return;
                await Share.share(
                  'My EcoScan Madrid progress: ${stats.xp} XP, '
                  'Level ${stats.level}, ${stats.streak}-day streak, '
                  '${stats.badges.length} badges. 🌱',
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyApp.ecoBackground,
      appBar: AppBar(
        title: const Text('EcoScan Madrid'),
        backgroundColor: MyApp.ecoGreen,
        foregroundColor: Colors.white,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share progress',
            onPressed: _shareProgress,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshStats,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<GameStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _greetingCard(),
              const SizedBox(height: 12),
              _levelCard(s),
              const SizedBox(height: 12),
              _statsRow(s),
              const SizedBox(height: 12),
              _weeklyCard(s),
              const SizedBox(height: 12),
              _badgesCard(s),
            ],
          );
        },
      ),
    );
  }

  Widget _greetingCard() {
    return Card(
      color: MyApp.ecoGreen,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.eco, color: Colors.white, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _uid.isEmpty ? 'Welcome!' : 'Hi, $_uid',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Scan products to discover their Eco-Score',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _levelCard(GameStats s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: MyApp.ecoGreen,
                  child: Text(
                    '${s.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Level ${s.level}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${s.xp} XP total'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: s.xpIntoLevel / GameStats.xpPerLevel,
                minHeight: 10,
                backgroundColor: Colors.grey.shade300,
                color: MyApp.ecoGreen,
              ),
            ),
            const SizedBox(height: 4),
            Text('${s.xpToNextLevel} XP to level ${s.level + 1}'),
          ],
        ),
      ),
    );
  }

  Widget _statsRow(GameStats s) {
    return Row(
      children: [
        _statTile(Icons.local_fire_department, '${s.streak}', 'Day streak'),
        const SizedBox(width: 8),
        _statTile(Icons.qr_code_scanner, '${s.scanCount}', 'Scans'),
        const SizedBox(width: 8),
        _statTile(Icons.emoji_events, '${s.badges.length}', 'Badges'),
      ],
    );
  }

  Widget _statTile(IconData icon, String value, String label) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: MyApp.ecoGreen),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weeklyCard(GameStats s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: MyApp.ecoGreen),
                const SizedBox(width: 8),
                const Text('Weekly Challenge',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text('${s.weeklyCount} / ${s.weeklyGoal} scans this week'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (s.weeklyCount / s.weeklyGoal).clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Colors.grey.shade300,
                color: MyApp.ecoGreen,
              ),
            ),
            if (s.weeklyDone)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: MyApp.ecoGreen, size: 18),
                    const SizedBox(width: 6),
                    const Text('Done! "Madrid Verde" badge earned'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _badgesCard(GameStats s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, color: MyApp.ecoGreen),
                const SizedBox(width: 8),
                Text(
                  'Badges (${s.badges.length}/${GameStats.badgeLabels.length})',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GameStats.badgeLabels.entries.map((e) {
                final earned = s.badges.contains(e.key);
                return Chip(
                  avatar: Icon(
                    earned ? Icons.check_circle : Icons.lock,
                    size: 18,
                    color: earned ? MyApp.ecoGreen : Colors.grey,
                  ),
                  label: Text(e.value),
                  backgroundColor:
                      earned ? const Color(0xFFC8E6C9) : Colors.grey.shade200,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
