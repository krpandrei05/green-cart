import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
  List<LatLng> _coordinates = [];
  final List<LatLng> _dynamicMarkers = [];
  bool _loading = true;

  static const LatLng _madridCenter = LatLng(40.4168, -3.7038);

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    final dbCoords = await DatabaseHelper.instance.getCoordinates();
    final coords = dbCoords
        .map((c) => LatLng(c['latitude'] as double, c['longitude'] as double))
        .toList();
    setState(() {
      _coordinates = coords;
      _loading = false;
    });
  }

  List<LatLng> _lastRoute(List<LatLng> all) {
    if (all.length <= 10) return all;
    return all.sublist(all.length - 10);
  }

  double _totalDistanceKm(List<LatLng> route) {
    if (route.length < 2) return 0;
    const Distance distance = Distance();
    double total = 0;
    for (var i = 0; i < route.length - 1; i++) {
      total += distance.as(LengthUnit.Kilometer, route[i], route[i + 1]);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final route = _lastRoute(_coordinates);
    final totalKm = _totalDistanceKm(route);
    final initialCenter =
        _coordinates.isNotEmpty ? _coordinates.last : _madridCenter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eco Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _loadMarkers();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 14,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onLongPress: (tapPosition, latlng) {
                setState(() {
                  _dynamicMarkers.add(latlng);
                });
                _mapController.move(latlng, _mapController.camera.zoom);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Marker added at ${latlng.latitude.toStringAsFixed(4)}, ${latlng.longitude.toStringAsFixed(4)}',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'es.upm.mad.greencart',
              ),
              if (route.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: route,
                      color: MyApp.ecoGreen,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: _coordinates.map((coord) {
                  final isFirst = coord == _coordinates.first;
                  final isLast = coord == _coordinates.last;
                  Color color;
                  double size;
                  if (isLast) {
                    color = Colors.blue;
                    size = 42;
                  } else if (isFirst) {
                    color = Colors.amber;
                    size = 42;
                  } else {
                    color = Colors.red;
                    size = 32;
                  }
                  return Marker(
                    point: coord,
                    width: size,
                    height: size + 20,
                    child: Column(
                      children: [
                        if (isFirst)
                          const Text(
                            'Start',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        if (isLast)
                          const Text(
                            'End',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        Icon(Icons.location_on, color: color, size: size),
                      ],
                    ),
                  );
                }).toList(),
              ),
              MarkerLayer(
                markers: _dynamicMarkers
                    .map(
                      (coord) => Marker(
                        point: coord,
                        width: 36,
                        height: 36,
                        child: const Icon(
                          Icons.push_pin,
                          color: Colors.purple,
                          size: 32,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                _coordinates.isEmpty
                    ? 'No check-ins yet'
                    : 'Distance (last ${route.length}): ${totalKm.toStringAsFixed(2)} km',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (_coordinates.isNotEmpty)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'recenter',
                backgroundColor: MyApp.ecoGreen,
                onPressed: () => _mapController.move(_coordinates.last, 15),
                child: const Icon(Icons.my_location, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
