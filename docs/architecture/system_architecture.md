# System Architecture

This document describes the planned system boundaries for HEAVEN.

## Current Scope

The current project contains only the UI shell:

- Startup flow
- 3D start menu
- Main menu
- Settings
- About
- Select screen

The gameplay runtime, chart runtime, chart editor, scoring system, and Boss
mode are planned but not implemented yet.

## Domain Layout

```text
scenes/ui/          Player-facing UI scenes
scripts/ui/         Player-facing UI logic
assets/ui/          UI audio, graphics, and textures
shaders/ui/         UI/menu shaders
themes/ui/          UI theme resources

scenes/game/        Gameplay scenes
scripts/game/       Gameplay runtime logic

scenes/editor/      Chart editor scenes
scripts/editor/     Chart editor logic

data/charts/        Chart files
data/songs/         Song package data
data/boss/          Boss and Live2D event data
```

## Runtime Modules

### UI Flow

The UI flow owns scene navigation outside active gameplay.

Responsibilities:

- Boot and startup animation
- Main menu navigation
- Settings and audio sliders
- About screen
- Song or mode select

The UI layer should not contain gameplay judgement logic.

### Game Runtime

The game runtime should own the playable cube rhythm system.

Planned responsibilities:

- Outer cube and center cube setup
- Music timeline
- Chart event playback
- Note spawning
- Input mapping
- Judgement windows
- Score and combo state
- Spatial transform state

Suggested future files:

```text
scenes/game/cube_playfield.tscn
scripts/game/chart_player.gd
scripts/game/note_event.gd
scripts/game/note_spawner.gd
scripts/game/judgement_window.gd
scripts/game/score_state.gd
scripts/game/spatial_transform.gd
```

### Chart Editor

The chart editor should create and modify chart data used by the game runtime.

Planned responsibilities:

- Timeline view
- 3D cube preview
- Surface Tap placement
- Future Edge Slide placement
- Future Spatial Judge trajectory editing
- JSON load/save
- BPM grid and offset tools

The editor should share chart data structures with the game runtime, but editor
UI should remain separate from player-facing UI.

### Boss Mode

Boss mode is a future extension of the game runtime.

Planned responsibilities:

- Boss state
- HP and score relationship
- Live2D event hooks
- Attack events
- Special judgement zones
- Expression and animation triggers

Boss event data should live under `data/boss/` or inside chart files once the
chart format is stable.

## Scene Flow

Current UI flow:

```text
scenes/ui/startup/control.tscn
  -> scenes/ui/start_menu/start_menu_3d.tscn
  -> scenes/ui/main_menu/main_menu.tscn
      -> scenes/ui/settings/settings.tscn
      -> scenes/ui/about/about.tscn
      -> scenes/ui/select/select.tscn
```

Future game flow:

```text
scenes/ui/select/select.tscn
  -> scenes/game/cube_playfield.tscn
```

## Coordinate Model

The core gameplay is based on two cube spaces:

- Outer cube with edge length `L`
- Center cube with edge length `l`, where `l << L`

Chart events should describe:

- Spawn time
- Event type
- Source face or source position
- Target face or target position
- Travel duration or speed
- Judgement parameters
- Optional spatial transform references

## Implementation Priorities

1. Keep UI navigation working.
2. Add a minimal game scene with outer cube and center cube.
3. Spawn one Surface Tap from chart-like test data.
4. Add timing and judgement windows.
5. Move hardcoded test data into JSON.
6. Add chart editor only after the runtime data shape is stable.

## Non-Goals For The Current Stage

- Full chart editor
- Live2D integration
- Online services
- Binary chart format
- Complex plugin system

These should wait until the Surface Tap runtime is playable.
