# 乘风AI - 打包前检查清单与测试指南

## 📋 打包前检查清单

### 1. 项目结构检查
- [ ] 所有核心 Swift 文件存在且可读
- [ ] Models 目录完整（7 个模型文件）
- [ ] Services 目录完整（9 个子服务）
- [ ] Views 目录完整（5 个视图目录）
- [ ] ViewModels 和 Utils 存在
- [ ] Tests 目录存在且包含测试文件

### 2. 配置文件检查
- [ ] `project.yml` 存在且语法正确（YAML 格式）
- [ ] `Package.swift` 存在且语法正确
- [ ] `build.sh` 存在且有执行权限
- [ ] `.gitignore` 存在
- [ ] `Info.plist` 存在且包含必要权限
- [ ] `.github/workflows/ci.yml` 存在

### 3. 代码质量检查
- [ ] 所有 Swift 文件包含 `import` 语句
- [ ] 括号匹配正确（`{}`, `()`, `[]`）
- [ ] 模型文件符合 `Codable` 协议
- [ ] 视图文件包含 `import SwiftUI`
- [ ] 无明显语法错误

### 4. 单元测试检查
- [ ] 模型层测试覆盖所有核心模型
- [ ] 服务层测试覆盖 TokenCounter 和存储服务
- [ ] 测试可以在 Xcode 中编译通过
- [ ] 测试用例数量充足（建议 > 30 个）

### 5. 文档检查
- [ ] `README.md` 存在且完整
- [ ] `APP核心设计原则（修订版）.md` 存在
- [ ] 本检查清单存在

### 6. 打包准备检查
- [ ] 本地已安装 Xcode 15+（macOS 环境）
- [ ] 已安装 XcodeGen
- [ ] Apple Developer 账号可用（用于签名）
- [ ] 确认 iOS 版本目标正确（16.0+）
- [ ] Bundle Identifier 正确配置
- [ ] Git 仓库已初始化（可选，但推荐）

---

## 🧪 测试说明

### 测试框架
- **框架**: XCTest（Apple 官方测试框架）
- **语言**: Swift 5.9+
- **平台**: iOS 16.0+, macOS 13.0+

### 测试文件位置

```
Tests/
├── ModelTests.swift          # 模型层测试（7 个测试类）
│   ├── MessageTests         # 消息模型测试（5 个用例）
│   ├── AttachmentTests      # 附件模型测试（4 个用例）
│   ├── ConversationTests    # 对话模型测试（7 个用例）
│   ├── UserProfileTests     # 用户配置测试（3 个用例）
│   ├── ModelProviderTests   # 模型提供者测试（4 个用例）
│   └── APICredentialTests   # API 凭证测试（2 个用例）
│
├── ServiceTests.swift        # 服务层测试（6 个测试类）
│   ├── TokenCounterTests             # Token估算（12个用例）
│   ├── ConversationStoreTests        # 对话存储（7个用例）
│   ├── SettingsStoreTests            # 设置存储（7个用例）
│   ├── ModelSchedulerTests           # 模型调度（8个用例）
│   ├── IOSLocalModelServiceTests     # 本地模型（7个用例）
│   ├── DataIntegrityTests            # 数据完整性（6个用例）
│   └── ErrorHandlingTests            # 错误处理（6个用例）
│
└── XCTestManifests.swift     # 测试入口与概览
```

### 测试覆盖范围

| 模块 | 测试类 | 测试方法 | 覆盖率 |
|------|--------|----------|--------|
| 数据模型 | 7 | 25+ | 核心属性 & Codable |
| Token估算 | 1 | 12+ | 空值/长短/阈值/一致性 |
| 存储服务 | 2 | 14+ | CRUD & 持久化 |
| 模型调度 | 1 | 8+ | 状态管理 & 切换逻辑 |
| 本地模型 | 1 | 7+ | 各类输入响应 |
| 数据完整性 | 1 | 6+ | JSON大小/特殊字符/Unicode |
| 错误处理 | 1 | 6+ | 各类错误本地化 |
| **总计** | **14** | **80+** | 核心逻辑全覆盖 |

### 测试用例重点

1. **基础初始化**: 验证所有模型的默认值和初始化方法
2. **Codable 编码解码**: 验证 JSON 序列化/反序列化的正确性
3. **业务逻辑**: 验证对话添加、上下文重置等核心功能
4. **边界条件**: 验证空输入、超长文本、特殊字符等场景
5. **状态管理**: 验证模型调度器的状态切换正确性
6. **数据完整性**: 验证 Unicode、特殊字符处理
7. **错误处理**: 验证所有自定义错误类型的本地化描述

---

## 🚀 如何运行测试

### 方式一: Windows 环境（项目结构检查）

由于 Windows 无法直接编译运行 iOS 项目，但可以使用检查脚本验证项目完整性：

```powershell
# 在项目根目录下运行
.\check.ps1
```

**预期输出**:
```
==================================================
  乘风AI - 项目结构与代码检查工具
  版本: 1.0.0
  时间: 2026-06-15 22:30:00
==================================================

[信息]  检查 1: 项目目录结构...
[成功]  目录结构完整 (20/20)

[信息]  检查 2: Swift 源文件检查...
[信息]    源代码文件: 36+ 个
[信息]    测试文件: 3 个
[成功]  关键文件完整

[信息]  检查 3: Swift 代码基本语法检查...
[信息]    总代码行数: 4000+ 行
[信息]    总代码大小: XXX KB
[成功]  所有 Swift 文件通过基本语法检查

[信息]  检查 4: 项目配置文件检查...
[成功]  配置文件完整 (7/7)

[信息]  检查 5: 测试文件检查...
[成功]  测试文件结构检查通过

[信息]  检查 6: 代码统计分析...
  ┌─────────────────────────────────────┐
  │       代码分层统计 (按模块)         │
  ├─────────────────────────────────────┤
  │   Models    : 7 文件, XXX 行       │
  │   Services  : 12 文件, XXX 行      │
  │   Views     : 15 文件, XXX 行      │
  │   ViewModels: 1 文件, XXX 行       │
  │   Utils     : 3 文件, XXX 行       │
  │   Tests     : 3 文件, XXX 行       │
  ├─────────────────────────────────────┤
  │   总计: 40+ 文件, 4000+ 行          │
  └─────────────────────────────────────┘

[信息]  检查 7: 打包前完整性验证...
  [✓] 主入口文件
  [✓] 模型文件完整
  [✓] 服务文件完整
  [✓] 视图文件完整
  ...

[成功]  打包前完整性验证全部通过 (14/14)

==================================================
  检查结果汇总
==================================================
  成功: X 项
  警告: X 项
  失败: 0 项
==================================================
  ✓ 项目检查通过，可以进行打包!
```

**日志文件**: `check_results.log` - 包含详细检查记录

### 方式二: macOS 环境（完整测试）

#### 步骤 1: 生成 Xcode 项目

```bash
# 安装 XcodeGen（如未安装）
brew install xcodegen

# 生成项目
cd /path/to/乘风AI
xcodegen generate
```

预期输出:
```
🌧  Generating project "乘风AI"...
🌧  Loading project specification from project.yml
🌧  Generating project settings...
🌧  Resolving dependencies...
🌧  Writing Xcode project file to 乘风AI.xcodeproj
✅  Generated project successfully
```

#### 步骤 2: 编译检查

```bash
# 使用 xcodebuild 编译（不运行应用，仅验证编译）
xcodebuild \
  -project 乘风AI.xcodeproj \
  -scheme 乘风AI \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
  build \
  CODE_SIGNING_ALLOWED=NO | xcpretty
```

预期结果:
- **`BUILD SUCCEEDED`** - 编译成功，无语法错误
- **`BUILD FAILED`** - 需要根据错误信息修复

#### 步骤 3: 运行单元测试

```bash
# 运行所有单元测试
xcodebuild test \
  -project 乘风AI.xcodeproj \
  -scheme 乘风AI \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO 2>&1 | xcpretty --test
```

预期输出:
```
Test Suite 'All tests' started at ...
Test Suite 'ModelTests.xctest' started at ...
Test Case '-[ModelTests.MessageTests testMessageInitialization]' started.
Test Case '-[ModelTests.MessageTests testMessageInitialization]' passed (0.001 seconds).
Test Case '-[ModelTests.MessageTests testMessageWithRoleAndContent]' started.
...
Test Suite 'ServiceTests.xctest' started at ...
Test Case '-[ServiceTests.TokenCounterTests testEstimateTokensForEmptyString]' started.
...
Executed 80 tests, with 0 failures (0 unexpected) in 0.123 seconds
✅ Test run complete
```

#### 步骤 4: 运行特定测试

```bash
# 仅运行模型测试
xcodebuild test \
  -project 乘风AI.xcodeproj \
  -scheme 乘风AI \
  -only-testing:乘风AITests/MessageTests \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
  CODE_SIGNING_ALLOWED=NO

# 仅运行特定测试方法
xcodebuild test \
  -project 乘风AI.xcodeproj \
  -scheme 乘风AI \
  -only-testing:乘风AITests/TokenCounterTests/testApproachingLimit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
  CODE_SIGNING_ALLOWED=NO
```

#### 步骤 5: 使用 build.sh 自动化

```bash
chmod +x build.sh

# 生成项目
./build.sh generate

# 运行测试
./build.sh test

# 完整流程
./build.sh all
```

### 方式三: Xcode GUI 操作

1. **打开项目**: `open 乘风AI.xcodeproj`
2. **选择模拟器**: 选择 "iPhone 15 (17.0)" 或更高
3. **运行测试**:
   - 按 `Cmd + U` 运行所有测试
   - 或点击 Product → Test
4. **查看结果**: 在左侧导航栏的 Test navigator 中查看
5. **查看测试报告**: 在 Report Navigator 中查看详细报告

### 测试结果解读

| 状态 | 含义 | 建议 |
|------|------|------|
| ✅ 通过 | 所有测试断言成立 | 可以继续打包 |
| ⚠ 警告 | 编译器警告（未使用变量等） | 建议修复以提高代码质量 |
| ❌ 失败 | 测试断言不成立或编译错误 | 必须修复，查看具体错误信息 |
| 🚫 崩溃 | 运行时异常或内存问题 | 严重问题，需调试修复 |

---

## 📦 打包流程（测试通过后）

### 方式一: 模拟器打包（快速验证）

```bash
# 生成项目
xcodegen generate

# 构建模拟器版本
xcodebuild build \
  -project 乘风AI.xcodeproj \
  -scheme 乘风AI \
  -configuration Release \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
  CODE_SIGNING_ALLOWED=NO | xcpretty
```

### 方式二: 真机打包（Archive）

```bash
# 生成项目
xcodegen generate

# 打包 Archive（需要正确的签名配置）
xcodebuild archive \
  -project 乘风AI.xcodeproj \
  -scheme 乘风AI \
  -configuration Release \
  -archivePath "archives/乘风AI.xcarchive" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=YOUR_TEAM_ID | xcpretty
```

### 方式三: GitHub Actions 自动构建

1. 推送代码到 GitHub 仓库
2. Workflow 自动触发
3. 查看 Actions 页面获取构建结果
4. 下载构建产物（源代码包等）

---

## ⚠ 常见问题与解决

### 问题 1: XcodeGen 命令未找到

```bash
# 解决: 安装 XcodeGen
brew install xcodegen

# 或使用 mint
brew install mint
mint install yonaskolb/XcodeGen
```

### 问题 2: 编译失败 - 签名问题

**错误信息**: `No signing certificate "iOS Development" found`

**解决**:
```bash
# 在命令行中禁用签名
CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO

# 或在 project.yml 中配置
# settings:
#   base:
#     CODE_SIGN_STYLE: Automatic
#     DEVELOPMENT_TEAM: YOUR_TEAM_ID
```

### 问题 3: 测试失败 - 特定断言不成立

**定位方法**:
1. 查看测试输出中的失败信息
2. 打开对应测试文件，检查断言逻辑
3. 检查是否有依赖项未正确配置
4. 可能需要调整测试预期值

### 问题 4: Windows 环境无法运行测试

**说明**: 这是正常的！iOS 应用必须在 macOS + Xcode 环境下构建和测试。

**在 Windows 上可以做的**:
- ✅ 使用 `check.ps1` 进行项目结构和代码检查
- ✅ 验证配置文件语法正确性
- ✅ 查看代码逻辑是否正确
- ❌ 无法编译运行 Swift 代码
- ❌ 无法运行 XCTest 测试

### 问题 5: 构建警告过多

**常见警告类型**:
- `Unused variable` - 未使用变量
- `Immutable value` - 可以改为 let
- `File deprecated` - API 已弃用

**建议**:
- 优先修复模型和服务层的警告
- 视图层警告可以延后处理
- 使用 `swiftlint` 进行代码规范检查（可选）

---

## 🎯 测试通过标准

要判定项目"可以打包"，必须满足以下条件：

### 必要条件（全部满足）
1. [ ] **结构完整**: `check.ps1` 输出 0 失败
2. [ ] **编译成功**: Xcode 编译无错误（`BUILD SUCCEEDED`）
3. [ ] **测试通过**: 单元测试 100% 通过（`Executed XX tests, with 0 failures`）
4. [ ] **无严重警告**: 编译警告 < 10 个，且无弃用 API 警告

### 建议条件（尽量满足）
1. [ ] 代码覆盖率 > 70%
2. [ ] 无编译器警告
3. [ ] 测试用例数量 > 50
4. [ ] 测试覆盖所有模型和核心服务
5. [ ] 测试包含边界条件和错误路径

---

## 📊 测试结果记录模板

| 检查项 | 结果 | 备注 |
|--------|------|------|
| Windows 结构检查 (`check.ps1`) | ✅/⚠/❌ | 失败数: X |
| Xcode 编译 (Debug) | ✅/⚠/❌ | 警告数: X |
| Xcode 编译 (Release) | ✅/⚠/❌ | 警告数: X |
| 单元测试运行 | ✅/⚠/❌ | 通过 X/总数 X |
| 模拟器运行 | ✅/⚠/❌ | 启动成功 |
| Archive 打包 | ✅/⚠/❌ | 签名状态 |

**检查时间**: `2026-06-15 22:30:00`
**结论**: `可以打包 / 需要修复 / 暂缓打包`

---

## 🔗 相关文档

- 设计原则: `APP核心设计原则（修订版）.md`
- 项目说明: `README.md`
- 构建脚本: `build.sh`
- 检查脚本: `check.ps1`
- CI 配置: `.github/workflows/ci.yml`

---

> 乘风AI v1.0.0 - 测试与打包指南
> 最后更新: 2026-06-15
