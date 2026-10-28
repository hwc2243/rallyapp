import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/app_session.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.session});

  final AppSession session;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _dividerExtent = 16.0;
  double _splitRatio = 0.5;

  void _resize(double delta, double availableExtent) {
    if (availableExtent <= 0) return;
    setState(
      () => _splitRatio = (_splitRatio + delta / availableExtent)
          .clamp(0.15, 0.85)
          .toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.session.organization.name ?? 'RallyMaster')),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final portrait =
            MediaQuery.orientationOf(context) == Orientation.portrait;
        final availableExtent =
            (portrait ? constraints.maxHeight : constraints.maxWidth) -
            _dividerExtent;
        final firstExtent = availableExtent * _splitRatio;
        final secondExtent = availableExtent - firstExtent;
        final divider = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) => _resize(
            portrait ? details.delta.dy : details.delta.dx,
            availableExtent,
          ),
          child: MouseRegion(
            cursor: portrait
                ? SystemMouseCursors.resizeUpDown
                : SystemMouseCursors.resizeLeftRight,
            child: SizedBox(
              height: portrait ? _dividerExtent : null,
              width: portrait ? null : _dividerExtent,
              child: Center(
                child: Container(
                  height: portrait ? 4 : 48,
                  width: portrait ? 48 : 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        );

        return portrait
            ? Column(
                children: [
                  SizedBox(height: firstExtent, child: const LiveLocationMap()),
                  divider,
                  SizedBox(
                    height: secondExtent,
                    child: const _PlaceholderPanel(),
                  ),
                ],
              )
            : Row(
                children: [
                  SizedBox(width: firstExtent, child: const LiveLocationMap()),
                  divider,
                  SizedBox(
                    width: secondExtent,
                    child: const _PlaceholderPanel(),
                  ),
                ],
              );
      },
    ),
  );
}

class _PlaceholderPanel extends StatelessWidget {
  const _PlaceholderPanel();

  @override
  Widget build(BuildContext context) =>
      Container(color: Theme.of(context).colorScheme.surfaceContainerHighest);
}

class LiveLocationMap extends StatefulWidget {
  const LiveLocationMap({super.key});

  @override
  State<LiveLocationMap> createState() => _LiveLocationMapState();
}

class _LiveLocationMapState extends State<LiveLocationMap> {
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
