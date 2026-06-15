import type { BuildRecord, PipelineStep } from '../types'

// 演示用步骤定义：7 步 iOS 打包流水线
export const demoPipelineSteps: PipelineStep[] = [
  {
    index: 0,
    title: '代码准备 & Checkout',
    description: '拉取最新源码，检查项目完整性',
    status: 'success',
    logSnippet:
      'Checking out main branch...  \nProject files verified: 47 files  \nNo merge conflicts detected.',
  },
  {
    index: 1,
    title: '生成 Xcode 项目 (XcodeGen)',
    description: '根据 project.yml 生成 XcodeProj 工程',
    status: 'success',
    logSnippet:
      'Generating project with XcodeGen...  \nTargets: 乘风AI, 乘风AITests  \nBuild settings resolved, .xcodeproj generated.',
  },
  {
    index: 2,
    title: '模拟器 Debug 构建',
    description: '在 iOS Simulator 上编译，验证语法 & 链接',
    status: 'success',
    logSnippet:
      'Building for iphonesimulator (arm64)...  \nCompile Swift sources (45 files)  \nLink — 乘风AI.app  \nBuild succeeded in 28s.',
  },
  {
    index: 3,
    title: '真机 Release Archive',
    description: 'iphoneos SDK，关闭签名，生成 .xcarchive',
    status: 'success',
    logSnippet:
      'Building for iphoneos with Release configuration  \nCODE_SIGNING_ALLOWED=NO  \nArchive: 乘风AI.xcarchive (16.8 MB)  \nArchive succeeded in 3m 12s.',
  },
  {
    index: 4,
    title: '导出 IPA (Payload 方式)',
    description: '提取 .app → Payload 目录 → zip 重命名',
    status: 'success',
    logSnippet:
      'Extracting .app from Products/Applications  \nBuilding Payload directory  \nZipping payload → 乘风AI.ipa (14.8 MB)  \nIPA exported successfully.',
  },
  {
    index: 5,
    title: '上传 Artifact',
    description: '上传 IPA + Archive 到 GitHub Actions 产物',
    status: 'success',
    logSnippet:
      'Uploading ipa-乘风AI ... done  \nUploading archive-乘风AI ... done  \nTotal artifacts: 2, 54 MB.',
  },
  {
    index: 6,
    title: '生成 GitHub Release (可选)',
    description: '打 tag，生成 release 说明并附加 IPA',
    status: 'success',
    logSnippet:
      'Tag: v1.0.0  \nRelease notes generated  \nPublished at https://github.com/<you>/releases/v1.0.0',
  },
]

// 演示用构建历史：最近 5 次
export const mockBuildHistory: BuildRecord[] = [
  {
    id: 'build-latest',
    version: '1.0.0',
    status: 'success',
    createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
    durationSec: 520,
    ipaSizeKB: 14800,
    steps: demoPipelineSteps,
  },
  {
    id: 'build-2',
    version: '0.9.8-beta',
    status: 'success',
    createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000),
    durationSec: 480,
    ipaSizeKB: 14200,
    steps: demoPipelineSteps,
  },
  {
    id: 'build-3',
    version: '0.9.5',
    status: 'failed',
    createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
    durationSec: 115,
    ipaSizeKB: 0,
    steps: demoPipelineSteps.map((s, i) => ({ ...s, status: i < 2 ? 'success' : i === 2 ? 'failed' : 'pending' })),
  },
  {
    id: 'build-4',
    version: '0.9.0',
    status: 'success',
    createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
    durationSec: 505,
    ipaSizeKB: 13800,
    steps: demoPipelineSteps,
  },
  {
    id: 'build-5',
    version: '0.8.2',
    status: 'success',
    createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
    durationSec: 490,
    ipaSizeKB: 13600,
    steps: demoPipelineSteps,
  },
]
