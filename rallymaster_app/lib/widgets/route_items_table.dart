import 'package:flutter/material.dart';

import '../models/route_item_display.dart';

/// Reusable read-only table for rendering ordered route instructions and
/// checkpoints. Provide [controller] to control the vertical scroll position.
class RouteItemsTable extends StatelessWidget {
  const RouteItemsTable({
    super.key,
    required this.items,
    this.controller,
    this.emptyMessage = 'No route items yet.',
  });

  final List<RouteItemDisplay> items;
  final ScrollController? controller;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final sortedItems = [...items]
      ..sort(
        (left, right) =>
            (left.item.position ?? 0).compareTo(right.item.position ?? 0),
      );
    if (sortedItems.isEmpty) return Center(child: Text(emptyMessage));

    return SingleChildScrollView(
      controller: controller,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('NRI'), numeric: true),
            DataColumn(label: Text('DISTANCE'), numeric: true),
            DataColumn(label: Text('TYPE')),
            DataColumn(label: Text('INSTRUCTION / CHECKPOINT')),
          ],
          rows: sortedItems
              .map(
                (routeItem) => DataRow(
                  cells: [
                    DataCell(
                      Text(
                        routeItem.item.itemType == 'NRI'
                            ? '${routeItem.instructionNumber ?? ''}'
                            : '',
                      ),
                    ),
                    DataCell(
                      Text(
                        routeItem.item.distance == null
                            ? '-'
                            : routeItem.item.distance!.toStringAsFixed(3),
                      ),
                    ),
                    DataCell(Text(routeItem.item.itemType ?? 'Route item')),
                    DataCell(Text(routeItem.detail ?? '-')),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
