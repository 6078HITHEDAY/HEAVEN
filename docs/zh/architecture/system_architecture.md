# 系统架构

本文档描述 HEAVEN 计划中的系统边界。

## 当前范围

当前项目只包含 UI 外壳：

- 启动流程
- 3D 开始菜单
- 主菜单
- 设置
- 关于
- 选择页面

游玩运行时、谱面运行时、谱面编辑器、计分系统和 Boss 模式仍处于计划阶段，尚未实现。

## 领域目录

```text
scenes/ui/          玩家可见的 UI 场景
scripts/ui/         玩家可见的 UI 逻辑
assets/ui/          UI 音频、图形和贴图
shaders/ui/         UI 与菜单 shader
themes/ui/          UI 主题资源

scenes/game/        游玩场景
scripts/game/       游玩运行时逻辑

scenes/editor/      谱面编辑器场景
scripts/editor/     谱面编辑器逻辑

data/charts/        谱面文件
data/songs/         曲包数据
data/boss/          Boss 与 Live2D 事件数据
```

## 运行时模块

### UI 流程

UI 流程负责活跃游玩之外的场景导航。

职责：

- 启动和开场动画
- 主菜单导航
- 设置与音频滑条
- 关于页面
- 曲目或模式选择

UI 层不应包含游玩判定逻辑。

### 游戏运行时

游戏运行时负责可游玩的立方体音游系统。

计划职责：

- 外置立方体与中心立方体搭建
- 音乐时间轴
- 谱面事件播放
- 音符生成
- 输入映射
- 判定窗口
- 分数和连击状态
- 空间变换状态

建议的未来文件：

```text
scenes/game/cube_playfield.tscn
scripts/game/chart_player.gd
scripts/game/note_event.gd
scripts/game/note_spawner.gd
scripts/game/judgement_window.gd
scripts/game/score_state.gd
scripts/game/spatial_transform.gd
```

### 游玩设置

共享的音游设置接口预留在 `scripts/game/rhythm_settings.gd`。

它负责保存 UI 与未来游玩代码都需要读取的持久化设置：

- 音频总线音量
- 音符速度
- 全局音频偏移，单位为毫秒
- 判定偏移，单位为毫秒
- 玩家名称

设置 UI 可以编辑这些值，但未来的谱面播放和判定系统应通过
`RhythmSettings` 读取，而不是依赖 `scripts/ui/settings/settings.gd` 或 UI 场景节点。

### 谱面编辑器

谱面编辑器负责创建和修改游戏运行时使用的谱面数据。

计划职责：

- 时间轴视图
- 3D 立方体预览
- Surface Tap 放置
- 未来 Edge Slide 放置
- 未来 Spatial Judge 轨迹编辑
- JSON 加载与保存
- BPM 网格与偏移工具

编辑器应与游戏运行时共享谱面数据结构，但编辑器 UI 应与玩家可见 UI 分离。

### Boss 模式

Boss 模式是游戏运行时的未来扩展。

计划职责：

- Boss 状态
- HP 与分数关系
- Live2D 事件钩子
- 攻击事件
- 特殊判定区域
- 表情与动画触发

Boss 事件数据应放在 `data/boss/`，或在谱面格式稳定后放入谱面文件。

## 场景流程

当前 UI 流程：

```text
scenes/ui/startup/control.tscn
  -> scenes/ui/start_menu/start_menu_3d.tscn
  -> scenes/ui/main_menu/main_menu.tscn
      -> scenes/ui/settings/settings.tscn
      -> scenes/ui/about/about.tscn
      -> scenes/ui/select/select.tscn
```

未来游戏流程：

```text
scenes/ui/select/select.tscn
  -> scenes/game/cube_playfield.tscn
```

## 坐标模型

核心玩法基于两个立方体空间：

- 外置立方体，边长为 `L`
- 中心立方体，边长为 `l`，其中 `l << L`

谱面事件应描述：

- 生成时间
- 事件类型
- 来源面或来源位置
- 目标面或目标位置
- 飞行时长或速度
- 判定参数
- 可选空间变换引用

## 实现优先级

1. 保持 UI 导航可用。
2. 添加包含外置立方体与中心立方体的最小游戏场景。
3. 从类谱面测试数据中生成一个 Surface Tap。
4. 添加时间与判定窗口。
5. 将硬编码测试数据迁移到 JSON。
6. 在运行时数据形态稳定后再添加谱面编辑器。

## 当前阶段非目标

- 完整谱面编辑器
- Live2D 集成
- 在线服务
- 二进制谱面格式
- 复杂插件系统

这些内容应等 Surface Tap 运行时可玩后再推进。
