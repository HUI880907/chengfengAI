import type { InstallMethod } from '../types'

export const installMethods: InstallMethod[] = [
  {
    id: 'sideloadly',
    title: 'Sideloadly',
    tagline: 'Windows / macOS 双平台首选',
    description:
      '轻量级 IPA 侧装工具，支持普通 Apple ID（非开发者账号），Windows 用户最容易上手。',
    downloadUrl: 'https://sideloadly.io/',
    platforms: ['windows', 'macos'],
    steps: [
      '下载并安装 Sideloadly（需要 iTunes 组件，官网含说明）',
      'iPhone 用数据线连接电脑，首次连接时在 iPhone 上选择「信任」',
      '打开 Sideloadly，选择 Device 为当前连接的 iPhone',
      '选择下载好的 乘风AI.ipa 文件',
      '输入 Apple ID（可使用免费账号，每 7 天需重签）',
      '点击「Start」等待签名与安装完成',
      '在 iPhone 设置 → 通用 → VPN 与设备管理 → 信任该开发者',
      '回到桌面，打开 乘风AI',
    ],
  },
  {
    id: 'altstore',
    title: 'AltStore',
    tagline: 'macOS / Windows 老牌工具',
    description: '由前 Apple 工程师开发，支持无线安装、续签，生态插件丰富（AltServer 常驻）。',
    downloadUrl: 'https://altstore.io/',
    platforms: ['windows', 'macos'],
    steps: [
      '下载 AltServer，Mac 拖入应用程序 / Windows 安装',
      '安装后启动 AltServer，在菜单栏或托盘里会显示图标',
      'iPhone 连接电脑，在 Finder/iTunes 中开启「通过 Wi-Fi 连接」',
      '点击 AltServer 图标 → Install AltStore → 选择你的 iPhone',
      '输入 Apple ID（免费账号即可，需允许开发者模式）',
      'AltStore 安装好后，在 iPhone 设置 → 通用 → VPN 与设备管理 → 信任',
      '打开 AltStore → My Apps → + → 选择 乘风AI.ipa',
    ],
  },
  {
    id: 'trollstore',
    title: 'TrollStore (永久签)',
    tagline: '特定 iOS 版本支持，安装即用',
    description:
      '利用系统漏洞实现的永久签名工具，安装后不会过期；支持 iOS 14.0–15.4.1 / 15.5 beta 1–4 / 15.6 beta 1–5 以及 iOS 16.0–16.5 / 17.0。',
    downloadUrl: 'https://github.com/opa334/TrollStore',
    platforms: ['macos'],
    highlight: '永久签名，永不重签',
    steps: [
      '检查 iPhone iOS 版本是否在支持范围内',
      '按 TrollStore 官方指南安装（通过漏洞或安装 .tipa 文件）',
      '安装成功后，将 乘风AI.ipa 传输到 iPhone',
      '用 TrollStore 打开 ipa 文件 → 选择 Install',
      '等待安装完成即可直接在桌面打开',
      '无需在设置里额外信任',
    ],
  },
]

export const faqList: { q: string; a: string }[] = [
  {
    q: '为什么每次安装 7 天后就无法打开了？',
    a: '这是免费 Apple ID 的限制（免费开发者账号每 7 天需重签）。可在 AltStore 或 Sideloadly 启用「自动续签」，或使用 TrollStore（永久签名）绕过此限制。',
  },
  {
    q: '安装时提示「Unable to install」怎么办？',
    a: '请检查：① iPhone 是否被电脑信任；② IPA 是否对应你的设备架构（本项目同时支持 arm64/arm64e）；③ U盘设备数量是否超过苹果限制（每账号最多 10 台设备）；④ 重启电脑与手机后重试。',
  },
  {
    q: 'IPA 文件在哪里下载？',
    a: '推送代码到 GitHub 后，会自动触发 GitHub Actions 打包，完成后可在 Actions 运行结果的 Artifacts 中找到 ipa-乘风AI 文件（扩展名为 .zip，解压后即为 .ipa）。',
  },
  {
    q: '可以不连电脑吗？',
    a: '使用 TrollStore 可在 iOS 本地完成安装。其他侧装方式通常需要电脑完成一次安装。',
  },
  {
    q: '本项目是否需要越狱？',
    a: '不需要。所有侧装方式都在非越狱设备上运行，不需要 Root 权限。',
  },
]
