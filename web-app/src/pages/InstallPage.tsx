import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Monitor, Apple, ChevronDown, ChevronUp, Download, CheckSquare } from 'lucide-react'
import { installMethods, faqList } from '../data/installGuides'

export function InstallPage() {
  const [openFAQ, setOpenFAQ] = useState<number | null>(0)

  return (
    <div className="space-y-10">
      <div>
        <h1 className="text-3xl font-bold text-slate-100">iPhone 侧装指南</h1>
        <p className="text-slate-400 text-sm mt-1">选择最适合你的安装方式，下载 IPA 后按步骤完成安装</p>
      </div>

      {/* 三种方式卡片 */}
      <section className="grid grid-cols-1 md:grid-cols-3 gap-5">
        {installMethods.map((m, idx) => (
        <motion.article
          key={m.id}
          initial={{ opacity: 0, y: 24 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: idx * 0.1, duration: 0.5 }}
          className="glass-card p-6 relative flex flex-col"
        >
          <div className="flex items-center gap-3 mb-4">
            <div className="w-11 h-11 rounded-xl bg-gradient-to-br from-neon-cyan/25 to-neon-purple/25 ring-1 ring-white/10 grid place-items-center">
              {m.id === 'sideloadly' ? <Monitor size={20} className="text-neon-cyan" /> : <Apple size={20} className="text-neon-cyan" />}
            </div>
            <div>
              <div className="text-lg font-semibold text-slate-100">{m.title}</div>
              <div className="text-xs text-slate-400">{m.tagline}</div>
            </div>
          </div>

          <p className="text-sm text-slate-400 leading-relaxed flex-1">{m.description}</p>

          {m.highlight && (
            <div className="mt-4 text-[11px] font-mono px-2.5 py-1 rounded-lg bg-amber-500/10 text-amber-300 ring-1 ring-amber-500/30 inline-block self-start">
              ★ {m.highlight}
            </div>
          )}

          <div className="mt-5 pt-4 border-t border-white/5">
            <div className="text-[11px] uppercase tracking-widest text-slate-500 mb-2">安装步骤</div>
            <ol className="space-y-2">
              {m.steps.map((s, i) => (
                <li key={i} className="flex gap-2 text-sm text-slate-300 leading-relaxed">
                  <span className="shrink-0 w-5 h-5 rounded-full bg-white/5 text-[11px] font-semibold grid place-items-center text-slate-400">
                    {i + 1}
                  </span>
                  <span className="flex-1">{s}</span>
                </li>
              ))}
            </ol>
          </div>

          <a
            href={m.downloadUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="mt-5 inline-flex items-center justify-center gap-2 w-full px-4 py-2.5 rounded-xl bg-gradient-to-r from-neon-cyan/20 to-neon-purple/20 ring-1 ring-neon-cyan/30 text-sm font-semibold text-slate-100 hover:shadow-glow-cyan transition-shadow"
          >
            <Download size={16} />
            前往 {m.title} 官网
          </a>
        </motion.article>
      ))}
      </section>

      {/* FAQ */}
      <section>
        <div className="flex items-end justify-between mb-5">
          <h2 className="text-xl font-bold text-slate-100">常见问题 FAQ</h2>
        </div>
        <div className="space-y-2">
          {faqList.map((item, idx) => {
            const open = openFAQ === idx
            return (
              <motion.div
                key={idx}
                className="glass-card overflow-hidden"
                layout
              >
                <button
                  onClick={() => setOpenFAQ(open ? null : idx)}
                  className="flex w-full items-start justify-between gap-4 p-5 text-left"
                >
                  <div className="flex items-start gap-3 flex-1">
                    <CheckSquare size={18} className="text-neon-cyan mt-0.5" />
                    <span className="text-slate-100 font-medium">{item.q}</span>
                  </div>
                  {open ? (
                    <ChevronUp size={18} className="text-slate-400" />
                  ) : (
                    <ChevronDown size={18} className="text-slate-400" />
                  )}
                </button>
                <AnimatePresence initial={false}>
                  {open && (
                    <motion.div
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: 'auto', opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      transition={{ duration: 0.25 }}
                    >
                      <div className="px-5 pb-5 pl-[52px] text-sm text-slate-400 leading-relaxed">
                        {item.a}
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </motion.div>
            )
          })}
        </div>
      </section>
    </div>
  )
}
