import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/route_item_display.dart';

/// Reusable live map that follows the device while location access is allowed.
class RallyMap extends StatefulWidget {
  const RallyMap({super.key, this.routeItems = const [], this.onRouteItemTap});

  final List<RouteItemDisplay> routeItems;
  final ValueChanged<RouteItemDisplay>? onRouteItemTap;

  @override
  State<RallyMap> createState() => RallyMapState();
}

class RallyMapState extends State<RallyMap> {
  final _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;
  LatLng? _position;
  String? _locationError;
  bool _followCurrentLocation = true;
  double _mapRotation = 0;

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
            if (_followCurrentLocation) _mapController.move(point, 16);
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
        options: MapOptions(
          initialCenter: LatLng(39.8283, -98.5795),
          initialZoom: 4,
          onPositionChanged: (camera, hasGesture) {
            final rotation = _normalizedRotation(camera.rotation);
            if ((rotation - _mapRotation).abs() > 0.1) {
              setState(() => _mapRotation = rotation);
            }
            if (hasGesture && _followCurrentLocation) {
              setState(() => _followCurrentLocation = false);
            }
          },
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
          if (widget.routeItems.isNotEmpty)
            MarkerLayer(
              markers: widget.routeItems
                  .where(
                    (item) =>
                        item.item.latitude != null &&
                        item.item.longitude != null &&
                        item.item.latitude!.isFinite &&
                        item.item.longitude!.isFinite,
                  )
                  .map(
                    (item) => Marker(
                      point: LatLng(item.item.latitude!, item.item.longitude!),
                      width: 128,
                      height: 66,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () => widget.onRouteItemTap?.call(item),
                        child: Tooltip(
                          message: item.item.itemType == 'NRI'
                              ? item.routeInstruction?.instructionText ?? 'NRI'
                              : item.checkpoint?.name ?? 'Checkpoint',
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: item.item.itemType == 'NRI'
                                    ? const _NriMarker()
                                    : const _CheckpointMarker(),
                              ),
                              const SizedBox(height: 2),
                              _RouteItemLabel(
                                text: item.item.itemType == 'NRI'
                                    ? 'NRI ${item.routeInstruction?.instructionNumber ?? ''}'
                                    : 'CHECKPOINT ${item.checkpoint?.checkpointNumber ?? ''}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
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
      Positioned(
        right: 16,
        bottom: 16,
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          elevation: 4,
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: 'Recenter on current location',
            onPressed: _position == null ? null : _recenterOnCurrentLocation,
            icon: Icon(
              Icons.my_location,
              color: _followCurrentLocation
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
      Positioned(
        right: 16,
        bottom: 80,
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          elevation: 4,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Zoom in',
                onPressed: () => _zoomBy(1),
                icon: const Icon(Icons.add),
              ),
              SizedBox(
                width: 32,
                child: Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              IconButton(
                tooltip: 'Zoom out',
                onPressed: () => _zoomBy(-1),
                icon: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
      ),
      Positioned(
        right: 16,
        top: 16,
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          elevation: 4,
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: 'Orient north up',
            onPressed: _orientNorthUp,
            constraints: const BoxConstraints.tightFor(width: 64, height: 64),
            padding: const EdgeInsets.all(6),
            icon: Transform.rotate(
              angle: -_mapRotation * math.pi / 180,
              child: const SizedBox(
                width: 52,
                height: 52,
                child: _CompassRose(),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  void _recenterOnCurrentLocation() {
    final position = _position;
    if (position == null) return;
    setState(() => _followCurrentLocation = true);
    _mapController.move(position, 16);
  }

  void _zoomBy(double delta) {
    final camera = _mapController.camera;
    setState(() => _followCurrentLocation = false);
    _mapController.move(camera.center, (camera.zoom + delta).clamp(1.0, 19.0));
  }

  void _orientNorthUp() {
    setState(() => _mapRotation = 0);
    _mapController.rotate(0);
  }

  double _normalizedRotation(double degrees) {
    final normalized = degrees % 360;
    return normalized > 180 ? normalized - 360 : normalized;
  }

  /// Centers on a route item selected from another planning component.
  void centerOnRouteItem(RouteItemDisplay item) {
    final latitude = item.item.latitude;
    final longitude = item.item.longitude;
    if (latitude == null || longitude == null) return;
    setState(() => _followCurrentLocation = false);
    _mapController.move(LatLng(latitude, longitude), 16);
  }
}

class _RouteItemLabel extends StatelessWidget {
  const _RouteItemLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _CompassRose extends StatelessWidget {
  const _CompassRose();

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _CompassRosePainter(
      northColor: Theme.of(context).colorScheme.primary,
    ),
  );
}

class _CompassRosePainter extends CustomPainter {
  const _CompassRosePainter({required this.northColor});

  final Color northColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final ringRadius = radius * 0.62;
    final longPoint = radius * 0.76;
    final shortPoint = radius * 0.46;
    final outline = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final fill = Paint()..style = PaintingStyle.fill;

    canvas.drawCircle(center, ringRadius, outline);
    _drawNeedle(
      canvas,
      center,
      angle: -math.pi / 2,
      pointDistance: longPoint,
      width: radius * 0.18,
      color: northColor,
    );
    _drawNeedle(
      canvas,
      center,
      angle: math.pi / 2,
      pointDistance: longPoint,
      width: radius * 0.18,
      color: Colors.black87,
    );
    _drawNeedle(
      canvas,
      center,
      angle: 0,
      pointDistance: shortPoint,
      width: radius * 0.15,
      color: Colors.black87,
    );
    _drawNeedle(
      canvas,
      center,
      angle: math.pi,
      pointDistance: shortPoint,
      width: radius * 0.15,
      color: Colors.black87,
    );
    canvas.drawCircle(center, radius * 0.09, fill..color = Colors.white);
    canvas.drawCircle(center, radius * 0.09, outline);

    _drawCardinal(canvas, 'N', center + Offset(0, -radius), northColor);
    _drawCardinal(canvas, 'E', center + Offset(radius, 0), Colors.black87);
    _drawCardinal(canvas, 'S', center + Offset(0, radius), Colors.black87);
    _drawCardinal(canvas, 'W', center + Offset(-radius, 0), Colors.black87);
  }

  void _drawNeedle(
    Canvas canvas,
    Offset center, {
    required double angle,
    required double pointDistance,
    required double width,
    required Color color,
  }) {
    final point =
        center + Offset(math.cos(angle), math.sin(angle)) * pointDistance;
    final perpendicular = Offset(-math.sin(angle), math.cos(angle)) * width;
    final path = ui.Path()
      ..moveTo(point.dx, point.dy)
      ..lineTo(center.dx + perpendicular.dx, center.dy + perpendicular.dy)
      ..lineTo(center.dx - perpendicular.dx, center.dy - perpendicular.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawCardinal(Canvas canvas, String value, Offset center, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _CompassRosePainter oldDelegate) =>
      oldDelegate.northColor != northColor;
}

class _NriMarker extends StatelessWidget {
  const _NriMarker();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: BoxShape.circle,
      border: Border.all(
        color: Theme.of(context).colorScheme.primary,
        width: 2,
      ),
      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 3)],
    ),
    child: Icon(
      Icons.menu_book_rounded,
      color: Theme.of(context).colorScheme.onPrimaryContainer,
      size: 25,
    ),
  );
}

class _CheckpointMarker extends StatelessWidget {
  const _CheckpointMarker();

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.tertiary,
            width: 2,
          ),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 3)],
        ),
        child: Center(
          child: Icon(
            Icons.check_rounded,
            color: Theme.of(context).colorScheme.onTertiaryContainer,
            size: 28,
          ),
        ),
      ),
      Positioned(
        right: -1,
        bottom: -1,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    ],
  );
}
