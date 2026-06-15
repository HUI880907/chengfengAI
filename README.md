# 乘风AI (ChengFengAI)

> 基于通义千问云端 API + iOS 本地模型的原生智能助手应用

## 目录

- [项目简介](#项目简介)
- [系统要求](#系统要求)
- [技术架构](#技术架构)
- [核心功能](#核心功能)
- [梯队功能](#梯队功能)
- [快速开始](#快速开始)
- [项目结构](#项目结构)
- [构建与打包](#构建与打包)
- [开发文档](#开发文档)

---

## 项目简介

乘风AI 是一款纯原生 iOS 应用，主打 **免费模型调用 + 本地运行** 的双模型智能助手。应用以通义千问云端 API 为核心推理载体，同时集成 iOS 系统原生模型作为离线兜底，确保在网络异常或限流场景下依然可用。

### 设计理念

| 原则 | 说明 |
|------|------|
| **云端优先** | 首选通义千问 API，能力更强大 |
| **本地兜底** | 云端不可用时无缝降级至系统模型 |
| **数据本地** | 对话、上传文件均在本地存储，无云端留存 |
| **零第三方依赖 | 尽量使用 iOS 原生框架 |
| **分层设计 | 核心功能必做，扩展功能可开关 |

---

## 系统要求

| 组件 | 版本要求 |
|------|----------|
| **iOS** | 16.0+ |
| **Xcode** | 15.0+ |
| **Swift** | 5.9+ |
| **构建工具** | XcodeGen 2.38.0+ |
| **macOS** | 13.0+ (用于开发构建) |

---

## 技术架构

### 模型调度流程

```
用户输入
   │
   ▼
┌─────────────────────────────┐
│    上下文管理器           │  ← 检查 token 数量、自动截断
└─────────────────────────────┘
   │
   ▼
┌─────────────────────────────┐
│     模型调度器           │  ← ModelScheduler
│  ┌─────────────────────┐  │
│  │ 1. 网络可达性检测   │  │
│  │ 2. API Key 检查      │  │
│  │ 3. Token 超限判断    │  │
│  │ 4. 附件大小评估    │  │
│  └─────────────────────┘  │
└─────────────────────────────┘
   │
   ├──────────┐
   ▼           ▼
┌─────────┐  ┌─────────────┐
│ 千问API │  │ iOS本地模型 │
│ (云端)   │  │ (离线兜底) │
└─────────┘  └─────────────┘
   │           │
   └────┬──────┘
        ▼
   响应结果 → 本地存储 → UI展示
```

### 模块划分

```
乘风AI/
├── Models/                    # 数据模型层 (7 个文件)
│   ├── Message.swift        # 消息模型 (用户/助手/系统)
│   ├── Attachment.swift    # 附件模型 (文本/图片/PDF/文档)
│   ├── Conversation.swift  # 对话模型 (包含多条消息)
│   ├── UserProfile.swift   # 用户配置 (昵称/主题等)
│   ├── AppSettings.swift   # 应用设置 (API Key/模型优先级)
│   ├── ModelProvider.swift # 模型提供者类型
│   └── APICredential.swift # API 凭证
│
├── Services/                 # 核心服务层 (9 个子目录)
│   ├── APIClient/        # 千问 API 客户端
│   │   └── QwenAPIClient.swift
│   ├── LocalModel/        # iOS 本地模型服务
│   │   └── IOSLocalModelService.swift
│   ├── ModelScheduler/    # 统一模型调度器
│   │   └── ModelScheduler.swift
│   ├── Storage/          # 本地存储服务
│   │   ├── ConversationStore.swift
│   │   ├── SettingsStore.swift
│   │   └── TokenCounter.swift
│   ├── Speech/           # 语音朗读服务
│   │   ├── SpeechService.swift
│   │   └── SpeechSettings.swift
│   ├── Export/           # 导出服务
│   │   ├── ExportService.swift
│   │   └── ShareService.swift
│   ├── FileInteraction/  # 文件交互 (梯队1)
│   │   ├── ClipboardService.swift
│   │   └── QuickPromptService.swift
│   ├── TokenUsage/       # Token 使用监控
│   │   └── TokenUsageMonitor.swift
│   └── SystemIntegration/ # 系统集成
│       └── ShortcutSupport.swift
│
├── Views/                   # UI 视图层 (6 个子目录)
│   ├── Chat/              # 聊天主界面
│   │   ├── RootView.swift
│   │   ├── MainChatView.swift
│   │   ├── MessageListView.swift
│   │   ├── MessageBubbleView.swift
│   │   ├── ChatInputBarView.swift
│   │   └── AttachmentPickerView.swift
│   ├── Sidebar/         # 侧边栏
│   │   └── SidebarView.swift
│   ├── Settings/        # 设置页面
│   │   └── SettingsView.swift
│   ├── Export/          # 导出面板
│   │   └── ExportPanelView.swift
│   ├── Components/      # 通用组件
│   │   ├── ImagePicker.swift
│   │   ├── ActivityView.swift
│   │   ├── ClipboardSuggestionView.swift
│   │   ├── SpeechControlsView.swift
│   │   ├── ShareContentView.swift
│   │   ├── TokenUsageIndicator.swift
│   │   └── ProviderSwitchBanner.swift
│   └── Theme/         # 主题管理
│       └── ThemeManager.swift
│
├── ViewModels/            # 视图模型层
│   └── ChatViewModel.swift
│
├── Utils/                # 工具扩展
│   ├── String+Helpers.swift
│   ├── Date+Helpers.swift
│   ├── Color+AppTheme.swift
│   └── Bundle+AppVersion.swift
│
├── ChengFengAIApp.swift  # 应用入口
└── Info.plist             # 应用配置
```

---

## 核心功能

| 功能 | 状态 | 说明 |
|------|------|
| **聊天对话** | ✅ | 文本输入、流式响应 |
| **云端模型** | ✅ | 通义千问 Qwen3.5-9B |
| **本地模型兜底** | ✅ | iOS 系统原生模型 |
| **上下文管理** | ✅ | 自动截断、手动重置 |
| **附件上传** | ✅ | 图片/PDF/文档/文本 |
| **语音朗读** | ✅ | AVSpeechSynthesizer |
| **对话导出** | ✅ | 纯文本/Markdown/截图 |
| **用户昵称** | ✅ | 自定义显示名 |
| **折叠侧边栏** | ✅ | 对话列表与设置入口 |

---

## 梯队功能

### 梯队 1 (已实现 - 纯 iOS 原生)

| 功能 | 技术实现 |
|------|----------|
| 朗读增强 | 自定义语速/音调/音色切换 |
| 剪贴板联动 | 自动识别剪贴板文本/图片 |
| 快捷提问入口 | 根据内容生成建议问题 |
| 系统主题适配 | 跟随系统深浅色模式 |
| 系统分享 | iOS 原生分享面板 |
| Siri 快捷指令 | `cfeng://ask?text=xxx` |

### 梯队 2 (复用现有架构 - 上层业务)

| 功能 | 说明 |
|------|------|
| 对话分支 | 同会话拆分多条独立对话线 |
| 消息编辑 | 单条消息编辑/删除/隐藏 |
| 会话标签 | 对话分类归档 |
| 预设模板 | 摘要/翻译/润色/数据解析 |
| Token 面板 | 实时显示消耗情况 |
| 文档预处理 | 多文件统一摘要再提交 |
| 导出 Word | 本地生成 Word 文档 |
| 长截图 | 对话长截图导出 |

### 梯队 3 (独立模块 - 内置开关)

| 功能 | 说明 |
|------|------|
| 多模型 API | GLM/DeepSeek 等可视化配置 |
| 本地向量检索 | 文档知识库离线搜索 |
| 离线 TTS 音色 | 更拟人语音，故障降级系统朗读 |
| OCR 预解析 | 图片文字识别，再上传千问 |

### 梯队 4 (不建议早期开发)

| 功能 | 风险说明 |
|------|----------|
| 第三方笔记直传 | Notion/语雀/Obsidian 等 API 频繁变更 |
| 自建云端同步 | 网络/登录/隐私/服务器维护成本高 |
| 高度自定义 UI | 跨端协同/远程调用等复杂功能 |

---

## 快速开始

### 前置条件

1. **macOS 13.0+** 或更新
2. **Xcode 15.0+**
3. **XcodeGen 2.38.0+**
4. **千问 API Key** (在阿里云 DashScope 获取)

### 安装步骤

```bash
# 1. 克隆项目
git clone <仓库地址>
cd 乘风AI

# 2. 安装 XcodeGen (如果未安装)
brew install xcodegen

# 3. 生成 Xcode 项目
xcodegen generate

# 4. 打开项目
open 乘风AI.xcodeproj

# 5. 在 Xcode 中按 Cmd+R 运行
```

### 或使用构建脚本

```bash
# 一键执行所有步骤
chmod +x build.sh
./build.sh all

# 或分步执行
./build.sh setup      # 安装 XcodeGen
./build.sh generate # 生成项目
./build.sh build   # 构建
./build.sh archive # 打包
```

### 配置 API Key

1. 运行应用
2. 打开侧边栏 → 设置
3. 在「模型配置」中填入千问 API Key
4. 可选调整 Token 阈值（默认 85%）

### URL Scheme 快捷指令

```
# 从外部唤起应用并传入文本
cfeng://ask?text=今天天气怎么样

# 外部传入图片 (base64)
cfeng://ask?imageData=<base64>
```

---

## 项目结构

### 配置文件

| 文件 | 说明 |
|------|------|
| `project.yml` | XcodeGen 项目定义 |
| `Package.swift` | Swift Package Manager 配置 |
| `build.sh` | 自动化构建脚本 |
| `.gitignore` | Git 忽略规则 |
| `.github/workflows/ci.yml` | GitHub Actions CI/CD |
| `APP核心设计原则（修订版）.md | 设计原则文档 |

### 总计

- **Swift 文件**: 36+ 个核心文件
- **视图组件**: 15+ 个 SwiftUI 视图
- **服务模块**: 9+ 个独立服务
- **无第三方依赖**: 全部使用 iOS 原生框架
- **代码行数**: 约 4000+ 行

---

## 构建与打包

### 本地构建

```bash
# 生成项目
xcodegen generate

# 构建模拟器版本 (Debug)
xcodebuild -project 乘风AI.xcodeproj \
  -scheme 乘风AI \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
  build

# 构建真机版本 (Release)
xcodebuild -project 乘风AI.xcodeproj \
  -scheme 乘风AI \
  -configuration Release \
  -sdk iphoneos \
  build
```

### GitHub Actions 自动构建

项目已配置完整的 CI/CD 工作流，每次提交自动执行：

| 任务 | 说明 |
|------|------|
| **build-debug** | iOS Simulator 构建检查 |
| **build-release** | 真机 Release 构建 |
| **archive** | 生成 Archive 包 |
| **package-source** | 源代码 ZIP/TAR.GZ 打包 |
| **stats** | 代码统计 |
| **release** | Tag 触发时自动生成 GitHub Release |

### 打包产物说明

```
构建产物/
├── 乘风AI.xcodeproj/       # 生成的 Xcode 项目
├── build/                     # 构建中间产物
├── build-release/               # Release 构建
├── archives/                 # Archive 文件
│   └── 乘风AI.xcarchive/
├── 乘风AI-source-<commit>.zip
├── 乘风AI-source-<commit>.tar.gz
└── 乘风AI-release-<version>.tar.gz
```

### 签名与发布

1. **开发测试**: 使用个人 Apple Developer 账号自动签名
2. **发布到 App Store**: 需要团队账号 + 生产证书
3. **内测分发**: 可以使用 TestFlight 或蒲公英等第三方平台

---

## 开发文档

### 添加新的模型提供者

1. 在 `ModelProvider.swift` 添加新的 `ModelProviderType`

2. 在 `Services/APIClient/` 下创建新的 API Client

3. 在 `ModelScheduler.swift` 的调度逻辑中添加新的 Provider

### 添加新的视图

1. 在 `Views/` 对应目录下创建 SwiftUI 视图

2. 在 `project.yml` 中 XcodeGen 会自动识别

3. 在 `RootView.swift` 或相关容器中引用

### 代码规范

- 使用 Swift 5.9+ 语法
- 严格并发检查 (`StrictConcurrency`)
- 全部 `@MainActor` 更新 UI
- 本地存储使用 JSON 序列化
- 网络请求使用 `async/await`
- 错误类型实现 `LocalizedError`

### 安全与隐私

- **所有对话数据本地存储
- **API 调用仅在用户触发时传输
- **无云端持久化
- **iOS 系统权限按需请求

---

## 许可证

本项目遵循设计原则，核心功能和开发文档仅用于参考学习

---

## 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| v1.0.0 | 2026-06-15 | 初始版本，核心功能完整实现 |

---

## 联系与支持

如有问题或建议，欢迎提交 Issue。

---

> 乘风AI - 让 AI 更贴近你的生活

