// 通用格式化工具

export function formatDate(date: Date): string {
  const pad = (n: number) => n.toString().padStart(2, '0')
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}`
}

export function formatDuration(sec: number): string {
  if (sec < 60) return `${sec}s`
  const m = Math.floor(sec / 60)
  const s = sec % 60
  return `${m}m ${s}s`
}

export function formatSizeKB(kb: number): string {
  if (kb < 1024) return `${kb} KB`
  return `${(kb / 1024).toFixed(1)} MB`
}

export function statusLabel(status: string): string {
  const map: Record<string, string> = {
    success: '构建成功',
    failed: '构建失败',
    running: '构建中',
    pending: '等待中',
    pass: '通过',
    warn: '警告',
    fail: '未通过',
  }
  return map[status] ?? status
}
