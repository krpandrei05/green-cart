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
  List<Map<String, dynamic>> _scans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadScans();
  }

  Future<void> _loadScans() async {
    final scans = await DatabaseHelper.instance.getScans();
    setState(() {
      _scans = scans.reversed.toList();
      _loading = false;
    });
  }

  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm delete"),
          content: Text("Do you want to delete this scan?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () async {
                await DatabaseHelper.instance.deleteScan(id);
                Navigator.of(context).pop();
                _loadScans();
              },
            ),
          ],
        );
      },
    );
  }

  void _showRenameDialog(int id, String currentName) {
    TextEditingController nameController =
        TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Rename product"),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: "Product name"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Save"),
              onPressed: () async {
                Navigator.of(context).pop();
                await DatabaseHelper.instance.updateScan(id, nameController.text);
                _loadScans();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareCsv() async {
    final scans = await DatabaseHelper.instance.getScans();
    if (!mounted) return;
    if (scans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No scans to share yet.')),
      );
      return;
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/eco_scans.csv');
      final buffer = StringBuffer('barcode;name;eco_grade;nutri_grade;timestamp\n');
      for (final s in scans) {
        buffer.writeln(
            '${s['barcode']};${s['name']};${s['eco_grade']};${s['nutri_grade']};${s['timestamp']}');
      }
      await file.writeAsString(buffer.toString());
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'EcoScan scanned products exported from green-cart',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing CSV: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan History'),
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
              _loadScans();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _scans.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No scans yet', style: TextStyle(fontSize: 18)),
                        SizedBox(height: 8),
                        Text(
                          'Scan a product from the Scan tab to start your green history.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _scans.length,
                  itemBuilder: (context, index) {
                    final s = _scans[index];
                    final grade = (s['eco_grade'] ?? '').toString();
                    final nutri = (s['nutri_grade'] ?? '').toString();
                    final id = s['id'] as int;
                    final name = s['name']?.toString() ?? 'Unknown product';
                    String date = '';
                    final ms = int.tryParse(s['timestamp']?.toString() ?? '');
                    if (ms != null) {
                      date = DateFormat('dd/MM/yyyy HH:mm')
                          .format(DateTime.fromMillisecondsSinceEpoch(ms));
                    }
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: MyApp.gradeColor(grade),
                          child: Text(
                            MyApp.gradeLabel(grade),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(name),
                        subtitle: Text(
                          'Eco-Score ${MyApp.gradeLabel(grade)} · Nutri ${MyApp.gradeLabel(nutri)}\n$date',
                        ),
                        isThreeLine: true,
                        onTap: () => _showDeleteDialog(id),
                        onLongPress: () => _showRenameDialog(id, name),
                      ),
                    );
                  },
                ),
    );
  }
}
