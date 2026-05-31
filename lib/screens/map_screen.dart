import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../app.dart';
import '../db/database_helper.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<Marker> markers = [];
  List<LatLng> routeCoordinates = [];
  LatLng? _myLocation;

  static const LatLng _madridCenter = LatLng(40.4168, -3.7038);

  @override
  void initState() {
    super.initState();
    loadMarkers();
    loadRouteCoordinates();
    _locateMe();
  }

  Future<void> loadMarkers() async {
    final scans = await DatabaseHelper.instance.getScans();
    final List<Marker> loadedMarkers = [];
    for (final s in scans) {
      if (s['latitude'] == null || s['longitude'] == null) continue;
      loadedMarkers.add(
        Marker(
          point: LatLng(s['latitude'], s['longitude']),
          width: 80,
          height: 80,
          child: Icon(
            Icons.location_pin,
            size: 50,
            color: MyApp.gradeColor((s['eco_grade'] ?? '').toString()),
          ),
        ),
      );
    }
    // me marker
    if (_myLocation != null) {
      loadedMarkers.add(
        Marker(
          point: _myLocation!,
          width: 80,
          height: 80,
          child: const Icon(Icons.my_location, size: 36, color: Colors.blue),
        ),
      );
    }
    setState(() {
      markers = loadedMarkers;
    });
  }

  Future<void> loadRouteCoordinates() async {
    final scans = await DatabaseHelper.instance.getScans();
    setState(() {
      routeCoordinates = scans
          .where((s) => s['latitude'] != null && s['longitude'] != null)
          .map((s) => LatLng(s['latitude'], s['longitude']))
          .toList();
    });
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

  Future<void> _locateMe() async {
    final pos = await _currentPosition();
    if (!mounted) return;
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location unavailable — grant permission to see yourself on the map.',
          ),
        ),
      );
      return;
    }
    final me = LatLng(pos.latitude, pos.longitude);
    setState(() => _myLocation = me);
    await loadMarkers();
    _mapController.move(me, 15);
  }

  void _zoomIn() {
    final z = (_mapController.camera.zoom + 1).clamp(3.0, 18.0);
    _mapController.move(_mapController.camera.center, z);
  }

  void _zoomOut() {
    final z = (_mapController.camera.zoom - 1).clamp(3.0, 18.0);
    _mapController.move(_mapController.camera.center, z);
  }

  void _refresh() {
    loadMarkers();
    loadRouteCoordinates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map View')),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'zoomIn',
            backgroundColor: MyApp.ecoGreen,
            tooltip: 'Zoom in',
            onPressed: _zoomIn,
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'zoomOut',
            backgroundColor: MyApp.ecoGreen,
            tooltip: 'Zoom out',
            onPressed: _zoomOut,
            child: const Icon(Icons.remove, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'refresh',
            backgroundColor: MyApp.ecoGreen,
            tooltip: 'Refresh map',
            onPressed: _refresh,
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'locate',
            backgroundColor: MyApp.ecoGreen,
            tooltip: 'My location',
            onPressed: _locateMe,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter: _madridCenter,
          initialZoom: 14,
          interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
        ),
        children: [
          openStreetMapTileLayer,
          MarkerLayer(markers: markers),
          PolylineLayer(
            polylines: [
              Polyline(
                points: routeCoordinates,
                color: Colors.pink,
                strokeWidth: 8.0,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

TileLayer get openStreetMapTileLayer => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      // OSM needs a real app id or returns 403
      userAgentPackageName: 'es.upm.mad.greencart',
    );
