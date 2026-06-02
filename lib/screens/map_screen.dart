import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../app.dart';
import '../services/realtime_db.dart';

class MapScreen extends StatefulWidget {
  // bumped by MainScreen after each scan so the map reloads without being
  // destroyed (keeps the user's zoom/pan).
  final int dataVersion;
  const MapScreen({super.key, this.dataVersion = 0});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _scans = [];
  LatLng? _myLocation;
  bool _mapReady = false;

  static const LatLng _madridCenter = LatLng(40.4168, -3.7038);

  @override
  void initState() {
    super.initState();
    _loadScans();
    _locateMe();
  }

  @override
  void didUpdateWidget(MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataVersion != widget.dataVersion) {
      _loadScans(); // a new scan was added → refresh data, keep the camera
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // Single source of truth: fetch scans once, markers + route are derived.
  Future<void> _loadScans() async {
    final scans = await RealtimeDb.instance.getScans();
    if (!mounted) return;
    setState(() => _scans = scans);
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    for (final s in _scans) {
      final lat = s['latitude'];
      final lng = s['longitude'];
      if (lat is! num || lng is! num) continue; // skip scans with no GPS
      markers.add(
        Marker(
          point: LatLng(lat.toDouble(), lng.toDouble()),
          width: 80,
          height: 80,
          child: Icon(
            Icons.location_pin,
            size: 50,
            color: MyApp.gradeColor((s['ecoGrade'] ?? '').toString()),
          ),
        ),
      );
    }
    if (_myLocation != null) {
      markers.add(
        Marker(
          point: _myLocation!,
          width: 80,
          height: 80,
          child: const Icon(Icons.my_location, size: 36, color: Colors.blue),
        ),
      );
    }
    return markers;
  }

  List<LatLng> _buildRoute() {
    final pts = <LatLng>[];
    for (final s in _scans) {
      final lat = s['latitude'];
      final lng = s['longitude'];
      if (lat is num && lng is num) {
        pts.add(LatLng(lat.toDouble(), lng.toDouble()));
      }
    }
    return pts;
  }

  Future<Position?> _currentPosition() async {
    try {
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
      // timeLimit so a device that never gets a fix doesn't hang forever
      return await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      // timeout / no fix / services toggled off mid-call → unavailable
      return null;
    }
  }

  Future<void> _locateMe() async {
    final pos = await _currentPosition();
    if (!mounted) return;
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location unavailable — enable GPS and grant permission to see '
            'yourself on the map.',
          ),
        ),
      );
      return;
    }
    setState(() => _myLocation = LatLng(pos.latitude, pos.longitude));
    if (_mapReady) _mapController.move(_myLocation!, 15);
  }

  void _zoomIn() {
    if (!_mapReady) return;
    final z = (_mapController.camera.zoom + 1).clamp(3.0, 18.0);
    _mapController.move(_mapController.camera.center, z);
  }

  void _zoomOut() {
    if (!_mapReady) return;
    final z = (_mapController.camera.zoom - 1).clamp(3.0, 18.0);
    _mapController.move(_mapController.camera.center, z);
  }

  void _refresh() => _loadScans();

  @override
  Widget build(BuildContext context) {
    final route = _buildRoute();
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
        options: MapOptions(
          initialCenter: _madridCenter,
          initialZoom: 14,
          interactionOptions:
              const InteractionOptions(flags: InteractiveFlag.all),
          onMapReady: () => _mapReady = true,
        ),
        children: [
          openStreetMapTileLayer,
          MarkerLayer(markers: _buildMarkers()),
          if (route.length >= 2)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: route,
                  color: MyApp.ecoGreen,
                  strokeWidth: 6.0,
                ),
              ],
            ),
          const RichAttributionWidget(
            attributions: [
              TextSourceAttribution('OpenStreetMap contributors'),
            ],
          ),
        ],
      ),
    );
  }
}

TileLayer get openStreetMapTileLayer => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      // OSM 403-blocks the default dev.fleaflet UA → use a real package name
      userAgentPackageName: 'es.upm.mad.greencart',
    );
