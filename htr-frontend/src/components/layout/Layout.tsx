import type { ReactNode } from 'react'
import Sidebar from './Sidebar'
import Header from './Header'

interface LayoutProps {
  children: ReactNode
  title?: string
}

export default function Layout({ children, title }: LayoutProps) {
  return (
    <div className="flex h-screen bg-bg">
      <Sidebar />
      <div className="flex-1 flex flex-col overflow-hidden min-w-0 bg-[linear-gradient(to_bottom,theme(colors.sidebar)_0,theme(colors.bg)_120px)]">
        <Header title={title} />
        <main className="flex-1 overflow-auto px-6 pb-8 pt-5 lg:px-8">
          <div className="mx-auto w-full max-w-[1440px]">
            {children}
          </div>
        </main>
      </div>
    </div>
  )
}
