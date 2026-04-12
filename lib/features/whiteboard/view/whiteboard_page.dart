import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../app/di/service_locator.dart';
import '../../../core/models/whiteboard/whiteboard_models.dart';
import '../../../core/services/whiteboard_repository.dart';
import '../cubit/whiteboard_cubit.dart';

@RoutePage()
class WhiteboardPage extends HookWidget {
  const WhiteboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          WhiteboardCubit(getIt<WhiteboardRepository>())..load(),
      child: const _WhiteboardView(),
    );
  }
}

class _WhiteboardView extends HookWidget {
  const _WhiteboardView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WhiteboardCubit>();
    final selectionRect = useState<Rect?>(null);
    final dragStartScreen = useState<Offset?>(null);
    final dragStartWorld = useState<Offset?>(null);
    final draggingSelection = useState(false);
    final draggingItems = useState(false);
    final pendingConnection = useState<_PendingConnection?>(null);
    final pointerWorld = useState<Offset?>(null);
    final hoveredAnchorTarget = useState<_AnchorTarget?>(null);
    final focusScopeNode = useFocusScopeNode();
    final panZoomStartOffset = useState<Offset?>(null);
    final panZoomStartZoom = useState<double?>(null);

    return BlocBuilder<WhiteboardCubit, WhiteboardState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final document = state.document;

        Offset screenToWorld(Offset screen) {
          return Offset(
            document.viewportOffset.dx + (screen.dx / document.zoom),
            document.viewportOffset.dy + (screen.dy / document.zoom),
          );
        }

        Offset worldToScreen(Offset world) {
          return Offset(
            (world.dx - document.viewportOffset.dx) * document.zoom,
            (world.dy - document.viewportOffset.dy) * document.zoom,
          );
        }

        WhiteboardItem? itemById(String itemId) {
          for (final item in document.items) {
            if (item.id == itemId) {
              return item;
            }
          }
          return null;
        }

        Offset anchorFor(WhiteboardItem item, ConnectorAnchor position) {
          final rect = item.rect;
          return switch (position) {
            ConnectorAnchor.top => Offset(rect.center.dx, rect.top),
            ConnectorAnchor.right => Offset(rect.right, rect.center.dy),
            ConnectorAnchor.bottom => Offset(rect.center.dx, rect.bottom),
            ConnectorAnchor.left => Offset(rect.left, rect.center.dy),
          };
        }

        List<Offset> connectorPointsFor(WhiteboardItem item) {
          final connectorData = item.connectorData;
          if (connectorData == null) {
            return item.points;
          }
          final source = connectorData.sourceItemId == null
              ? null
              : itemById(connectorData.sourceItemId!);
          final target = connectorData.targetItemId == null
              ? null
              : itemById(connectorData.targetItemId!);
          if (source != null &&
              target != null &&
              connectorData.sourceAnchor != null &&
              connectorData.targetAnchor != null) {
            return [
              anchorFor(source, connectorData.sourceAnchor!),
              anchorFor(target, connectorData.targetAnchor!),
            ];
          }
          return connectorData.points;
        }

        WhiteboardItem? hitTest(Offset world) {
          for (final item in document.items.reversed) {
            final connectorPoints = item.isConnector
                ? connectorPointsFor(item)
                : const <Offset>[];
            if (item.isConnector && connectorPoints.length >= 2) {
              if (_distanceToSegment(
                    world,
                    connectorPoints.first,
                    connectorPoints.last,
                  ) <
                  (10 / document.zoom)) {
                return item;
              }
            } else if (item.rect.contains(world)) {
              return item;
            }
          }
          return null;
        }

        Rect? selectedScreenRect() {
          final selectedItem = state.selectedSingleItem;
          if (selectedItem == null || selectedItem.isConnector) {
            return null;
          }
          return Rect.fromLTWH(
            (selectedItem.rect.left - document.viewportOffset.dx) *
                document.zoom,
            (selectedItem.rect.top - document.viewportOffset.dy) *
                document.zoom,
            selectedItem.rect.width * document.zoom,
            selectedItem.rect.height * document.zoom,
          );
        }

        Offset? selectedToolbarAnchorScreen() {
          final selectedItem = state.selectedSingleItem;
          if (selectedItem == null) {
            return null;
          }
          if (selectedItem.isConnector) {
            final points = connectorPointsFor(selectedItem);
            if (points.length < 2) {
              return null;
            }
            final source = worldToScreen(points.first);
            final target = worldToScreen(points.last);
            return Offset(
              (source.dx + target.dx) / 2,
              math.min(source.dy, target.dy) - 20,
            );
          }
          final screenRect = selectedScreenRect();
          if (screenRect == null) {
            return null;
          }
          return Offset(screenRect.center.dx, screenRect.top);
        }

        List<Offset> selectedConnectorScreenPoints() {
          final selectedItem = state.selectedSingleItem;
          if (selectedItem == null || !selectedItem.isConnector) {
            return const <Offset>[];
          }
          return connectorPointsFor(
            selectedItem,
          ).map(worldToScreen).toList(growable: false);
        }

        double selectedToolbarWidth() {
          final selectedItem = state.selectedSingleItem;
          if (selectedItem == null) {
            return 0;
          }
          return selectedItem.isConnector ? 520 : 760;
        }

        bool isSelectionOverlayHit(Offset screen) {
          final screenRect = selectedScreenRect();
          if (screenRect == null) {
            return false;
          }

          for (final handle in ResizeHandle.values) {
            final center = _handlePosition(screenRect, handle);
            if (Rect.fromCenter(
              center: center,
              width: 18,
              height: 18,
            ).contains(screen)) {
              return true;
            }
          }

          for (final anchor in ConnectorAnchor.values) {
            final center = _anchorPosition(screenRect, anchor);
            if (Rect.fromCenter(
              center: center,
              width: 22,
              height: 22,
            ).contains(screen)) {
              return true;
            }
          }

          return false;
        }

        bool isConnectorEndpointOverlayHit(Offset screen) {
          final points = selectedConnectorScreenPoints();
          if (points.length < 2) {
            return false;
          }
          return Rect.fromCenter(
                center: points.first,
                width: 22,
                height: 22,
              ).contains(screen) ||
              Rect.fromCenter(
                center: points.last,
                width: 22,
                height: 22,
              ).contains(screen);
        }

        bool isInsideSelectedEditableItem(Offset world) {
          final selectedItem = state.selectedSingleItem;
          if (selectedItem == null || selectedItem.isConnector) {
            return false;
          }
          return selectedItem.rect.contains(world);
        }

        bool isConnectableTarget(WhiteboardItem? item) {
          final source = pendingConnection.value?.item;
          return source != null &&
              item != null &&
              !item.isConnector &&
              (!source.isConnector || source.id != item.id);
        }

        _AnchorTarget? anchorTargetAt(Offset world) {
          for (final item in document.items.reversed) {
            if (!isConnectableTarget(item)) {
              continue;
            }
            for (final anchor in ConnectorAnchor.values) {
              final anchorPoint = anchorFor(item, anchor);
              if ((anchorPoint - world).distance <= (18 / document.zoom)) {
                return _AnchorTarget(item: item, anchor: anchor);
              }
            }
          }
          return null;
        }

        WhiteboardItem? hoveredTargetItem(Offset world) {
          final hit = hitTest(world);
          if (isConnectableTarget(hit)) {
            return hit;
          }
          return null;
        }

        Future<Offset> maybeAutopan(Offset screen) async {
          const edgePadding = 68.0;
          const speed = 22.0;
          double dx = 0;
          double dy = 0;
          if (screen.dx < edgePadding) {
            dx = -speed / document.zoom;
          } else if (screen.dx >
              MediaQuery.sizeOf(context).width - edgePadding) {
            dx = speed / document.zoom;
          }
          if (screen.dy < edgePadding) {
            dy = -speed / document.zoom;
          } else if (screen.dy >
              MediaQuery.sizeOf(context).height - edgePadding) {
            dy = speed / document.zoom;
          }
          if (dx != 0 || dy != 0) {
            final delta = Offset(dx, dy);
            await cubit.updateViewport(
              viewportOffset: document.viewportOffset + delta,
            );
            return delta;
          }
          return Offset.zero;
        }

        Future<void> addItemFromTool(
          WhiteboardTool tool,
          Offset start,
          Offset end,
        ) async {
          final itemType = switch (tool) {
            WhiteboardTool.pointer => null,
            WhiteboardTool.rectangle => WhiteboardItemType.rectangle,
            WhiteboardTool.roundedRectangle =>
              WhiteboardItemType.roundedRectangle,
            WhiteboardTool.entity => WhiteboardItemType.entity,
            WhiteboardTool.connector => WhiteboardItemType.connector,
          };
          if (itemType == null) {
            return;
          }

          final rect = Rect.fromPoints(start, end);
          final minimumSize = switch (itemType) {
            WhiteboardItemType.entity => const Size(240, 140),
            WhiteboardItemType.rectangle ||
            WhiteboardItemType.roundedRectangle => const Size(180, 110),
            WhiteboardItemType.connector => const Size(0, 0),
          };
          final safeRect = Rect.fromLTWH(
            rect.left,
            rect.top,
            math.max(rect.width, minimumSize.width),
            math.max(rect.height, minimumSize.height),
          );

          await cubit.addItem(
            WhiteboardItem(
              id: 'item_${DateTime.now().microsecondsSinceEpoch}',
              type: itemType,
              rect: itemType == WhiteboardItemType.connector
                  ? Rect.fromPoints(start, end)
                  : safeRect,
              style: WhiteboardStyle.defaultsFor(itemType),
              data: switch (itemType) {
                WhiteboardItemType.entity => EntityItemData(
                  title: 'Entity',
                  columns: [
                    EntityColumn(
                      id: 'column_${DateTime.now().microsecondsSinceEpoch}',
                      name: 'id',
                      dataType: defaultSqlDataTypeFor(document.sqlDialect),
                      nullable: false,
                      isPrimaryKey: true,
                      isForeignKey: false,
                    ),
                  ],
                ),
                WhiteboardItemType.connector => ConnectorItemData(
                  points: [start, end],
                ),
                WhiteboardItemType.rectangle ||
                WhiteboardItemType.roundedRectangle => const ShapeItemData(
                  text: 'New shape',
                ),
              },
            ),
          );
          cubit.selectTool(WhiteboardTool.pointer);
        }

        Future<void> onPointerDown(PointerDownEvent event) async {
          focusScopeNode.requestFocus();
          final screen = event.localPosition;
          if (isSelectionOverlayHit(screen) ||
              isConnectorEndpointOverlayHit(screen)) {
            dragStartScreen.value = null;
            dragStartWorld.value = null;
            return;
          }
          final world = screenToWorld(screen);
          dragStartScreen.value = screen;
          dragStartWorld.value = world;

          if (pendingConnection.value != null) {
            final target = anchorTargetAt(world);
            if (target != null) {
              if (pendingConnection.value!.connectorId != null) {
                await cubit.reconnectConnectorEndpoint(
                  connectorId: pendingConnection.value!.connectorId!,
                  reconnectSource: pendingConnection.value!.reconnectSource,
                  itemId: target.item.id,
                  anchor: target.anchor,
                );
              } else {
                await cubit.addConnectorEndpoint(
                  sourceItemId: pendingConnection.value!.item.id,
                  sourceAnchor: pendingConnection.value!.anchor,
                  targetItemId: target.item.id,
                  targetAnchor: target.anchor,
                );
              }
              pendingConnection.value = null;
              hoveredAnchorTarget.value = null;
              pointerWorld.value = null;
              return;
            }
            pendingConnection.value = null;
            hoveredAnchorTarget.value = null;
          }

          if (state.activeTool == WhiteboardTool.pointer) {
            final hit = hitTest(world);
            if (hit != null) {
              if (!state.selectedItemIds.contains(hit.id)) {
                await cubit.selectItems({hit.id});
                draggingItems.value = true;
                return;
              }
              if (!isInsideSelectedEditableItem(world)) {
                draggingItems.value = true;
              }
              return;
            }
            draggingSelection.value = true;
            selectionRect.value = Rect.fromPoints(screen, screen);
            await cubit.selectItems(<String>{});
            return;
          }

          selectionRect.value = Rect.fromPoints(screen, screen);
        }

        Future<void> onPointerMove(PointerMoveEvent event) async {
          final startScreen = dragStartScreen.value;
          final startWorld = dragStartWorld.value;
          if (startScreen == null || startWorld == null) {
            return;
          }

          final screen = event.localPosition;
          final world = screenToWorld(screen);
          pointerWorld.value = world;
          hoveredAnchorTarget.value = anchorTargetAt(world);

          if (draggingSelection.value) {
            selectionRect.value = Rect.fromPoints(startScreen, screen);
            return;
          }

          if (!draggingItems.value &&
              state.activeTool == WhiteboardTool.pointer &&
              isInsideSelectedEditableItem(startWorld) &&
              (screen - startScreen).distance >= 4) {
            draggingItems.value = true;
          }

          if (draggingItems.value) {
            final delta = Offset(
              event.delta.dx / document.zoom,
              event.delta.dy / document.zoom,
            );
            await cubit.moveSelection(delta);
            final autoPanDelta = await maybeAutopan(screen);
            if (autoPanDelta != Offset.zero) {
              await cubit.moveSelection(autoPanDelta);
            }
            return;
          }

          if (state.activeTool != WhiteboardTool.pointer) {
            selectionRect.value = Rect.fromPoints(startScreen, screen);
          }
        }

        void onPointerHover(PointerHoverEvent event) {
          if (pendingConnection.value == null) {
            return;
          }
          final world = screenToWorld(event.localPosition);
          pointerWorld.value = world;
          hoveredAnchorTarget.value = anchorTargetAt(world);
        }

        Future<void> onPointerUp(PointerUpEvent event) async {
          final startScreen = dragStartScreen.value;
          final startWorld = dragStartWorld.value;
          final currentSelection = selectionRect.value;
          final endWorld = startWorld == null
              ? null
              : screenToWorld(event.localPosition);

          dragStartScreen.value = null;
          dragStartWorld.value = null;
          pointerWorld.value = null;
          hoveredAnchorTarget.value = null;

          if (startScreen == null || startWorld == null || endWorld == null) {
            selectionRect.value = null;
            draggingItems.value = false;
            draggingSelection.value = false;
            return;
          }

          if (draggingSelection.value) {
            await cubit.setSelectionFrame(
              Rect.fromPoints(startWorld, endWorld),
            );
          } else if (!draggingItems.value &&
              state.activeTool != WhiteboardTool.pointer) {
            await addItemFromTool(state.activeTool, startWorld, endWorld);
          } else if (!draggingItems.value && currentSelection != null) {
            final hit = hitTest(endWorld);
            await cubit.selectItems(hit == null ? <String>{} : {hit.id});
          }

          selectionRect.value = null;
          draggingItems.value = false;
          draggingSelection.value = false;
        }

        Future<void> onScroll(PointerSignalEvent event) async {
          if (event is! PointerScrollEvent) {
            return;
          }
          final keys = HardwareKeyboard.instance.logicalKeysPressed;
          final isMeta =
              keys.contains(LogicalKeyboardKey.metaLeft) ||
              keys.contains(LogicalKeyboardKey.metaRight);
          final isShift =
              keys.contains(LogicalKeyboardKey.shiftLeft) ||
              keys.contains(LogicalKeyboardKey.shiftRight);

          if (isMeta) {
            final nextZoom =
                (document.zoom * (event.scrollDelta.dy > 0 ? 0.92 : 1.08))
                    .clamp(0.25, 4.0);
            final focalWorld = screenToWorld(event.localPosition);
            final nextOffset = Offset(
              focalWorld.dx - (event.localPosition.dx / nextZoom),
              focalWorld.dy - (event.localPosition.dy / nextZoom),
            );
            await cubit.updateViewport(
              viewportOffset: nextOffset,
              zoom: nextZoom,
            );
            return;
          }

          if (isShift &&
              event.scrollDelta.dy.abs() >= event.scrollDelta.dx.abs()) {
            final nextZoom =
                (document.zoom * (event.scrollDelta.dy > 0 ? 0.985 : 1.015))
                    .clamp(0.25, 4.0);
            final focalWorld = screenToWorld(event.localPosition);
            final nextOffset = Offset(
              focalWorld.dx - (event.localPosition.dx / nextZoom),
              focalWorld.dy - (event.localPosition.dy / nextZoom),
            );
            await cubit.updateViewport(
              viewportOffset: nextOffset,
              zoom: nextZoom,
            );
            return;
          }

          final delta = Offset(
            event.scrollDelta.dx / document.zoom,
            event.scrollDelta.dy / document.zoom,
          );
          await cubit.updateViewport(
            viewportOffset: document.viewportOffset + delta,
          );
        }

        void onPointerPanZoomStart(PointerPanZoomStartEvent event) {
          panZoomStartOffset.value = document.viewportOffset;
          panZoomStartZoom.value = document.zoom;
        }

        Future<void> onPointerPanZoomUpdate(
          PointerPanZoomUpdateEvent event,
        ) async {
          final startOffset =
              panZoomStartOffset.value ?? document.viewportOffset;
          final startZoom = panZoomStartZoom.value ?? document.zoom;
          final keys = HardwareKeyboard.instance.logicalKeysPressed;
          final isShift =
              keys.contains(LogicalKeyboardKey.shiftLeft) ||
              keys.contains(LogicalKeyboardKey.shiftRight);
          final hasPinchScale = (event.scale - 1).abs() > 0.001;

          if (hasPinchScale || isShift) {
            final scaleFactor = hasPinchScale
                ? event.scale
                : (1 - (event.panDelta.dy * 0.003)).clamp(0.85, 1.15);
            final nextZoom = (startZoom * scaleFactor).clamp(0.25, 4.0);
            final focalWorld = screenToWorld(event.localPosition);
            final nextOffset = Offset(
              focalWorld.dx - (event.localPosition.dx / nextZoom),
              focalWorld.dy - (event.localPosition.dy / nextZoom),
            );
            await cubit.updateViewport(
              viewportOffset: nextOffset,
              zoom: nextZoom,
            );
            return;
          }

          await cubit.updateViewport(
            viewportOffset: startOffset + (event.pan / document.zoom),
          );
        }

        void onPointerPanZoomEnd(PointerPanZoomEndEvent event) {
          panZoomStartOffset.value = null;
          panZoomStartZoom.value = null;
        }

        return Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.keyV): _ToolIntent(
              WhiteboardTool.pointer,
            ),
            SingleActivator(LogicalKeyboardKey.keyR): _ToolIntent(
              WhiteboardTool.rectangle,
            ),
            SingleActivator(LogicalKeyboardKey.keyU): _ToolIntent(
              WhiteboardTool.roundedRectangle,
            ),
            SingleActivator(LogicalKeyboardKey.keyE): _ToolIntent(
              WhiteboardTool.entity,
            ),
            SingleActivator(LogicalKeyboardKey.keyL): _ToolIntent(
              WhiteboardTool.connector,
            ),
            SingleActivator(LogicalKeyboardKey.delete):
                _DeleteSelectionIntent(),
            SingleActivator(LogicalKeyboardKey.backspace):
                _DeleteSelectionIntent(),
            SingleActivator(LogicalKeyboardKey.keyZ, meta: true): _UndoIntent(),
            SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
                _RedoIntent(),
            SingleActivator(LogicalKeyboardKey.keyZ, control: true):
                _UndoIntent(),
            SingleActivator(
              LogicalKeyboardKey.keyZ,
              control: true,
              shift: true,
            ): _RedoIntent(),
            SingleActivator(LogicalKeyboardKey.tab): _CycleIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _ToolIntent: CallbackAction<_ToolIntent>(
                onInvoke: (intent) => cubit.selectTool(intent.tool),
              ),
              _DeleteSelectionIntent: CallbackAction<_DeleteSelectionIntent>(
                onInvoke: (intent) => cubit.deleteSelection(),
              ),
              _CycleIntent: CallbackAction<_CycleIntent>(
                onInvoke: (intent) => cubit.cycleFocus(),
              ),
              _UndoIntent: CallbackAction<_UndoIntent>(
                onInvoke: (intent) => cubit.undo(),
              ),
              _RedoIntent: CallbackAction<_RedoIntent>(
                onInvoke: (intent) => cubit.redo(),
              ),
            },
            child: Scaffold(
              body: SafeArea(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FocusScope(
                        node: focusScopeNode,
                        autofocus: true,
                        child: Listener(
                          onPointerSignal: onScroll,
                          onPointerPanZoomStart: onPointerPanZoomStart,
                          onPointerPanZoomUpdate: onPointerPanZoomUpdate,
                          onPointerPanZoomEnd: onPointerPanZoomEnd,
                          onPointerDown: onPointerDown,
                          onPointerMove: onPointerMove,
                          onPointerHover: onPointerHover,
                          onPointerUp: onPointerUp,
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3F1EB),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _GridPainter(
                                      viewportOffset: document.viewportOffset,
                                      zoom: document.zoom,
                                    ),
                                  ),
                                ),
                                for (final item in document.items)
                                  Builder(
                                    builder: (context) {
                                      final connectorPoints = item.isConnector
                                          ? connectorPointsFor(item)
                                                .map(worldToScreen)
                                                .toList(growable: false)
                                          : null;
                                      return _BoardItem(
                                        item: item,
                                        zoom: document.zoom,
                                        selected: state.selectedItemIds
                                            .contains(item.id),
                                        focused: state.focusedItemId == item.id,
                                        editable:
                                            state.selectedSingleItem?.id ==
                                            item.id,
                                        targetHighlighted: false,
                                        screenRect: item.isConnector
                                            ? null
                                            : Rect.fromLTWH(
                                                (item.rect.left -
                                                        document
                                                            .viewportOffset
                                                            .dx) *
                                                    document.zoom,
                                                (item.rect.top -
                                                        document
                                                            .viewportOffset
                                                            .dy) *
                                                    document.zoom,
                                                item.rect.width * document.zoom,
                                                item.rect.height *
                                                    document.zoom,
                                              ),
                                        connectorPoints: connectorPoints,
                                        onTextChanged: (value) => cubit
                                            .updateItemText(item.id, value),
                                        onUpdateColumn: item.isEntity
                                            ? (columnId, transform) =>
                                                  cubit.updateEntityColumn(
                                                    item.id,
                                                    columnId,
                                                    transform,
                                                  )
                                            : null,
                                        onTap: () =>
                                            cubit.selectItems({item.id}),
                                      );
                                    },
                                  ),
                                if (pendingConnection.value != null &&
                                    pointerWorld.value != null)
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _ConnectorPainter(
                                        points: [
                                          worldToScreen(
                                            anchorFor(
                                              pendingConnection.value!.item,
                                              pendingConnection.value!.anchor,
                                            ),
                                          ),
                                          worldToScreen(
                                            hoveredAnchorTarget.value == null
                                                ? pointerWorld.value!
                                                : anchorFor(
                                                    hoveredAnchorTarget
                                                        .value!
                                                        .item,
                                                    hoveredAnchorTarget
                                                        .value!
                                                        .anchor,
                                                  ),
                                          ),
                                        ],
                                        color: _neonPink.withValues(
                                          alpha: 0.65,
                                        ),
                                        selected: true,
                                        family: pendingConnection
                                            .value!
                                            .connectorFamily,
                                        relationKind: pendingConnection
                                            .value!
                                            .relationKind,
                                        dashed: true,
                                      ),
                                    ),
                                  ),
                                if (pendingConnection.value != null &&
                                    pointerWorld.value != null &&
                                    hoveredTargetItem(pointerWorld.value!) !=
                                        null)
                                  _AnchorBubbleOverlay(
                                    screenRect: Rect.fromLTWH(
                                      (hoveredTargetItem(
                                                pointerWorld.value!,
                                              )!.rect.left -
                                              document.viewportOffset.dx) *
                                          document.zoom,
                                      (hoveredTargetItem(
                                                pointerWorld.value!,
                                              )!.rect.top -
                                              document.viewportOffset.dy) *
                                          document.zoom,
                                      hoveredTargetItem(
                                            pointerWorld.value!,
                                          )!.rect.width *
                                          document.zoom,
                                      hoveredTargetItem(
                                            pointerWorld.value!,
                                          )!.rect.height *
                                          document.zoom,
                                    ),
                                    activeAnchor:
                                        hoveredAnchorTarget.value?.item.id ==
                                            hoveredTargetItem(
                                              pointerWorld.value!,
                                            )!.id
                                        ? hoveredAnchorTarget.value?.anchor
                                        : null,
                                  ),
                                if (selectionRect.value != null)
                                  Positioned.fromRect(
                                    rect: selectionRect.value!,
                                    child: IgnorePointer(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: const Color(0x300E7C66),
                                          border: Border.all(color: _neonPink),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (state.selectedSingleItem != null &&
                                    !state.selectedSingleItem!.isConnector)
                                  _SelectionOverlay(
                                    screenRect: selectedScreenRect()!,
                                    onResizeDelta: (handle, screenDelta) {
                                      cubit.resizeItem(
                                        state.selectedSingleItem!.id,
                                        handle,
                                        Offset(
                                          screenDelta.dx / document.zoom,
                                          screenDelta.dy / document.zoom,
                                        ),
                                      );
                                    },
                                    onStartConnection: (anchor) {
                                      pendingConnection.value =
                                          _PendingConnection(
                                            item: state.selectedSingleItem!,
                                            anchor: anchor,
                                            connectorFamily:
                                                ConnectorFamily.database,
                                            relationKind:
                                                ConnectorRelationKind.oneToOne,
                                          );
                                      pointerWorld.value = anchorFor(
                                        state.selectedSingleItem!,
                                        anchor,
                                      );
                                      hoveredAnchorTarget.value = null;
                                    },
                                  ),
                                if (state.selectedSingleItem?.isConnector ==
                                    true)
                                  _ConnectorEndpointOverlay(
                                    points:
                                        connectorPointsFor(
                                              state.selectedSingleItem!,
                                            )
                                            .map(worldToScreen)
                                            .toList(growable: false),
                                    onReconnectStart: (reconnectSource) {
                                      final connector =
                                          state.selectedSingleItem!;
                                      final connectorData =
                                          connector.connectorData!;
                                      final sourceItem = itemById(
                                        reconnectSource
                                            ? connectorData.sourceItemId!
                                            : connectorData.targetItemId!,
                                      );
                                      final sourceAnchor = reconnectSource
                                          ? connectorData.sourceAnchor!
                                          : connectorData.targetAnchor!;
                                      if (sourceItem == null) {
                                        return;
                                      }
                                      pendingConnection.value =
                                          _PendingConnection(
                                            item: sourceItem,
                                            anchor: sourceAnchor,
                                            connectorFamily:
                                                connector.connectorFamily,
                                            relationKind:
                                                connector.connectorRelationKind,
                                            connectorId: connector.id,
                                            reconnectSource: reconnectSource,
                                          );
                                      pointerWorld.value = anchorFor(
                                        sourceItem,
                                        sourceAnchor,
                                      );
                                      hoveredAnchorTarget.value = null;
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 18,
                      left: 18,
                      child: _LeftRail(
                        onBack: () => context.router.maybePop(),
                        dialect: document.sqlDialect,
                        onChangeDialect: cubit.updateSqlDialect,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 26,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _ToolDock(
                          activeTool: state.activeTool,
                          onSelect: cubit.selectTool,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 18,
                      bottom: 26,
                      child: _ZoomBadge(
                        zoom: document.zoom,
                        onZoomIn: () => cubit.updateViewport(
                          zoom: (document.zoom * 1.1).clamp(0.25, 4.0),
                        ),
                        onZoomOut: () => cubit.updateViewport(
                          zoom: (document.zoom / 1.1).clamp(0.25, 4.0),
                        ),
                      ),
                    ),
                    if (state.selectedSingleItem != null &&
                        selectedToolbarAnchorScreen() != null)
                      Positioned(
                        left:
                            ((selectedToolbarAnchorScreen()!.dx -
                                    (selectedToolbarWidth() / 2))
                                .clamp(
                                  18.0,
                                  math.max(
                                    18.0,
                                    MediaQuery.sizeOf(context).width -
                                        18 -
                                        selectedToolbarWidth(),
                                  ),
                                )),
                        top: math.max(
                          12,
                          selectedToolbarAnchorScreen()!.dy - 148,
                        ),
                        child: _FloatingObjectDetails(
                          item: state.selectedSingleItem!,
                          onTextSizeChanged: (value) => cubit.updateItemStyle(
                            state.selectedSingleItem!.id,
                            (style) => style.copyWith(textSize: value),
                          ),
                          onFillChanged: (value) => cubit.updateItemStyle(
                            state.selectedSingleItem!.id,
                            (style) => style.copyWith(
                              fillColor: value,
                              strokeColor: _darkenColor(value),
                            ),
                          ),
                          onStrokeChanged: (value) => cubit.updateItemStyle(
                            state.selectedSingleItem!.id,
                            (style) => style.copyWith(strokeColor: value),
                          ),
                          onHorizontalAlignChanged:
                              state.selectedSingleItem!.isConnector
                              ? null
                              : (value) => cubit.updateItemStyle(
                                  state.selectedSingleItem!.id,
                                  (style) => style.copyWith(
                                    textHorizontalAlign: value,
                                  ),
                                ),
                          onVerticalAlignChanged:
                              state.selectedSingleItem!.isConnector
                              ? null
                              : (value) => cubit.updateItemStyle(
                                  state.selectedSingleItem!.id,
                                  (style) =>
                                      style.copyWith(textVerticalAlign: value),
                                ),
                          connectorStyle:
                              state.selectedSingleItem!.connectorData?.style,
                          connectorFamily:
                              state.selectedSingleItem!.connectorData?.family,
                          connectorRelationKind: state
                              .selectedSingleItem!
                              .connectorData
                              ?.relationKind,
                          onConnectorStyleChanged:
                              state.selectedSingleItem!.isConnector
                              ? (style) => cubit.updateConnectorStyle(
                                  state.selectedSingleItem!.id,
                                  style,
                                )
                              : null,
                          onConnectorFamilyChanged:
                              state.selectedSingleItem!.isConnector
                              ? (family) => cubit.updateConnectorFamily(
                                  state.selectedSingleItem!.id,
                                  family,
                                )
                              : null,
                          onConnectorRelationKindChanged:
                              state.selectedSingleItem!.isConnector
                              ? (relationKind) =>
                                    cubit.updateConnectorRelationKind(
                                      state.selectedSingleItem!.id,
                                      relationKind,
                                    )
                              : null,
                        ),
                      ),
                    if (state.selectedSingleItem?.isEntity == true)
                      Positioned(
                        top: 18,
                        right: 18,
                        bottom: 110,
                        child: _EntityDetailsPanel(
                          item: state.selectedSingleItem!,
                          availableDataTypes: sqlDataTypesFor(
                            document.sqlDialect,
                          ),
                          onAddColumn: () => cubit.addEntityColumn(
                            state.selectedSingleItem!.id,
                          ),
                          onUpdateColumn: (columnId, transform) =>
                              cubit.updateEntityColumn(
                                state.selectedSingleItem!.id,
                                columnId,
                                transform,
                              ),
                          onRename: (value) => cubit.updateItemText(
                            state.selectedSingleItem!.id,
                            value,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter({required this.viewportOffset, required this.zoom});

  final Offset viewportOffset;
  final double zoom;

  @override
  void paint(Canvas canvas, Size size) {
    final minorPaint = Paint()..color = const Color(0xFFE4DFD2);
    final majorPaint = Paint()..color = const Color(0xFFD3CCBC);
    final minorStep = 32.0 * zoom;
    final startX = -((viewportOffset.dx * zoom) % minorStep);
    final startY = -((viewportOffset.dy * zoom) % minorStep);

    for (double x = startX; x < size.width; x += minorStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorPaint);
    }
    for (double y = startY; y < size.height; y += minorStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorPaint);
    }

    for (double x = startX; x < size.width; x += minorStep * 4) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), majorPaint);
    }
    for (double y = startY; y < size.height; y += minorStep * 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), majorPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.viewportOffset != viewportOffset ||
        oldDelegate.zoom != zoom;
  }
}

class _BoardItem extends StatelessWidget {
  const _BoardItem({
    required this.item,
    required this.zoom,
    required this.selected,
    required this.focused,
    required this.editable,
    required this.targetHighlighted,
    required this.onTextChanged,
    required this.onTap,
    this.onUpdateColumn,
    this.screenRect,
    this.connectorPoints,
  });

  final WhiteboardItem item;
  final double zoom;
  final bool selected;
  final bool focused;
  final bool editable;
  final bool targetHighlighted;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onTap;
  final Future<void> Function(
    String columnId,
    EntityColumn Function(EntityColumn column) transform,
  )?
  onUpdateColumn;
  final Rect? screenRect;
  final List<Offset>? connectorPoints;

  @override
  Widget build(BuildContext context) {
    final stroke = targetHighlighted
        ? item.style.stroke.withValues(alpha: 0.9)
        : item.style.stroke;
    final borderRadius =
        (item.type == WhiteboardItemType.rectangle ? 10.0 : 18.0) *
        zoom.clamp(0.35, 1.0);

    if (item.isConnector &&
        connectorPoints != null &&
        connectorPoints!.length >= 2) {
      return Positioned.fill(
        child: CustomPaint(
          painter: _ConnectorPainter(
            points: connectorPoints!,
            color: stroke,
            selected: selected || focused,
            style: item.connectorStyle,
            family: item.connectorFamily,
            relationKind: item.connectorRelationKind,
          ),
        ),
      );
    }
    if (screenRect == null) {
      return const SizedBox.shrink();
    }
    return Positioned.fromRect(
      rect: screenRect!,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: item.style.fill,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: stroke,
                width: selected || focused ? 2.1 : 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected || focused
                      ? _neonPink.withValues(alpha: 0.28)
                      : targetHighlighted
                      ? _neonPink.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: selected || focused
                      ? 28
                      : targetHighlighted
                      ? 24
                      : 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(14 * zoom.clamp(0.45, 1.4)),
              child: item.isEntity
                  ? _EntityPreview(
                      item: item,
                      zoom: zoom,
                      editable: editable,
                      onTextChanged: onTextChanged,
                      onUpdateColumn: onUpdateColumn,
                    )
                  : _ShapePreview(
                      item: item,
                      zoom: zoom,
                      editable: editable,
                      onTextChanged: onTextChanged,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShapePreview extends StatelessWidget {
  const _ShapePreview({
    required this.item,
    required this.zoom,
    required this.editable,
    required this.onTextChanged,
  });

  final WhiteboardItem item;
  final double zoom;
  final bool editable;
  final ValueChanged<String> onTextChanged;

  @override
  Widget build(BuildContext context) {
    final horizontal = _textAlign(item.style.textHorizontalAlign);
    final effectiveFontSize = (item.style.textSize * zoom).clamp(9.0, 28.0);
    return Align(
      alignment: _contentAlignment(
        item.style.textHorizontalAlign,
        item.style.textVerticalAlign,
      ),
      child: editable
          ? _InlineEditableText(
              value: item.text,
              fontSize: effectiveFontSize,
              color: item.style.text,
              textAlign: horizontal,
              onSubmitted: onTextChanged,
            )
          : Text(
              item.text,
              textAlign: horizontal,
              maxLines: zoom < 0.7 ? 2 : null,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: item.style.text,
                fontWeight: FontWeight.w600,
                fontSize: effectiveFontSize,
              ),
            ),
    );
  }
}

class _EntityPreview extends StatelessWidget {
  const _EntityPreview({
    required this.item,
    required this.zoom,
    required this.editable,
    required this.onTextChanged,
    required this.onUpdateColumn,
  });

  final WhiteboardItem item;
  final double zoom;
  final bool editable;
  final ValueChanged<String> onTextChanged;
  final Future<void> Function(
    String columnId,
    EntityColumn Function(EntityColumn column) transform,
  )?
  onUpdateColumn;

  @override
  Widget build(BuildContext context) {
    final titleFontSize = (item.style.textSize * zoom).clamp(9.0, 28.0);
    final columnFontSize = ((item.style.textSize - 1) * zoom).clamp(8.0, 24.0);
    final flagFontSize = ((item.style.textSize - 2) * zoom).clamp(7.0, 22.0);
    final compact = zoom < 0.65;
    final spacing = 10.0 * zoom.clamp(0.35, 1.0);

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: item.style.text,
              fontWeight: FontWeight.w700,
              fontSize: titleFontSize,
            ),
          ),
          SizedBox(height: spacing),
          const Divider(height: 1),
          SizedBox(height: spacing * 0.8),
          Expanded(
            child: ClipRect(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.columns
                    .take(3)
                    .map((column) {
                      final flags = [
                        if (column.isPrimaryKey) 'PK',
                        if (column.isForeignKey) 'FK',
                        if (!column.nullable) 'NN',
                      ].join(' • ');
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 3 * zoom.clamp(0.4, 1),
                        ),
                        child: Text(
                          '${column.name}  ${column.dataType}${flags.isEmpty ? '' : '  $flags'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: item.style.text,
                            fontSize: columnFontSize,
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        editable
            ? _InlineEditableText(
                value: item.text,
                fontSize: titleFontSize,
                color: item.style.text,
                onSubmitted: onTextChanged,
                fontWeight: FontWeight.w700,
              )
            : Text(
                item.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: item.style.text,
                  fontWeight: FontWeight.w700,
                  fontSize: titleFontSize,
                ),
              ),
        SizedBox(height: spacing),
        const Divider(height: 1),
        SizedBox(height: 8 * zoom.clamp(0.35, 1.0)),
        Expanded(
          child: ClipRect(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: item.columns
                  .map((column) {
                    final flags = [
                      if (column.isPrimaryKey) 'PK',
                      if (column.isForeignKey) 'FK',
                      if (!column.nullable) 'NN',
                    ].join(' • ');
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 4 * zoom.clamp(0.5, 1),
                      ),
                      child: editable && onUpdateColumn != null
                          ? Row(
                              children: [
                                Expanded(
                                  child: _InlineEditableText(
                                    value: column.name,
                                    fontSize: columnFontSize,
                                    color: item.style.text,
                                    onSubmitted: (value) => onUpdateColumn!(
                                      column.id,
                                      (current) =>
                                          current.copyWith(name: value),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _InlineEditableText(
                                    value: column.dataType,
                                    fontSize: columnFontSize,
                                    color: item.style.text,
                                    onSubmitted: (value) => onUpdateColumn!(
                                      column.id,
                                      (current) =>
                                          current.copyWith(dataType: value),
                                    ),
                                  ),
                                ),
                                if (flags.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    flags,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: item.style.text,
                                      fontSize: flagFontSize,
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : Text(
                              '${column.name}  ${column.dataType}${flags.isEmpty ? '' : '  $flags'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: item.style.text,
                                fontSize: columnFontSize,
                              ),
                            ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  const _ConnectorPainter({
    required this.points,
    required this.color,
    required this.selected,
    this.style = ConnectorLineStyle.straight,
    this.family = ConnectorFamily.plain,
    this.relationKind = ConnectorRelationKind.none,
    this.dashed = false,
  });

  final List<Offset> points;
  final Color color;
  final bool selected;
  final ConnectorLineStyle style;
  final ConnectorFamily family;
  final ConnectorRelationKind relationKind;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = selected ? 3 : 2
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    switch (style) {
      case ConnectorLineStyle.straight:
        path.lineTo(points.last.dx, points.last.dy);
      case ConnectorLineStyle.curved:
        final control = Offset(
          (points.first.dx + points.last.dx) / 2,
          math.min(points.first.dy, points.last.dy) - 40,
        );
        path.quadraticBezierTo(
          control.dx,
          control.dy,
          points.last.dx,
          points.last.dy,
        );
      case ConnectorLineStyle.orthogonal:
        final midX = (points.first.dx + points.last.dx) / 2;
        path.lineTo(midX, points.first.dy);
        path.lineTo(midX, points.last.dy);
        path.lineTo(points.last.dx, points.last.dy);
      case ConnectorLineStyle.rounded:
        final midX = (points.first.dx + points.last.dx) / 2;
        path.lineTo(midX - 18, points.first.dy);
        path.arcToPoint(
          Offset(midX, points.first.dy + 18),
          radius: const Radius.circular(18),
        );
        path.lineTo(midX, points.last.dy - 18);
        path.arcToPoint(
          Offset(midX + 18, points.last.dy),
          radius: const Radius.circular(18),
        );
        path.lineTo(points.last.dx, points.last.dy);
    }
    if (dashed) {
      for (final metric in path.computeMetrics()) {
        var distance = 0.0;
        while (distance < metric.length) {
          final next = math.min(distance + 10, metric.length);
          canvas.drawPath(metric.extractPath(distance, next), paint);
          distance += 16;
        }
      }
    } else {
      canvas.drawPath(path, paint);
    }

    final labels = connectorEndpointLabels(family, relationKind);
    if (labels.source != null) {
      _paintConnectorLabel(
        canvas,
        points.first,
        points.last,
        labels.source!,
        color,
      );
    }
    if (labels.target != null) {
      _paintConnectorLabel(
        canvas,
        points.last,
        points.first,
        labels.target!,
        color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.selected != selected ||
        oldDelegate.style != style ||
        oldDelegate.family != family ||
        oldDelegate.relationKind != relationKind ||
        oldDelegate.dashed != dashed;
  }
}

class _LeftRail extends StatelessWidget {
  const _LeftRail({
    required this.onBack,
    required this.dialect,
    required this.onChangeDialect,
  });

  final VoidCallback onBack;
  final SqlDialect dialect;
  final ValueChanged<SqlDialect> onChangeDialect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      elevation: 10,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.home_outlined),
            ),
            SizedBox(
              width: 64,
              child: RotatedBox(
                quarterTurns: 3,
                child: DropdownButton<SqlDialect>(
                  value: dialect,
                  underline: const SizedBox.shrink(),
                  onChanged: (value) {
                    if (value != null) {
                      onChangeDialect(value);
                    }
                  },
                  items: SqlDialect.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.name),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolDock extends StatelessWidget {
  const _ToolDock({required this.activeTool, required this.onSelect});

  final WhiteboardTool activeTool;
  final ValueChanged<WhiteboardTool> onSelect;

  @override
  Widget build(BuildContext context) {
    final tools = <(WhiteboardTool, IconData, String)>[
      (WhiteboardTool.pointer, Icons.near_me_outlined, 'Pointer'),
      (WhiteboardTool.rectangle, Icons.crop_square, 'Rectangle'),
      (WhiteboardTool.roundedRectangle, Icons.rounded_corner, 'Rounded'),
      (WhiteboardTool.entity, Icons.table_chart_outlined, 'Entity'),
      (WhiteboardTool.connector, Icons.timeline, 'Connector'),
    ];

    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      elevation: 12,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Wrap(
          spacing: 8,
          children: tools
              .map((tool) {
                return ChoiceChip(
                  selected: activeTool == tool.$1,
                  onSelected: (_) => onSelect(tool.$1),
                  avatar: Icon(tool.$2, size: 18),
                  label: Text(tool.$3),
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _ZoomBadge extends StatelessWidget {
  const _ZoomBadge({
    required this.zoom,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final double zoom;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      elevation: 10,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onZoomOut,
              icon: const Icon(Icons.remove),
              visualDensity: VisualDensity.compact,
            ),
            Text('${(zoom * 100).round()}%'),
            IconButton(
              onPressed: onZoomIn,
              icon: const Icon(Icons.add),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingObjectDetails extends HookWidget {
  const _FloatingObjectDetails({
    required this.item,
    required this.onTextSizeChanged,
    required this.onFillChanged,
    required this.onStrokeChanged,
    this.onHorizontalAlignChanged,
    this.onVerticalAlignChanged,
    this.connectorStyle,
    this.connectorFamily,
    this.connectorRelationKind,
    this.onConnectorStyleChanged,
    this.onConnectorFamilyChanged,
    this.onConnectorRelationKindChanged,
  });

  final WhiteboardItem item;
  final ValueChanged<double> onTextSizeChanged;
  final ValueChanged<int> onFillChanged;
  final ValueChanged<int> onStrokeChanged;
  final ValueChanged<TextHorizontalAlign>? onHorizontalAlignChanged;
  final ValueChanged<TextVerticalAlign>? onVerticalAlignChanged;
  final ConnectorLineStyle? connectorStyle;
  final ConnectorFamily? connectorFamily;
  final ConnectorRelationKind? connectorRelationKind;
  final ValueChanged<ConnectorLineStyle>? onConnectorStyleChanged;
  final ValueChanged<ConnectorFamily>? onConnectorFamilyChanged;
  final ValueChanged<ConnectorRelationKind>? onConnectorRelationKindChanged;

  @override
  Widget build(BuildContext context) {
    final colors = <int>[
      0xFFE2F6E9,
      0xFFFEE7C8,
      0xFFDDEBFF,
      0xFFF7D8E6,
      0xFFE8E3FF,
    ];
    final textSizeController = useTextEditingController(
      text: item.style.textSize.round().toString(),
    );
    useEffect(() {
      final next = item.style.textSize.round().toString();
      if (textSizeController.text != next) {
        textSizeController.text = next;
      }
      return null;
    }, [item.style.textSize]);
    final toolbarWidth = item.isConnector ? 760.0 : 760.0;

    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      elevation: 18,
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: toolbarWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Icon(
                      item.type == WhiteboardItemType.roundedRectangle
                          ? Icons.rounded_corner
                          : item.type == WhiteboardItemType.entity
                          ? Icons.table_chart_outlined
                          : Icons.crop_square,
                      size: 24,
                    ),
                    const SizedBox(width: 14),
                    _ToolbarDivider(),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: 82,
                      child: TextField(
                        controller: textSizeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Size',
                          isDense: true,
                          border: InputBorder.none,
                        ),
                        textAlign: TextAlign.center,
                        onSubmitted: (value) {
                          final parsed = double.tryParse(value);
                          if (parsed != null) {
                            onTextSizeChanged(parsed.clamp(10, 48));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    _ToolbarDivider(),
                    const SizedBox(width: 10),
                    _ToolbarIconButton(
                      icon: Icons.remove,
                      tooltip: 'Smaller text',
                      onPressed: () => onTextSizeChanged(
                        (item.style.textSize - 1).clamp(10, 48),
                      ),
                    ),
                    _ToolbarIconButton(
                      icon: Icons.add,
                      tooltip: 'Larger text',
                      onPressed: () => onTextSizeChanged(
                        (item.style.textSize + 1).clamp(10, 48),
                      ),
                    ),
                    if (onHorizontalAlignChanged != null) ...[
                      const SizedBox(width: 10),
                      _ToolbarDivider(),
                      const SizedBox(width: 10),
                      PopupMenuButton<TextHorizontalAlign>(
                        tooltip: 'Horizontal alignment',
                        onSelected: onHorizontalAlignChanged,
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: TextHorizontalAlign.left,
                            child: ListTile(
                              leading: Icon(Icons.format_align_left),
                              title: Text('Left'),
                            ),
                          ),
                          PopupMenuItem(
                            value: TextHorizontalAlign.center,
                            child: ListTile(
                              leading: Icon(Icons.format_align_center),
                              title: Text('Center'),
                            ),
                          ),
                          PopupMenuItem(
                            value: TextHorizontalAlign.right,
                            child: ListTile(
                              leading: Icon(Icons.format_align_right),
                              title: Text('Right'),
                            ),
                          ),
                        ],
                        child: _ToolbarIconChip(
                          icon: switch (item.style.textHorizontalAlign) {
                            TextHorizontalAlign.left => Icons.format_align_left,
                            TextHorizontalAlign.center =>
                              Icons.format_align_center,
                            TextHorizontalAlign.right =>
                              Icons.format_align_right,
                          },
                        ),
                      ),
                    ],
                    if (onVerticalAlignChanged != null) ...[
                      const SizedBox(width: 10),
                      PopupMenuButton<TextVerticalAlign>(
                        tooltip: 'Vertical alignment',
                        onSelected: onVerticalAlignChanged,
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: TextVerticalAlign.top,
                            child: Text('Top'),
                          ),
                          PopupMenuItem(
                            value: TextVerticalAlign.center,
                            child: Text('Center'),
                          ),
                          PopupMenuItem(
                            value: TextVerticalAlign.bottom,
                            child: Text('Bottom'),
                          ),
                        ],
                        child: _ToolbarIconChip(
                          icon: switch (item.style.textVerticalAlign) {
                            TextVerticalAlign.top => Icons.vertical_align_top,
                            TextVerticalAlign.center =>
                              Icons.vertical_align_center,
                            TextVerticalAlign.bottom =>
                              Icons.vertical_align_bottom,
                          },
                        ),
                      ),
                    ],
                    const SizedBox(width: 10),
                    _ToolbarDivider(),
                    const SizedBox(width: 10),
                    PopupMenuButton<int>(
                      tooltip: 'Fill color',
                      onSelected: onFillChanged,
                      itemBuilder: (context) => colors
                          .map(
                            (color) => PopupMenuItem(
                              value: color,
                              child: Row(
                                children: [
                                  _ColorSwatch(color: Color(color)),
                                  const SizedBox(width: 10),
                                  Text(
                                    '#${color.toRadixString(16).substring(2).toUpperCase()}',
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(growable: false),
                      child: _ToolbarColorChip(
                        color: Color(item.style.fillColor),
                        icon: Icons.format_color_fill,
                      ),
                    ),
                    const SizedBox(width: 10),
                    PopupMenuButton<int>(
                      tooltip: 'Border color',
                      onSelected: onStrokeChanged,
                      itemBuilder: (context) => colors
                          .map(
                            (color) => PopupMenuItem(
                              value: _darkenColor(color),
                              child: Row(
                                children: [
                                  _ColorSwatch(
                                    color: Color(_darkenColor(color)),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '#${_darkenColor(color).toRadixString(16).substring(2).toUpperCase()}',
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(growable: false),
                      child: _ToolbarColorChip(
                        color: Color(item.style.strokeColor),
                        icon: Icons.border_color,
                      ),
                    ),
                    if (item.isConnector &&
                        connectorStyle != null &&
                        onConnectorStyleChanged != null) ...[
                      const SizedBox(width: 10),
                      _ToolbarDivider(),
                      const SizedBox(width: 10),
                      PopupMenuButton<ConnectorFamily>(
                        tooltip: 'Connector family',
                        onSelected: onConnectorFamilyChanged,
                        itemBuilder: (context) => ConnectorFamily.values
                            .map(
                              (family) => PopupMenuItem(
                                value: family,
                                child: Text(family.name),
                              ),
                            )
                            .toList(growable: false),
                        child: _ToolbarIconChip(
                          icon: connectorFamily == ConnectorFamily.database
                              ? Icons.schema_outlined
                              : Icons.arrow_right_alt,
                        ),
                      ),
                      if (connectorFamily == ConnectorFamily.database &&
                          connectorRelationKind != null &&
                          onConnectorRelationKindChanged != null) ...[
                        const SizedBox(width: 10),
                        PopupMenuButton<ConnectorRelationKind>(
                          tooltip: 'Relationship',
                          onSelected: onConnectorRelationKindChanged,
                          itemBuilder: (context) => ConnectorRelationKind.values
                              .where(
                                (relationKind) =>
                                    relationKind != ConnectorRelationKind.none,
                              )
                              .map(
                                (relationKind) => PopupMenuItem(
                                  value: relationKind,
                                  child: Text(
                                    _connectorRelationLabel(relationKind),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                          child: _ToolbarTextChip(
                            text: _connectorRelationShortLabel(
                              connectorRelationKind!,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 10),
                      PopupMenuButton<ConnectorLineStyle>(
                        tooltip: 'Connector style',
                        onSelected: onConnectorStyleChanged,
                        itemBuilder: (context) => ConnectorLineStyle.values
                            .map(
                              (style) => PopupMenuItem(
                                value: style,
                                child: Text(style.name),
                              ),
                            )
                            .toList(growable: false),
                        child: const _ToolbarIconChip(icon: Icons.timeline),
                      ),
                    ],
                    const SizedBox(width: 16),
                    const _ToolbarIconChip(icon: Icons.more_vert),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: const Color(0xFFE3E5EC));
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        visualDensity: VisualDensity.compact,
        splashRadius: 20,
      ),
    );
  }
}

class _ToolbarIconChip extends StatelessWidget {
  const _ToolbarIconChip({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22),
    );
  }
}

class _ToolbarTextChip extends StatelessWidget {
  const _ToolbarTextChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class _ToolbarColorChip extends StatelessWidget {
  const _ToolbarColorChip({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          _ColorSwatch(color: color),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
      ),
    );
  }
}

class _EntityDetailsPanel extends StatelessWidget {
  const _EntityDetailsPanel({
    required this.item,
    required this.availableDataTypes,
    required this.onAddColumn,
    required this.onUpdateColumn,
    required this.onRename,
  });

  final WhiteboardItem item;
  final List<String> availableDataTypes;
  final VoidCallback onAddColumn;
  final Future<void> Function(
    String columnId,
    EntityColumn Function(EntityColumn column) transform,
  )
  onUpdateColumn;
  final ValueChanged<String> onRename;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.98),
      elevation: 14,
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: 360,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Entity', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _PanelTextField(
                label: 'Name',
                initialValue: item.text,
                onSubmitted: onRename,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Columns',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: onAddColumn,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: item.columns.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final column = item.columns[index];
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7FA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE3E5EE)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _PanelTextField(
                              label: 'Column',
                              initialValue: column.name,
                              onSubmitted: (value) => onUpdateColumn(
                                column.id,
                                (current) => current.copyWith(name: value),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _PanelDropdownField<String>(
                              label: 'Type',
                              value:
                                  availableDataTypes.contains(column.dataType)
                                  ? column.dataType
                                  : availableDataTypes.first,
                              options: availableDataTypes,
                              labelBuilder: (value) => value,
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                onUpdateColumn(
                                  column.id,
                                  (current) =>
                                      current.copyWith(dataType: value),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilterChip(
                                  label: const Text('Primary key'),
                                  selected: column.isPrimaryKey,
                                  onSelected: (value) => onUpdateColumn(
                                    column.id,
                                    (current) =>
                                        current.copyWith(isPrimaryKey: value),
                                  ),
                                ),
                                FilterChip(
                                  label: const Text('Foreign key'),
                                  selected: column.isForeignKey,
                                  onSelected: (value) => onUpdateColumn(
                                    column.id,
                                    (current) =>
                                        current.copyWith(isForeignKey: value),
                                  ),
                                ),
                                FilterChip(
                                  label: const Text('Not null'),
                                  selected: !column.nullable,
                                  onSelected: (value) => onUpdateColumn(
                                    column.id,
                                    (current) =>
                                        current.copyWith(nullable: !value),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelTextField extends HookWidget {
  const _PanelTextField({
    required this.label,
    required this.initialValue,
    required this.onSubmitted,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: initialValue);
    useEffect(() {
      if (controller.text != initialValue) {
        controller.text = initialValue;
      }
      return null;
    }, [initialValue]);

    return Shortcuts(
      shortcuts: _editorShortcutBlockers,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: onSubmitted,
        onTapOutside: (_) => onSubmitted(controller.text),
      ),
    );
  }
}

class _PanelDropdownField<T> extends StatelessWidget {
  const _PanelDropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> options;
  final String Function(T value) labelBuilder;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          onChanged: onChanged,
          items: options
              .map(
                (option) => DropdownMenuItem<T>(
                  value: option,
                  child: Text(labelBuilder(option)),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _ToolIntent extends Intent {
  const _ToolIntent(this.tool);

  final WhiteboardTool tool;
}

class _DeleteSelectionIntent extends Intent {
  const _DeleteSelectionIntent();
}

class _CycleIntent extends Intent {
  const _CycleIntent();
}

class _UndoIntent extends Intent {
  const _UndoIntent();
}

class _RedoIntent extends Intent {
  const _RedoIntent();
}

class _InlineEditableText extends HookWidget {
  const _InlineEditableText({
    required this.value,
    required this.fontSize,
    required this.color,
    required this.onSubmitted,
    this.textAlign = TextAlign.left,
    this.fontWeight = FontWeight.w600,
  });

  final String value;
  final double fontSize;
  final Color color;
  final TextAlign textAlign;
  final FontWeight fontWeight;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: value);
    useEffect(() {
      if (controller.text != value) {
        controller.text = value;
      }
      return null;
    }, [value]);

    return Shortcuts(
      shortcuts: _editorShortcutBlockers,
      child: TextField(
        controller: controller,
        textAlign: textAlign,
        cursorColor: color,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.zero,
        ),
        minLines: 1,
        maxLines: null,
        onSubmitted: onSubmitted,
        onTapOutside: (_) => onSubmitted(controller.text),
      ),
    );
  }
}

class _SelectionOverlay extends StatelessWidget {
  const _SelectionOverlay({
    required this.screenRect,
    required this.onResizeDelta,
    required this.onStartConnection,
  });

  final Rect screenRect;
  final void Function(ResizeHandle handle, Offset screenDelta) onResizeDelta;
  final ValueChanged<ConnectorAnchor> onStartConnection;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final handle in ResizeHandle.values)
          Positioned(
            left: _handlePosition(screenRect, handle).dx - 5,
            top: _handlePosition(screenRect, handle).dy - 5,
            child: MouseRegion(
              cursor: _resizeCursor(handle),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) => onResizeDelta(handle, details.delta),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _neonPink,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        for (final anchor in ConnectorAnchor.values)
          Positioned(
            left: _anchorPosition(screenRect, anchor).dx - 8,
            top: _anchorPosition(screenRect, anchor).dy - 8,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onStartConnection(anchor),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: _neonPink,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AnchorBubbleOverlay extends StatelessWidget {
  const _AnchorBubbleOverlay({required this.screenRect, this.activeAnchor});

  final Rect screenRect;
  final ConnectorAnchor? activeAnchor;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          for (final anchor in ConnectorAnchor.values)
            Positioned(
              left: _anchorPosition(screenRect, anchor).dx - 8,
              top: _anchorPosition(screenRect, anchor).dy - 8,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: activeAnchor == anchor
                      ? _neonPink
                      : _neonPink.withValues(alpha: 0.58),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _neonPink.withValues(alpha: 0.28),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ConnectorEndpointOverlay extends StatelessWidget {
  const _ConnectorEndpointOverlay({
    required this.points,
    required this.onReconnectStart,
  });

  final List<Offset> points;
  final ValueChanged<bool> onReconnectStart;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const SizedBox.shrink();
    }
    return Stack(
      children: [
        Positioned(
          left: points.first.dx - 8,
          top: points.first.dy - 8,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => onReconnectStart(true),
              child: _EndpointBubble(),
            ),
          ),
        ),
        Positioned(
          left: points.last.dx - 8,
          top: points.last.dy - 8,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => onReconnectStart(false),
              child: _EndpointBubble(),
            ),
          ),
        ),
      ],
    );
  }
}

class _EndpointBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: _neonPink,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

Offset _handlePosition(Rect rect, ResizeHandle handle) {
  return switch (handle) {
    ResizeHandle.topLeft => rect.topLeft,
    ResizeHandle.topRight => rect.topRight,
    ResizeHandle.bottomLeft => rect.bottomLeft,
    ResizeHandle.bottomRight => rect.bottomRight,
  };
}

Offset _anchorPosition(Rect rect, ConnectorAnchor anchor) {
  return switch (anchor) {
    ConnectorAnchor.top => Offset(rect.center.dx, rect.top),
    ConnectorAnchor.right => Offset(rect.right, rect.center.dy),
    ConnectorAnchor.bottom => Offset(rect.center.dx, rect.bottom),
    ConnectorAnchor.left => Offset(rect.left, rect.center.dy),
  };
}

class _PendingConnection {
  const _PendingConnection({
    required this.item,
    required this.anchor,
    this.connectorFamily = ConnectorFamily.database,
    this.relationKind = ConnectorRelationKind.oneToOne,
    this.connectorId,
    this.reconnectSource = false,
  });

  final WhiteboardItem item;
  final ConnectorAnchor anchor;
  final ConnectorFamily connectorFamily;
  final ConnectorRelationKind relationKind;
  final String? connectorId;
  final bool reconnectSource;
}

class _AnchorTarget {
  const _AnchorTarget({required this.item, required this.anchor});

  final WhiteboardItem item;
  final ConnectorAnchor anchor;
}

const _neonPink = Color(0xFFFF3FC7);

const _editorShortcutBlockers = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.keyV): DoNothingAndStopPropagationIntent(),
  SingleActivator(LogicalKeyboardKey.keyR): DoNothingAndStopPropagationIntent(),
  SingleActivator(LogicalKeyboardKey.keyU): DoNothingAndStopPropagationIntent(),
  SingleActivator(LogicalKeyboardKey.keyE): DoNothingAndStopPropagationIntent(),
  SingleActivator(LogicalKeyboardKey.keyL): DoNothingAndStopPropagationIntent(),
  SingleActivator(LogicalKeyboardKey.backspace):
      DoNothingAndStopPropagationIntent(),
  SingleActivator(LogicalKeyboardKey.delete):
      DoNothingAndStopPropagationIntent(),
  SingleActivator(LogicalKeyboardKey.tab): DoNothingAndStopPropagationIntent(),
  SingleActivator(LogicalKeyboardKey.keyZ, meta: true):
      DoNothingAndStopPropagationIntent(),
  SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
      DoNothingAndStopPropagationIntent(),
  SingleActivator(LogicalKeyboardKey.keyZ, control: true):
      DoNothingAndStopPropagationIntent(),
  SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
      DoNothingAndStopPropagationIntent(),
};

SystemMouseCursor _resizeCursor(ResizeHandle handle) {
  return switch (handle) {
    ResizeHandle.topLeft ||
    ResizeHandle.bottomRight => SystemMouseCursors.resizeUpLeftDownRight,
    ResizeHandle.topRight ||
    ResizeHandle.bottomLeft => SystemMouseCursors.resizeUpRightDownLeft,
  };
}

void _paintConnectorLabel(
  Canvas canvas,
  Offset origin,
  Offset toward,
  String text,
  Color color,
) {
  final direction = toward - origin;
  final length = direction.distance == 0 ? 1.0 : direction.distance;
  final unit = Offset(direction.dx / length, direction.dy / length);
  final normal = Offset(-unit.dy, unit.dx);
  final position = origin + (unit * 18) + (normal * 12);
  final textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        backgroundColor: Colors.white.withValues(alpha: 0.9),
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  textPainter.paint(
    canvas,
    Offset(
      position.dx - (textPainter.width / 2),
      position.dy - (textPainter.height / 2),
    ),
  );
}

String _connectorRelationLabel(ConnectorRelationKind relationKind) {
  return switch (relationKind) {
    ConnectorRelationKind.none => 'None',
    ConnectorRelationKind.oneToOne => 'One to one',
    ConnectorRelationKind.zeroToOne => 'Zero to one',
    ConnectorRelationKind.oneToMany => 'One to many',
    ConnectorRelationKind.zeroToMany => 'Zero to many',
    ConnectorRelationKind.manyToMany => 'Many to many',
  };
}

String _connectorRelationShortLabel(ConnectorRelationKind relationKind) {
  return switch (relationKind) {
    ConnectorRelationKind.none => '-',
    ConnectorRelationKind.oneToOne => '1:1',
    ConnectorRelationKind.zeroToOne => '0..1:1',
    ConnectorRelationKind.oneToMany => '1:N',
    ConnectorRelationKind.zeroToMany => '0..1:N',
    ConnectorRelationKind.manyToMany => 'N:M',
  };
}

TextAlign _textAlign(TextHorizontalAlign align) {
  return switch (align) {
    TextHorizontalAlign.left => TextAlign.left,
    TextHorizontalAlign.center => TextAlign.center,
    TextHorizontalAlign.right => TextAlign.right,
  };
}

Alignment _contentAlignment(
  TextHorizontalAlign horizontal,
  TextVerticalAlign vertical,
) {
  final x = switch (horizontal) {
    TextHorizontalAlign.left => -1.0,
    TextHorizontalAlign.center => 0.0,
    TextHorizontalAlign.right => 1.0,
  };
  final y = switch (vertical) {
    TextVerticalAlign.top => -1.0,
    TextVerticalAlign.center => 0.0,
    TextVerticalAlign.bottom => 1.0,
  };
  return Alignment(x, y);
}

int _darkenColor(int colorValue) {
  final color = Color(colorValue);
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness((hsl.lightness - 0.18).clamp(0.0, 1.0))
      .toColor()
      .toARGB32();
}

double _distanceToSegment(Offset point, Offset a, Offset b) {
  final ab = b - a;
  final ap = point - a;
  final lengthSquared = ab.dx * ab.dx + ab.dy * ab.dy;
  if (lengthSquared == 0) {
    return (point - a).distance;
  }
  final t = ((ap.dx * ab.dx) + (ap.dy * ab.dy)) / lengthSquared;
  final clamped = t.clamp(0.0, 1.0);
  final projection = Offset(a.dx + ab.dx * clamped, a.dy + ab.dy * clamped);
  return (point - projection).distance;
}
