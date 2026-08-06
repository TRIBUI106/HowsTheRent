import { useState, type ReactNode } from 'react'
import Sidebar from './Sidebar'
import Header from './Header'

interface LayoutProps {
  children: ReactNode
  title?: string
}

export default function Layout({ children, title }: LayoutProps) {
  const [mobileNavOpen, setMobileNavOpen] = useState(false)

  return (
    <div className="flex h-screen bg-bg">
      <Sidebar mobileOpen={mobileNavOpen} onClose={() => setMobileNavOpen(false)} />
      <div className="flex-1 flex flex-col overflow-hidden min-w-0 bg-[linear-gradient(to_bottom,theme(colors.sidebar)_0,theme(colors.bg)_120px)]">
        <Header title={title} onMenuClick={() => setMobileNavOpen(true)} />
        <main className="flex-1 overflow-auto px-3 sm:px-5 pb-8 pt-5 lg:px-8 animate-enter">
          <div className="mx-auto w-full max-w-[1440px]">
            {children}
          </div>
        </main>
      </div>
    </div>
  )
}
