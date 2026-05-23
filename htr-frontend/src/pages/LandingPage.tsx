import { Link } from 'react-router-dom'
import {
  FileText, Wrench, FileCheck, CreditCard, Shield,
  CheckCircle2, Users, BarChart3, ChevronRight, ArrowRight,
} from 'lucide-react'
import logoHtr from '@/assets/logo-htr.png'

const operatingSignals = [
  'Công nợ đến hạn trong ngày',
  'Yêu cầu bảo trì mới từ khách thuê',
  'Dòng tiền theo tháng và tỷ lệ lấp đầy',
]

const capabilities = [
  {
    title: 'Điều hành theo ngày, không bỏ sót việc',
    desc: 'Bảng điều hành tập trung công nợ, bảo trì và trạng thái phòng để biết việc nào cần xử lý trước.',
    points: ['Theo dõi hóa đơn quá hạn theo phòng', 'Nhìn nhanh bảo trì mới và việc đang xử lý', 'Biết số phòng trống để quyết định lấp đầy'],
  },
  {
    title: 'Chuẩn hóa vận hành, không phụ thuộc trí nhớ',
    desc: 'Hợp đồng, hóa đơn, cấu hình phí và thanh toán được lưu trong cùng một hệ thống.',
    points: ['Quy tắc tính tiền rõ theo từng tòa nhà', 'Lịch sử thao tác và thay đổi được lưu lại', 'Khách thuê và kỹ thuật viên có luồng làm việc riêng'],
  },
]

const modules = [
  { icon: FileText, title: 'Hóa đơn hàng tháng', desc: 'Tạo tiền phòng, điện, nước, dịch vụ và theo dõi trạng thái thanh toán.' },
  { icon: FileCheck, title: 'Hợp đồng thuê', desc: 'Quản lý thời hạn, đặt cọc, gia hạn và thông tin thuê theo từng phòng.' },
  { icon: Wrench, title: 'Bảo trì', desc: 'Tiếp nhận yêu cầu, phân công kỹ thuật viên và cập nhật tiến độ xử lý.' },
  { icon: CreditCard, title: 'Thanh toán PayOS', desc: 'Cho phép khách thuê thanh toán trực tuyến, giảm việc đối soát thủ công.' },
  { icon: Shield, title: 'Nhật ký vận hành', desc: 'Lưu lại hành động quan trọng để kiểm tra, bàn giao và truy vết.' },
]

const roleProof = [
  {
    title: 'Quản lý',
    summary: 'Theo dõi công nợ, tỷ lệ lấp đầy, hợp đồng và người dùng trong cùng một nơi.',
  },
  {
    title: 'Khách thuê',
    summary: 'Xem hóa đơn, hợp đồng, gửi yêu cầu bảo trì và theo dõi lịch sử thanh toán.',
  },
  {
    title: 'Kỹ thuật viên',
    summary: 'Nhận việc, cập nhật trạng thái sửa chữa và phản hồi ngay trên hệ thống.',
  },
]

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-bg">
      <header className="sticky top-0 z-50 border-b border-border/60 bg-surface/95 backdrop-blur-sm">
        <div className="mx-auto flex h-14 max-w-6xl items-center justify-between px-6">
          <div className="flex items-center gap-2.5">
            <img src={logoHtr} alt="HowsTheRent" className="h-8 w-8 rounded-xl object-cover shadow-[0_1px_2px_rgba(15,23,42,0.08)]" />
            <div>
              <p className="text-sm font-semibold leading-none text-fg">How&apos;s The Rent</p>
              <p className="mt-0.5 text-[11px] text-fg-subtle">Hệ thống vận hành nhà trọ</p>
            </div>
          </div>
          <Link
            to="/login"
            className="rounded-xl border border-border/80 bg-surface px-4 py-2 text-sm font-medium text-fg transition-colors hover:bg-sidebar"
          >
            Đăng nhập
          </Link>
        </div>
      </header>

      <section className="mx-auto grid max-w-6xl gap-10 px-6 pb-20 pt-16 lg:grid-cols-[1.15fr_0.85fr] lg:items-start lg:pt-24">
        <div className="animate-slide-up">
          <h1 className="max-w-[16ch] text-[clamp(2.5rem,6vw,3.5rem)] font-semibold leading-[1.04] tracking-[-0.04em] text-fg">
            Biết ngay hôm nay cần thu gì, sửa gì, và phòng nào cần chú ý.
          </h1>
          <p className="mt-5 max-w-[52ch] text-base leading-7 text-fg-muted">
            HowsTheRent gom công nợ, hợp đồng, bảo trì và thanh toán về một luồng vận hành rõ ràng, để việc quản lý nhà trọ không còn phụ thuộc vào ghi nhớ thủ công.
          </p>
          <div className="mt-8 flex flex-col gap-3 sm:flex-row">
            <Link
              to="/login"
              className="inline-flex items-center justify-center gap-2 rounded-xl bg-accent px-5 py-3 text-sm font-semibold text-accent-fg shadow-[inset_0_1px_0_rgba(255,255,255,0.16)] transition-colors hover:bg-accent-hover"
            >
              Vào hệ thống <ChevronRight className="h-4 w-4" />
            </Link>
            <a
              href="#capabilities"
              className="inline-flex items-center justify-center gap-2 rounded-xl border border-border/80 px-5 py-3 text-sm font-medium text-fg transition-colors hover:bg-sidebar"
            >
              Xem cách vận hành <ArrowRight className="h-4 w-4" />
            </a>
          </div>
        </div>

        <div className="animate-slide-up stagger-2 rounded-[28px] border border-border/80 bg-surface p-5 shadow-[0_1px_2px_rgba(15,23,42,0.03)]">
          <div className="flex items-center justify-between gap-4 border-b border-border/80 pb-4">
            <div>
              <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-fg-subtle">Bảng điều hành</p>
              <h2 className="mt-1 text-lg font-semibold tracking-[-0.01em] text-fg">Những gì chủ trọ cần thấy đầu ngày</h2>
            </div>
            <div className="inline-flex h-10 w-10 items-center justify-center rounded-2xl bg-accent-surface text-accent">
              <BarChart3 className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-5 space-y-3">
            {operatingSignals.map((item, i) => (
              <div key={item} className={`flex items-start gap-3 rounded-2xl border border-border/70 bg-bg px-4 py-3 animate-enter stagger-${i + 3}`}>
                <span className="mt-0.5 inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-accent-surface text-accent">
                  <CheckCircle2 className="h-4 w-4" />
                </span>
                <div>
                  <p className="text-sm font-medium text-fg">{item}</p>
                  <p className="mt-1 text-sm text-fg-muted">Hiển thị trực tiếp trong dashboard, không phải đối chiếu từ nhiều file.</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="border-y border-border/60 bg-surface">
        <div className="mx-auto grid max-w-6xl gap-px sm:grid-cols-3">
          {[
            { value: '3', label: 'Vai trò riêng biệt', detail: 'Quản lý, khách thuê, kỹ thuật viên' },
            { value: '12+', label: 'Nghiệp vụ chính', detail: 'Bao phủ công nợ, hợp đồng, bảo trì và đối soát' },
            { value: '100%', label: 'Trên nền web', detail: 'Dùng được ở quầy tiếp khách, văn phòng hoặc khi đi kiểm phòng' },
          ].map((stat, i) => (
            <div
              key={stat.label}
              className={`px-6 py-8 ${i > 0 ? 'border-t border-border/60 sm:border-t-0 sm:border-l' : ''}`}
            >
              <p className="text-3xl font-semibold tracking-tight text-accent">{stat.value}</p>
              <p className="mt-1.5 text-sm font-medium text-fg">{stat.label}</p>
              <p className="mt-1 text-sm text-fg-muted">{stat.detail}</p>
            </div>
          ))}
        </div>
      </section>

      <section id="capabilities" className="mx-auto max-w-6xl px-6 py-20">
        <div className="grid gap-6 lg:grid-cols-2">
          {capabilities.map((capability, index) => (
            <div key={capability.title} className={`rounded-[28px] border border-border/80 ${index === 0 ? 'bg-surface' : 'bg-sidebar/55'} p-6`}>
              <h3 className="text-xl font-semibold tracking-[-0.02em] text-fg">{capability.title}</h3>
              <p className="mt-3 text-sm leading-6 text-fg-muted">{capability.desc}</p>
              <ul className="mt-6 space-y-3">
                {capability.points.map(point => (
                  <li key={point} className="flex items-start gap-3 text-sm text-fg">
                    <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-accent" />
                    <span>{point}</span>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </section>

      <section className="mx-auto max-w-6xl px-6 pb-20">
        <div className="mb-8">
          <h2 className="text-2xl font-semibold tracking-[-0.03em] text-fg">Những phần việc được gom về cùng một hệ thống.</h2>
        </div>
        <div className="grid gap-6 lg:grid-cols-[1fr_1fr_1fr]">
          {modules.slice(0, 2).map((mod) => (
            <div key={mod.title} className="rounded-2xl border border-border/80 bg-surface p-6">
              <div className="mb-3 inline-flex h-10 w-10 items-center justify-center rounded-2xl bg-accent-surface text-accent">
                <mod.icon className="h-5 w-5" />
              </div>
              <h3 className="text-base font-semibold text-fg">{mod.title}</h3>
              <p className="mt-2 text-sm leading-6 text-fg-muted">{mod.desc}</p>
            </div>
          ))}
          <div className="space-y-4 lg:row-span-1">
            {modules.slice(2).map((mod) => (
              <div key={mod.title} className="flex items-start gap-4 rounded-2xl border border-border/70 bg-bg px-5 py-4">
                <div className="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-accent-surface text-accent">
                  <mod.icon className="h-4 w-4" />
                </div>
                <div>
                  <h3 className="text-sm font-semibold text-fg">{mod.title}</h3>
                  <p className="mt-1 text-sm text-fg-muted">{mod.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="border-y border-border/60 bg-surface">
        <div className="mx-auto max-w-6xl px-6 py-16">
          <h2 className="mb-8 text-2xl font-semibold tracking-[-0.03em] text-fg">Mỗi người thấy đúng phần việc của mình.</h2>
          <div className="grid gap-4 md:grid-cols-3">
            {roleProof.map((role) => (
              <div key={role.title} className="rounded-2xl border border-border/70 bg-bg px-5 py-5">
                <div className="mb-4 inline-flex h-10 w-10 items-center justify-center rounded-2xl bg-sidebar text-fg-muted">
                  <Users className="h-4 w-4" />
                </div>
                <h3 className="text-lg font-semibold text-fg">{role.title}</h3>
                <p className="mt-2 text-sm leading-6 text-fg-muted">{role.summary}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-5xl px-6 py-20">
        <div className="rounded-[32px] border border-border/80 bg-fg px-8 py-10 text-center sm:px-12 sm:py-12">
          <h2 className="text-2xl font-semibold tracking-[-0.03em] text-fg-inverted sm:text-3xl">
            Sẵn sàng vận hành gọn hơn?
          </h2>
          <p className="mx-auto mt-3 max-w-[48ch] text-sm leading-6 text-fg-inverted-muted">
            Đăng nhập để xem bảng điều hành, công nợ và bảo trì trong cùng một luồng làm việc. Phù hợp cho chủ trọ cần hệ thống gọn, rõ, đủ chặt để bàn giao mà không cần giải thích lại.
          </p>
          <Link
            to="/login"
            className="mt-8 inline-flex items-center gap-2 rounded-xl bg-surface px-6 py-3 text-sm font-semibold text-fg transition-colors hover:bg-bg"
          >
            Đăng nhập vào hệ thống <ChevronRight className="h-4 w-4" />
          </Link>
        </div>
      </section>

      <footer className="border-t border-border/60">
        <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-3 px-6 py-6 sm:flex-row">
          <div className="flex items-center gap-2.5">
            <img src={logoHtr} alt="HowsTheRent" className="h-7 w-7 rounded-xl object-cover" />
            <div>
              <p className="text-sm font-semibold text-fg">How&apos;s The Rent</p>
              <p className="text-xs text-fg-subtle">Hệ thống quản lý nhà trọ</p>
            </div>
          </div>
          <p className="text-xs text-fg-subtle">© {new Date().getFullYear()} HowsTheRent. Dành cho vận hành nhà trọ hằng ngày.</p>
        </div>
      </footer>
    </div>
  )
}
