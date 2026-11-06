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
    this.onItemTap,
    this.onItemEdit,
    this.selectedItem,
  });

  final List<RouteItemDisplay> items;
  final ScrollController? controller;
  final String emptyMessage;
  final ValueChanged<RouteItemDisplay>? onItemTap;
  final ValueChanged<RouteItemDisplay>? onItemEdit;
  final RouteItemDisplay? selectedItem;

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
          showCheckboxColumn: false,
          columns: const [
            DataColumn(label: Text('NRI'), numeric: true),
            DataColumn(label: Text('DISTANCE'), numeric: true),
            DataColumn(label: Text('TYPE')),
            DataColumn(label: Text('INSTRUCTION / CHECKPOINT')),
            DataColumn(label: SizedBox.shrink()),
          ],
          rows: sortedItems
              .map(
                (routeItem) => DataRow(
                  selected: identical(routeItem, selectedItem),
                  onSelectChanged: onItemTap == null
                      ? null
                      : (_) => onItemTap!(routeItem),
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
                    DataCell(
                      IconButton(
                        tooltip: 'Edit route item',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: onItemEdit == null
                            ? null
                            : () => onItemEdit!(routeItem),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
