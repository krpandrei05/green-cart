import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../app.dart';

class SecondScreen extends StatefulWidget {
  const SecondScreen({super.key});

  @override
  _SecondScreenState createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  List<List<String>> _coordinates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCoordinates();
  }

  Future<void> _loadCoordinates() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/gps_coordinates.csv');
    if (!await file.exists()) {
      setState(() => _loading = false);
      return;
    }
    List<String> lines = await file.readAsLines();
    setState(() {
      _coordinates = lines.reversed.map((line) => line.split(';')).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Check-in History'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _loadCoordinates();
            },
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _coordinates.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.explore_off, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No check-ins yet',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Enable GPS tracking from the Home screen to log visited supermarkets.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _coordinates.length,
                  itemBuilder: (context, index) {
                    var coord = _coordinates[index];
                    if (coord.length < 3) {
                      return const SizedBox.shrink();
                    }
                    var formattedDate = DateFormat('dd/MM/yyyy HH:mm')
                        .format(DateTime.fromMillisecondsSinceEpoch(int.parse(coord[0])));
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.store, color: MyApp.ecoGreen),
                        title: Text('Check-in #${_coordinates.length - index}'),
                        subtitle: Text(
                          '$formattedDate\nLat: ${coord[1]}, Lng: ${coord[2]}',
                        ),
                        trailing: Text('+5 XP', style: TextStyle(color: MyApp.ecoGreen)),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
