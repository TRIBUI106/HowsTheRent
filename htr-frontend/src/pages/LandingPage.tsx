import { Link } from 'react-router-dom'
import {
  Building2, FileText, Wrench, FileCheck, CreditCard, Shield,
  CheckCircle, Users, BarChart3, Bell, ChevronRight, Star,
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
  { value: '3', label: 'Vai trò người dùng', sub: 'Quản lý · Khách thuê · Kỹ thuật viên' },
  { value: '12+', label: 'Tính năng quản lý', sub: 'Tích hợp đầy đủ trong một hệ thống' },
  { value: '100%', label: 'Trên nền web', sub: 'Không cần cài đặt, dùng mọi thiết bị' },
]

const roles = [
  {
    title: 'Quản lý',
    color: 'indigo',
    items: [
      'Quản lý tòa nhà & phòng trọ',
      'Tạo & duyệt hợp đồng thuê',
      'Theo dõi hóa đơn & doanh thu',
      'Phân công công việc bảo trì',
      'Quản lý người dùng & phân quyền',
      'Xem nhật ký toàn hệ thống',
    ],
  },
  {
    title: 'Khách thuê',
    color: 'blue',
    items: [
      'Xem thông tin hợp đồng',
      'Tra cứu & thanh toán hóa đơn',
      'Gửi yêu cầu bảo trì',
      'Theo dõi lịch sử thanh toán',
      'Nhận thông báo từ quản lý',
      'Thanh toán trực tuyến qua PayOS',
    ],
  },
  {
    title: 'Kỹ thuật viên',
    color: 'green',
    items: [
      'Nhận yêu cầu bảo trì được phân công',
      'Cập nhật trạng thái xử lý',
      'Tải ảnh kết quả hoàn thành',
      'Xem lịch sử công việc',
      'Nhận thông báo nhiệm vụ mới',
    ],
  },
]

const colorMap: Record<string, { bg: string; text: string; ring: string; badge: string }> = {
  indigo: {
    bg: 'bg-indigo-50',
    text: 'text-indigo-600',
    ring: 'ring-indigo-200',
    badge: 'bg-indigo-600',
  },
  blue: {
    bg: 'bg-blue-50',
    text: 'text-blue-600',
    ring: 'ring-blue-200',
    badge: 'bg-blue-600',
  },
  green: {
    bg: 'bg-green-50',
    text: 'text-green-600',
    ring: 'ring-green-200',
    badge: 'bg-green-600',
  },
}

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-white font-sans">
      {/* Navbar */}
      <header className="sticky top-0 z-50 bg-white/90 backdrop-blur border-b border-gray-100">
        <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 bg-indigo-600 rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-sm">P</span>
            </div>
            <span className="font-bold text-gray-900 text-lg">HowsTheRent</span>
          </div>
          <Link
            to="/login"
            className="inline-flex items-center gap-1.5 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-medium px-4 py-2 rounded-lg transition-colors duration-150"
          >
            Đăng nhập <ChevronRight className="w-4 h-4" />
          </Link>
        </div>
      </header>

      {/* Hero */}
      <section className="relative bg-gradient-to-br from-indigo-600 via-indigo-700 to-blue-800 overflow-hidden">
        <div className="absolute inset-0 pointer-events-none overflow-hidden">
          <div className="absolute -top-40 -right-40 w-[500px] h-[500px] bg-white/5 rounded-full" />
          <div className="absolute -bottom-32 -left-32 w-96 h-96 bg-white/5 rounded-full" />
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[700px] h-[700px] bg-white/[0.02] rounded-full" />
        </div>

        <div className="relative max-w-6xl mx-auto px-6 py-24 text-center">
          <div className="inline-flex items-center gap-2 bg-white/10 text-indigo-100 text-xs font-medium px-3 py-1.5 rounded-full mb-6 ring-1 ring-white/20">
            <Star className="w-3.5 h-3.5 fill-indigo-200 text-indigo-200" />
            Hệ thống quản lý nhà trọ toàn diện
          </div>

          <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold text-white leading-tight mb-6">
            Quản lý nhà trọ<br />
            <span className="text-indigo-200">thông minh & hiệu quả</span>
          </h1>

          <p className="text-indigo-100 text-lg max-w-2xl mx-auto mb-10 leading-relaxed">
            Nền tảng số hóa toàn bộ quy trình quản lý bất động sản cho thuê —
            từ hợp đồng, hóa đơn, bảo trì đến thanh toán trực tuyến.
          </p>

          <div className="flex flex-col sm:flex-row items-center justify-center gap-3">
            <Link
              to="/login"
              className="inline-flex items-center gap-2 bg-white text-indigo-700 hover:bg-indigo-50 font-semibold px-7 py-3.5 rounded-xl shadow-lg transition-colors duration-150"
            >
              Bắt đầu ngay <ChevronRight className="w-4 h-4" />
            </Link>
            <a
              href="#features"
              className="inline-flex items-center gap-2 text-indigo-100 hover:text-white font-medium px-7 py-3.5 rounded-xl ring-1 ring-white/20 hover:ring-white/40 transition-all duration-150"
            >
              Khám phá tính năng
            </a>
          </div>
        </div>
      </section>

      {/* Stats */}
      <section className="border-b border-gray-100">
        <div className="max-w-6xl mx-auto px-6 py-14 grid grid-cols-1 sm:grid-cols-3 divide-y sm:divide-y-0 sm:divide-x divide-gray-100">
          {stats.map(s => (
            <div key={s.label} className="text-center py-6 sm:py-0 sm:px-10">
              <div className="text-4xl font-bold text-indigo-600 mb-1">{s.value}</div>
              <div className="text-sm font-semibold text-gray-900 mb-0.5">{s.label}</div>
              <div className="text-xs text-gray-500">{s.sub}</div>
            </div>
          ))}
        </div>
      </section>

      {/* Features */}
      <section id="features" className="max-w-6xl mx-auto px-6 py-20">
        <div className="text-center mb-14">
          <div className="inline-flex items-center gap-2 bg-indigo-50 text-indigo-600 text-xs font-semibold px-3 py-1.5 rounded-full mb-4">
            <BarChart3 className="w-3.5 h-3.5" /> Tính năng
          </div>
          <h2 className="text-3xl font-bold text-gray-900 mb-3">Mọi thứ bạn cần trong một nơi</h2>
          <p className="text-gray-500 max-w-xl mx-auto text-sm leading-relaxed">
            Từ quản lý tài sản đến thanh toán trực tuyến, HowsTheRent bao phủ toàn bộ
            quy trình vận hành nhà trọ chuyên nghiệp.
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {features.map(f => (
            <div
              key={f.title}
              className="group bg-white border border-gray-100 rounded-2xl p-6 shadow-sm hover:shadow-md hover:border-indigo-100 transition-all duration-150"
            >
              <div className="w-10 h-10 bg-indigo-50 rounded-xl flex items-center justify-center mb-4 group-hover:bg-indigo-100 transition-colors duration-150">
                <f.icon className="w-5 h-5 text-indigo-600" />
              </div>
              <h3 className="font-semibold text-gray-900 mb-2">{f.title}</h3>
              <p className="text-sm text-gray-500 leading-relaxed">{f.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Roles */}
      <section className="bg-gray-50 py-20">
        <div className="max-w-6xl mx-auto px-6">
          <div className="text-center mb-14">
            <div className="inline-flex items-center gap-2 bg-indigo-50 text-indigo-600 text-xs font-semibold px-3 py-1.5 rounded-full mb-4">
              <Users className="w-3.5 h-3.5" /> Vai trò người dùng
            </div>
            <h2 className="text-3xl font-bold text-gray-900 mb-3">Thiết kế cho từng vai trò</h2>
            <p className="text-gray-500 text-sm max-w-xl mx-auto leading-relaxed">
              Ba giao diện riêng biệt, được tối ưu cho công việc hàng ngày của từng nhóm người dùng.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {roles.map(r => {
              const c = colorMap[r.color]
              return (
                <div key={r.title} className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
                  <div className={`${c.badge} px-6 py-4`}>
                    <span className="text-white font-bold text-lg">{r.title}</span>
                  </div>
                  <ul className="px-6 py-5 space-y-3">
                    {r.items.map(item => (
                      <li key={item} className="flex items-start gap-2.5 text-sm text-gray-700">
                        <CheckCircle className={`w-4 h-4 mt-0.5 shrink-0 ${c.text}`} />
                        {item}
                      </li>
                    ))}
                  </ul>
                </div>
              )
            })}
          </div>
        </div>
      </section>

      {/* How it works */}
      <section className="max-w-6xl mx-auto px-6 py-20">
        <div className="text-center mb-14">
          <div className="inline-flex items-center gap-2 bg-indigo-50 text-indigo-600 text-xs font-semibold px-3 py-1.5 rounded-full mb-4">
            <Bell className="w-3.5 h-3.5" /> Quy trình
          </div>
          <h2 className="text-3xl font-bold text-gray-900 mb-3">Hoạt động đơn giản</h2>
          <p className="text-gray-500 text-sm max-w-xl mx-auto leading-relaxed">
            Hệ thống được thiết kế để dễ dàng triển khai và vận hành ngay từ ngày đầu.
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-8">
          {[
            {
              step: '01',
              title: 'Thiết lập hệ thống',
              desc: 'Quản lý tạo tài khoản, thêm tòa nhà, phòng trọ và cấu hình các loại phí dịch vụ.',
            },
            {
              step: '02',
              title: 'Thêm khách thuê',
              desc: 'Tạo hợp đồng thuê phòng, cấp tài khoản cho khách thuê và kỹ thuật viên.',
            },
            {
              step: '03',
              title: 'Vận hành tự động',
              desc: 'Hệ thống tự động tạo hóa đơn, gửi thông báo và xử lý thanh toán hàng tháng.',
            },
          ].map(s => (
            <div key={s.step} className="relative text-center">
              <div className="inline-flex items-center justify-center w-14 h-14 bg-indigo-600 text-white rounded-2xl font-bold text-xl mb-5 shadow-lg shadow-indigo-200">
                {s.step}
              </div>
              <h3 className="font-semibold text-gray-900 mb-2">{s.title}</h3>
              <p className="text-sm text-gray-500 leading-relaxed">{s.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* CTA */}
      <section className="bg-gradient-to-br from-indigo-600 via-indigo-700 to-blue-800 py-20">
        <div className="max-w-2xl mx-auto px-6 text-center">
          <h2 className="text-3xl font-bold text-white mb-4">
            Sẵn sàng số hóa việc quản lý nhà trọ?
          </h2>
          <p className="text-indigo-200 text-sm mb-8 leading-relaxed">
            Đăng nhập ngay để trải nghiệm toàn bộ tính năng của HowsTheRent.
          </p>
          <Link
            to="/login"
            className="inline-flex items-center gap-2 bg-white text-indigo-700 hover:bg-indigo-50 font-semibold px-8 py-3.5 rounded-xl shadow-lg transition-colors duration-150"
          >
            Đăng nhập vào hệ thống <ChevronRight className="w-4 h-4" />
          </Link>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-gray-100 py-8">
        <div className="max-w-6xl mx-auto px-6 flex flex-col sm:flex-row items-center justify-between gap-3">
          <div className="flex items-center gap-2">
            <div className="w-6 h-6 bg-indigo-600 rounded-md flex items-center justify-center">
              <span className="text-white font-bold text-xs">P</span>
            </div>
            <span className="text-sm font-semibold text-gray-900">HowsTheRent</span>
          </div>
          <p className="text-xs text-gray-400">© {new Date().getFullYear()} HowsTheRent. Hệ thống Quản lý Nhà trọ.</p>
        </div>
      </footer>
    </div>
  )
}
