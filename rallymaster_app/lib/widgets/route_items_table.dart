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
    this.onItemDelete,
    this.selectedItem,
  });

  final List<RouteItemDisplay> items;
  final ScrollController? controller;
  final String emptyMessage;
  final ValueChanged<RouteItemDisplay>? onItemTap;
  final ValueChanged<RouteItemDisplay>? onItemEdit;
  final ValueChanged<RouteItemDisplay>? onItemDelete;
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
            DataColumn(label: Text('ITEM')),
            DataColumn(label: Text('DISTANCE'), numeric: true),
            DataColumn(label: Text('TYPE')),
            DataColumn(label: Text('INSTRUCTION / CHECKPOINT')),
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
                      SizedBox(
                        width: 180,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                routeItem.item.itemType == 'NRI'
                                    ? 'NRI ${routeItem.instructionNumber ?? ''}'
                                : 'CHKPT ${routeItem.checkpoint?.checkpointNumber ?? ''}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            PopupMenuButton<_RouteItemAction>(
                              tooltip: 'Route item actions',
                              icon: const Icon(Icons.more_vert),
                              onSelected: (action) {
                                switch (action) {
                                  case _RouteItemAction.edit:
                                    onItemEdit?.call(routeItem);
                                    break;
                                  case _RouteItemAction.delete:
                                    onItemDelete?.call(routeItem);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: _RouteItemAction.edit,
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: _RouteItemAction.delete,
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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

enum _RouteItemAction { edit, delete }
