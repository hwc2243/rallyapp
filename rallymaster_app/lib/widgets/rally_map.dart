import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Reusable live map that follows the device while location access is allowed.
class RallyMap extends StatefulWidget {
  const RallyMap({super.key});

  @override
  State<RallyMap> createState() => _RallyMapState();
}

class _RallyMapState extends State<RallyMap> {
  final _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;
  LatLng? _position;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  Future<void> _startLocationUpdates() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      setState(() => _locationError = 'Location services are disabled.');
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(
        () => _locationError =
            'Location permission is required to follow your position.',
      );
      return;
    }
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 1,
          ),
        ).listen(
          (position) {
            final point = LatLng(position.latitude, position.longitude);
            if (!mounted) return;
            setState(() {
              _position = point;
              _locationError = null;
            });
            _mapController.move(point, 16);
          },
          onError: (Object error) {
            if (mounted) {
              setState(
                () => _locationError = 'Unable to read location: $error',
              );
            }
          },
        );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter: LatLng(39.8283, -98.5795),
          initialZoom: 4,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.rallyapp.rallymaster',
          ),
          if (_position != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _position!,
                  width: 48,
                  height: 48,
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.blue,
                    size: 36,
                  ),
                ),
              ],
            ),
        ],
      ),
      if (_locationError != null)
        Positioned(
          left: 12,
          right: 12,
          top: 12,
          child: Material(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_locationError!),
            ),
          ),
        ),
    ],
  );
}
