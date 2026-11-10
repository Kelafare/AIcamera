## Why

Step 1 已经有一个能拍照、保存的本地相机 App。要进入 AI 渲染，下一步需要两件事：

1. **角色资产**：用户能新建角色文档、零负担上传图片，系统自动清洗并生成角色卡；
2. **云端骨架**：客户端能创建 AI 会话、上传素材、调用 VLM/生图 Provider，并先用 Mock 跑通端到端协议。

没有这两块，2B 的延迟预览、2C 的 AI 导演、2D 的最终渲染都只能悬空。本变更先做角色素材库 + 云端会话骨架 + Provider 抽象，为后续 AI 功能打地基。

## What Changes

- 新增本地「角色文档」库：新建/重命名/删除/选择；每个文档可上传多张角色图片。
- 新增零负担上传：用户不分类；客户端做基础质量检查（分辨率/模糊/重复），服务端做角色检测、去背景、聚类、参考图选择、身份 embedding。
- 新增角色卡：VLM 根据角色文档生成外观/标签/主要参考图；用户可编辑但不强制；缺全身/背面图时提示但不阻塞。
- 新增云端会话骨架：创建/保活/结束会话；上传角色素材；调用 Provider；返回角色卡；错误/重试/超时；会话结束清理。
- 新增 Provider 抽象：
  - `VlmProvider`：场景分析、角色卡、质量打分（Mock + Qwen-VL/GLM-4V 适配器）。
  - `GenerationProvider`：角色生成/编辑（Mock + SiliconFlow/LiblibAI/Seedream 适配器，2C 使用）。
  - `ImageEditProvider`：最终光影协调（Mock + Qwen-Image-Edit/Seedream 适配器，2D 使用）。
  - 配置化：provider/model/api key 通过环境变量或远程配置注入，不在客户端硬编码。
- 新增隐私与审核：上传前明确告知；素材与生成结果审核；用户确认素材使用权；会话结束清理。
- 明确非目标：本变更不做 AI 导演、不做延迟预览、不做最终成片渲染；这些留给 2B–2D。

## Capabilities

### New Capabilities

- `character-library`: 角色文档、零负担上传、自动清洗/聚类、角色卡、缺图提示、审核。
- `ai-session`: 云端会话、素材上传、Provider 抽象与 Mock/真实适配器、错误/重试、隐私与清理。

### Modified Capabilities

<!-- Step 1 的本地相机/拍照保存不改变需求。 -->

## Impact

- 移动端：素材库页面从占位变为可用的角色文档库；新增上传、角色卡、会话客户端；本地文件存储/权限；网络依赖只在 AI 会话中。
- 云端：会话 API、上传/存储、VLM/生图/图像编辑 Provider 适配；初期 Mock，随后接国内 API（SiliconFlow/百炼/火山/LiblibAI）。
- 数据：角色文档、参考图、角色卡、身份 embedding；隐私与审核。
- 成本：角色卡 VLM 调用、图片处理；生成暂不启用；需要限额/缓存。
- 兼容：Step 1 的本地相机/照片保存不受影响；AI 会话是后续 2B–2D 的基础。
