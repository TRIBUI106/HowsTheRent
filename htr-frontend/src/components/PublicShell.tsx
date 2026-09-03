import { Link } from 'react-router-dom'
import { ChevronRight } from 'lucide-react'
import type { ReactNode } from 'react'
import logoHtr from '@/assets/logo-htr.png'

function NavPill() {
  return (
    <nav
      aria-label="Primary"
      style={{
        position: 'fixed',
        inset: 'var(--space-md) auto auto 50%',
        transform: 'translateX(-50%)',
        zIndex: 50,
        display: 'inline-flex',
        alignItems: 'center',
        gap: 'var(--space-xs)',
        padding: '0.5rem 0.875rem',
        background: 'color-mix(in oklch, var(--color-surface) 82%, transparent)',
        backdropFilter: 'blur(16px) saturate(130%)',
        WebkitBackdropFilter: 'blur(16px) saturate(130%)',
        border: 'var(--rule-hair) solid var(--color-border)',
        borderRadius: 'var(--radius-full)',
        boxShadow: '0 8px 24px -12px oklch(0% 0 0 / 0.16)',
        whiteSpace: 'nowrap',
      }}
    >
      {/* Wordmark */}
      <Link
        to="/"
        className="flex items-center gap-2 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-3"
        style={{ outlineColor: 'var(--color-accent)', borderRadius: 'var(--radius-xs)' }}
        aria-label="HowsTheRent — trang chủ"
      >
        <img
          src={logoHtr}
          alt=""
          aria-hidden="true"
          className="h-6 w-6 rounded-lg object-cover"
          style={{ boxShadow: '0 1px 2px oklch(0% 0 0 / 0.10)' }}
        />
        {/* Full wordmark only from sm up — below that the pill (fixed-position, nowrap,
            no max-width) has no room for logo + wordmark + "Blog" + CTA button without
            overflowing narrow phone viewports. Logo alone stays as the home link. */}
        <span
          className="hidden text-sm font-semibold sm:inline"
          style={{ fontFamily: 'var(--font-body)', color: 'var(--color-fg)' }}
        >
          How&apos;s The Rent
        </span>
      </Link>

      {/* Separator */}
      <span
        aria-hidden="true"
        className="hidden sm:block"
        style={{
          width: 'var(--rule-hair)',
          height: '1rem',
          background: 'var(--color-border)',
          flexShrink: 0,
          margin: '0 var(--space-3xs)',
        }}
      />

      <Link
        to="/blog"
        className="text-sm font-medium transition-colors hover:text-accent focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-3"
        style={{ color: 'var(--color-fg)', outlineColor: 'var(--color-accent)', borderRadius: 'var(--radius-xs)' }}
      >
        Blog
      </Link>

      {/* CTA */}
      <Link
        to="/login"
        className="inline-flex items-center gap-1.5 text-sm font-semibold transition-colors focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-3"
        style={{
          padding: '0.375rem 0.875rem',
          background: 'var(--color-accent)',
          color: 'var(--color-accent-fg)',
          borderRadius: 'var(--radius-full)',
          outlineColor: 'var(--color-accent)',
          transition: `background-color var(--dur-short) var(--ease-out), transform var(--dur-instant) var(--ease-out)`,
        }}
        onMouseEnter={e => { (e.currentTarget as HTMLElement).style.backgroundColor = 'var(--color-accent-hover)'; (e.currentTarget as HTMLElement).style.transform = 'translateY(-1px)'; }}
        onMouseLeave={e => { (e.currentTarget as HTMLElement).style.backgroundColor = 'var(--color-accent)'; (e.currentTarget as HTMLElement).style.transform = 'translateY(0)'; }}
        onMouseDown={e => { (e.currentTarget as HTMLElement).style.transform = 'translateY(1px)'; }}
        onMouseUp={e => { (e.currentTarget as HTMLElement).style.transform = 'translateY(-1px)'; }}
      >
        Đăng nhập
        <ChevronRight className="h-3.5 w-3.5" aria-hidden="true" />
      </Link>
    </nav>
  )
}

function Footer() {
  return (
    <footer>
      <div
        className="mx-auto max-w-6xl"
        style={{
          padding: 'var(--space-3xl) var(--space-xl) var(--space-2xl)',
          display: 'grid',
          gap: 'var(--space-lg)',
        }}
      >
        <p
          style={{
            fontFamily: 'var(--font-display)',
            fontSize: 'clamp(1.75rem, 4vw, 3rem)',
            fontWeight: 400,
            lineHeight: 1.05,
            letterSpacing: '-0.02em',
            color: 'var(--color-fg)',
            maxWidth: '38ch',
            fontStyle: 'normal',
          }}
        >
          Vận hành rõ ràng, bàn giao không cần giải thích lại.
        </p>

        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            paddingTop: 'var(--space-sm)',
            borderTop: 'var(--rule-hair) solid var(--color-border)',
            flexWrap: 'wrap',
            gap: 'var(--space-sm)',
          }}
        >
          <div className="flex items-center gap-2.5">
            <img
              src={logoHtr}
              alt=""
              aria-hidden="true"
              className="h-6 w-6 rounded-lg object-cover"
            />
            <span
              className="text-sm font-semibold"
              style={{ color: 'var(--color-fg)', fontFamily: 'var(--font-body)' }}
            >
              How&apos;s The Rent
            </span>
          </div>
          <p className="text-xs" style={{ color: 'var(--color-fg-subtle)' }}>
            © {new Date().getFullYear()} HowsTheRent · Dành cho vận hành nhà trọ hằng ngày.
          </p>
        </div>
      </div>
    </footer>
  )
}

export default function PublicShell({ children }: { children: ReactNode }) {
  return (
    <div
      style={{
        minHeight: '100vh',
        background: 'var(--color-bg)',
        color: 'var(--color-fg)',
        fontFamily: 'var(--font-body)',
      }}
    >
      <NavPill />
      <main>{children}</main>
      <Footer />
    </div>
  )
}
