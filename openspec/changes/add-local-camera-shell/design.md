## Context

Comira 的第一步是做一个可运行的本地相机 App，作为后续 AI 渲染、角色素材库、账号/社区的产品与工程底座。当前仓库从零开始，没有任何移动端代码。

范围：Flutter 应用壳、首页/素材库/我的占位页、本地相机预览、前后摄切换、快门拍照、拍照预览、保存到系统相册。纯本地，无账号、无上传、无 AI。

技术环境：Flutter 3.44.5 / Dart 3.12.2；`camera` 0.12.2；`gal` 2.3.3；Android SDK 36；Windows 开发机（Android 可构建，iOS 需要 macOS）。

## Goals / Non-Goals

**Goals**

- 一个能在 Android/iOS 上启动的 Flutter App「Comira」。
- 应用壳：底部导航（首页/素材库/我的）+ 居中拍照按钮；三个占位页。
- 本地相机：实时预览、前后摄切换、快门拍照、权限与生命周期处理。
- 拍照预览：查看刚拍的照片，保存到系统相册或重拍。
- 保存成功/失败有明确反馈；无网络依赖。
- 相机层保持最小抽象，第二步可以替换为原生帧管线而不改页面。

**Non-Goals**

- 不做 AI、角色素材库、上传、账号、社区。
- 不做原生 Camera2/AVFoundation 帧管线（第二步再做）。
- 不做视频录制、滤镜、美颜、专业相机参数。
- 不做多语言、深色模式切换、复杂动效。
- 不在本阶段做 iOS 真机验证（Windows 开发机无法构建 iOS）。

## Decisions

### D1. Flutter + Material 3

**选择**：Flutter 单代码库支持 Android/iOS；Material 3 主题。

**理由**：第二步的 AI 客户端、素材库、账号/社区都可用同一套 Flutter 页面；相机/GPU 重活后续下探原生。Material 3 提供现成的 NavigationBar/FAB/主题。

**替代方案**：原生双端——性能最好，但第一步和后续页面开发成本翻倍；不选。

### D2. 第一步用 `camera` 插件，第二步换原生

**选择**：`camera` 0.12.2 负责预览与拍照；通过 `CameraService` 抽象隔离页面。

**理由**：插件能最快跑通权限、预览、拍照；第一步不需要逐帧访问。第二步 AI 需要帧、时间戳、编码，插件不够，届时实现 `NativeCameraService` 替换。

**替代方案**：第一步直接上 Camera2/AVFoundation——更贴近最终形态，但开发/调试成本高，会拖慢第一步；不选。

### D3. `CameraService` 最小抽象

**选择**：定义 `CameraService` 接口：初始化、预览 Widget、拍照、切换摄像头、释放。插件实现 `PluginCameraService`。相机页只依赖接口。

**理由**：第二步替换原生实现时，页面/状态不用重写；同时第一步不过度设计。

**替代方案**：相机页直接持有 `CameraController`——更快，但第二步要重写页面；不选。

### D4. 拍照后进入预览页，再保存/重拍

**选择**：快门后把照片交给 `PhotoPreviewPage`；用户选择「保存到相册」或「重拍」。

**理由**：给用户确认机会；这个页面第二步的 WYSIWYG 拍照回顾可以复用。直接保存虽然更少一步，但容易误存，且没有可复用的回顾页。

**替代方案**：拍完直接保存 + SnackBar；更简单，但体验差、不可复用；不选。

### D5. 保存使用 `gal`

**选择**：`gal` 2.3.3 写入系统相册；保存前请求相册权限；失败给出明确提示。

**理由**：`gal` 支持 Android MediaStore 与 iOS PHPhotoLibrary，API 简单；避免自己写平台通道。

**替代方案**：`image_gallery_saver`（维护状态较弱）/自写平台通道；不选。

### D6. 应用壳：三 Tab + 居中拍照按钮

**选择**：`NavigationBar` 三个目的地（首页/素材库/我的）+ `FloatingActionButton`（居中浮动）打开相机页。

**理由**：首页/素材库/我的为后续功能留位置；拍照是最核心动作，用独立按钮突出。相机页是 push 出来的全屏页面，不占 Tab。

**替代方案**：四 Tab 把「拍照」也放底部——实现简单但拍照不够突出；不选。

### D7. 纯本地与权限最小化

**选择**：第一步不申请网络/账号/存储读写之外的能力；相机与相册权限在需要时申请。

**理由**：本地优先是产品叙事的一部分；也避免第一步引入后端复杂度。

## Risks / Trade-offs

- **`camera` 插件生命周期问题**（切后台/锁屏/旋转）→ 用 `WidgetsBindingObserver` 在 paused 时释放、resumed 时重建；真机验证。
- **权限被拒** → 相机页/保存页给出明确说明；不静默失败；必要时引导去系统设置。
- **相册保存平台差异**（Android 10+/13+、iOS add-only 权限）→ 使用 `gal` 的权限 API；AndroidManifest/Info.plist 按插件文档配置；真机验证。
- **iPhone 无法在 Windows 构建** → iOS 配置先写好，构建/真机验证留给 macOS/CI；本阶段以 Android 验证为主。
- **插件相机不满足第二步帧管线** → `CameraService` 抽象 + 第二步原生替换；页面不重写。
- **预览比例/方向** → 用 `AspectRatio` + 设备方向测试；后续再做更精细的取景框。
- **误存/重复保存** → 预览页确认 + 保存中禁用按钮 + 成功/失败反馈。

## Migration Plan

- **Step 1（本变更）**：Flutter 壳 + 插件相机 + 预览/保存；Android 构建验证，iOS 配置就绪。
- **Step 2**：新增 `NativeCameraService`（Camera2/AVFoundation），暴露帧、时间戳、编码；页面继续用 `CameraService`；在 AI 会话中替换实现。
- **Step 3**：账号/社区；沿用首页/我的占位页的位置。
- **回滚**：第一步无后端/数据迁移；如相机插件出问题，可退回系统相机 Intent（后续备选），或暂时保留占位页。

## Open Questions

- 正式 bundle id / 开发者账号：当前用 `com.example.comira`，上线前替换。
- App 显示名：中文「漫镜头」还是英文「Comira」？当前用「Comira」。
- 默认摄像头：后摄（当前选择）；是否需要默认前摄？
- 保存相册名：是否固定为「Comira」相册？
- iOS 构建/签名由谁负责？Windows 开发机无法验证。
- 是否需要点击对焦/闪光灯/网格线？当前不做，留到后续。
