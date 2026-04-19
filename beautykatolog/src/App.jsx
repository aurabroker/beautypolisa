import { useEffect } from 'react'
import { Routes, Route } from 'react-router-dom'
import { useAuth } from './store/useAuth'
import { useToast } from './store/useToast'
import HomePage  from './pages/HomePage'
import SalonPage from './pages/SalonPage'
import PanelPage from './pages/PanelPage'

function Toasts() {
  const toasts = useToast(s => s.toasts)
  return (
    <div className="toast-wrap" aria-live="polite">
      {toasts.map(t => (
        <div key={t.id} className={`toast ${t.type}`}>{t.msg}</div>
      ))}
    </div>
  )
}

export default function App() {
  const init = useAuth(s => s.init)

  useEffect(() => { init() }, [init])

  return (
    <>
      <Routes>
        <Route path="/"         element={<HomePage />} />
        <Route path="/salon/:id" element={<SalonPage />} />
        <Route path="/panel"    element={<PanelPage />} />
      </Routes>
      <Toasts />
    </>
  )
}
