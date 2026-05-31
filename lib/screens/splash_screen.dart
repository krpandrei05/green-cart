import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app.dart';
import '../db/database_helper.dart';
import '../models/game_stats.dart';
import 'settings_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final logger = Logger();
  final _uidController = TextEditingController();
  final _tokenController = TextEditingController();
  DatabaseHelper db = DatabaseHelper.instance;
  String _uid = '';
  late Future<GameStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    print("initState: Initial state setup.");
    _statsFuture = db.computeGameStats();
    _loadPrefs();
  }

  void _refreshStats() {
    setState(() {
      _statsFuture = db.computeGameStats();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print("didChangeDependencies: Dependencies updated.");
  }

  @override
  void didUpdateWidget(SplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    print("didUpdateWidget: The widget has been updated from the parent.");
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String? uid = prefs.getString('uid');
    String? token = prefs.getString('token');
    if (uid == null || token == null) {
      _showInputDialog();
    } else {
      logger.d("UID: $uid, Token: $token");
      setState(() => _uid = uid);
    }
  }

  Future<void> _showInputDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('EcoScanner Profile'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _uidController,
                  decoration: InputDecoration(hintText: "Username"),
                ),
                TextField(
                  controller: _tokenController,
                  decoration: InputDecoration(hintText: "API Token"),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                final uid = _uidController.text.trim();
                final token = _tokenController.text.trim();
                if (uid.isEmpty || token.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in both fields to continue.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('uid', uid);
                await prefs.setString('token', token);
                setState(() => _uid = uid);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
    print("build: Building the user interface.");
    logger.d("Debug message");
    logger.w("Warning message!");
    logger.e("Error message!!");
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

  @override
  void dispose() {
    print("dispose: Cleaning up before the state is destroyed.");
    _uidController.dispose();
    _tokenController.dispose();
    super.dispose();
  }
}
