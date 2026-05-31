import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class TasksFilePersistenceScreen extends StatefulWidget {
  const TasksFilePersistenceScreen({super.key});

  @override
  State<TasksFilePersistenceScreen> createState() =>
      _TasksFilePersistenceScreenState();
}

class _TasksFilePersistenceScreenState
    extends State<TasksFilePersistenceScreen> {
  final TextEditingController _textController = TextEditingController();
  String _filePath = '';
  String _fileContent = '';

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/tasks.txt');
      _filePath = file.path;

      if (await file.exists()) {
        _fileContent = await file.readAsString();
        _textController.text = _fileContent;
      } else {
        await file.create();
      }

      setState(() {});
    } catch (e) {
      // ignore: avoid_print
      print('Error loading file: $e');
    }
  }

  Future<void> _saveFile() async {
    try {
      final file = File(_filePath);
      await file.writeAsString(_textController.text);
      setState(() {
        _fileContent = _textController.text;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File saved successfully!')),
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error saving file: $e');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task list — File persistence')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _textController,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Tasks for today',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _saveFile,
                child: const Text('Save Tasks'),
              ),
            ),
            const SizedBox(height: 16),
            Text('File Path: $_filePath'),
          ],
        ),
      ),
    );
  }
}
