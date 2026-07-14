export interface Page<T> {
  content: T[]
  totalElements: number
  totalPages: number
  number: number
  size: number
}

export interface User {
  id: string
  fullName: string
  email: string
  phone?: string
  role: 'ADMIN' | 'TENANT' | 'TECHNICIAN'
  avatarUrl?: string
  active: boolean
  specialties?: string
  activeTicketCount?: number
  avgRating?: number
}

export interface AuthResponse {
  user: User
}

export interface PropertyType {
  id: string
  code: string
  name: string
  description?: string
  active: boolean
}

export interface Property {
  id: string
  ownerId: string
  ownerName: string
  name: string
  address: string
  propertyTypeId: string
  propertyTypeCode: string
  propertyTypeName: string
  description?: string
  floorCount?: number | null
  roomCount?: number | null
  createdAt: string
  updatedAt: string
}

export interface Room {
  id: string
  property?: Property
  propertyId: string
  propertyName: string
  roomNumber: string
  floor?: number
  areaM2?: number
  maxPeople: number
  rentOverride?: number
  status: 'EMPTY' | 'RENTED' | 'MAINTENANCE'
  images: string[]
  createdAt: string
  updatedAt: string
}

export interface FeeConfig {
  id: string
  property: Property
  rentDefault: number
  elecPrice: number
  waterMode: 'PERSON' | 'CUBIC'
  waterPrice: number
  serviceFee: number
  vehicleProRata: boolean
  serviceProRata: boolean
  motorbikePrice: number
  carPrice: number
  bicyclePrice: number
}

export interface Contract {
  id: string
  room: Room
  tenant: User
  moveInDate: string
  moveOutDate?: string
  status: 'ACTIVE' | 'TERMINATED' | 'EXPIRED'
  depositAmount: number
  notes?: string
  fileUrl?: string
  createdAt: string
  updatedAt: string
}

export interface MeterReading {
  id: string
  room: Room
  readingMonth: string
  elecOld: number
  elecNew: number
  waterOld?: number
  waterNew?: number
  source?: 'MANUAL' | 'HUNONIC'
  recordedBy: User
  recordedAt: string
}

export interface VehicleRecord {
  id: string
  room: Room
  recordMonth: string
  motorbikeCount: number
  carCount: number
  bicycleCount: number
}

export interface Invoice {
  id: string
  room: Room
  contract: Contract
  invoiceMonth: string
  proRata: boolean
  daysUsed?: number
  rentAmount: number
  elecAmount: number
  waterAmount: number
  vehicleAmount: number
  serviceAmount: number
  totalAmount: number
  status: 'PENDING' | 'PAID' | 'OVERDUE'
  paymentMethod?: 'CASH' | 'PAYOS'
  paymentLinkId?: string
  checkoutUrl?: string
  transactionId?: string
  dueDate: string
  paidAt?: string
}

export interface MaintenanceMaterial {
  id: string
  requestId: string
  name: string
  quantity: number
  unit: string
  unitPrice: number
  totalPrice: number
  isFreeInContract?: boolean
  createdAt?: string
}

export interface MaintenanceNote {
  id: string
  requestId: string
  actorId?: string
  actorName?: string
  status?: string
  note: string
  createdAt: string
}

export interface MaintenanceRequest {
  id: string
  room: Room
  tenant: User
  title: string
  description?: string
  images: string[]
  status: 'OPEN' | 'ASSIGNED' | 'IN_PROGRESS' | 'PENDING_PAYMENT' | 'PENDING_REVIEW' | 'COMPLETED' | 'CANCELLED' | 'DONE'
  priority?: 'NORMAL' | 'HIGH' | 'URGENT'
  category?: 'ELECTRIC' | 'PLUMBING' | 'AIR_CONDITIONER' | 'FURNITURE' | 'OTHER'
  assignedTo?: User
  resolvedAt?: string
  expectedResolvedAt?: string
  ticketCode?: string
  preferredTimeSlots?: string[]
  confirmedTimeSlot?: string
  confirmSlotByTenant?: boolean
  completionImages?: string[]
  attachmentVideo?: string
  startedAt?: string
  isOverdueSla?: boolean
  isComplained?: boolean
  complainReason?: string
  cancelReason?: string
  materialCost?: number
  materialPaidAt?: string
  createdAt: string
  updatedAt: string
}


export interface Notification {
  id: string
  user: User
  title: string
  body: string
  type: string
  refId?: string
  read: boolean
  createdAt: string
}

export interface Dashboard {
  totalProperties: number
  totalRooms: number
  occupiedRooms: number
  emptyRooms: number
  occupancyRate: number
  pendingInvoices: number
  overdueInvoices: number
  revenueThisMonth: number
  openMaintenance: number
  inProgressMaintenance: number
  urgentMaintenance?: number
  overdueUrgentMaintenance?: number
}

export interface RoomTimelineEntry {
  type: 'CONTRACT_MOVE_IN' | 'CONTRACT_MOVE_OUT' | 'INVOICE' | 'MAINTENANCE' | 'METER_READING' | 'NOTE'
  date: string
  title: string
  description: string
  metadata: Record<string, unknown>
}

export interface RoomNote {
  id: string
  authorName: string
  authorEmail: string
  content: string
  createdAt: string
}

export interface AuditLog {
  id: string
  action: string
  entityType?: string
  entityId?: string
  userId?: string
  userEmail?: string
  description?: string
  requestMethod?: string
  requestPath?: string
  ipAddress?: string
  createdAt: string
}

export interface SlaRule {
  id: string
  priority?: 'NORMAL' | 'HIGH' | 'URGENT'
  category?: 'ELECTRIC' | 'PLUMBING' | 'AIR_CONDITIONER' | 'FURNITURE' | 'OTHER'
  maxHours: number
  updatedAt?: string
}

export interface TechnicianPerformance {
  technicianId: string
  technicianName: string
  specialties: string
  assignedCount: number
  activeCount: number
  completedCount: number
  overdueSlaCount: number
  avgRatingStars: number
  totalReviews: number
}

export interface MaintenanceReportSummary {
  totalTickets: number
  completedTickets: number
  openTickets: number
  inProgressTickets: number
  overdueSlaTickets: number
  avgResolutionHours: number
  byCategory: Record<string, number>
  byPriority: Record<string, number>
  byStatus: Record<string, number>
  technicianPerformance: TechnicianPerformance[]
}

export interface MaintenanceReview {
  id: string
  requestId: string
  requestTitle?: string
  technicianId?: string
  technicianName?: string
  tenantId?: string
  tenantName?: string
  ratingStars: number
  comment?: string
  createdAt?: string
}
