import type { BuildStatus, CheckStatus } from '../types'
import { statusLabel } from '../utils/formatters'

interface Props {
  status: BuildStatus | CheckStatus
  size?: 'sm' | 'md'
  className?: string
}

const STATUS_STYLE: Record<BuildStatus | CheckStatus, string> = {
  success: 'bg-emerald-500/15 text-emerald-300 ring-1 ring-emerald-500/30',
  pass: 'bg-emerald-500/15 text-emerald-300 ring-1 ring-emerald-500/30',
  running: 'bg-neon-cyan/15 text-neon-cyan ring-1 ring-neon-cyan/30',
  pending: 'bg-slate-500/15 text-slate-300 ring-1 ring-slate-500/30',
  failed: 'bg-red-500/15 text-red-300 ring-1 ring-red-500/30',
  fail: 'bg-red-500/15 text-red-300 ring-1 ring-red-500/30',
  warn: 'bg-amber-500/15 text-amber-300 ring-1 ring-amber-500/30',
}

const DOT_STYLE: Record<BuildStatus | CheckStatus, string> = {
  success: 'bg-emerald-400',
  pass: 'bg-emerald-400',
  running: 'bg-neon-cyan animate-pulse',
  pending: 'bg-slate-400',
  failed: 'bg-red-400',
  fail: 'bg-red-400',
  warn: 'bg-amber-400',
}

export function StatusBadge({ status, size = 'md', className = '' }: Props) {
  const sizeCls =
    size === 'sm' ? 'text-[10px] px-1.5 py-0.5 gap-1' : 'text-xs px-2.5 py-1 gap-1.5'
  return (
    <span
      className={`inline-flex items-center font-medium rounded-full ${STATUS_STYLE[status]} ${sizeCls} ${className}`}
    >
      <span className={`w-1.5 h-1.5 rounded-full ${DOT_STYLE[status]}`} />
      {statusLabel(status)}
    </span>
  )
}
