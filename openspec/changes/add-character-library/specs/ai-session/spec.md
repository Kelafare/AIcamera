## ADDED Requirements

### Requirement: 云端会话创建与管理
系统 SHALL 为角色处理创建云端会话，包含 sessionId、deviceId、characterDocumentId、状态和过期时间；会话 SHALL 可结束并清理。

#### Scenario: 创建会话
- **WHEN** 用户选择一个角色文档并请求生成角色卡
- **THEN** 系统创建会话，返回 sessionId 和状态

#### Scenario: 结束会话
- **WHEN** 用户退出或会话完成
- **THEN** 系统结束会话并清理临时上传文件

### Requirement: 素材上传
系统 SHALL 支持把角色文档的参考图上传到会话，并在上传前告知用户素材将上传云端处理。

#### Scenario: 上传前告知
- **WHEN** 用户首次开始云端处理
- **THEN** 系统提示素材将上传云端，并获得用户确认

#### Scenario: 上传进度与重试
- **WHEN** 上传进行中或失败
- **THEN** 系统显示进度，失败项可重试，不丢失已上传内容

### Requirement: Provider 抽象
系统 SHALL 通过服务端 Provider 抽象调用模型：

- `VlmProvider`：角色卡、场景分析、质量打分；
- `GenerationProvider`：角色生成/编辑；
- `ImageEditProvider`：最终光影协调。

每个 Provider SHALL 有 Mock 实现，并支持国内真实适配器（Qwen-VL/GLM-4V、SiliconFlow/LiblibAI/Seedream、Qwen-Image-Edit/Seedream）。客户端 MUST NOT 持有 API key。

#### Scenario: Mock 模式
- **WHEN** 服务端未配置真实 Provider
- **THEN** 系统使用 Mock 返回可预测的角色卡，流程可跑通

#### Scenario: 真实 Provider 配置
- **WHEN** 服务端配置了国内 Provider 的 API key 和模型名
- **THEN** 系统调用真实服务并返回结果，客户端不接触 key

### Requirement: 角色卡处理结果
系统 SHALL 在会话中返回角色卡，并支持轮询/查询状态；会话 MUST 区分处理中、成功、失败。

#### Scenario: 处理成功
- **WHEN** 云端处理完成
- **THEN** 系统返回角色卡并标记会话 ready

#### Scenario: 处理失败
- **WHEN** 处理超时或 Provider 返回错误
- **THEN** 系统标记 failed，返回可读错误，允许重试

### Requirement: 错误分类与重试
系统 SHALL 区分网络、超时、限流、内容审核、服务端错误，并只为可重试错误提供重试。

#### Scenario: 限流
- **WHEN** Provider 返回限流
- **THEN** 系统提示稍后重试，不重复扣费或重复提交

### Requirement: 隐私与清理
系统 SHALL 按会话隔离素材，会话结束或过期后清理临时文件；MUST NOT 将素材用于训练或长期保留（除非用户明确保存）。

#### Scenario: 会话过期
- **WHEN** 会话超过过期时间
- **THEN** 系统清理临时上传文件和中间结果

### Requirement: 限额与成本
系统 SHALL 对每设备/会话设置请求限额，并记录 Provider 延迟、失败率和成本；Mock 模式 MUST NOT 产生外部费用。

#### Scenario: 超出限额
- **WHEN** 设备超过当日角色卡/会话限额
- **THEN** 系统拒绝新请求并提示限额

### Requirement: Provider 健康检查
系统 SHALL 提供 Provider 健康检查，标记 Mock/真实 Provider 的可用状态；不可用时 SHALL 降级或提示。

#### Scenario: 真实 Provider 不可用
- **WHEN** 健康检查发现真实 Provider 不可用
- **THEN** 系统切回 Mock 或提示用户稍后重试
