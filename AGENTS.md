# Agent Guide

This file gives future agents and contributors the project-specific rules for
working on HEAVEN.

## Project Summary

HEAVEN is a Godot 4 prototype for a 3D cube-based rhythm game. The current
repository contains the UI shell only:

- Startup screen
- 3D start menu
- Main menu
- Settings
- About
- Select screen

The actual gameplay system, chart player, judgement logic, chart editor, and
Boss/Live2D systems are not implemented yet.

## Current Architecture

Keep the project organized by system domain, not only by file type.

```text
scenes/ui/          Current UI flow scenes
scripts/ui/         Current UI flow scripts
assets/ui/          UI audio, graphics, and textures
shaders/ui/         UI/menu shaders
themes/ui/          UI themes and materials

scenes/game/        Reserved for gameplay scenes
scripts/game/       Reserved for gameplay logic

scenes/editor/      Reserved for chart editor scenes
scripts/editor/     Reserved for chart editor logic

data/charts/        Reserved for chart files
data/songs/         Reserved for song packages
data/boss/          Reserved for Boss and Live2D event data

assets/fonts/       Shared fonts
config/             Godot project resources and config
docs/               Architecture and chart-format documentation
```

## Development Stage

The project is currently in `Stage 0: Concept Prototype and Project Cleanup`.

Priorities:

- Keep the UI flow stable.
- Keep Godot resource paths valid after moves.
- Prepare the project for the first gameplay prototype.
- Define the first chart data format before building large editor features.

Do not mix gameplay code into `scripts/ui/`. New gameplay work belongs under
`scripts/game/` and `scenes/game/`.

Do not mix chart editor code into UI or gameplay folders. Editor work belongs
under `scripts/editor/` and `scenes/editor/`.

## Godot Rules

- This project targets Godot 4.6 according to `project.godot`.
- Keep `.uid` files with their matching Godot resources and scripts.
- Keep `.import` files with imported assets when those assets are committed.
- Do not commit `.godot/`, `android/`, or local editor settings.
- After moving resources, update all `res://` references in `.tscn`, `.tres`,
  `.gd`, `.import`, `project.godot`, and `export_presets.cfg`.
- Prefer Godot editor moves when available. If moving files manually, run a
  static `res://` path check before finishing.

Useful static check:

```bash
rg -n "res://" -g "*.gd" -g "*.tscn" -g "*.tres" -g "*.cfg" -g "*.import" -g "project.godot"
```

## Naming Guidelines

Use lowercase snake_case for new files and folders.

Examples:

- `scenes/game/cube_playfield.tscn`
- `scripts/game/chart_player.gd`
- `scripts/game/judgement_window.gd`
- `scripts/editor/chart_editor.gd`
- `data/charts/test_chart.json`

Existing files that were already imported by Godot may keep their current names
unless there is a clear reason to rename them.

## Planned Gameplay Concepts

The core game should be built around:

- Outer cube: main judgement space.
- Center cube: interaction core and note emitter.
- Surface Tap: point judgement on cube surfaces.
- Edge Slide: slide judgement along cube edges.
- Spatial Judge: spatial transformation event for rotation, scale, or other
  relative-coordinate judgement.

Judgement grades should include:

- `Perfect`
- `Great`
- `Good`
- `Miss`

## Data And Editor Direction

Chart data should start as JSON for readability and debugging.

Early chart data should include:

- Song metadata
- BPM and offset
- Difficulty metadata
- Note events
- Spatial transform events
- Future Boss/Live2D event hooks

Do not create a binary chart format until the JSON structure is stable.

## Licensing Rules

Code is MIT licensed. See `LICENSE`.

Non-code assets are not automatically MIT licensed. See `ASSET_LICENSE.md`.

Before adding or publishing third-party assets, document them in
`THIRD_PARTY.md`.

If an asset license is unknown, treat it as not redistributable.

## Git Rules

The repository is initialized on the `main` branch.

Ignored paths include:

- `.godot/`
- `android/`
- `.vscode/`
- `.idea/`
- exported builds

Before committing, check:

```bash
git status --short
git status --ignored --short
```

Expected ignored generated folders:

```text
!! .godot/
!! .vscode/
!! android/
```

## Agent Workflow

When changing project structure:

1. Inspect current references with `rg`.
2. Move files conservatively.
3. Update all `res://` paths.
4. Run a static missing-path check.
5. Update README or docs if architecture changes.
6. Commit only intentional changes.

When implementing gameplay:

1. Add new files under `scenes/game/` and `scripts/game/`.
2. Keep the UI flow separate.
3. Start with a minimal Surface Tap prototype.
4. Add chart loading only after the runtime prototype is understandable.

When implementing editor features:

1. Add new files under `scenes/editor/` and `scripts/editor/`.
2. Reuse chart data structures from gameplay.
3. Keep editor-only UI separate from player-facing UI.
