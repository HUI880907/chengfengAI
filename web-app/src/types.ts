// 核心数据类型定义

export type BuildStatus = 'success' | 'failed' | 'running' | 'pending'

export interface PipelineStep {
  index: number
  title: string
  description: string
  status: BuildStatus
  logSnippet: string
}

export interface BuildRecord {
  id: string
  version: string
  status: BuildStatus
  createdAt: Date
  durationSec: number
  ipaSizeKB: number
  steps: PipelineStep[]
}

export type CheckStatus = 'pass' | 'warn' | 'fail'

export interface ConfigCheckItem {
  id: string
  fileName: string
  description: string
  status: CheckStatus
  detail: string
}

export interface InstallMethod {
  id: string
  title: string
  tagline: string
  description: string
  downloadUrl: string
  steps: string[]
  platforms: ('windows' | 'macos')[]
  highlight?: string
}
