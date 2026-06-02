import 'package:flutter/material.dart';
import 'app.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/map_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  int _dataVersion = 0;

  static const int _scanIndex = 2;

  List<Widget> get _screens => [
        HomeScreen(key: ValueKey('home_$_dataVersion')),
        const HistoryScreen(), // live via StreamBuilder — no key churn needed
        const SizedBox.shrink(),
        MapScreen(key: ValueKey('map_$_dataVersion')),
      ];

  void _onItemTapped(int index) {
    if (index == _scanIndex) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ScanScreen()),
      ).then((_) {
        // refresh after scan
        if (mounted) setState(() => _dataVersion++);
      });
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.eco),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: MyApp.ecoGreen,
        onTap: _onItemTapped,
      ),
    );
  }
}
