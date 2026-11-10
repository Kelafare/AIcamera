## 1. Flutter 工程与依赖

- [x] 1.1 创建 Flutter 工程（Android/iOS），设置项目名 `comira`
- [x] 1.2 添加 `camera`、`gal` 依赖
- [x] 1.3 配置应用显示名「Comira」与 Material 3 主题
- [x] 1.4 配置 Android/iOS 相机与相册权限
- [x] 1.5 检查 `.gitignore` 与仓库结构

## 2. 应用壳与占位页

- [x] 2.1 实现 `MainShell`：底部导航（首页/素材库/我的）+ 居中拍照按钮
- [x] 2.2 实现首页占位页
- [x] 2.3 实现素材库占位页
- [x] 2.4 实现我的占位页
- [x] 2.5 添加应用壳的 widget test

## 3. 本地相机

- [x] 3.1 定义 `CameraService` 接口与 `PluginCameraService` 实现
- [x] 3.2 实现 `CameraPage` 实时预览、权限/错误状态
- [x] 3.3 实现快门拍照并进入照片预览页
- [x] 3.4 实现前后摄切换
- [x] 3.5 处理应用生命周期（后台释放、前台重建）
- [x] 3.6 实现照片预览页（保存/重拍入口）

## 4. 保存到相册

- [x] 4.1 接入 `gal` 的相册权限与写入
- [x] 4.2 保存中禁用按钮，防止重复保存
- [x] 4.3 保存成功/失败/权限被拒的反馈
- [x] 4.4 保存后返回相机页，保持可继续拍照

## 5. 验证与提交

- [x] 5.1 `flutter analyze` 无错误
- [x] 5.2 `flutter test` 通过
- [x] 5.3 `flutter build apk --debug` 构建成功
- [ ] 5.4 真机/模拟器手动验证拍照与保存
- [x] 5.5 检查 iOS Info.plist 权限配置（Windows 上不做构建）
- [ ] 5.6 在 `add-local-camera-shell` 分支提交第一步实现
