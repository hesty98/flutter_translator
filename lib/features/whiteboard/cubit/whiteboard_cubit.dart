import 'dart:math' as math;

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

import '../../../core/models/whiteboard/whiteboard_models.dart';
import '../../../core/services/whiteboard_repository.dart';

enum ResizeHandle { topLeft, topRight, bottomLeft, bottomRight }

class WhiteboardState {
  const WhiteboardState({
    required this.document,
    required this.activeTool,
    required this.selectedItemIds,
    required this.focusedItemId,
    required this.isLoading,
    required this.undoStack,
    required this.redoStack,
    this.errorMessage,
  });

  factory WhiteboardState.initial() => WhiteboardState(
    document: WhiteboardDocument.initial(),
    activeTool: WhiteboardTool.pointer,
    selectedItemIds: const <String>{},
    focusedItemId: null,
    isLoading: true,
    undoStack: const <WhiteboardDocument>[],
    redoStack: const <WhiteboardDocument>[],
  );

  final WhiteboardDocument document;
  final WhiteboardTool activeTool;
  final Set<String> selectedItemIds;
  final String? focusedItemId;
  final bool isLoading;
  final List<WhiteboardDocument> undoStack;
  final List<WhiteboardDocument> redoStack;
  final String? errorMessage;

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  WhiteboardItem? get selectedSingleItem {
    if (selectedItemIds.length != 1) {
      return null;
    }
    final selectedId = selectedItemIds.first;
    for (final item in document.items) {
      if (item.id == selectedId) {
        return item;
      }
    }
    return null;
  }

  WhiteboardState copyWith({
    WhiteboardDocument? document,
    WhiteboardTool? activeTool,
    Set<String>? selectedItemIds,
    String? focusedItemId,
    bool clearFocusedItem = false,
    bool? isLoading,
    List<WhiteboardDocument>? undoStack,
    List<WhiteboardDocument>? redoStack,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WhiteboardState(
      document: document ?? this.document,
      activeTool: activeTool ?? this.activeTool,
      selectedItemIds: selectedItemIds ?? this.selectedItemIds,
      focusedItemId: clearFocusedItem
          ? null
          : focusedItemId ?? this.focusedItemId,
      isLoading: isLoading ?? this.isLoading,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class WhiteboardCubit extends Cubit<WhiteboardState> {
  WhiteboardCubit(this._repository) : super(WhiteboardState.initial());

  final WhiteboardRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      emit(
        state.copyWith(
          document: _repository.loadDocument(),
          isLoading: false,
          undoStack: const <WhiteboardDocument>[],
          redoStack: const <WhiteboardDocument>[],
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: '$error'));
    }
  }

  void selectTool(WhiteboardTool tool) {
    emit(state.copyWith(activeTool: tool));
  }

  Future<void> updateViewport({Offset? viewportOffset, double? zoom}) async {
    final nextDocument = state.document.copyWith(
      viewportOffset: viewportOffset,
      zoom: zoom,
    );
    await _persist(nextDocument, saveSelectionOnly: true);
  }

  Future<void> selectItems(Set<String> ids) async {
    emit(
      state.copyWith(
        selectedItemIds: ids,
        focusedItemId: ids.isEmpty ? null : ids.first,
        clearFocusedItem: ids.isEmpty,
      ),
    );
  }

  Future<void> addItem(WhiteboardItem item) async {
    await _persist(
      state.document.copyWith(items: [...state.document.items, item]),
      selectedItemIds: {item.id},
      focusedItemId: item.id,
    );
  }

  Future<void> moveSelection(Offset delta) async {
    if (state.selectedItemIds.isEmpty) {
      return;
    }

    final nextItems = state.document.items
        .map((item) {
          if (!state.selectedItemIds.contains(item.id)) {
            return item;
          }
          if (item.isConnector) {
            final connector = item.connectorData;
            if (connector?.sourceItemId != null ||
                connector?.targetItemId != null) {
              return item;
            }
            return item.copyWithConnector(
              points: item.points
                  .map(
                    (point) => Offset(point.dx + delta.dx, point.dy + delta.dy),
                  )
                  .toList(growable: false),
            );
          }
          return item.copyWith(rect: item.rect.shift(delta));
        })
        .toList(growable: false);

    await _persist(
      state.document.copyWith(items: nextItems),
      saveSelectionOnly: true,
    );
  }

  Future<void> resizeItem(
    String itemId,
    ResizeHandle handle,
    Offset delta,
  ) async {
    await _updateItem(itemId, (item) {
      if (item.isConnector) {
        return item;
      }

      final minimumSize = _minimumSizeForItem(item);
      var left = item.rect.left;
      var top = item.rect.top;
      var right = item.rect.right;
      var bottom = item.rect.bottom;

      switch (handle) {
        case ResizeHandle.topLeft:
          left += delta.dx;
          top += delta.dy;
        case ResizeHandle.topRight:
          right += delta.dx;
          top += delta.dy;
        case ResizeHandle.bottomLeft:
          left += delta.dx;
          bottom += delta.dy;
        case ResizeHandle.bottomRight:
          right += delta.dx;
          bottom += delta.dy;
      }

      if ((right - left) < minimumSize.width) {
        if (handle == ResizeHandle.topLeft ||
            handle == ResizeHandle.bottomLeft) {
          left = right - minimumSize.width;
        } else {
          right = left + minimumSize.width;
        }
      }
      if ((bottom - top) < minimumSize.height) {
        if (handle == ResizeHandle.topLeft || handle == ResizeHandle.topRight) {
          top = bottom - minimumSize.height;
        } else {
          bottom = top + minimumSize.height;
        }
      }

      return item.copyWith(rect: Rect.fromLTRB(left, top, right, bottom));
    });
  }

  Future<void> setSelectionFrame(Rect selectionRect) async {
    final ids = <String>{};
    for (final item in state.document.items) {
      final matchesSelection = item.isConnector
          ? _connectorIntersectsSelection(
              selectionRect,
              _connectorPoints(item, state.document.items),
            )
          : selectionRect.overlaps(item.rect);
      if (matchesSelection) {
        ids.add(item.id);
      }
    }
    emit(
      state.copyWith(
        selectedItemIds: ids,
        focusedItemId: ids.isEmpty ? null : ids.first,
        clearFocusedItem: ids.isEmpty,
      ),
    );
  }

  Future<void> deleteSelection() async {
    if (state.selectedItemIds.isEmpty) {
      return;
    }
    final nextItems = state.document.items
        .where((item) => !state.selectedItemIds.contains(item.id))
        .toList(growable: false);
    await _persist(
      state.document.copyWith(items: nextItems),
      selectedItemIds: <String>{},
      focusedItemId: null,
      clearFocusedItem: true,
    );
  }

  Future<void> updateItemText(String itemId, String value) async {
    await _updateItem(itemId, (item) {
      final nextItem = item.copyWithText(value);
      return _normalizedItem(nextItem);
    });
  }

  Future<void> updateItemStyle(
    String itemId,
    WhiteboardStyle Function(WhiteboardStyle style) transform,
  ) async {
    await _updateItem(
      itemId,
      (item) => _normalizedItem(item.copyWith(style: transform(item.style))),
    );
  }

  Future<void> updateConnectorStyle(
    String itemId,
    ConnectorLineStyle style,
  ) async {
    await _updateItem(itemId, (item) => item.copyWithConnector(style: style));
  }

  Future<void> updateConnectorFamily(
    String itemId,
    ConnectorFamily family,
  ) async {
    await _updateItem(
      itemId,
      (item) => item.copyWithConnector(
        family: family,
        relationKind: family == ConnectorFamily.plain
            ? ConnectorRelationKind.none
            : item.connectorRelationKind == ConnectorRelationKind.none
            ? ConnectorRelationKind.oneToOne
            : item.connectorRelationKind,
      ),
    );
  }

  Future<void> updateConnectorRelationKind(
    String itemId,
    ConnectorRelationKind relationKind,
  ) async {
    await _updateItem(
      itemId,
      (item) => item.copyWithConnector(
        family: ConnectorFamily.database,
        relationKind: relationKind,
      ),
    );
  }

  Future<void> updateSqlDialect(SqlDialect dialect) async {
    await _persist(
      state.document.copyWith(sqlDialect: dialect),
      saveSelectionOnly: true,
    );
  }

  Future<void> addEntityColumn(String itemId) async {
    await _updateItem(itemId, (item) {
      final nextIndex = item.columns.length + 1;
      return _normalizedItem(
        item.copyWithColumns([
          ...item.columns,
          EntityColumn(
            id: 'column_${DateTime.now().microsecondsSinceEpoch}',
            name: 'column_$nextIndex',
            dataType: defaultSqlDataTypeFor(state.document.sqlDialect),
            nullable: true,
            isPrimaryKey: false,
            isForeignKey: false,
          ),
        ]),
      );
    });
  }

  Future<void> updateEntityColumn(
    String itemId,
    String columnId,
    EntityColumn Function(EntityColumn column) transform,
  ) async {
    await _updateItem(itemId, (item) {
      return _normalizedItem(
        item.copyWithColumns(
          item.columns
              .map((column) {
                if (column.id != columnId) {
                  return column;
                }
                final nextColumn = transform(column);
                return nextColumn.copyWith(
                  dataType:
                      isValidSqlDataType(
                        state.document.sqlDialect,
                        nextColumn.dataType,
                      )
                      ? nextColumn.dataType
                      : defaultSqlDataTypeFor(state.document.sqlDialect),
                );
              })
              .toList(growable: false),
        ),
      );
    });
  }

  Future<void> addConnectorEndpoint({
    required String sourceItemId,
    required ConnectorAnchor sourceAnchor,
    required String targetItemId,
    required ConnectorAnchor targetAnchor,
    ConnectorLineStyle style = ConnectorLineStyle.straight,
  }) async {
    final source = _itemById(sourceItemId);
    final target = _itemById(targetItemId);
    if (source == null || target == null) {
      return;
    }

    await addItem(
      WhiteboardItem(
        id: 'item_${DateTime.now().microsecondsSinceEpoch}',
        type: WhiteboardItemType.connector,
        rect: Rect.fromPoints(source.rect.topLeft, target.rect.bottomRight),
        style: WhiteboardStyle.defaultsFor(WhiteboardItemType.connector),
        data: ConnectorItemData(
          points: const <Offset>[],
          style: style,
          family: ConnectorFamily.database,
          relationKind: ConnectorRelationKind.oneToOne,
          sourceItemId: sourceItemId,
          targetItemId: targetItemId,
          sourceAnchor: sourceAnchor,
          targetAnchor: targetAnchor,
        ),
      ),
    );
  }

  Future<void> reconnectConnectorEndpoint({
    required String connectorId,
    required bool reconnectSource,
    required String itemId,
    required ConnectorAnchor anchor,
  }) async {
    await _updateItem(connectorId, (item) {
      if (!item.isConnector || item.connectorData == null) {
        return item;
      }
      return item.copyWithConnector(
        sourceItemId: reconnectSource
            ? itemId
            : item.connectorData!.sourceItemId,
        targetItemId: reconnectSource
            ? item.connectorData!.targetItemId
            : itemId,
        sourceAnchor: reconnectSource
            ? anchor
            : item.connectorData!.sourceAnchor,
        targetAnchor: reconnectSource
            ? item.connectorData!.targetAnchor
            : anchor,
      );
    });
  }

  Future<void> cycleFocus() async {
    if (state.document.items.isEmpty) {
      return;
    }
    final ids = state.document.items
        .map((item) => item.id)
        .toList(growable: false);
    final currentIndex = state.focusedItemId == null
        ? -1
        : ids.indexOf(state.focusedItemId!);
    final nextId = ids[(currentIndex + 1) % ids.length];
    emit(state.copyWith(focusedItemId: nextId, selectedItemIds: {nextId}));
  }

  Future<void> nudgeSelection(Offset delta) => moveSelection(delta);

  Future<void> undo() async {
    if (!state.canUndo) {
      return;
    }
    final previousDocument = state.undoStack.last;
    await _repository.saveDocument(previousDocument);
    emit(
      state.copyWith(
        document: previousDocument,
        undoStack: state.undoStack.sublist(0, state.undoStack.length - 1),
        redoStack: [...state.redoStack, state.document],
        selectedItemIds: const <String>{},
        clearFocusedItem: true,
        isLoading: false,
        clearError: true,
      ),
    );
  }

  Future<void> redo() async {
    if (!state.canRedo) {
      return;
    }
    final nextDocument = state.redoStack.last;
    await _repository.saveDocument(nextDocument);
    emit(
      state.copyWith(
        document: nextDocument,
        undoStack: [...state.undoStack, state.document],
        redoStack: state.redoStack.sublist(0, state.redoStack.length - 1),
        selectedItemIds: const <String>{},
        clearFocusedItem: true,
        isLoading: false,
        clearError: true,
      ),
    );
  }

  Future<void> createConnector({
    required Offset start,
    required Offset end,
    ConnectorLineStyle style = ConnectorLineStyle.straight,
  }) async {
    await addItem(
      WhiteboardItem(
        id: 'item_${DateTime.now().microsecondsSinceEpoch}',
        type: WhiteboardItemType.connector,
        rect: Rect.fromPoints(start, end),
        style: WhiteboardStyle.defaultsFor(WhiteboardItemType.connector),
        data: ConnectorItemData(points: [start, end], style: style),
      ),
    );
  }

  WhiteboardItem? _itemById(String itemId) {
    for (final item in state.document.items) {
      if (item.id == itemId) {
        return item;
      }
    }
    return null;
  }

  WhiteboardItem _normalizedItem(WhiteboardItem item) {
    if (!item.isEntity) {
      return item;
    }
    final minimumSize = _minimumSizeForItem(item);
    final nextRect = Rect.fromLTWH(
      item.rect.left,
      item.rect.top,
      item.rect.width < minimumSize.width ? minimumSize.width : item.rect.width,
      item.rect.height < minimumSize.height
          ? minimumSize.height
          : item.rect.height,
    );
    return item.copyWith(rect: nextRect);
  }

  Future<void> _updateItem(
    String itemId,
    WhiteboardItem Function(WhiteboardItem item) transform,
  ) async {
    final nextItems = state.document.items
        .map((item) => item.id == itemId ? transform(item) : item)
        .toList(growable: false);
    await _persist(
      state.document.copyWith(items: nextItems),
      saveSelectionOnly: true,
    );
  }

  Future<void> _persist(
    WhiteboardDocument document, {
    Set<String>? selectedItemIds,
    String? focusedItemId,
    bool clearFocusedItem = false,
    bool saveSelectionOnly = false,
  }) async {
    await _repository.saveDocument(document);
    final shouldTrackHistory =
        document != state.document &&
        (saveSelectionOnly || selectedItemIds != null || focusedItemId != null);
    emit(
      state.copyWith(
        document: document,
        selectedItemIds: selectedItemIds ?? state.selectedItemIds,
        focusedItemId: focusedItemId,
        clearFocusedItem: clearFocusedItem,
        isLoading: false,
        undoStack: shouldTrackHistory
            ? [...state.undoStack, state.document]
            : state.undoStack,
        redoStack: shouldTrackHistory
            ? const <WhiteboardDocument>[]
            : state.redoStack,
        clearError: true,
      ),
    );
  }
}

List<Offset> _connectorPoints(WhiteboardItem item, List<WhiteboardItem> items) {
  final connector = item.connectorData;
  if (connector == null) {
    return item.points;
  }
  WhiteboardItem? findById(String? itemId) {
    if (itemId == null) {
      return null;
    }
    for (final candidate in items) {
      if (candidate.id == itemId) {
        return candidate;
      }
    }
    return null;
  }

  final source = findById(connector.sourceItemId);
  final target = findById(connector.targetItemId);
  if (source != null &&
      target != null &&
      connector.sourceAnchor != null &&
      connector.targetAnchor != null) {
    return [
      _anchorPoint(source.rect, connector.sourceAnchor!),
      _anchorPoint(target.rect, connector.targetAnchor!),
    ];
  }
  return connector.points;
}

Offset _anchorPoint(Rect rect, ConnectorAnchor anchor) {
  return switch (anchor) {
    ConnectorAnchor.top => Offset(rect.center.dx, rect.top),
    ConnectorAnchor.right => Offset(rect.right, rect.center.dy),
    ConnectorAnchor.bottom => Offset(rect.center.dx, rect.bottom),
    ConnectorAnchor.left => Offset(rect.left, rect.center.dy),
  };
}

bool _connectorIntersectsSelection(Rect selectionRect, List<Offset> points) {
  if (points.length < 2) {
    return false;
  }

  final start = points.first;
  final end = points.last;
  if (selectionRect.contains(start) || selectionRect.contains(end)) {
    return true;
  }

  final edges = <(Offset, Offset)>[
    (selectionRect.topLeft, selectionRect.topRight),
    (selectionRect.topRight, selectionRect.bottomRight),
    (selectionRect.bottomRight, selectionRect.bottomLeft),
    (selectionRect.bottomLeft, selectionRect.topLeft),
  ];

  for (final edge in edges) {
    if (_segmentsIntersect(start, end, edge.$1, edge.$2)) {
      return true;
    }
  }

  return false;
}

bool _segmentsIntersect(Offset a1, Offset a2, Offset b1, Offset b2) {
  final d1 = _crossProduct(a1, a2, b1);
  final d2 = _crossProduct(a1, a2, b2);
  final d3 = _crossProduct(b1, b2, a1);
  final d4 = _crossProduct(b1, b2, a2);

  if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
      ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
    return true;
  }

  return (d1 == 0 && _pointOnSegment(a1, a2, b1)) ||
      (d2 == 0 && _pointOnSegment(a1, a2, b2)) ||
      (d3 == 0 && _pointOnSegment(b1, b2, a1)) ||
      (d4 == 0 && _pointOnSegment(b1, b2, a2));
}

double _crossProduct(Offset a, Offset b, Offset c) {
  return (b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx);
}

bool _pointOnSegment(Offset a, Offset b, Offset p) {
  return p.dx >= math.min(a.dx, b.dx) &&
      p.dx <= math.max(a.dx, b.dx) &&
      p.dy >= math.min(a.dy, b.dy) &&
      p.dy <= math.max(a.dy, b.dy);
}

Size _minimumSizeForItem(WhiteboardItem item) {
  if (!item.isEntity) {
    return const Size(140, 96);
  }

  final titleLength = item.text.length.clamp(6, 28);
  final longestColumn = item.columns.fold<int>(
    8,
    (current, column) =>
        math.max(current, '${column.name} ${column.dataType}'.length),
  );
  final width = math
      .max(220, math.max(titleLength * 11, longestColumn * 9) + 48)
      .toDouble();
  final height = (76 + (item.columns.length * 34)).clamp(132, 520).toDouble();
  return Size(width, height);
}
