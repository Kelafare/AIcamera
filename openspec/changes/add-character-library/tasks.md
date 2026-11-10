## 1. 本地角色文档库

- [ ] 1.1 定义 `CharacterDocument` / `ReferenceImage` / `CharacterCard` 数据模型与本地 JSON + 文件存储
- [ ] 1.2 实现素材库列表：新建、重命名、删除、选择角色文档
- [ ] 1.3 实现角色文档详情与多图上传
- [ ] 1.4 实现本地基础检查：分辨率、模糊、重复哈希、NSFW 初筛
- [ ] 1.5 实现缺全身/背面图提示与离线可用
- [ ] 1.6 实现角色卡展示与可编辑 UI

## 2. 云端会话骨架

- [ ] 2.1 建立服务端骨架（FastAPI 优先）与健康检查
- [ ] 2.2 实现会话创建/查询/结束 API；匿名 deviceId 与过期时间
- [ ] 2.3 实现素材 multipart 上传、按会话隔离、临时文件清理
- [ ] 2.4 实现处理状态机：created → uploading → processing → ready / failed
- [ ] 2.5 实现错误分类、重试、每设备/会话限额
- [ ] 2.6 记录 Provider 延迟、失败率、成本等遥测

## 3. Provider 抽象与 Mock

- [ ] 3.1 定义 `VlmProvider` / `GenerationProvider` / `ImageEditProvider` 接口
- [ ] 3.2 实现 Mock Provider（确定性角色卡 + 占位图）
- [ ] 3.3 实现 Provider 注册与配置（服务端环境变量/远程配置，客户端不持 key）
- [ ] 3.4 实现 Provider 健康检查与 Mock 降级
- [ ] 3.5 编写 Provider 契约测试

## 4. 国内 Provider 适配

- [ ] 4.1 接入 SiliconFlow：Qwen-Image / Qwen-Image-Edit / Qwen-VL / GLM-4V（以可用列表为准）
- [ ] 4.2 评估并接入 LiblibAI / ComfyUI（动漫 SDXL + IP-Adapter + ControlNet）
- [ ] 4.3 评估并接入阿里云百炼 / 火山引擎 Seedream（生图/编辑备选）
- [ ] 4.4 探测模型能力：多图参考、局部编辑、ControlNet；不支持时降级
- [ ] 4.5 用真实 key 做冒烟测试，记录延迟与成本

## 5. 客户端集成

- [ ] 5.1 实现会话客户端：创建、上传、轮询、结束；超时/重试
- [ ] 5.2 实现上传前隐私告知、内容审核与权利确认
- [ ] 5.3 接入角色卡生成进度、错误与重试 UI
- [ ] 5.4 实现离线行为与本地缓存
- [ ] 5.5 添加素材库/会话客户端 widget/unit 测试

## 6. 验证与提交

- [ ] 6.1 `flutter analyze` 无错误
- [ ] 6.2 `flutter test` 通过
- [ ] 6.3 服务端 Mock Provider 测试通过
- [ ] 6.4 Mock 端到端：上传 → 角色卡 → 展示
- [ ] 6.5 真实国内 Provider 冒烟测试（SiliconFlow 或选定 provider）
- [ ] 6.6 `flutter build apk --debug` 构建成功
- [ ] 6.7 在 `add-character-library` 分支提交 2A 实现
