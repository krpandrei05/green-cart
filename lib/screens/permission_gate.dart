import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../app.dart';

class PermissionGate extends StatefulWidget {
  final Widget child;
  const PermissionGate({super.key, required this.child});

  @override
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate> {
  bool _checking = true;
  bool _granted = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final camera = await Permission.camera.status;
    final location = await Permission.location.status;
    setState(() {
      _granted = camera.isGranted && location.isGranted;
      _checking = false;
    });
  }

  Future<void> _request() async {
    final statuses = await [Permission.camera, Permission.location].request();
    final granted = (statuses[Permission.camera]?.isGranted ?? false) &&
        (statuses[Permission.location]?.isGranted ?? false);
    if (!mounted) return;
    if (granted) {
      setState(() => _granted = true);
      return;
    }
    final permanentlyDenied =
        (statuses[Permission.camera]?.isPermanentlyDenied ?? false) ||
            (statuses[Permission.location]?.isPermanentlyDenied ?? false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          permanentlyDenied
              ? 'Enable Camera & Location in Settings to play.'
              : 'Camera & Location are required to play.',
        ),
      ),
    );
    if (permanentlyDenied) {
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_granted) return widget.child;
    return Scaffold(
      backgroundColor: MyApp.ecoBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.eco, size: 72, color: MyApp.ecoGreen),
              const SizedBox(height: 24),
              const Text(
                'EcoScan Madrid',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'To play, EcoScan needs your Camera (to scan barcodes) and '
                'Location (to map where you shop).',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _request,
                icon: const Icon(Icons.lock_open),
                label: const Text('Grant access'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyApp.ecoGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _check,
                child: const Text('I already enabled them'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
