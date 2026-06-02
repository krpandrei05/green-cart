import 'dart:async';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../app.dart';
import '../services/realtime_db.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final RealtimeDb db = RealtimeDb.instance;

  void _showDeleteDialog(String key) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm delete"),
          content: const Text("Do you want to delete this scan?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Delete"),
              onPressed: () async {
                await db.deleteScan(key);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showRenameDialog(String key, String currentName) {
    final nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Rename product"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Product name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Save"),
              onPressed: () async {
                await db.updateScan(key, nameController.text);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareCsv() async {
    final scans = await db.getScans();
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
      final buffer = StringBuffer('barcode;name;ecoGrade;nutriGrade;timestamp\n');
      for (final s in scans) {
        buffer.writeln(
            '${s['barcode']};${s['name']};${s['ecoGrade']};${s['nutriGrade']};${s['timestamp']}');
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
        title: const Text('Scan History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share CSV',
            onPressed: _shareCsv,
          ),
        ],
      ),
      // Read pattern: live StreamBuilder on the user's scans node.
      body: StreamBuilder<DatabaseEvent>(
        // timeout so an unreachable / not-yet-provisioned RTDB falls through to
        // the empty state instead of spinning forever.
        stream: (db.scansStream ?? const Stream<DatabaseEvent>.empty())
            .timeout(const Duration(seconds: 8)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // On error (RTDB unavailable / not provisioned) fall through to the
          // empty state rather than showing a raw error.
          final scans = snapshot.hasData && !snapshot.hasError
              ? RealtimeDb.parseScans(snapshot.data!.snapshot.value)
                  .reversed
                  .toList()
              : <Map<String, dynamic>>[];
          if (scans.isEmpty) {
            return Center(
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
            );
          }
          return ListView.builder(
            itemCount: scans.length,
            itemBuilder: (context, index) {
              final s = scans[index];
              final grade = (s['ecoGrade'] ?? '').toString();
              final nutri = (s['nutriGrade'] ?? '').toString();
              final key = s['key'].toString();
              final name = s['name']?.toString() ?? 'Unknown product';
              String date = '';
              final ms = s['timestamp'];
              if (ms is num) {
                date = DateFormat('dd/MM/yyyy HH:mm')
                    .format(DateTime.fromMillisecondsSinceEpoch(ms.toInt()));
              }
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: MyApp.gradeColor(grade),
                    child: Text(
                      MyApp.gradeLabel(grade),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(name),
                  subtitle: Text(
                    'Eco-Score ${MyApp.gradeLabel(grade)} · Nutri ${MyApp.gradeLabel(nutri)}\n$date',
                  ),
                  isThreeLine: true,
                  onTap: () => _showDeleteDialog(key),
                  onLongPress: () => _showRenameDialog(key, name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
