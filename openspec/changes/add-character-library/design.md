## Context

Step 1 已完成：Flutter 应用壳、本地相机、拍照预览、保存到相册、Android/iOS 权限。当前没有账号、网络、云端或 AI。

Step 2A 的目标是把「角色资产」和「云端骨架」搭起来，为 2B（延迟预览）、2C（AI 导演）、2D（最终渲染）提供基础：

- 本地角色文档库：新建、上传、查看、选择；
- 自动清洗与角色卡：用户零负担丢图，系统自动筛选、聚类、生成角色卡；
- 云端会话骨架：创建会话、上传素材、调用 Provider、返回结果；
- Provider 抽象：VLM / 生图 / 图像编辑，先用 Mock，随后接真实 API；
- 隐私、审核、成本控制。

## Goals / Non-Goals

**Goals**

- 用户能在素材库新建「角色文档」，往里面随意丢图，不要求分类。
- 客户端做基础质量检查；服务端做角色检测、去背景、聚类、参考图选择、身份 embedding、VLM 角色卡。
- 角色卡可查看、可编辑，但不编辑也能用；缺全身/背面图时提示但不阻塞。
- 客户端能创建云端会话、上传素材、拿到角色卡；有超时、重试、错误提示、会话清理。
- Provider 抽象与配置：`VlmProvider`、`GenerationProvider`、`ImageEditProvider`；Mock 优先，真实 API 可插拔。
- 上传前明确告知；素材/结果审核；会话结束清理。
- 为 2B–2D 留好接口，不引入返工。

**Non-Goals**

- 不做 AI 导演、站位/姿势候选、遮挡合成（2C）。
- 不做延迟预览、缓冲、状态机、双时间 UI（2B）。
- 不做最终成片渲染、二次生图、光影协调（2D）。
- 不做账号/社区（Step 3）。
- 不做实时视频流/WebRTC（2B）。
- 不做复杂后台管理/多人协作；角色文档是本机 + 云端处理的单用户资产。

## Architecture

```
Phone                                      Cloud
┌────────────────────────────┐            ┌─────────────────────────────┐
│ 素材库（角色文档列表）        │            │ Session API                 │
│ 角色文档详情（图片/角色卡）    │  HTTPS     │  ├─ create/keepalive/end     │
│ 上传/重试/进度                │◀──────────▶│  ├─ upload references       │
│ 本地存储（JSON + 文件）        │            │  ├─ character pipeline      │
│ AI 会话客户端                 │            │  │   ├─ detect/crop/bg     │
│  Provider 配置（只读）         │            │  │   ├─ dedup/cluster      │
└────────────────────────────┘            │  │   ├─ reference select   │
                                           │  │   ├─ embedding          │
                                           │  │   └─ VLM character card │
                                           │  └─ Provider registry       │
                                           │      ├─ VlmProvider         │
                                           │      ├─ GenerationProvider  │
                                           │      └─ ImageEditProvider   │
                                           └─────────────────────────────┘
```

- 客户端不持有任何 API key；所有 Provider 调用在服务端。
- Step 2A 用 REST + 轮询；2B 再引入 WebSocket/WebRTC 做延迟流。
- 无账号阶段用本地匿名 `deviceId` + 会话 ID；Step 3 再升级为账号。

## Decisions

### D1. 角色文档本地优先，云端按需处理

**选择**：角色文档的元数据和原图先存本地（应用目录 + JSON）；用户点击「生成角色卡/开始 AI」时才上传处理。

**理由**：本地优先符合产品叙事，也让素材库在无网络时可用；避免每次打开都同步大图。

**替代方案**：全部云端存储——需要账号/存储/同步，Step 2A 太重；不选。

### D2. 零负担上传 + 自动清洗

**选择**：客户端只做基础检查（分辨率、模糊、重复哈希、NSFW 初筛）；服务端做角色检测、裁剪、去背景、去重、聚类、参考图选择、身份 embedding、VLM 描述。

**理由**：用户不会分类，也不应该被要求分类；大部分清洗需要模型，放服务端更合适。

**替代方案**：让用户手动选正面/侧面/背面——用户负担高；不选。

### D3. 角色卡：VLM 生成，可改可不改

**选择**：VLM 读取角色文档的图片/缩略图，输出外观标签、描述、主参考图、可选性格标签；用户可编辑，但不强制。

**理由**：角色卡是「AI 理解成了什么」的轻量确认，也是 2C VLM 导演的输入；不编辑也能跑。

### D4. 云端会话骨架 + Provider 抽象

**选择**：

- `AiSession`：`created → uploading → processing → ready / failed → ended`。
- `VlmProvider`：角色卡、场景分析、质量打分。
- `GenerationProvider`：角色生成/编辑（2C 使用；2A 只做健康检查和 Mock）。
- `ImageEditProvider`：最终光影协调（2D 使用；2A 只做健康检查和 Mock）。
- 每个 provider 有 `MockProvider` 和至少一个真实适配器；通过服务端环境变量/远程配置选择。

**理由**：先把协议跑通，再接真实 API；Mock 让客户端/测试不依赖外部服务；接口隔离避免 provider 锁定。

### D5. 推荐 Provider 组合（国内模型）

**首选单 key：SiliconFlow（硅基流动）**

- 生图：Qwen-Image / Qwen-Image-Edit / FLUX.1 / Kolors（以控制台可用列表为准）。
- VLM：Qwen-VL / GLM-4V（SiliconFlow 上有开源 VLM）。
- 最终编辑：Qwen-Image-Edit。
- 优点：OpenAI 兼容接口，一个 key 覆盖生图 + 编辑 + VLM；接入最快，适合 2A 的角色卡和 2C 的原型。
- 限制：IP-Adapter/ControlNet 级别的精确控制可能不足；优先用「多图参考 / 局部编辑 + 候选 + 质量闸门」。如果模型不支持参考图/局部编辑，2C 的站位/姿势控制会受限。

**更强动漫控制：LiblibAI（哩布哩布 AI）**

- ComfyUI workflow + 动漫 SDXL（Animagine / Illustrious / Pony 系）+ IP-Adapter + ControlNet + inpainting。
- 优点：最接近产品需要的「身份 + 姿势 + 局部重绘」控制；国内访问/支付方便。
- 需要确认 API/工作流开放程度、并发与计费；作为 SiliconFlow 不足时的升级。

**官方 Qwen / 万相：阿里云百炼（DashScope）**

- Qwen-Image、Qwen-Image-Edit、Wanx、Qwen-VL；企业级稳定，一个 key 覆盖生图/编辑/VLM。
- 适合需要官方 SLA/合规的场景；接入比 SiliconFlow 稍重。

**多图参考/最终编辑：火山引擎 Seedream 系列 + 豆包视觉**

- Seedream 系列支持多图参考/编辑，适合最终成片的光影协调；豆包视觉可做 VLM 备选。
- 作为最终编辑的备选，或与 SiliconFlow 组合。

**长期**：国内 GPU 云（阿里云/火山/腾讯云）+ ComfyUI，完全可控，适合量产成本优化。前期不建议自建。

**约束**：
- 以拿 API 时可用列表为准；客户端不硬编码模型名；服务端配置化。
- 国内通用 API 可能不暴露 IP-Adapter/ControlNet；需要多图参考/局部编辑能力；否则用 LiblibAI/ComfyUI 或自建。
- 最终编辑模型要验证「保持二次元画风」；Qwen-Image-Edit / Seedream 需要 prompt + 参考图约束。

### D6. 数据、隐私与审核

**选择**：

- 上传前明确告知「素材将上传云端处理」；用户确认素材使用权。
- 角色素材按会话/文档隔离；处理完成后按保留策略清理临时文件。
- 上传图片和生成结果做内容审核；不合规的图片不进入流程。
- 传输 HTTPS；服务端密钥管理；客户端不存 API key。
- 匿名 `deviceId` + 会话 ID；Step 3 再接入账号。

### D7. 失败、重试与成本

**选择**：

- 上传/处理/Provider 调用都有超时、重试、错误分类（网络/限流/内容/服务端）。
- 角色卡生成按文档缓存；同一文档不重复调用；图片压缩/缩略图后再送 VLM。
- 每个会话/设备有请求限额；Mock 模式不产生外部费用。
- 记录 p50/p95 延迟、失败率、Provider 成本（为 2C 的容量规划做准备）。

## Data Model

```
CharacterDocument
  id, name, createdAt, updatedAt
  referenceImages[]        # 本地文件路径/哈希/宽高/状态
  selectedReferences[]     # 自动选出的最佳参考
  characterCard            # 外观标签、描述、主参考图、性格标签
  identityEmbedding        # 预留，服务端返回后缓存
  looks[]                  # 服装/形态聚类（可选）
  status                   # draft/processing/ready/failed

AiSession
  id, deviceId, characterDocumentId
  state                    # created/uploading/processing/ready/failed/ended
  providerConfig           # vlm/generation/imageEdit 的 provider/model
  createdAt, expiresAt
```

## API Sketch

- `POST /v1/sessions` → sessionId, expiresAt
- `POST /v1/sessions/{id}/references`（multipart，多图）
- `GET /v1/sessions/{id}` → state、进度、角色卡、错误
- `POST /v1/sessions/{id}/end`
- `GET /v1/health/providers` → provider 状态（Mock/真实）
- 2A 用轮询；2B 换成 WebSocket/WebRTC。

## Risks / Trade-offs

- **Provider/API 可用性/价格变化** → Provider 抽象 + Mock；配置化；至少两个备选（Fal/Replicate、SiliconFlow/LiblibAI）。
- **角色卡质量不稳定** → 多图参考、VLM 提示词约束、用户可编辑；质量差时提示补图。
- **杂乱文件夹** → 自动清洗 + 聚类 + 轻量选择；不阻塞。
- **上传/处理延迟** → 进度、超时、重试；角色卡可先显示占位。
- **隐私/版权** → 上传告知、审核、权利确认、会话清理。
- **匿名会话被滥用** → 限额、deviceId、服务端风控；Step 3 接账号。
- **客户端不持 key** → 所有 Provider 调用在服务端；客户端只拿结果。
- **2B/2C 返工** → 本期接口按后续需求预留（session、provider、角色卡、embedding）。

## Migration Plan

- **2A.1**：本地角色文档库（新建/列表/详情/上传/删除）+ 本地基础检查。
- **2A.2**：云端 session API + Mock VLM；角色卡生成与展示。
- **2A.3**：接真实 VLM（Gemini/Qwen-VL）；接真实存储/审核。
- **2A.4**：Provider 健康检查与配置；为 2C 接 Fal/ComfyUI 预留。
- 回滚：Provider 切回 Mock；角色文档保留本地；会话失败可重试/删除。

## Open Questions

- 首选 API：SiliconFlow（生图 + 编辑 + VLM 一个 key）是否满足身份/姿势/局部编辑？不够时是否上 LiblibAI/百炼/火山？
- 服务端技术栈：Python/FastAPI + ComfyUI，还是 Node？需要和 2B/2C 的流媒体/GPU 方案统一。
- 图片存储：本地对象存储/云 OSS/S3？会话结束后的保留策略？
- 角色卡编辑的范围：只改名字/标签，还是允许删除参考图/换主参考？
- 审核方案：第三方审核 API 还是自建模型？阈值？
- 无账号阶段的限额：每设备每天几次角色卡/会话？
- 是否在 2A 就接入 Fal 生图做「角色卡预览图」，还是只做 VLM 角色卡？
