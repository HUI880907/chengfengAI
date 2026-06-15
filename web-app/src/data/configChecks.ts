import type { ConfigCheckItem } from '../types'

// 演示用的配置检查项：与 iOS 打包流程相关的核心文件
export const configChecks: ConfigCheckItem[] = [
  {
    id: 'project-yml',
    fileName: 'project.yml',
    description: 'XcodeGen 项目配置，定义 targets、编译设置与资源',
    status: 'pass',
    detail: '存在 2 个 targets（乘风AI / 乘风AITests），iOS 16.0+，Swift 5.9，Info.plist 路径已配置',
  },
  {
    id: 'package-swift',
    fileName: 'Package.swift',
    description: 'Swift Package Manager 配置',
    status: 'pass',
    detail: 'name: ChengFengAI，无外部依赖，Swift tools 5.9',
  },
  {
    id: 'info-plist',
    fileName: '乘风AI/Info.plist',
    description: 'iOS 应用属性列表（BundleId, 权限, 版本）',
    status: 'pass',
    detail: 'CFBundleIdentifier=com.chengfeng.ai，版本 1.0.0，相机/相册权限已声明',
  },
  {
    id: 'ci-yml',
    fileName: '.github/workflows/ci.yml',
    description: 'GitHub Actions 构建与 IPA 打包流水线',
    status: 'pass',
    detail: 'runs-on: macos-15，包含模拟器构建 + 真机 Archive + IPA 导出，产物上传为 Artifacts',
  },
  {
    id: 'export-plist',
    fileName: 'exportOptions.plist',
    description: '可选：IPA 导出选项（不使用官方导出时可忽略）',
    status: 'warn',
    detail: '当前项目使用 Payload 方式打包 IPA，无需此文件。若后续使用 xcodebuild -exportArchive，请补全',
  },
  {
    id: 'build-sh',
    fileName: 'build.sh / package_ipa.sh',
    description: '本地手动打包脚本（macOS）',
    status: 'pass',
    detail: '两档脚本均已存在：build.sh 用于常规 Xcode 打包，package_ipa.sh 专用于生成 IPA',
  },
  {
    id: 'app-settings',
    fileName: '乘风AI/Models/AppSettings.swift',
    description: '应用内配置（API Key、主题）',
    status: 'pass',
    detail: 'API Key 可在 App 内设置页输入，默认空，支持 UserDefaults 持久化',
  },
  {
    id: 'apple-account',
    fileName: 'Apple ID / 开发者账号',
    description: '代码签名与分发凭据',
    status: 'warn',
    detail: '打包已设置为 CODE_SIGNING_ALLOWED=NO，可生成无签名 IPA；若希望分发到 App Store，需苹果开发者账号 ($99/年)',
  },
]
