import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../app.dart';
import '../db/database_helper.dart';
import '../models/game_stats.dart';
import '../models/product.dart';
import '../services/off_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final DatabaseHelper db = DatabaseHelper.instance;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<Position?> _currentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    return Geolocator.getCurrentPosition();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy || capture.barcodes.isEmpty) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);

    final product = await OffService.fetchProduct(code);
    if (!mounted) return;
    if (product == null) {
      messenger.showSnackBar(
        SnackBar(content: Text('Product not found ($code)')),
      );
      setState(() => _busy = false);
      return;
    }

    final poor = product.isPoorEco;

    final position = await _currentPosition();
    await db.insertScan(
      product,
      latitude: position?.latitude,
      longitude: position?.longitude,
    );
    final stats = await db.computeGameStats();
    final newly = await db.awardBadges(stats);
    if (!mounted) return;

    Fluttertoast.showToast(
      msg: 'Scanned! (XP ${stats.xp}, Lv ${stats.level})',
      backgroundColor: MyApp.ecoGreen,
      textColor: Colors.white,
    );
    if (poor) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            'Poor Eco-Score (${product.ecoGrade.toUpperCase()}) — '
            'try a greener alternative!',
          ),
        ),
      );
    }
    await _showResultDialog(product, newly, poor);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _showResultDialog(Product product, Set<String> newly, bool poor) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: MyApp.gradeColor(product.ecoGrade),
                child: Text(
                  MyApp.gradeLabel(product.ecoGrade),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(product.name)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🎉 +${product.isSustainable ? GameStats.xpPerScan + GameStats.sustainableBonus : GameStats.xpPerScan} XP earned',
                style: const TextStyle(
                  color: MyApp.ecoGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Eco-Score: ${MyApp.gradeLabel(product.ecoGrade)}'
                '${product.ecoScore != null ? ' (${product.ecoScore})' : ''}',
              ),
              Text('Nutri-Score: ${MyApp.gradeLabel(product.nutriGrade)}'),
              if (product.origin.isNotEmpty) Text('Origin: ${product.origin}'),
              if (poor)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Poor Eco-Score. Try a more sustainable alternative!',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              if (product.isSustainable)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '🌱 Great choice! +${GameStats.sustainableBonus} bonus XP.',
                    style: const TextStyle(color: MyApp.ecoGreen),
                  ),
                ),
              for (final id in newly)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('🎉 Badge unlocked: ${GameStats.badgeLabels[id] ?? id}'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan a product')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.no_photography, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Camera permission is required to scan products.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Enable the camera in your phone settings, then return here.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_busy)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
