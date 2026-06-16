// swift-tools-version:5.9
// ================================================
// 乘风AI - Swift Package Manager 配置文件
// 使用方法：
//   swift build      - 编译检查
//   swift test       - 运行测试
// ================================================

import PackageDescription

let package = Package(
    name: "ChengFengAI",

    // 支持的平台
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],

    // 产品定义：编译为库供外部使用
    products: [
        .library(
            name: "ChengFengAI",
            targets: ["ChengFengAI"]
        )
    ],

    // 外部依赖：无第三方依赖，全部使用系统框架
    dependencies: [],

    // 模块定义
    targets: [
        // 主应用模块 - 包含所有源代码
        .target(
            name: "ChengFengAI",
            dependencies: [],
            path: "ChengFengAI",
            exclude: [
                "Info.plist"
            ],
            sources: nil,
            resources: [],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ],
            linkerSettings: nil
        ),

        // 单元测试
        .testTarget(
            name: "ChengFengAITests",
            dependencies: [
                .target(name: "ChengFengAI")
            ],
            path: "Tests"
        )
    ],

    // Swift 语言版本
    swiftLanguageVersions: [.v5]
)
