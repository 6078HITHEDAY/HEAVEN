# Chart Format Draft

This document defines the first draft of HEAVEN chart data.

The format should remain JSON during early development so it is easy to inspect,
edit, debug, and version-control.

## Goals

- Represent music metadata.
- Represent BPM and offset.
- Represent difficulty metadata.
- Represent Surface Tap events.
- Leave room for Edge Slide, Spatial Judge, and Boss events.
- Keep runtime and editor data compatible.

## File Location

Chart files should live under:

```text
data/charts/
```

Example:

```text
data/charts/test_chart.json
```

Song files should live under:

```text
data/songs/
```

## Draft JSON Shape

```json
{
  "format_version": 1,
  "song": {
    "id": "test_song",
    "title": "Test Song",
    "artist": "Unknown Artist",
    "audio": "res://data/songs/test_song/audio.ogg",
    "preview_time": 30.0
  },
  "timing": {
    "bpm": 120.0,
    "offset": 0.0,
    "time_unit": "seconds"
  },
  "difficulty": {
    "name": "Normal",
    "level": 1,
    "chart_author": "Unknown",
    "version": "0.1.0"
  },
  "cube": {
    "outer_size": 10.0,
    "center_size": 1.0
  },
  "events": [
    {
      "id": "note_0001",
      "type": "surface_tap",
      "time": 1.0,
      "source": {
        "face": "front",
        "uv": [0.5, 0.5]
      },
      "target": {
        "face": "front",
        "uv": [0.5, 0.5]
      },
      "travel_time": 1.0,
      "size": 0.25
    }
  ]
}
```

## Time

For the first prototype, use seconds.

Later versions may add beat-based timing or MIDI-like tick timing. Do not add a
binary format until the JSON format is stable.

## Cube Faces

Initial face names:

- `front`
- `back`
- `left`
- `right`
- `top`
- `bottom`

`uv` coordinates are normalized from `[0.0, 0.0]` to `[1.0, 1.0]` on a face.

## Event Types

### Surface Tap

`surface_tap` is the first required note type.

Required fields:

- `id`
- `type`
- `time`
- `source`
- `target`
- `travel_time`
- `size`

### Edge Slide

Reserved for a future phase.

Possible fields:

- `edge`
- `start_t`
- `end_t`
- `duration`
- `path`

### Spatial Judge

Reserved for a future phase.

Possible fields:

- `transform_id`
- `axis`
- `rotation`
- `scale`
- `duration`
- `easing`

### Boss Event

Reserved for Boss mode.

Possible fields:

- `boss_event`
- `animation`
- `expression`
- `attack`
- `hp_delta`
- `judge_zone`

## Judgement Windows

Default judgement windows should be runtime config, not duplicated in every
chart.

Draft values:

```json
{
  "perfect": 0.04,
  "great": 0.08,
  "good": 0.12,
  "miss": 0.18
}
```

Values are in seconds.

## Validation Rules

The loader should reject a chart if:

- `format_version` is missing.
- Audio path is missing.
- BPM is less than or equal to zero.
- An event has an unknown `type`.
- An event has a negative `time`.
- A Surface Tap event has an invalid face.
- A Surface Tap event has `uv` values outside `0.0` to `1.0`.

## Open Questions

- Should charts be stored as one file per difficulty or one file with multiple
  difficulties?
- Should timing eventually use beats, seconds, or ticks internally?
- Should cube transform events be separate from note events?
- Should Boss events live inside chart files or separate event files?
- How should editor-only metadata be stored?
