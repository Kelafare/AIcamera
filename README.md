# Comira

Comira（漫镜头）是一款把二次元角色带进真实世界的手机相机应用。

当前处于 **Step 1：本地相机壳**。这是一个纯本地的相机 App：应用壳、首页/素材库/我的占位页、相机预览、拍照、照片预览、保存到系统相册。没有账号、上传或 AI。

## 当前功能

- 应用壳：底部导航（首页 / 素材库 / 我的）+ 居中拍照按钮。
- 本地相机：实时预览、前后摄切换、快门拍照。
- 照片预览：保存到系统相册或重拍。
- 纯本地：不上传、不依赖网络。

## 目录

```
lib/
  main.dart
  src/
    app.dart                 # MaterialApp / 主题
    shell/main_shell.dart    # 底部导航 + 拍照入口
    pages/                   # 首页、素材库、我的、相机、照片预览
    camera/camera_service.dart # 相机抽象（后续可替换原生实现）
test/
  widget_test.dart
docs/项目方案.md             # 产品/技术方案（讨论定稿）
openspec/
  changes/add-local-camera-shell/   # Step 1 规格与任务
  changes/add-ai-comic-camera-mvp/  # Step 2 AI 渲染规格与任务
```

## 运行

```bash
flutter pub get
flutter run
```

Android 需要相机权限；保存照片需要相册权限。iOS 的 Info.plist 已配置相机/相册权限说明，但需要在 macOS 上构建验证。

## 路线图

1. **Step 1（当前）**：本地相机壳、拍照、保存。
2. **Step 2**：角色素材库 + AI 渲染模式（延迟预览、AI 导演、遮挡、最终渲染）。
3. **Step 3**：账号管理与社区分享。

详见 [docs/项目方案.md](docs/项目方案.md)。
