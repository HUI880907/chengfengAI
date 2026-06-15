import { Routes, Route } from 'react-router-dom'
import { LayoutContainer } from './components/LayoutContainer'
import { DashboardPage } from './pages/DashboardPage'
import { PipelinePage } from './pages/PipelinePage'
import { InstallPage } from './pages/InstallPage'
import { ConfigPage } from './pages/ConfigPage'

export default function App() {
  return (
    <LayoutContainer>
      <Routes>
        <Route path="/" element={<DashboardPage />} />
        <Route path="/pipeline" element={<PipelinePage />} />
        <Route path="/install" element={<InstallPage />} />
        <Route path="/config" element={<ConfigPage />} />
        <Route path="*" element={<DashboardPage />} />
      </Routes>
    </LayoutContainer>
  )
}
