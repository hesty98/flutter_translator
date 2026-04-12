# Whiteboard Status

## Goal

This file is the handoff checkpoint for the whiteboard feature. It records:

- what has already been implemented
- what is partial
- what still needs to be done next

Use this before continuing work in a new chat/context.

## Done

### Integration

- whiteboard route exists
  - [lib/app/router/app_router.dart](/Users/linus/Documents/Projekte/flutter_translator/lib/app/router/app_router.dart)
- whiteboard repository is registered in DI
  - [lib/app/di/service_locator.dart](/Users/linus/Documents/Projekte/flutter_translator/lib/app/di/service_locator.dart)
- whiteboard entry button exists on the main page
  - [lib/features/projects/view/projects_page.dart](/Users/linus/Documents/Projekte/flutter_translator/lib/features/projects/view/projects_page.dart)

### Persistence

- whiteboard document model exists
- whiteboard models use `json_serializable`
- document is saved locally in `SharedPreferences`
  - key: `whiteboard_document`

Relevant files:

- [lib/core/models/whiteboard/whiteboard_models.dart](/Users/linus/Documents/Projekte/flutter_translator/lib/core/models/whiteboard/whiteboard_models.dart)
- [lib/core/services/whiteboard_repository.dart](/Users/linus/Documents/Projekte/flutter_translator/lib/core/services/whiteboard_repository.dart)
- [lib/core/storage/project_storage.dart](/Users/linus/Documents/Projekte/flutter_translator/lib/core/storage/project_storage.dart)

### State Management

- `WhiteboardCubit` created
- single `WhiteboardState`
- supports:
  - load
  - save
  - tool selection
  - selection
  - focus cycling
  - viewport updates
  - add item
  - delete selection
  - move selection
  - style/text edits
  - SQL dialect change
  - entity column add/update

Relevant file:

- [lib/features/whiteboard/cubit/whiteboard_cubit.dart](/Users/linus/Documents/Projekte/flutter_translator/lib/features/whiteboard/cubit/whiteboard_cubit.dart)

### UI / Interaction

- whiteboard page exists
- infinite-feeling grid canvas exists
- floating left rail exists
- floating bottom-center tool dock exists
- floating bottom-right zoom control exists
- pointer tool works
- rectangle tool works
- rounded rectangle tool works
- entity tool works
- connector tool works at a basic level
- marquee selection exists
- item dragging exists
- inspector exists
- entity columns can be edited in inspector

Relevant file:

- [lib/features/whiteboard/view/whiteboard_page.dart](/Users/linus/Documents/Projekte/flutter_translator/lib/features/whiteboard/view/whiteboard_page.dart)

### Verification

Last verified state:

- `flutter analyze` passed
- `flutter test` passed

## Partial / Incomplete

These pieces exist but are not production-ready yet.

### Keyboard usability

Current:

- some shortcuts exist
- `Tab` cycles canvas items

Missing:

- proper focus traversal between floating controls, inspector, tool dock, zoom control, and canvas
- explicit accessibility ordering
- keyboard-only activation/editing for all controls

### Connector / association model

Current:

- connectors are just freeform two-point lines

Missing:

- real EER associations
- source/target node attachment
- cardinalities:
  - one-to-one
  - one-to-many
  - many-to-many
- robust line rerouting when nodes move

### SQL dialect handling

Current:

- dialect enum exists
- changing dialect updates document state
- default entity column types vary by dialect

Missing:

- canonical internal data type model
- proper type remapping when dialect changes
- non-breaking migration of existing columns

### Canvas structure

Current:

- page works, but is too large

Missing:

- extraction into smaller widgets/services/painters
- cleaner separation between layout and interaction logic

## Not Started

### Whiteboard management

- multiple boards
- board list / board creation / rename / delete
- persisted board metadata separate from document payload

### Whiteboard polish

- sticky rulers or minimap
- alignment guides
- snapping
- multi-select transforms
- duplicate, bring forward/backward
- undo/redo

### EER-specific modeling

- entity resize handles
- richer column editing
- PK/FK visual tags on canvas
- relationship labels
- crow’s foot / cardinality visuals

### Backend readiness

- repository abstraction for remote sync
- conflict strategy
- event/operation model for collaboration

## Recommended Next Steps

1. Split `whiteboard_page.dart` into canvas, overlays, and inspector widgets.
2. Add proper toolbar/focus traversal for keyboard-first use.
3. Replace freeform connectors with association objects that reference source/target items.
4. Introduce canonical SQL data types plus dialect mappings.
5. Move whiteboard persistence from `SharedPreferences` to file-based document storage.
6. Add undo/redo before expanding editing complexity further.

## Caution

The current implementation is a functional stage-1 foundation, not the final architecture. Before adding many more tools, stabilize:

- focus model
- connector data model
- persistence format
- undo/redo strategy
