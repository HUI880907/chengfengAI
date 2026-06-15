import { NavLink } from 'react-router-dom'
import { LayoutDashboard, Workflow, Smartphone, ShieldCheck, Sparkles } from 'lucide-react'

const navItems = [
  { to: '/', label: 'Dashboard', icon: LayoutDashboard, desc: '项目总览' },
  { to: '/pipeline', label: 'Build Pipeline', icon: Workflow, desc: '构建流程' },
  { to: '/install', label: 'Installation', icon: Smartphone, desc: '侧装指南' },
  { to: '/config', label: 'Config Check', icon: ShieldCheck, desc: '配置检查' },
]

export function Sidebar() {
  return (
    <aside className="w-64 shrink-0 h-screen sticky top-0 border-r border-neon-cyan/10 bg-ink-900/60 backdrop-blur-xl">
      <div className="px-6 py-6 border-b border-neon-cyan/10">
        <div className="flex items-center gap-3">
          <div className="relative">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-neon-cyan to-neon-purple grid place-items-center shadow-glow-cyan">
              <Sparkles size={20} className="text-ink-900" />
            </div>
            <div className="absolute inset-0 rounded-xl bg-neon-cyan/30 blur-lg -z-10" />
          </div>
          <div>
            <div className="font-semibold text-slate-100 tracking-tight">乘风AI</div>
            <div className="text-[11px] text-slate-400 font-mono">IPA Packager · v1.0</div>
          </div>
        </div>
      </div>

      <nav className="px-3 py-4 space-y-1">
        {navItems.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            end={item.to === '/'}
            className={({ isActive }) =>
              `group flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all duration-200 text-sm ${
                isActive
                  ? 'bg-gradient-to-r from-neon-cyan/15 to-neon-purple/10 text-white ring-1 ring-neon-cyan/30 shadow-glow-cyan'
                  : 'text-slate-400 hover:text-white hover:bg-white/5'
              }`
            }
          >
            <item.icon
              size={18}
              className="text-neon-cyan/80 group-hover:text-neon-cyan transition-colors"
            />
            <div className="flex-1">
              <div className="font-medium">{item.label}</div>
              <div className="text-[10px] text-slate-500">{item.desc}</div>
            </div>
          </NavLink>
        ))}
      </nav>

      <div className="absolute bottom-0 left-0 right-0 p-4">
        <div className="glass-card p-4 text-[11px] text-slate-400 leading-relaxed">
          <div className="text-slate-200 font-medium mb-1 text-xs">💡 小提示</div>
          在 GitHub 推送代码后，Actions 会自动在 macos-15 环境下生成 IPA，约 6-8 分钟完成。
        </div>
      </div>
    </aside>
  )
}
