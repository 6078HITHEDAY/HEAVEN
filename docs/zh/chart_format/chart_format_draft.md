# 谱面格式草案

本文档定义 HEAVEN 谱面数据的第一版草案。

早期开发阶段应保持 JSON 格式，方便查看、编辑、调试和版本管理。

## 目标

- 表达曲目信息。
- 表达 BPM 与偏移。
- 表达难度信息。
- 表达 Surface Tap 事件。
- 为 Edge Slide、Spatial Judge 和 Boss 事件预留空间。
- 保持运行时与编辑器数据兼容。

## 文件位置

谱面文件应放在：

```text
data/charts/
```

示例：

```text
data/charts/test_chart.json
```

曲目文件应放在：

```text
data/songs/
```

## JSON 草案结构

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

## 时间

第一版原型使用秒。

后续版本可以加入基于拍或类似 MIDI tick 的时间表示。在 JSON 格式稳定之前，不要加入二进制格式。

## 立方体面

初始面名称：

- `front`
- `back`
- `left`
- `right`
- `top`
- `bottom`

`uv` 坐标在单个面上归一化，范围为 `[0.0, 0.0]` 到 `[1.0, 1.0]`。

## 事件类型

### Surface Tap

`surface_tap` 是第一阶段必需的音符类型。

必填字段：

- `id`
- `type`
- `time`
- `source`
- `target`
- `travel_time`
- `size`

### Edge Slide

为未来阶段预留。

可能字段：

- `edge`
- `start_t`
- `end_t`
- `duration`
- `path`

### Spatial Judge

为未来阶段预留。

可能字段：

- `transform_id`
- `axis`
- `rotation`
- `scale`
- `duration`
- `easing`

### Boss Event

为 Boss 模式预留。

可能字段：

- `boss_event`
- `animation`
- `expression`
- `attack`
- `hp_delta`
- `judge_zone`

## 判定窗口

默认判定窗口应属于运行时配置，不应在每个谱面中重复定义。

草案值：

```json
{
  "perfect": 0.04,
  "great": 0.08,
  "good": 0.12,
  "miss": 0.18
}
```

单位为秒。

## 校验规则

加载器应在以下情况下拒绝谱面：

- 缺少 `format_version`。
- 缺少音频路径。
- BPM 小于或等于 0。
- 事件包含未知 `type`。
- 事件 `time` 为负数。
- Surface Tap 事件包含无效面名称。
- Surface Tap 事件的 `uv` 超出 `0.0` 到 `1.0`。

## 待确认问题

- 谱面应按每个难度一个文件存储，还是一个文件包含多个难度？
- 内部时间最终应使用拍、秒还是 tick？
- 立方体变换事件是否应与音符事件分离？
- Boss 事件应放在谱面文件内，还是独立事件文件中？
- 编辑器专用元数据应如何存储？
