import { motion } from 'framer-motion'
import { ShieldCheck, AlertTriangle, CheckCircle2, XCircle } from 'lucide-react'
import { configChecks } from '../data/configChecks'
import type { CheckStatus } from '../types'

const STATUS_META: Record<CheckStatus, { label: string; icon: any; color: string; ring: string; }> = {
  pass: {
    label: '通过',
    icon: CheckCircle2,
    color: 'text-emerald-400',
    ring: 'ring-emerald-500/30 bg-emerald-500/10',
  },
  warn: {
    label: '警告',
    icon: AlertTriangle,
    color: 'text-amber-400',
    ring: 'ring-amber-500/30 bg-amber-500/10',
  },
  fail: {
    label: '未通过',
    icon: XCircle,
    color: 'text-red-400',
    ring: 'ring-red-500/30 bg-red-500/10',
  },
}

export function ConfigPage() {
  const stats = {
    pass: configChecks.filter(c => c.status === 'pass').length,
    warn: configChecks.filter(c => c.status === 'warn').length,
    fail: configChecks.filter(c => c.status === 'fail').length,
    total: configChecks.length,
  }

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold text-slate-100">配置检查</h1>
        <p className="text-slate-400 text-sm mt-1">
          自动扫描项目配置文件，确保打包流程可顺利运行
        </p>
      </div>

      {/* 统计栏 */}
      <section className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.05, duration: 0.4 }}
          className="glass-card p-5 flex items-center justify-between"
        >
          <div>
            <div className="text-[11px] uppercase tracking-widest text-slate-400">总检查项</div>
            <div className="text-3xl font-bold text-slate-100">{stats.total}</div>
          </div>
          <ShieldCheck size={28} className="text-neon-cyan" />
        </motion.div>

        {(['pass', 'warn', 'fail'] as CheckStatus[]).map((s, i) => {
          const meta = STATUS_META[s]
          const Icon = meta.icon
          const count =
            s === 'pass' ? stats.pass : s === 'warn' ? stats.warn : stats.fail
          return (
            <motion.div
              key={s}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 + i * 0.08, duration: 0.4 }}
              className={`glass-card p-5 flex items-center justify-between ${meta.ring} ring-1`}
            >
              <div>
                <div className="text-[11px] uppercase tracking-widest text-slate-400">{meta.label}</div>
                <div className="text-3xl font-bold text-slate-100">{count}</div>
              </div>
              <Icon size={28} className={meta.color} />
            </motion.div>
          )
        })}
      </section>

      {/* 检查项列表 */}
      <section className="space-y-3">
        {configChecks.map((c, idx) => {
          const meta = STATUS_META[c.status]
          const Icon = meta.icon
          return (
            <motion.div
              key={c.id}
              initial={{ opacity: 0, y: 16 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.08 * idx, duration: 0.4 }}
              className="glass-card p-5"
            >
              <div className="flex items-start gap-4">
                <div className={`w-10 h-10 shrink-0 rounded-xl grid place-items-center ring-1 ${meta.ring}`}>
                  <Icon size={18} className={meta.color} />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between gap-4 flex-wrap">
                    <div className="font-mono text-sm text-neon-cyan">{c.fileName}</div>
                    <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${meta.color} ${meta.ring} ring-1`}>
                      {meta.label}
                    </span>
                  </div>
                  <div className="text-sm text-slate-200 mt-0.5">{c.description}</div>
                  <div className="text-xs text-slate-500 mt-2 leading-relaxed">{c.detail}</div>
                </div>
              </div>
            </motion.div>
          )
        })}
      </section>
    </div>
  )
}
