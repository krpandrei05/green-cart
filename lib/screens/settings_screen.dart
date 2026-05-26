import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, TextEditingController> controllers = {};
  Future<Map<String, dynamic>>? _prefsFuture;

  @override
  void initState() {
    super.initState();
    _prefsFuture = _fetchAllPreferences();
  }

  Future<Map<String, dynamic>> _fetchAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final Map<String, dynamic> prefsMap = {};
    for (String key in keys) {
      prefsMap[key] = prefs.get(key);
      controllers[key] = TextEditingController(text: prefs.get(key).toString());
    }
    return prefsMap;
  }

  Future<void> _updatePreference(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('EcoScan Settings'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _prefsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            return ListView(
              children: snapshot.data!.entries.map((entry) {
                return ListTile(
                  title: Text("${entry.key}"),
                  subtitle: TextField(
                    controller: controllers[entry.key],
                    decoration: InputDecoration(hintText: "Enter ${entry.key}"),
                    onSubmitted: (value) {
                      _updatePreference(entry.key, value);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${entry.key} updated'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
