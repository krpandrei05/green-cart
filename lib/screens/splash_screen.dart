import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app.dart';
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
  StreamSubscription<Position>? _positionStreamSubscription;
  String _uid = '';

  @override
  void initState() {
    super.initState();
    print("initState: Initial state setup.");
    _loadPrefs();
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
    if (prefs.getString('eco_score_threshold') == null) {
      await prefs.setString('eco_score_threshold', 'C');
    }
    if (prefs.getString('gps_radius_m') == null) {
      await prefs.setString('gps_radius_m', '50');
    }
    if (prefs.getString('language') == null) {
      await prefs.setString('language', 'fr');
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

  @override
  Widget build(BuildContext context) {
    print("build: Building the user interface.");
    logger.d("Debug message");
    logger.w("Warning message!");
    logger.e("Error message!!");
    final tracking = _positionStreamSubscription != null;
    return Scaffold(
      appBar: AppBar(
        title: Text('EcoScan Madrid'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.eco, color: MyApp.ecoGreen, size: 32),
                      const SizedBox(width: 12),
                      Text(
                        _uid.isEmpty ? 'Welcome!' : 'Hi, $_uid',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Scan, earn XP, save the planet'),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emoji_events, color: MyApp.ecoGreen),
                      const SizedBox(width: 8),
                      const Text('Progress', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('XP: 120   Level: 3   Streak: 5d'),
                  const SizedBox(height: 4),
                  const Text('60 XP until next badge'),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    tracking ? Icons.location_on : Icons.location_off,
                    color: MyApp.ecoGreen,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Supermarket check-in', style: TextStyle(fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(
                          tracking
                              ? 'GPS tracking active'
                              : 'Enable to earn XP',
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: tracking,
                    onChanged: (value) {
                      setState(() {
                        if (value) {
                          startTracking();
                        } else {
                          stopTracking();
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flag, color: MyApp.ecoGreen),
                      const SizedBox(width: 8),
                      const Text('Weekly Challenge', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Scan 5 products with Eco-Score A or B'),
                  const SizedBox(height: 4),
                  const Text('Reward: "Madrid Verde" badge'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void startTracking() async {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        writePositionToFile(position);
      },
    );
  }

  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  Future<void> writePositionToFile(Position position) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/gps_coordinates.csv');
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await file.writeAsString('${timestamp};${position.latitude};${position.longitude}\n', mode: FileMode.append);
  }

  @override
  void dispose() {
    print("dispose: Cleaning up before the state is destroyed.");
    _uidController.dispose();
    _tokenController.dispose();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }
}
