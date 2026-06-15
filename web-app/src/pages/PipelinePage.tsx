import { motion } from 'framer-motion'
import { useState } from 'react'
import { CheckCircle2, Loader2, XCircle, Clock } from 'lucide-react'
import { useBuildStore } from '../store/useBuildStore'
import type { BuildStatus, PipelineStep } from '../types'

const STEP_ICON: Record<BuildStatus, any> = {
  success: CheckCircle2,
  running: Loader2,
  pending: Clock,
  failed: XCircle,
}

const STEP_COLOR: Record<BuildStatus, string> = {
  success: 'text-emerald-400',
  running: 'text-neon-cyan',
  pending: 'text-slate-500',
  failed: 'text-red-400',
}

const STEP_RING: Record<BuildStatus, string> = {
  success: 'ring-emerald-400/50 bg-emerald-500/20',
  running: 'ring-neon-cyan/50 bg-neon-cyan/20 animate-pulse',
  pending: 'ring-slate-500/30 bg-slate-500/10',
  failed: 'ring-red-400/50 bg-red-500/20',
}

function StepCard({ step, active, onClick }: { step: PipelineStep; active: boolean; onClick: () => void }) {
  const Icon = STEP_ICON[step.status]
  return (
    <button
      onClick={onClick}
      className={`glass-card w-full text-left p-5 transition-all duration-300 ${active ? 'ring-2 ring-neon-cyan/40 shadow-glow-cyan' : 'hover:translate-y-0.5'}`}
    >
      <div className="flex items-start gap-4">
        <div className={`w-10 h-10 rounded-xl ring-1 grid place-items-center ${STEP_RING[step.status]}`}>
          <Icon size={18} className={STEP_COLOR[step.status]} />
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center justify-between gap-3">
            <span className="font-medium text-slate-100">步骤 {step.index + 1}</span>
            <span className="text-xs font-mono text-slate-500">
              {step.status === 'success' && '已完成'}
              {step.status === 'running' && '处理中…'}
              {step.status === 'pending' && '等待中'}
              {step.status === 'failed' && '失败'}
            </span>
          </div>
          <div className="text-sm text-slate-200 mt-0.5">{step.title}</div>
          <div className="text-xs text-slate-400 mt-1 leading-relaxed">{step.description}</div>
        </div>
      </div>
    </button>
  )
}

export function PipelinePage() {
  const { currentBuild, currentStatus } = useBuildStore()
  const [selectedStep, setSelectedStep] = useState(0)
  const steps = currentBuild?.steps ?? []
  const activeStep = steps[selectedStep]

  return (
    <div className="space-y-8">
      <div className="flex items-end justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-100">构建流水线</h1>
          <p className="text-slate-400 text-sm mt-1">
            共 {steps.length} 步，当前状态：<span className="text-neon-cyan font-mono">{currentStatus}</span>
          </p>
        </div>
        <div className="text-xs font-mono text-slate-400">
          v{currentBuild?.version} · #{currentBuild?.id.slice(-5)}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* 左侧步骤列表 */}
        <div className="lg:col-span-1 space-y-3">
          {steps.map((step, idx) => (
            <StepCard
              key={step.index}
              step={step}
              active={selectedStep === idx}
              onClick={() => setSelectedStep(idx)}
            />
          ))}
        </div>

        {/* 右侧日志 */}
        <div className="lg:col-span-2">
          <motion.div
            key={selectedStep}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.35 }}
            className="glass-card p-6 h-full"
          >
            <div className="flex items-center justify-between mb-4">
              <div>
                <div className="text-xs font-mono text-neon-cyan/80">STEP {activeStep?.index + 1} / {steps.length}</div>
                <div className="text-lg font-semibold text-slate-100">{activeStep?.title}</div>
              </div>
            </div>
            <div className="text-sm text-slate-400 leading-relaxed mb-4">
              {activeStep?.description}
            </div>

            <div className="mt-6">
              <div className="text-xs text-slate-500 font-mono mb-2">LOG OUTPUT</div>
              <pre className="text-[13px] leading-relaxed font-mono text-slate-200 bg-black/40 rounded-xl p-4 overflow-x-auto whitespace-pre-wrap">
{activeStep?.logSnippet}
              </pre>
            </div>

            <div className="mt-6 grid grid-cols-3 gap-3 text-center text-xs">
              <div className="rounded-xl bg-white/5 p-3 ring-1 ring-white/10">
                <div className="text-slate-500">状态</div>
                <div className={`mt-1 font-semibold ${STEP_COLOR[activeStep?.status ?? 'pending']}`}>
                  {activeStep?.status === 'success' ? '✓ PASS' : activeStep?.status === 'running' ? '⏳ RUNNING' : activeStep?.status === 'failed' ? '✗ FAIL' : '… WAITING'}
                </div>
              </div>
              <div className="rounded-xl bg-white/5 p-3 ring-1 ring-white/10">
                <div className="text-slate-500">阶段</div>
                <div className="mt-1 font-semibold text-slate-200">macos-15</div>
              </div>
              <div className="rounded-xl bg-white/5 p-3 ring-1 ring-white/10">
                <div className="text-slate-500">工具</div>
                <div className="mt-1 font-semibold text-slate-200">xcodebuild</div>
              </div>
            </div>
          </motion.div>
        </div>
      </div>
    </div>
  )
}
