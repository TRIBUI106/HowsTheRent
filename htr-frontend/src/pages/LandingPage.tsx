import { Link } from 'react-router-dom'
import {
  Building2, FileText, Wrench, FileCheck, CreditCard, Shield,
  CheckCircle, Users, BarChart3, Bell, ChevronRight,
} from 'lucide-react'

const features = [
  {
    icon: Building2,
    title: 'Quản lý tài sản',
    desc: 'Theo dõi toàn bộ bất động sản, tòa nhà và phòng trọ trên một nền tảng duy nhất.',
  },
  {
    icon: FileText,
    title: 'Hóa đơn tự động',
    desc: 'Tự động tạo hóa đơn tiền điện, nước, phòng hàng tháng. Nhắc nhở thanh toán đúng hạn.',
  },
  {
    icon: Wrench,
    title: 'Quản lý bảo trì',
    desc: 'Tiếp nhận, phân công và theo dõi tiến độ xử lý yêu cầu sửa chữa từ khách thuê.',
  },
  {
    icon: FileCheck,
    title: 'Hợp đồng số',
    desc: 'Ký kết và quản lý hợp đồng thuê phòng. Tự động nhắc gia hạn trước khi hết hạn.',
  },
  {
    icon: CreditCard,
    title: 'Thanh toán trực tuyến',
    desc: 'Tích hợp PayOS — khách thuê thanh toán hóa đơn trực tiếp qua app, không cần tiền mặt.',
  },
  {
    icon: Shield,
    title: 'Nhật ký hoạt động',
    desc: 'Ghi lại mọi thao tác quan trọng trong hệ thống. Kiểm soát rủi ro và truy vết sự kiện.',
  },
]

const stats = [
  { value: '3',    label: 'Vai trò người dùng', sub: 'Quản lý · Khách thuê · Kỹ thuật viên' },
  { value: '12+',  label: 'Tính năng quản lý',  sub: 'Tích hợp đầy đủ trong một hệ thống' },
  { value: '100%', label: 'Trên nền web',        sub: 'Không cần cài đặt, dùng mọi thiết bị' },
]

const roles = [
  {
    title: 'Quản lý',
    items: [
      'Quản lý tòa nhà và phòng trọ',
      'Tạo và duyệt hợp đồng thuê',
      'Theo dõi hóa đơn và doanh thu',
      'Phân công công việc bảo trì',
      'Quản lý người dùng và phân quyền',
      'Xem nhật ký toàn hệ thống',
    ],
  },
  {
    title: 'Khách thuê',
    items: [
      'Xem thông tin hợp đồng',
      'Tra cứu và thanh toán hóa đơn',
      'Gửi yêu cầu bảo trì',
      'Theo dõi lịch sử thanh toán',
      'Nhận thông báo từ quản lý',
      'Thanh toán trực tuyến qua PayOS',
    ],
  },
  {
    title: 'Kỹ thuật viên',
    items: [
      'Nhận yêu cầu bảo trì được phân công',
      'Cập nhật trạng thái xử lý',
      'Tải ảnh kết quả hoàn thành',
      'Xem lịch sử công việc',
      'Nhận thông báo nhiệm vụ mới',
    ],
  },
]

const steps = [
  {
    title: 'Thiết lập hệ thống',
    desc: 'Tạo tài khoản, thêm tòa nhà, phòng trọ và cấu hình các loại phí dịch vụ.',
  },
  {
    title: 'Thêm khách thuê',
    desc: 'Tạo hợp đồng thuê phòng, cấp tài khoản cho khách thuê và kỹ thuật viên.',
  },
  {
    title: 'Vận hành tự động',
    desc: 'Hệ thống tự động tạo hóa đơn, gửi thông báo và xử lý thanh toán hàng tháng.',
  },
]

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-bg">
      {/* Navbar */}
      <header className="sticky top-0 z-50 bg-surface/95 backdrop-blur-sm border-b border-border">
        <div className="max-w-6xl mx-auto px-6 h-14 flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="w-7 h-7 bg-accent rounded-lg flex items-center justify-center shrink-0">
              <span className="text-accent-fg font-bold text-xs">P</span>
            </div>
            <span className="font-semibold text-fg text-sm">HowsTheRent</span>
          </div>
          <Link
            to="/login"
            className="inline-flex items-center gap-1.5 bg-accent hover:bg-accent-hover text-accent-fg text-sm font-medium px-4 py-2 rounded-lg transition-colors duration-100"
          >
            Đăng nhập
          </Link>
        </div>
      </header>

      {/* Hero */}
      <section className="max-w-6xl mx-auto px-6 pt-20 pb-16 text-center">
        <div className="inline-flex items-center gap-2 bg-accent-surface text-accent text-xs font-medium px-3 py-1.5 rounded-full mb-8">
          <span className="w-1.5 h-1.5 bg-accent rounded-full shrink-0" />
          Hệ thống quản lý nhà trọ chuyên nghiệp
        </div>
        <h1 className="text-5xl font-bold text-fg tracking-tight leading-[1.1] mb-5 max-w-3xl mx-auto">
          Quản lý nhà trọ<br className="hidden sm:block" /> đơn giản và hiệu quả
        </h1>
        <p className="text-lg text-fg-muted max-w-xl mx-auto mb-10 leading-relaxed">
          Số hóa toàn bộ quy trình vận hành: hợp đồng, hóa đơn, bảo trì và thanh toán trong một nền tảng duy nhất.
        </p>
        <div className="flex flex-col sm:flex-row items-center justify-center gap-3">
          <Link
            to="/login"
            className="inline-flex items-center gap-2 bg-accent hover:bg-accent-hover text-accent-fg font-semibold px-6 py-3 rounded-lg transition-colors duration-100"
          >
            Bắt đầu ngay <ChevronRight className="w-4 h-4" />
          </Link>
          <a
            href="#features"
            className="inline-flex items-center gap-2 text-fg-muted hover:text-fg font-medium px-6 py-3 rounded-lg border border-border hover:border-border-strong transition-colors duration-100"
          >
            Khám phá tính năng
          </a>
        </div>
      </section>

      {/* Stats */}
      <section className="border-y border-border bg-surface">
        <div className="max-w-6xl mx-auto px-6 py-10 grid grid-cols-1 sm:grid-cols-3 divide-y sm:divide-y-0 sm:divide-x divide-border">
          {stats.map(s => (
            <div key={s.label} className="text-center py-6 sm:py-0 sm:px-10">
              <div className="text-3xl font-bold text-fg mb-1">{s.value}</div>
              <div className="text-sm font-semibold text-fg mb-0.5">{s.label}</div>
              <div className="text-xs text-fg-subtle">{s.sub}</div>
            </div>
          ))}
        </div>
      </section>

      {/* Features */}
      <section id="features" className="max-w-6xl mx-auto px-6 py-20">
        <div className="mb-12">
          <div className="flex items-center gap-2 text-accent text-xs font-semibold uppercase tracking-wider mb-3">
            <BarChart3 className="w-3.5 h-3.5" />
            Tính năng
          </div>
          <h2 className="text-3xl font-bold text-fg mb-3 tracking-tight">Mọi thứ bạn cần, trong một nơi</h2>
          <p className="text-fg-muted max-w-lg text-sm leading-relaxed">
            HowsTheRent bao phủ toàn bộ quy trình vận hành nhà trọ từ A đến Z.
          </p>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-x-8 gap-y-10">
          {features.map(f => (
            <div key={f.title}>
              <div className="w-8 h-8 bg-accent-surface rounded-lg flex items-center justify-center mb-3">
                <f.icon className="w-4 h-4 text-accent" />
              </div>
              <h3 className="font-semibold text-fg text-sm mb-1.5">{f.title}</h3>
              <p className="text-sm text-fg-muted leading-relaxed">{f.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Roles */}
      <section className="bg-surface border-y border-border py-20">
        <div className="max-w-6xl mx-auto px-6">
          <div className="mb-12">
            <div className="flex items-center gap-2 text-accent text-xs font-semibold uppercase tracking-wider mb-3">
              <Users className="w-3.5 h-3.5" />
              Vai trò người dùng
            </div>
            <h2 className="text-3xl font-bold text-fg mb-3 tracking-tight">Thiết kế cho từng vai trò</h2>
            <p className="text-fg-muted text-sm max-w-lg leading-relaxed">
              Ba giao diện riêng biệt, tối ưu cho công việc hàng ngày của từng nhóm người dùng.
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {roles.map(r => (
              <div key={r.title}>
                <p className="text-xs font-semibold text-fg-muted uppercase tracking-wider mb-4 pb-3 border-b border-border">
                  {r.title}
                </p>
                <ul className="space-y-2.5">
                  {r.items.map(item => (
                    <li key={item} className="flex items-start gap-2 text-sm text-fg-muted">
                      <CheckCircle className="w-4 h-4 mt-0.5 shrink-0 text-success" />
                      {item}
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* How it works */}
      <section className="max-w-6xl mx-auto px-6 py-20">
        <div className="mb-12">
          <div className="flex items-center gap-2 text-accent text-xs font-semibold uppercase tracking-wider mb-3">
            <Bell className="w-3.5 h-3.5" />
            Quy trình
          </div>
          <h2 className="text-3xl font-bold text-fg mb-3 tracking-tight">Hoạt động trong 3 bước</h2>
          <p className="text-fg-muted text-sm max-w-lg leading-relaxed">
            Triển khai và vận hành ngay từ ngày đầu, không cần đào tạo phức tạp.
          </p>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-8">
          {steps.map((s, i) => (
            <div key={s.title}>
              <div className="inline-flex items-center justify-center w-10 h-10 bg-accent text-accent-fg rounded-lg font-bold text-sm mb-4">
                {String(i + 1).padStart(2, '0')}
              </div>
              <h3 className="font-semibold text-fg mb-2 text-sm">{s.title}</h3>
              <p className="text-sm text-fg-muted leading-relaxed">{s.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* CTA — inverted */}
      <section className="bg-fg py-20">
        <div className="max-w-2xl mx-auto px-6 text-center">
          <h2 className="text-3xl font-bold text-fg-inverted tracking-tight mb-4">
            Sẵn sàng số hóa việc quản lý nhà trọ?
          </h2>
          <p className="text-fg-inverted-muted text-sm mb-8 leading-relaxed">
            Đăng nhập ngay để trải nghiệm toàn bộ tính năng của HowsTheRent.
          </p>
          <Link
            to="/login"
            className="inline-flex items-center gap-2 bg-surface hover:bg-bg text-fg font-semibold px-8 py-3 rounded-lg transition-colors duration-100"
          >
            Đăng nhập vào hệ thống <ChevronRight className="w-4 h-4" />
          </Link>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-border bg-surface py-6">
        <div className="max-w-6xl mx-auto px-6 flex flex-col sm:flex-row items-center justify-between gap-3">
          <div className="flex items-center gap-2">
            <div className="w-5 h-5 bg-accent rounded flex items-center justify-center">
              <span className="text-accent-fg font-bold text-xs">P</span>
            </div>
            <span className="text-sm font-semibold text-fg">HowsTheRent</span>
          </div>
          <p className="text-xs text-fg-subtle">
            © {new Date().getFullYear()} HowsTheRent. Hệ thống Quản lý Nhà trọ.
          </p>
        </div>
      </footer>
    </div>
  )
}
