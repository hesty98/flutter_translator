# Whiteboard Architecture

## Purpose

The whiteboard feature is the first stage of a local-first EER/diagram editor built entirely in Flutter. The current implementation is focused on:

- an infinite-feeling canvas
- floating controls
- pan/zoom
- basic shape creation
- entity nodes with editable columns
- local persistence
- keyboard-first foundations

This document captures the intended architecture so future work can continue without depending on chat context.

## Architectural Layers

### Domain

Primary model file:

- [lib/core/models/whiteboard/whiteboard_models.dart](/Users/linus/Documents/Projekte/flutter_translator/lib/core/models/whiteboard/whiteboard_models.dart)

Core concepts:

- `WhiteboardDocument`
  - full persisted board state
  - contains viewport, SQL dialect, and all whiteboard items
- `WhiteboardItem`
  - a node on the canvas
  - supports `rectangle`, `roundedRectangle`, `entity`, `connector`
- `WhiteboardStyle`
  - visual style per item
- `EntityColumn`
  - column metadata for entity nodes
- enums
  - `WhiteboardTool`
  - `WhiteboardItemType`
  - `SqlDialect`

Serialization:

- models use `json_serializable`
- generated file:
  - [lib/core/models/whiteboard/whiteboard_models.g.dart](/Users/linus/Documents/Projekte/flutter_translator/lib/core/models/whiteboard/whiteboard_models.g.dart)
- custom converters are used for:
  - `Offset`
  - `Rect`
  - `List<Offset>`

### Persistence

Persistence files:

- [lib/core/services/whiteboard_repository.dart](/Users/linus/Documents/Projekte/flutter_translator/lib/core/services/whiteboard_repository.dart)
- [lib/core/storage/project_storage.dart](/Users/linus/Documents/Projekte/flutter_translator/lib/core/storage/project_storage.dart)

Current persistence design:

- local-only
- stored in `SharedPreferences`
- one serialized whiteboard document under `whiteboard_document`

Reasoning:

- fast for stage 1
- simple enough to iterate on interaction design
- compatible with future migration to file storage or backend sync

### Application State

State file:

- [lib/features/whiteboard/cubit/whiteboard_cubit.dart](/Users/linus/Documents/Projekte/flutter_translator/lib/features/whiteboard/cubit/whiteboard_cubit.dart)

The whiteboard uses a single cubit and a single state object:

- `WhiteboardCubit`
- `WhiteboardState`

Responsibilities:

- load/save document
- active tool selection
- current selection
- focused item tracking
- viewport pan/zoom state
- adding items
- moving items
- deleting selection
- selection rectangle resolution
- text/style updates
- SQL dialect changes
- entity column add/edit
- keyboard focus cycling

This follows the app rule of using cubits with one state object.

### Presentation

Page file:

- [lib/features/whiteboard/view/whiteboard_page.dart](/Users/linus/Documents/Projekte/flutter_translator/lib/features/whiteboard/view/whiteboard_page.dart)

The page currently owns:

- the canvas shell
- pointer/scroll gesture handling
- world/screen coordinate conversion
- hit testing
- selection marquee overlay
- floating left rail
- floating bottom-center tool dock
- floating bottom-right zoom badge
- floating inspector panel

This is acceptable for stage 1, but the page should be split later into:

- `whiteboard_canvas.dart`
- `whiteboard_toolbar.dart`
- `whiteboard_inspector.dart`
- `whiteboard_painters.dart`

## Navigation / Integration

Integrated files:

- [lib/app/router/app_router.dart](/Users/linus/Documents/Projekte/flutter_translator/lib/app/router/app_router.dart)
- [lib/features/projects/view/projects_page.dart](/Users/linus/Documents/Projekte/flutter_translator/lib/features/projects/view/projects_page.dart)
- [lib/app/di/service_locator.dart](/Users/linus/Documents/Projekte/flutter_translator/lib/app/di/service_locator.dart)

Current entry points:

- whiteboard route: `/whiteboard`
- button in main page app bar
- button in empty state card

## Interaction Model

### Viewport

The whiteboard is modeled in world coordinates, not screen coordinates.

Document stores:

- `viewportOffset`
- `zoom`

Canvas translates:

- screen -> world
- world -> screen

Scroll behavior currently implemented:

- normal wheel: vertical pan
- `Shift + wheel`: horizontal pan
- `Cmd + wheel`: zoom

### Tools

Current tools:

- pointer
- rectangle
- rounded rectangle
- entity
- connector

Current behavior:

- pointer:
  - single select
  - drag selected items
  - marquee selection
- shape/entity/connector tools:
  - drag to create
  - after creation tool switches back to pointer

### Keyboard

Current shortcuts:

- `V` pointer
- `R` rectangle
- `U` rounded rectangle
- `E` entity
- `L` connector
- `Delete` / `Backspace` delete selection
- `Tab` cycle item focus

This is only the first keyboard layer. Full focus traversal between canvas items, toolbars, zoom control, and settings is still incomplete.

## SQL Dialect Strategy

Current state:

- document stores `SqlDialect`
- left floating rail can change dialect
- new entity columns choose a default data type per dialect

Important note:

- there is no canonical type system yet
- current implementation stores display strings directly

Planned direction:

- introduce canonical internal types
- map canonical types to display/export types per dialect
- migrate existing column model when dialect changes

## Known Structural Gaps

These are known limitations in the current architecture and should be addressed before calling the whiteboard feature complete:

- whiteboard UI logic is still too concentrated in a single page file
- no undo/redo command stack
- no grouping/layering/z-index operations
- no dedicated selection model object
- no canonical SQL type model
- no backend-ready persistence abstraction beyond a repository wrapper
- no import/export layer
- no collaboration/event model
- no dedicated accessibility/focus graph for all floating controls

## Recommended Next Refactors

1. Extract canvas rendering and gesture logic from `whiteboard_page.dart`.
2. Add a canonical SQL type model.
3. Introduce board-level commands for undo/redo.
4. Move persistence from `SharedPreferences` to file-based storage before boards become large.
5. Introduce item/connector ids and anchor references for robust associations.
