import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../app.dart';
import '../db/database_helper.dart';

class SecondScreen extends StatefulWidget {
  const SecondScreen({super.key});

  @override
  _SecondScreenState createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  List<List<String>> _dbCoordinates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDbCoordinates();
  }

  Future<void> _loadDbCoordinates() async {
    List<Map<String, dynamic>> dbCoords = await DatabaseHelper.instance.getCoordinates();
    setState(() {
      _dbCoordinates = dbCoords.map((c) => [
        c['timestamp'].toString(),
        c['latitude'].toString(),
        c['longitude'].toString()
      ]).toList().reversed.toList();
      _loading = false;
    });
  }

  void _loadDbCoordinatesAndUpdate() async {
    List<Map<String, dynamic>> dbCoords = await DatabaseHelper.instance.getCoordinates();
    setState(() {
      _dbCoordinates = dbCoords.map((c) => [
        c['timestamp'].toString(),
        c['latitude'].toString(),
        c['longitude'].toString()
      ]).toList().reversed.toList();
    });
  }

  void _showDeleteDialog(String timestamp) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm delete $timestamp"),
          content: Text("Do you want to delete this coordinate?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () async {
                await DatabaseHelper.instance.deleteCoordinate(timestamp);
                Navigator.of(context).pop();
                _loadDbCoordinatesAndUpdate();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareCsv() async {
    final dbCoords = await DatabaseHelper.instance.getCoordinates();
    if (!mounted) return;
    if (dbCoords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No check-ins to share yet.')),
      );
      return;
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/eco_checkins.csv');
      final buffer = StringBuffer('timestamp;latitude;longitude\n');
      for (final c in dbCoords) {
        buffer.writeln('${c['timestamp']};${c['latitude']};${c['longitude']}');
      }
      await file.writeAsString(buffer.toString());
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'EcoScan check-ins exported from green-cart',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing CSV: $e')),
      );
    }
  }

  void _showUpdateDialog(String timestamp, String currentLat, String currentLong) {
    TextEditingController latController = TextEditingController(text: currentLat);
    TextEditingController longController = TextEditingController(text: currentLong);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Update coordinates for $timestamp"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: latController,
                decoration: InputDecoration(labelText: "Latitude"),
              ),
              TextField(
                controller: longController,
                decoration: InputDecoration(labelText: "Longitude"),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Update"),
              onPressed: () async {
                Navigator.of(context).pop();
                await DatabaseHelper.instance.updateCoordinate(timestamp, latController.text, longController.text);
                _loadDbCoordinatesAndUpdate();
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
      appBar: AppBar(
        title: Text('Check-in History'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            tooltip: 'Share CSV',
            onPressed: _shareCsv,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _loadDbCoordinates();
            },
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _dbCoordinates.isEmpty
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
                  itemCount: _dbCoordinates.length,
                  itemBuilder: (context, index) {
                    var coord = _dbCoordinates[index];
                    var formattedDate = DateFormat('dd/MM/yyyy HH:mm')
                        .format(DateTime.fromMillisecondsSinceEpoch(int.parse(coord[0])));
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.store, color: MyApp.ecoGreen),
                        title: Text('Check-in #${_dbCoordinates.length - index}'),
                        subtitle: Text(
                          '$formattedDate\nLat: ${coord[1]}, Lng: ${coord[2]}',
                        ),
                        trailing: Text('+5 XP', style: TextStyle(color: MyApp.ecoGreen)),
                        isThreeLine: true,
                        onTap: () => _showDeleteDialog(coord[0]),
                        onLongPress: () => _showUpdateDialog(coord[0], coord[1], coord[2]),
                      ),
                    );
                  },
                ),
    );
  }
}
