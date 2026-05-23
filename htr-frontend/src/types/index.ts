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
}

export interface VehicleConfig {
  id: string
  property: Property
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

export interface MaintenanceRequest {
  id: string
  room: Room
  tenant: User
  title: string
  description?: string
  images: string[]
  status: 'OPEN' | 'IN_PROGRESS' | 'DONE'
  assignedTo?: User
  resolvedAt?: string
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
