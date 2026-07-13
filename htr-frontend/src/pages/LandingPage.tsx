/*
 * Hallmark · macrostructure: Split Studio · nav: N5 Floating pill · footer: Ft5 Statement
 * tone: utilitarian · anchor hue: azure 220 · genre: modern-minimal
 * theme: catalog · display: Instrument Serif · body: Geist
 * enrichment: none (typography only)
 * contrast: pass (40–41) · nav: N5 · footer: Ft5 · slop: pass (42–45)
 * honest: pass (46) · chrome: pass (47) · tokens: pass (48) · responsive: pass (49)
 * mobile: pass (34, 49, 50–57)
 * pre-emit critique: P4 H5 E4 S4 R4 V5
 */

import { Link } from 'react-router-dom'
import {
  FileText,
  Wrench,
  FileCheck,
  CreditCard,
  Shield,
  CheckCircle2,
  BarChart3,
  ChevronRight,
} from 'lucide-react'
import logoHtr from '@/assets/logo-htr.png'

/* ── Data ──────────────────────────────────────────────────────────────────── */

const stats = [
  { value: '3',    label: 'Vai trò riêng biệt',  detail: 'Quản lý · Khách thuê · Kỹ thuật viên' },
  { value: '5',    label: 'Nghiệp vụ cốt lõi',   detail: 'Hợp đồng, hóa đơn, bảo trì, thanh toán, nhật ký' },
  { value: '100%', label: 'Trên nền web',          detail: 'Không cần cài đặt, dùng được mọi thiết bị' },
]

const splitPairs = [
  {
    id: 'congno',
    eyebrow: null,
    heading: 'Biết ngay ai đang nợ, nợ bao nhiêu.',
    body: 'Tất cả hóa đơn quá hạn, chưa thanh toán và sắp đến hạn hiển thị theo phòng — không cần mở từng file hay nhớ theo tháng.',
    points: [
      'Theo dõi hóa đơn quá hạn theo từng phòng',
      'Trạng thái thanh toán cập nhật khi khách thanh toán qua PayOS',
      'Lịch sử công nợ được lưu để đối chiếu khi cần',
    ],
    side: 'left' as const,
    visual: 'invoice',
  },
  {
    id: 'baotri',
    eyebrow: null,
    heading: 'Sự cố có người nhận, không bị bỏ sót.',
    body: 'Khách thuê gửi yêu cầu bảo trì trực tiếp trên hệ thống. Quản lý thấy ngay, phân công kỹ thuật viên, theo dõi tiến độ đến khi hoàn thành.',
    points: [
      'Khách gửi yêu cầu kèm mô tả và loại sự cố',
      'Quản lý assign cho kỹ thuật viên phù hợp',
      'Kỹ thuật viên cập nhật trạng thái, quản lý nắm được',
    ],
    side: 'right' as const,
    visual: 'maintenance',
  },
  {
    id: 'hopdong',
    eyebrow: null,
    heading: 'Hợp đồng và phí được lưu, không phụ thuộc trí nhớ.',
    body: 'Quy tắc tính tiền điện, nước, dịch vụ được cấu hình theo từng tòa nhà. Khi tạo hóa đơn, hệ thống tự áp đúng mức phí — không cần nhớ lại từng mức.',
    points: [
      'Cấu hình phí riêng cho từng tòa nhà',
      'Hợp đồng lưu thời hạn, đặt cọc, thông tin thuê',
      'Lịch sử thao tác được ghi lại để bàn giao',
    ],
    side: 'left' as const,
    visual: 'contract',
  },
]

const roles = [
  {
    title: 'Quản lý',
    desc: 'Theo dõi công nợ, tỷ lệ lấp đầy, hợp đồng và lịch sử thao tác trong một bảng điều hành.',
    modules: ['Dashboard tổng quan', 'Quản lý hóa đơn & thu tiền', 'Phân công bảo trì', 'Nhật ký vận hành'],
  },
  {
    title: 'Khách thuê',
    desc: 'Xem hóa đơn, hợp đồng, gửi yêu cầu bảo trì và theo dõi lịch sử thanh toán.',
    modules: ['Xem hóa đơn hàng tháng', 'Thanh toán trực tuyến', 'Gửi yêu cầu sửa chữa', 'Xem hợp đồng'],
  },
]

/* ── N5 Floating pill nav ───────────────────────────────────────────────────
 * Visibly detached from the page edges. Content-sized, blur+saturate backdrop.
 * Collapses to wordmark + CTA only on mobile (< 640px).
 * ─────────────────────────────────────────────────────────────────────────── */
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
        <span
          className="text-sm font-semibold"
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

/* ── Stat strip ─────────────────────────────────────────────────────────────
 * T4 Numbered stat strip — 3-up, full-width hairline border, no cards.
 * ─────────────────────────────────────────────────────────────────────────── */
function StatStrip() {
  return (
    <div
      style={{
        borderTop: 'var(--rule-hair) solid var(--color-border)',
        borderBottom: 'var(--rule-hair) solid var(--color-border)',
        background: 'var(--color-surface)',
      }}
    >
      <div
        className="mx-auto max-w-6xl"
        style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(3, minmax(0, 1fr))',
        }}
      >
        {stats.map((stat, i) => (
          <div
            key={stat.label}
            style={{
              padding: 'var(--space-lg) var(--space-lg)',
              borderLeft: i > 0 ? 'var(--rule-hair) solid var(--color-border)' : undefined,
            }}
          >
            <p
              className="font-semibold tabular-nums"
              style={{
                fontFamily: 'var(--font-display)',
                fontSize: 'clamp(1.75rem, 3vw, 2.5rem)',
                lineHeight: 1.0,
                letterSpacing: '-0.02em',
                color: 'var(--color-accent)',
              }}
            >
              {stat.value}
            </p>
            <p
              className="mt-1.5 text-sm font-medium"
              style={{ color: 'var(--color-fg)' }}
            >
              {stat.label}
            </p>
            <p
              className="mt-0.5 text-sm"
              style={{ color: 'var(--color-fg-muted)' }}
            >
              {stat.detail}
            </p>
          </div>
        ))}
      </div>
    </div>
  )
}

/* ── Visual proof block ─────────────────────────────────────────────────────
 * Renders a lightweight typographic proof panel for each Split Studio pair.
 * No fake chrome, no re-drawn UI — just content in a contained surface.
 * ─────────────────────────────────────────────────────────────────────────── */
function VisualBlock({ type }: { type: 'invoice' | 'maintenance' | 'contract' }) {
  if (type === 'invoice') {
    return (
      <div
        style={{
          background: 'var(--color-surface)',
          border: 'var(--rule-hair) solid var(--color-border)',
          borderRadius: 'var(--radius-lg)',
          padding: 'var(--space-md)',
          display: 'flex',
          flexDirection: 'column',
          gap: 'var(--space-xs)',
        }}
        aria-hidden="true"
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', borderBottom: 'var(--rule-hair) solid var(--color-border)', paddingBottom: 'var(--space-xs)', marginBottom: 'var(--space-2xs)' }}>
          <span className="text-xs font-semibold uppercase tracking-widest" style={{ color: 'var(--color-fg-subtle)', letterSpacing: '0.12em', fontFamily: 'var(--font-body)' }}>Hóa đơn tháng 7</span>
          <span className="text-xs" style={{ color: 'var(--color-fg-muted)' }}>3 phòng chưa thanh toán</span>
        </div>
        {[
          { room: 'P.101', amount: '3.200.000 ₫', status: 'Quá hạn', overdue: true },
          { room: 'P.203', amount: '2.850.000 ₫', status: 'Chưa thanh toán', overdue: false },
          { room: 'P.305', amount: '3.500.000 ₫', status: 'Đã thanh toán', overdue: false, paid: true },
        ].map(row => (
          <div
            key={row.room}
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              padding: 'var(--space-2xs) var(--space-xs)',
              borderRadius: 'var(--radius-xs)',
              background: row.paid ? 'var(--color-success-surface)' : row.overdue ? 'var(--color-error-surface)' : 'var(--color-bg)',
            }}
          >
            <span className="text-sm font-medium" style={{ color: 'var(--color-fg)', fontFamily: 'var(--font-body)' }}>{row.room}</span>
            <span className="text-sm tabular-nums" style={{ color: 'var(--color-fg-muted)', fontVariantNumeric: 'tabular-nums' }}>{row.amount}</span>
            <span
              className="text-xs font-medium"
              style={{ color: row.paid ? 'var(--color-success-fg)' : row.overdue ? 'var(--color-error-fg)' : 'var(--color-fg-muted)' }}
            >
              {row.status}
            </span>
          </div>
        ))}
      </div>
    )
  }

  if (type === 'maintenance') {
    return (
      <div
        style={{
          background: 'var(--color-surface)',
          border: 'var(--rule-hair) solid var(--color-border)',
          borderRadius: 'var(--radius-lg)',
          padding: 'var(--space-md)',
          display: 'flex',
          flexDirection: 'column',
          gap: 'var(--space-xs)',
        }}
        aria-hidden="true"
      >
        <div style={{ borderBottom: 'var(--rule-hair) solid var(--color-border)', paddingBottom: 'var(--space-xs)', marginBottom: 'var(--space-2xs)' }}>
          <span className="text-xs font-semibold uppercase tracking-widest" style={{ color: 'var(--color-fg-subtle)', letterSpacing: '0.12em', fontFamily: 'var(--font-body)' }}>Yêu cầu bảo trì</span>
        </div>
        {[
          { room: 'P.102', desc: 'Bóng đèn phòng ngủ bị hỏng', status: 'Đang xử lý', assigned: 'Minh T.' },
          { room: 'P.204', desc: 'Vòi nước bếp bị rỉ', status: 'Mới gửi', assigned: 'Chưa phân công' },
          { room: 'P.301', desc: 'Ổ cắm điện không có điện', status: 'Hoàn thành', assigned: 'Hùng N.' },
        ].map(req => (
          <div
            key={req.room}
            style={{
              padding: 'var(--space-2xs) var(--space-xs)',
              borderRadius: 'var(--radius-xs)',
              background: 'var(--color-bg)',
              display: 'grid',
              gap: '2px',
            }}
          >
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <span className="text-xs font-semibold" style={{ color: 'var(--color-fg-muted)' }}>{req.room}</span>
              <span
                className="text-xs font-medium"
                style={{
                  color: req.status === 'Hoàn thành' ? 'var(--color-success-fg)' : req.status === 'Đang xử lý' ? 'var(--color-accent)' : 'var(--color-fg-subtle)',
                }}
              >
                {req.status}
              </span>
            </div>
            <p className="text-sm" style={{ color: 'var(--color-fg)' }}>{req.desc}</p>
            <p className="text-xs" style={{ color: 'var(--color-fg-subtle)' }}>→ {req.assigned}</p>
          </div>
        ))}
      </div>
    )
  }

  // contract
  return (
    <div
      style={{
        background: 'var(--color-surface)',
        border: 'var(--rule-hair) solid var(--color-border)',
        borderRadius: 'var(--radius-lg)',
        padding: 'var(--space-md)',
        display: 'flex',
        flexDirection: 'column',
        gap: 'var(--space-xs)',
      }}
      aria-hidden="true"
    >
      <div style={{ borderBottom: 'var(--rule-hair) solid var(--color-border)', paddingBottom: 'var(--space-xs)', marginBottom: 'var(--space-2xs)' }}>
        <span className="text-xs font-semibold uppercase tracking-widest" style={{ color: 'var(--color-fg-subtle)', letterSpacing: '0.12em', fontFamily: 'var(--font-body)' }}>Cấu hình phí — Toà A</span>
      </div>
      {[
        { label: 'Giá phòng', value: '3.200.000 ₫ / tháng' },
        { label: 'Tiền điện', value: '3.800 ₫ / kWh' },
        { label: 'Tiền nước', value: '12.000 ₫ / m³' },
        { label: 'Phí dịch vụ', value: '100.000 ₫ / tháng' },
        { label: 'Phí gửi xe', value: '80.000 ₫ / xe' },
      ].map(row => (
        <div
          key={row.label}
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'baseline',
            padding: 'var(--space-3xs) var(--space-xs)',
            borderBottom: 'var(--rule-hair) solid var(--color-border)',
          }}
        >
          <span className="text-sm" style={{ color: 'var(--color-fg-muted)' }}>{row.label}</span>
          <span className="text-sm font-medium tabular-nums" style={{ color: 'var(--color-fg)', fontVariantNumeric: 'tabular-nums' }}>{row.value}</span>
        </div>
      ))}
    </div>
  )
}

/* ── Split Studio pair ──────────────────────────────────────────────────────
 * Each pair divides the screen: text one side, visual proof the other.
 * Direction alternates (left/right) down the page.
 * ─────────────────────────────────────────────────────────────────────────── */
function SplitPair({ pair }: { pair: typeof splitPairs[number] }) {
  const textCol = (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'center',
        padding: 'var(--space-2xl) var(--space-xl)',
      }}
    >
      <h2
        style={{
          fontFamily: 'var(--font-display)',
          fontSize: 'clamp(1.625rem, 2.5vw + 0.5rem, 2.25rem)',
          fontWeight: 400,
          lineHeight: 1.15,
          letterSpacing: '-0.02em',
          color: 'var(--color-fg)',
          maxWidth: '22ch',
          marginBottom: 'var(--space-md)',
          fontStyle: 'normal',
        }}
      >
        {pair.heading}
      </h2>
      <p
        className="text-base leading-7"
        style={{
          color: 'var(--color-fg-muted)',
          maxWidth: '52ch',
          marginBottom: 'var(--space-md)',
        }}
      >
        {pair.body}
      </p>
      <ul style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-xs)' }}>
        {pair.points.map(point => (
          <li
            key={point}
            className="flex items-start gap-3 text-sm"
            style={{ color: 'var(--color-fg)' }}
          >
            <CheckCircle2
              className="mt-0.5 shrink-0"
              style={{ width: '1rem', height: '1rem', color: 'var(--color-accent)' }}
              aria-hidden="true"
            />
            <span>{point}</span>
          </li>
        ))}
      </ul>
    </div>
  )

  const visualCol = (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: 'var(--space-2xl) var(--space-xl)',
        background: 'var(--color-sidebar)',
      }}
    >
      <div style={{ width: '100%', maxWidth: '420px' }}>
        <VisualBlock type={pair.visual} />
      </div>
    </div>
  )

  return (
    <div
      style={{
        display: 'grid',
        gridTemplateColumns: 'minmax(0, 1fr) minmax(0, 1fr)',
        borderBottom: 'var(--rule-hair) solid var(--color-border)',
      }}
      className="split-pair"
    >
      {pair.side === 'left' ? <>{textCol}{visualCol}</> : <>{visualCol}{textCol}</>}
    </div>
  )
}

/* ── Hero section ───────────────────────────────────────────────────────────
 * H2 Split diptych: headline + lede left, dashboard proof panel right.
 * Knobs: ratio=6/6, right-side=proof column, divider=negative space
 * ─────────────────────────────────────────────────────────────────────────── */
function Hero() {
  return (
    <section
      aria-labelledby="hero-heading"
      style={{
        display: 'grid',
        gridTemplateColumns: 'minmax(0, 1.1fr) minmax(0, 0.9fr)',
        minHeight: '85vh',
        paddingTop: 'calc(var(--space-4xl) + var(--space-md))', /* clear fixed pill nav */
        borderBottom: 'var(--rule-hair) solid var(--color-border)',
      }}
      className="hero-grid"
    >
      {/* Left: headline + lede + CTAs */}
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          padding: 'var(--space-2xl) var(--space-xl) var(--space-3xl)',
          maxWidth: '680px',
          marginLeft: 'auto',
        }}
      >
        <h1
          id="hero-heading"
          style={{
            fontFamily: 'var(--font-display)',
            fontSize: 'clamp(2.25rem, 4vw + 0.75rem, 3.75rem)',
            fontWeight: 400,
            lineHeight: 1.08,
            letterSpacing: '-0.03em',
            color: 'var(--color-fg)',
            maxWidth: '16ch',
            marginBottom: 'var(--space-md)',
            fontStyle: 'normal',
          }}
        >
          Vận hành nhà trọ từ một nơi, không cần nhớ gì thêm.
        </h1>
        <p
          className="text-base leading-7"
          style={{
            color: 'var(--color-fg-muted)',
            maxWidth: '52ch',
            marginBottom: 'var(--space-lg)',
          }}
        >
          HowsTheRent gom công nợ, hợp đồng, bảo trì và thanh toán vào một luồng rõ ràng. Biết ngay hôm nay cần thu gì, sửa gì, và phòng nào cần chú ý.
        </p>

        {/* CTAs */}
        <div className="flex flex-wrap items-center gap-3">
          <Link
            to="/login"
            className="inline-flex items-center gap-2 text-sm font-semibold focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-3"
            style={{
              padding: '0.6875rem 1.25rem',
              background: 'var(--color-accent)',
              color: 'var(--color-accent-fg)',
              borderRadius: 'var(--radius-md)',
              outlineColor: 'var(--color-accent)',
              boxShadow: 'inset 0 1px 0 oklch(100% 0 0 / 0.12)',
              transition: `background-color var(--dur-short) var(--ease-out), transform var(--dur-instant) var(--ease-out)`,
            }}
            onMouseEnter={e => { (e.currentTarget as HTMLElement).style.backgroundColor = 'var(--color-accent-hover)'; (e.currentTarget as HTMLElement).style.transform = 'translateY(-1.5px)'; }}
            onMouseLeave={e => { (e.currentTarget as HTMLElement).style.backgroundColor = 'var(--color-accent)'; (e.currentTarget as HTMLElement).style.transform = 'translateY(0)'; }}
            onMouseDown={e => { (e.currentTarget as HTMLElement).style.transform = 'translateY(0.5px)'; }}
            onMouseUp={e => { (e.currentTarget as HTMLElement).style.transform = 'translateY(-1.5px)'; }}
          >
            Vào hệ thống
            <ChevronRight className="h-4 w-4" aria-hidden="true" />
          </Link>
          <a
            href="#how-it-works"
            className="inline-flex items-center gap-2 text-sm font-medium focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-3"
            style={{
              padding: '0.6875rem 1.25rem',
              border: 'var(--rule-hair) solid var(--color-border)',
              borderRadius: 'var(--radius-md)',
              color: 'var(--color-fg)',
              outlineColor: 'var(--color-accent)',
              transition: `background-color var(--dur-short) var(--ease-out)`,
            }}
            onMouseEnter={e => { (e.currentTarget as HTMLElement).style.backgroundColor = 'var(--color-sidebar)'; }}
            onMouseLeave={e => { (e.currentTarget as HTMLElement).style.backgroundColor = ''; }}
          >
            Xem cách vận hành
          </a>
        </div>
      </div>

      {/* Right: dashboard proof panel */}
      <div
        style={{
          background: 'var(--color-sidebar)',
          borderLeft: 'var(--rule-hair) solid var(--color-border)',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          padding: 'var(--space-2xl) var(--space-lg)',
        }}
      >
        {/* Panel header */}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            marginBottom: 'var(--space-md)',
          }}
        >
          <div>
            <p
              className="text-xs font-semibold uppercase"
              style={{ letterSpacing: '0.12em', color: 'var(--color-fg-subtle)', fontFamily: 'var(--font-body)' }}
            >
              Bảng điều hành
            </p>
            <p
              className="mt-1 text-base font-semibold"
              style={{ color: 'var(--color-fg)', fontFamily: 'var(--font-body)' }}
            >
              Những gì cần xử lý hôm nay
            </p>
          </div>
          <div
            className="inline-flex items-center justify-center"
            style={{
              width: '2.5rem',
              height: '2.5rem',
              borderRadius: 'var(--radius-md)',
              background: 'var(--color-accent-surface)',
              color: 'var(--color-accent)',
              flexShrink: 0,
            }}
            aria-hidden="true"
          >
            <BarChart3 className="h-5 w-5" />
          </div>
        </div>

        {/* Signal rows */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-xs)' }}>
          {[
            { icon: FileText,  label: 'Công nợ đến hạn trong ngày',               sub: '3 hóa đơn chưa thu' },
            { icon: Wrench,    label: 'Yêu cầu bảo trì mới từ khách thuê',        sub: '2 yêu cầu chờ phân công' },
            { icon: FileCheck, label: 'Hợp đồng sắp hết hạn trong 30 ngày',       sub: '1 hợp đồng cần gia hạn' },
          ].map(({ icon: Icon, label, sub }) => (
            <div
              key={label}
              className="flex items-start gap-3"
              style={{
                padding: 'var(--space-xs) var(--space-sm)',
                borderRadius: 'var(--radius-sm)',
                border: 'var(--rule-hair) solid var(--color-border)',
                background: 'var(--color-bg)',
              }}
            >
              <span
                className="mt-0.5 inline-flex items-center justify-center shrink-0"
                style={{
                  width: '1.75rem',
                  height: '1.75rem',
                  borderRadius: 'var(--radius-xs)',
                  background: 'var(--color-accent-surface)',
                  color: 'var(--color-accent)',
                }}
                aria-hidden="true"
              >
                <Icon className="h-3.5 w-3.5" />
              </span>
              <div>
                <p className="text-sm font-medium" style={{ color: 'var(--color-fg)' }}>{label}</p>
                <p className="text-xs mt-0.5" style={{ color: 'var(--color-fg-muted)' }}>{sub}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

/* ── Roles section ──────────────────────────────────────────────────────────
 * Asymmetric 2-up grid (not the equal 3-col AI default).
 * Kỹ thuật viên rendered as a compact inline row below.
 * ─────────────────────────────────────────────────────────────────────────── */
function RolesSection() {
  return (
    <section
      aria-labelledby="roles-heading"
      style={{
        borderBottom: 'var(--rule-hair) solid var(--color-border)',
        padding: 'var(--space-3xl) 0',
      }}
    >
      <div className="mx-auto max-w-6xl" style={{ padding: '0 var(--space-xl)' }}>
        <h2
          id="roles-heading"
          style={{
            fontFamily: 'var(--font-display)',
            fontSize: 'clamp(1.5rem, 2vw + 0.5rem, 2rem)',
            fontWeight: 400,
            lineHeight: 1.2,
            letterSpacing: '-0.02em',
            color: 'var(--color-fg)',
            marginBottom: 'var(--space-lg)',
            maxWidth: '30ch',
            fontStyle: 'normal',
          }}
        >
          Mỗi người thấy đúng phần việc của mình.
        </h2>

        {/* 2-up asymmetric: Admin (wider) + Tenant */}
        <div
          style={{
            display: 'grid',
            gridTemplateColumns: 'minmax(0, 1.25fr) minmax(0, 0.75fr)',
            gap: 'var(--space-md)',
            marginBottom: 'var(--space-md)',
          }}
          className="roles-grid"
        >
          {roles.map(role => (
            <div
              key={role.title}
              style={{
                padding: 'var(--space-lg)',
                border: 'var(--rule-hair) solid var(--color-border)',
                borderRadius: 'var(--radius-lg)',
                background: 'var(--color-surface)',
                display: 'flex',
                flexDirection: 'column',
                gap: 'var(--space-sm)',
              }}
            >
              <h3
                style={{
                  fontFamily: 'var(--font-display)',
                  fontSize: '1.25rem',
                  fontWeight: 400,
                  color: 'var(--color-fg)',
                  fontStyle: 'normal',
                }}
              >
                {role.title}
              </h3>
              <p className="text-sm leading-6" style={{ color: 'var(--color-fg-muted)' }}>
                {role.desc}
              </p>
              <ul style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-2xs)', marginTop: 'auto' }}>
                {role.modules.map(mod => (
                  <li
                    key={mod}
                    className="flex items-center gap-2 text-sm"
                    style={{ color: 'var(--color-fg)' }}
                  >
                    <span
                      style={{
                        width: '5px',
                        height: '5px',
                        borderRadius: '50%',
                        background: 'var(--color-accent)',
                        flexShrink: 0,
                      }}
                      aria-hidden="true"
                    />
                    {mod}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        {/* Kỹ thuật viên — compact inline row */}
        <div
          style={{
            padding: 'var(--space-sm) var(--space-lg)',
            border: 'var(--rule-hair) solid var(--color-border)',
            borderRadius: 'var(--radius-md)',
            background: 'var(--color-bg)',
            display: 'flex',
            alignItems: 'center',
            gap: 'var(--space-lg)',
            flexWrap: 'wrap',
          }}
        >
          <div style={{ display: 'flex', flexDirection: 'column', gap: '2px', minWidth: '120px' }}>
            <span
              style={{ fontFamily: 'var(--font-display)', fontSize: '1rem', fontWeight: 400, color: 'var(--color-fg)', fontStyle: 'normal' }}
            >
              Kỹ thuật viên
            </span>
          </div>
          <p className="text-sm leading-6" style={{ color: 'var(--color-fg-muted)', flex: 1, minWidth: '200px' }}>
            Nhận việc được giao, cập nhật trạng thái sửa chữa và phản hồi trực tiếp trên hệ thống — không cần liên lạc qua Zalo hay giấy tờ.
          </p>
        </div>
      </div>
    </section>
  )
}

/* ── Modules strip ──────────────────────────────────────────────────────────
 * F3 Tabular spec sheet — 5 modules in a clean hairline-rule table.
 * Replaces the icon-tile grid (the AI default tell).
 * ─────────────────────────────────────────────────────────────────────────── */
function ModulesStrip() {
  const modules = [
    { icon: FileText,  title: 'Hóa đơn hàng tháng',   desc: 'Tiền phòng, điện, nước, dịch vụ — tự tính đúng theo cấu hình phí, theo dõi trạng thái thanh toán từng phòng.' },
    { icon: FileCheck, title: 'Hợp đồng thuê',         desc: 'Thời hạn, đặt cọc, gia hạn và thông tin thuê theo từng phòng — tra được ngay khi cần.' },
    { icon: Wrench,    title: 'Bảo trì',               desc: 'Tiếp nhận yêu cầu, phân công kỹ thuật viên, theo dõi tiến độ đến khi hoàn thành.' },
    { icon: CreditCard, title: 'Thanh toán PayOS',     desc: 'Khách thuê thanh toán trực tuyến, quản lý nhận xác nhận ngay — giảm đối soát thủ công.' },
    { icon: Shield,    title: 'Nhật ký vận hành',      desc: 'Lưu hành động quan trọng để kiểm tra, bàn giao và truy vết khi cần xác minh.' },
  ]

  return (
    <section
      aria-labelledby="modules-heading"
      style={{
        borderBottom: 'var(--rule-hair) solid var(--color-border)',
        background: 'var(--color-surface)',
      }}
    >
      <div className="mx-auto max-w-6xl" style={{ padding: 'var(--space-3xl) var(--space-xl)' }}>
        <h2
          id="modules-heading"
          style={{
            fontFamily: 'var(--font-display)',
            fontSize: 'clamp(1.5rem, 2vw + 0.5rem, 2rem)',
            fontWeight: 400,
            lineHeight: 1.2,
            letterSpacing: '-0.02em',
            color: 'var(--color-fg)',
            marginBottom: 'var(--space-lg)',
            maxWidth: '36ch',
            fontStyle: 'normal',
          }}
        >
          Những phần việc được gom về cùng một hệ thống.
        </h2>

        <div
          style={{
            border: 'var(--rule-hair) solid var(--color-border)',
            borderRadius: 'var(--radius-lg)',
            overflow: 'hidden',
          }}
        >
          {modules.map((mod, i) => (
            <div
              key={mod.title}
              style={{
                display: 'grid',
                gridTemplateColumns: 'minmax(0, 0.35fr) minmax(0, 1fr)',
                borderTop: i > 0 ? 'var(--rule-hair) solid var(--color-border)' : undefined,
              }}
              className="module-row"
            >
              {/* Label column */}
              <div
                style={{
                  padding: 'var(--space-md) var(--space-lg)',
                  borderRight: 'var(--rule-hair) solid var(--color-border)',
                  display: 'flex',
                  alignItems: 'center',
                  gap: 'var(--space-sm)',
                  background: 'var(--color-bg)',
                }}
              >
                <span
                  className="inline-flex items-center justify-center shrink-0"
                  style={{
                    width: '2rem',
                    height: '2rem',
                    borderRadius: 'var(--radius-xs)',
                    background: 'var(--color-accent-surface)',
                    color: 'var(--color-accent)',
                  }}
                  aria-hidden="true"
                >
                  <mod.icon className="h-4 w-4" />
                </span>
                <span
                  className="text-sm font-semibold"
                  style={{ color: 'var(--color-fg)', fontFamily: 'var(--font-body)' }}
                >
                  {mod.title}
                </span>
              </div>
              {/* Description column */}
              <div
                style={{
                  padding: 'var(--space-md) var(--space-lg)',
                  display: 'flex',
                  alignItems: 'center',
                }}
              >
                <p className="text-sm leading-6" style={{ color: 'var(--color-fg-muted)', maxWidth: '65ch' }}>
                  {mod.desc}
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

/* ── CTA strip ──────────────────────────────────────────────────────────────
 * One button. Not two. Not a floating card.
 * Full-width dark section anchored to the page bottom rhythm.
 * ─────────────────────────────────────────────────────────────────────────── */
function CtaStrip() {
  return (
    <section
      aria-labelledby="cta-heading"
      style={{
        background: 'var(--color-fg)',
        padding: 'var(--space-3xl) var(--space-xl)',
        borderBottom: 'var(--rule-hair) solid var(--color-border)',
      }}
    >
      <div
        className="mx-auto max-w-6xl"
        style={{
          display: 'grid',
          gridTemplateColumns: 'minmax(0, 1fr) auto',
          alignItems: 'center',
          gap: 'var(--space-xl)',
        }}
      >
        <div>
          <h2
            id="cta-heading"
            style={{
              fontFamily: 'var(--font-display)',
              fontSize: 'clamp(1.625rem, 2.5vw + 0.5rem, 2.5rem)',
              fontWeight: 400,
              lineHeight: 1.1,
              letterSpacing: '-0.03em',
              color: 'var(--color-fg-inverted)',
              maxWidth: '28ch',
              marginBottom: 'var(--space-xs)',
              fontStyle: 'normal',
            }}
          >
            Sẵn sàng vận hành gọn hơn?
          </h2>
          <p
            className="text-sm leading-6"
            style={{ color: 'var(--color-fg-inverted-muted)', maxWidth: '52ch' }}
          >
            Đăng nhập để xem bảng điều hành, công nợ và bảo trì trong cùng một luồng làm việc.
          </p>
        </div>
        <Link
          to="/login"
          className="inline-flex items-center gap-2 text-sm font-semibold shrink-0 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-3"
          style={{
            padding: '0.6875rem 1.5rem',
            background: 'var(--color-surface)',
            color: 'var(--color-fg)',
            borderRadius: 'var(--radius-md)',
            outlineColor: 'var(--color-accent)',
            transition: `background-color var(--dur-short) var(--ease-out), transform var(--dur-instant) var(--ease-out)`,
            whiteSpace: 'nowrap',
          }}
          onMouseEnter={e => { (e.currentTarget as HTMLElement).style.backgroundColor = 'var(--color-bg)'; (e.currentTarget as HTMLElement).style.transform = 'translateY(-1.5px)'; }}
          onMouseLeave={e => { (e.currentTarget as HTMLElement).style.backgroundColor = 'var(--color-surface)'; (e.currentTarget as HTMLElement).style.transform = 'translateY(0)'; }}
          onMouseDown={e => { (e.currentTarget as HTMLElement).style.transform = 'translateY(0.5px)'; }}
          onMouseUp={e => { (e.currentTarget as HTMLElement).style.transform = 'translateY(-1.5px)'; }}
        >
          Đăng nhập vào hệ thống
          <ChevronRight className="h-4 w-4" aria-hidden="true" />
        </Link>
      </div>
    </section>
  )
}

/* ── Ft5 Statement footer ───────────────────────────────────────────────────
 * Closing line dominates. Wordmark + minimal meta beneath a hairline rule.
 * Knobs: sentence-width=38ch, wordmark-position=under-sentence, rule=hairline
 * ─────────────────────────────────────────────────────────────────────────── */
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
        {/* Statement line */}
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

        {/* Meta row */}
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

/* ── Responsive overrides (injected as a style tag) ─────────────────────────
 * Split pairs collapse to single-column below 768px.
 * Modules table rows collapse to single-column below 640px.
 * ─────────────────────────────────────────────────────────────────────────── */
const responsiveCSS = `
  /* Preserve sticky pill nav clearance on all viewports */
  .hero-grid { padding-top: calc(var(--space-4xl) + var(--space-md)); }

  /* Split pairs: stack on mobile */
  @media (max-width: 768px) {
    .hero-grid {
      grid-template-columns: minmax(0, 1fr) !important;
    }
    .hero-grid > *:last-child {
      border-left: none !important;
      border-top: 1px solid var(--color-border);
      min-height: 320px;
    }
    .split-pair {
      grid-template-columns: minmax(0, 1fr) !important;
    }
    /* ensure visual col always renders after text col regardless of order */
    .split-pair > *:first-child { order: 1; }
    .split-pair > *:last-child  { order: 2; }
  }

  /* Roles grid: stack on mobile */
  @media (max-width: 640px) {
    .roles-grid {
      grid-template-columns: minmax(0, 1fr) !important;
    }
    .module-row {
      grid-template-columns: minmax(0, 1fr) !important;
    }
    .module-row > *:first-child {
      border-right: none !important;
      border-bottom: 1px solid var(--color-border);
    }
  }

  /* Stat strip: stack on mobile */
  @media (max-width: 480px) {
    .mx-auto.max-w-6xl > div[style*="repeat(3"] {
      grid-template-columns: minmax(0, 1fr) !important;
    }
  }
`

/* ── Page ───────────────────────────────────────────────────────────────────
 * Split Studio macrostructure:
 *   Nav (N5 pill) → Hero (H2 diptych) → Stats strip →
 *   3× alternating split pairs → Modules spec sheet →
 *   Roles section → CTA strip → Footer (Ft5 statement)
 * ─────────────────────────────────────────────────────────────────────────── */
export default function LandingPage() {
  return (
    <>
      <style>{responsiveCSS}</style>
      <div
        style={{
          minHeight: '100vh',
          background: 'var(--color-bg)',
          color: 'var(--color-fg)',
          fontFamily: 'var(--font-body)',
        }}
      >
        {/* N5 Floating pill nav — fixed, detached from page flow */}
        <NavPill />

        <main>
          {/* 1. Hero — H2 split diptych */}
          <Hero />

          {/* 2. T4 Numbered stat strip */}
          <StatStrip />

          {/* 3. Split Studio pairs — text/proof alternating */}
          <section id="how-it-works" aria-label="Cách hệ thống vận hành">
            {splitPairs.map(pair => (
              <SplitPair key={pair.id} pair={pair} />
            ))}
          </section>

          {/* 4. F3 Modules spec sheet */}
          <ModulesStrip />

          {/* 5. Roles — asymmetric 2-up */}
          <RolesSection />

          {/* 6. CTA strip — full-width dark */}
          <CtaStrip />
        </main>

        {/* Ft5 Statement footer */}
        <Footer />
      </div>
    </>
  )
}
