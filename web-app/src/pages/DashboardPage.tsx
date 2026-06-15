import { motion } from 'framer-motion'
import { PlayCircle, Rocket, Clock, HardDrive, Zap, ArrowRight, GitBranch } from 'lucide-react'
import { Link } from 'react-router-dom'
import { useBuildStore } from '../store/useBuildStore'
import { StatusBadge } from '../components/StatusBadge'
import { formatDate, formatDuration, formatSizeKB } from '../utils/formatters'

interface StatCardProps {
  icon: any
  label: string
  value: string
  sub?: string
  color: string
  delay: number
}

function StatCard({ icon: Icon, label, value, sub, color, delay }: StatCardProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay, duration: 0.5 }}
      className="glass-card p-5 relative overflow-hidden"
    >
      <div
        className={`absolute -top-10 -right-10 w-28 h-28 rounded-full blur-3xl ${color}`} />
      <div className="flex items-center justify-between">
        <div>
          <div className="text-[11px] uppercase tracking-widest text-slate-400">{label}</div>
          <div className="text-2xl font-semibold mt-1">{value}</div>
          {sub && <div className="text-xs text-slate-400 mt-1">{sub}</div>}
        </div>
        <div className="w-11 h-11 rounded-xl bg-white/5 grid place-items-center">
          <Icon size={20} className="text-neon-cyan" />
        </div>
      </div>
    </motion.div>
  )
}

export function DashboardPage() {
  const { currentStatus, currentBuild, currentStepIndex, history, startBuild } = useBuildStore()
  const totalSteps = currentBuild?.steps.length ?? 7
  const runningStep = currentBuild?.steps.find(s => s.status === 'running')
  const percent =
    currentStatus === 'running'
      ? Math.round(((currentStepIndex ?? 0) + 1) / totalSteps * 100)
      : currentStatus === 'success'
        ? 100
        : 0

  const stats = {
    success: history.filter(b => b.status === 'success').length,
    total: history.length,
    avgTime: Math.round(history.filter(b => b.durationSec > 0).reduce((s, b) => s + b.durationSec, 0) / Math.max(history.filter(b => b.durationSec > 0).length, 1)),
    avgSize: Math.round(history.filter(b => b.ipaSizeKB > 0).reduce((s, b) => s + b.ipaSizeKB, 0) / Math.max(history.filter(b => b.ipaSizeKB > 0).length, 1)),
  }

  return (
    <div className="space-y-8">
      {/* —— HERO —— */}
      <motion.section
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="relative glass-card p-8 overflow-hidden"
      >
        <div className="absolute inset-0 bg-gradient-to-br from-neon-cyan/8 via-transparent to-neon-purple/8 pointer-events-none" />
        <div className="relative">
          <div className="flex items-start justify-between gap-6">
            <div className="flex-1">
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-neon-cyan/10 text-neon-cyan text-xs font-mono mb-4">
              <span className="w-1.5 h-1.5 rounded-full bg-neon-cyan animate-pulse" />
              云端打包 · iOS 16+
            </div>
            <h1 className="text-4xl font-bold tracking-tight leading-tight">
              <span className="text-gradient">乘风AI</span>
              <span className="text-slate-100"> · IPA 打包工作台</span>
            </h1>
            <p className="mt-3 text-slate-400 max-w-xl leading-relaxed">
              推送代码 → GitHub Actions 在 macOS 上自动构建，生成可侧装的 IPA 文件。无需 Xcode，无需付费开发者账号。
            </p>

            <div className="mt-7 flex flex-wrap items-center gap-3">
              <button
                onClick={startBuild}
                disabled={currentStatus === 'running'}
                className="group relative inline-flex items-center gap-2 px-6 py-3 rounded-xl font-semibold text-ink-900 bg-gradient-to-r from-neon-cyan via-sky-300 to-neon-purple hover:shadow-glow-cyan animate-pulse-glow transition-all disabled:opacity-50 disabled:cursor-not-allowed"
              >
                <PlayCircle size={18} />
                {currentStatus === 'running' ? '构建中…' : '开始打包 IPA'}
                <ArrowRight size={16} className="transition-transform group-hover:translate-x-0.5" />
              </button>

              <Link
                to="/pipeline"
                className="inline-flex items-center gap-2 px-5 py-3 rounded-xl font-medium text-slate-200 bg-white/5 ring-1 ring-white/10 hover:bg-white/10 transition-colors"
              >
                查看流水线
              </Link>
              <StatusBadge status={currentStatus} />
            </div>

            {/* 实时进度条：显示当前推进到第几步 */}
            <div className="mt-6">
              <div className="flex items-center justify-between text-xs font-mono text-slate-400 mb-2">
                <span>
                  {currentStatus === 'running'
                    ? `正在处理：步骤 ${(currentStepIndex ?? 0) + 1} / ${totalSteps}`
                    : currentStatus === 'success'
                      ? '全部步骤已完成'
                      : '准备就绪'}
                </span>
                <span className="text-neon-cyan">{percent}%</span>
              </div>
              <div className="relative h-2 w-full rounded-full bg-white/5 overflow-hidden">
                <motion.div
                  initial={{ width: 0 }}
                  animate={{ width: `${percent}%` }}
                  transition={{ duration: 0.6, ease: 'easeOut' }}
                  className="absolute inset-y-0 left-0 rounded-full bg-gradient-to-r from-neon-cyan to-neon-purple"
                />
              </div>
              {runningStep && (
                <div className="mt-3 text-sm text-slate-300 leading-relaxed">
                  <span className="text-neon-cyan font-semibold">{runningStep.title}</span>
                  <span className="text-slate-500"> — {runningStep.description}</span>
                </div>
              )}
              {currentStatus === 'success' && currentBuild?.ipaSizeKB && (
                <div className="mt-3 text-sm text-emerald-400 leading-relaxed">
                  ✅ IPA 已生成：约 {(currentBuild.ipaSizeKB / 1024).toFixed(1)} MB，可在「安装指南」页面查看侧装方法
                </div>
              )}
            </div>
          </div>

          <div className="shrink-0 text-right hidden md:block">
            <div className="text-[11px] text-slate-400 font-mono tracking-wide">
              最新构建
            </div>
            <div className="text-2xl font-bold text-gradient mt-1">
              v{currentBuild?.version ?? '0.0.0'}
            </div>
            <div className="text-xs text-slate-500 mt-1">
              {currentBuild ? formatDate(currentBuild.createdAt) : '—'}
            </div>
          </div>
        </div>
      </div>
      </motion.section>

      {/* —— STATS —— */}
      <section className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <StatCard
          icon={Rocket}
          label="成功构建"
          value={`${stats.success} / ${stats.total}`}
          sub="近 5 次记录"
          color="bg-emerald-400/20"
          delay={0.1}
        />
        <StatCard
          icon={Clock}
          label="平均耗时"
          value={formatDuration(stats.avgTime)}
          sub="含 Archive + IPA"
          color="bg-neon-cyan/20"
          delay={0.18}
        />
        <StatCard
          icon={HardDrive}
          label="平均 IPA 大小"
          value={formatSizeKB(stats.avgSize)}
          sub="解压后约 35 MB"
          color="bg-neon-purple/20"
          delay={0.26}
        />
        <StatCard
          icon={Zap}
          label="成功率"
          value={`${Math.round((stats.success / stats.total) * 100)}%`}
          sub="最近 5 次构建"
          color="bg-amber-400/20"
          delay={0.34}
        />
      </section>

      {/* —— 最近构建历史 —— */}
      <section className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {history.map((b, idx) => (
          <motion.div
            key={b.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 * idx, duration: 0.5 }}
            className="glass-card p-5 cursor-pointer hover:shadow-glow-cyan transition-shadow"
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
              <GitBranch size={16} className="text-neon-cyan/70" />
              <span className="font-mono text-sm text-slate-200">v{b.version}</span>
              </div>
            <StatusBadge status={b.status} size="sm" />
            </div>
            <div className="mt-4 flex items-center justify-between text-xs text-slate-400">
              <div className="font-mono">{formatDate(b.createdAt)}</div>
              <div className="font-mono">{formatDuration(b.durationSec)}</div>
            </div>
            {b.ipaSizeKB > 0 && (
              <div className="mt-3 flex items-center justify-between text-xs">
                <span className="text-slate-500">IPA</span>
                <span className="text-slate-200 font-mono">{formatSizeKB(b.ipaSizeKB)}</span>
              </div>
            )}
          </motion.div>
        ))}
      </section>
    </div>
  )
}
