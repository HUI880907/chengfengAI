import { create } from 'zustand'
import type { BuildRecord, BuildStatus } from '../types'
import { mockBuildHistory, demoPipelineSteps } from '../data/mockBuilds'

interface BuildStore {
  currentStatus: BuildStatus
  currentBuild: BuildRecord | null
  currentStepIndex: number
  history: BuildRecord[]
  startBuild: () => void
  resetBuild: () => void
}

export const useBuildStore = create<BuildStore>((set, get) => ({
  currentStatus: 'success',
  currentBuild: mockBuildHistory[0],
  currentStepIndex: demoPipelineSteps.length,
  history: mockBuildHistory,

  startBuild: () => {
    // 如果已经在构建中，忽略重复点击
    const currentState = get().currentStatus
    if (currentState === 'running') return

    // 模拟启动一次新的构建（UI 演示用）
    const newBuild: BuildRecord = {
      id: `build-${Date.now()}`,
      version: '1.0.0',
      status: 'running',
      createdAt: new Date(),
      durationSec: 0,
      ipaSizeKB: 0,
      steps: demoPipelineSteps.map(s => ({
        ...s,
        status: 'pending' as BuildStatus,
      })),
    }
    // 让第一步先变为 running
    newBuild.steps[0].status = 'running'

    set({
      currentStatus: 'running',
      currentBuild: newBuild,
      currentStepIndex: 0,
      history: [newBuild, ...get().history],
    })

    // 每 5 秒推进一个步骤，便于页面观察流水线状态
    let step = 0
    const interval = setInterval(() => {
      step++
      const current = get().currentBuild
      if (!current) {
        clearInterval(interval)
        return
      }
      const steps = [...current.steps]
      if (step - 1 >= 0 && steps[step - 1]) steps[step - 1].status = 'success'
      if (step < steps.length) {
        steps[step].status = 'running'
        const updated = { ...current, steps, durationSec: step * 75 }
        set({ currentBuild: updated, currentStepIndex: step })
      } else {
        // 完成全部步骤
        const updated: BuildRecord = {
          ...current,
          status: 'success',
          durationSec: 520,
          ipaSizeKB: 14800,
        }
        set({
          currentStatus: 'success',
          currentBuild: updated,
          currentStepIndex: steps.length,
          history: [updated, ...get().history.slice(1)],
        })
        clearInterval(interval)
      }
    }, 5000)
  },

  resetBuild: () => {
    set({
      currentStatus: 'success',
      currentBuild: mockBuildHistory[0],
      currentStepIndex: demoPipelineSteps.length,
      history: mockBuildHistory,
    })
  },
}))
