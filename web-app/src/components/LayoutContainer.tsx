import type { ReactNode } from 'react'
import { Sidebar } from './Sidebar'

interface Props {
  children: ReactNode
}

export function LayoutContainer({ children }: Props) {
  return (
    <div className="min-h-screen bg-ink-900 text-slate-100 relative overflow-hidden">
      {/* 背景装饰层：渐变光晕 + 网格 */}
      <div className="pointer-events-none absolute inset-0 -z-10">
        <div className="absolute inset-0 bg-radial-hero opacity-80" />
        <div
          className="absolute inset-0 opacity-[0.08]"
          style={{
            backgroundImage:
              'linear-gradient(rgba(0,229,255,0.5) 1px, transparent 1px), linear-gradient(90deg, rgba(0,229,255,0.5) 1px, transparent 1px)',
            backgroundSize: '40px 40px',
          }}
        />
        <div className="absolute top-0 right-0 w-[600px] h-[600px] rounded-full bg-neon-purple/10 blur-[120px] -translate-y-40 translate-x-40" />
        <div className="absolute bottom-0 left-0 w-[600px] h-[600px] rounded-full bg-neon-cyan/8 blur-[120px] translate-y-40 -translate-x-40" />
      </div>

      <div className="flex">
        <Sidebar />
        <main className="flex-1 min-h-screen relative">
          <div className="max-w-6xl mx-auto px-8 py-10">{children}</div>
        </main>
      </div>
    </div>
  )
}
