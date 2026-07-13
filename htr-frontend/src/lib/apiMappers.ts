import type { Contract, Invoice, MaintenanceRequest, Page, Room, User } from '@/types'

type PagedData<T> = T[] | Page<T> | { content?: T[] } | null | undefined

type FlatRoomLike = {
  id?: string
  roomId?: string
  roomNumber?: string
  property?: Room['property']
  propertyName?: string
  propertyId?: string
  floor?: number
  areaM2?: number
  maxPeople?: number
  rentOverride?: number
  images?: string[]
  createdAt?: string
  updatedAt?: string
  status?: string
}

type FlatInvoiceLike = Partial<Omit<Invoice, 'room' | 'contract' | 'status'>> & {
  room?: Room
  contract?: Contract
  roomId?: string
  roomNumber?: string
  contractId?: string
  status?: Invoice['status']
}

type FlatMaintenanceLike = Partial<Omit<MaintenanceRequest, 'room' | 'tenant' | 'status'>> & {
  room?: Room
  tenant?: User
  roomId?: string
  roomNumber?: string
  propertyId?: string
  tenantId?: string
  tenantName?: string
  assignedToId?: string
  assignedToName?: string
  status?: MaintenanceRequest['status']
  priority?: MaintenanceRequest['priority']
  category?: MaintenanceRequest['category']
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
}

type FlatContractLike = Partial<Omit<Contract, 'room' | 'tenant' | 'status'>> & {
  room?: Room
  tenant?: User
  roomId?: string
  roomNumber?: string
  propertyId?: string
  propertyName?: string
  tenantId?: string
  tenantName?: string
  tenantEmail?: string
  status?: Contract['status']
}

function toRoomStatus(status?: string): Room['status'] {
  if (status === 'RENTED' || status === 'MAINTENANCE') return status
  return 'EMPTY'
}

function normalizeRoom(roomLike: FlatRoomLike): Room {
  const propertyName = roomLike.property?.name ?? roomLike.propertyName ?? ''
  const propertyId = roomLike.property?.id ?? roomLike.propertyId ?? ''

  return {
    id: roomLike.id ?? roomLike.roomId ?? '',
    property: roomLike.property ?? undefined,
    propertyId,
    propertyName,
    roomNumber: roomLike.roomNumber ?? '',
    floor: roomLike.floor,
    areaM2: roomLike.areaM2,
    maxPeople: roomLike.maxPeople ?? 0,
    rentOverride: roomLike.rentOverride,
    status: toRoomStatus(roomLike.status),
    images: roomLike.images ?? [],
    createdAt: roomLike.createdAt ?? '',
    updatedAt: roomLike.updatedAt ?? '',
  }
}

function emptyUser(overrides: Partial<User>): User {
  return {
    id: overrides.id ?? '',
    fullName: overrides.fullName ?? '',
    email: overrides.email ?? '',
    phone: overrides.phone,
    role: overrides.role ?? 'TENANT',
    avatarUrl: overrides.avatarUrl,
    active: overrides.active ?? true,
  }
}

export function extractPageContent<T>(data: PagedData<T>): T[] {
  if (Array.isArray(data)) return data
  return data?.content ?? []
}

export function getRoomPropertyName(room?: Partial<Room> | null): string {
  return room?.property?.name ?? room?.propertyName ?? ''
}

export function normalizeInvoice(invoiceLike: FlatInvoiceLike): Invoice {
  if (invoiceLike.room && invoiceLike.contract) {
    return invoiceLike as Invoice
  }

  const room = normalizeRoom(invoiceLike)

  return {
    id: invoiceLike.id ?? '',
    room,
    contract: invoiceLike.contract ?? {
      id: invoiceLike.contractId ?? '',
      room,
      tenant: emptyUser({}),
      moveInDate: '',
      moveOutDate: undefined,
      status: 'ACTIVE',
      depositAmount: 0,
      notes: undefined,
      fileUrl: undefined,
      createdAt: '',
      updatedAt: '',
    },
    invoiceMonth: invoiceLike.invoiceMonth ?? '',
    proRata: invoiceLike.proRata ?? false,
    daysUsed: invoiceLike.daysUsed,
    rentAmount: invoiceLike.rentAmount ?? 0,
    elecAmount: invoiceLike.elecAmount ?? 0,
    waterAmount: invoiceLike.waterAmount ?? 0,
    vehicleAmount: invoiceLike.vehicleAmount ?? 0,
    serviceAmount: invoiceLike.serviceAmount ?? 0,
    totalAmount: invoiceLike.totalAmount ?? 0,
    status: invoiceLike.status ?? 'PENDING',
    paymentMethod: invoiceLike.paymentMethod,
    paymentLinkId: invoiceLike.paymentLinkId,
    checkoutUrl: invoiceLike.checkoutUrl,
    transactionId: invoiceLike.transactionId,
    dueDate: invoiceLike.dueDate ?? '',
    paidAt: invoiceLike.paidAt,
  }
}

export function normalizeMaintenanceRequest(requestLike: FlatMaintenanceLike): MaintenanceRequest {
  if (requestLike.room && requestLike.tenant) {
    return requestLike as MaintenanceRequest
  }

  return {
    id: requestLike.id ?? '',
    room: requestLike.room ?? normalizeRoom(requestLike),
    tenant: requestLike.tenant ?? emptyUser({
      id: requestLike.tenantId ?? '',
      fullName: requestLike.tenantName ?? '',
      role: 'TENANT',
    }),
    title: requestLike.title ?? '',
    description: requestLike.description,
    images: requestLike.images ?? [],
    status: requestLike.status ?? 'OPEN',
    priority: requestLike.priority ?? 'NORMAL',
    category: requestLike.category ?? 'OTHER',
    assignedTo: requestLike.assignedTo ?? (
      requestLike.assignedToId || requestLike.assignedToName
        ? emptyUser({
            id: requestLike.assignedToId ?? '',
            fullName: requestLike.assignedToName ?? '',
            role: 'TECHNICIAN',
          })
        : undefined
    ),
    resolvedAt: requestLike.resolvedAt,
    expectedResolvedAt: requestLike.expectedResolvedAt,
    ticketCode: requestLike.ticketCode,
    preferredTimeSlots: requestLike.preferredTimeSlots ?? [],
    confirmedTimeSlot: requestLike.confirmedTimeSlot,
    confirmSlotByTenant: requestLike.confirmSlotByTenant,
    completionImages: requestLike.completionImages ?? [],
    attachmentVideo: requestLike.attachmentVideo,
    startedAt: requestLike.startedAt,
    isOverdueSla: requestLike.isOverdueSla,
    isComplained: requestLike.isComplained,
    complainReason: requestLike.complainReason,
    cancelReason: requestLike.cancelReason,
    materialCost: requestLike.materialCost,
    createdAt: requestLike.createdAt ?? '',
    updatedAt: requestLike.updatedAt ?? '',
  }
}

export function normalizeContract(contractLike: FlatContractLike): Contract {
  if (contractLike.room && contractLike.tenant) {
    return contractLike as Contract
  }

  const room = normalizeRoom(contractLike)

  return {
    id: contractLike.id ?? '',
    room,
    tenant: contractLike.tenant ?? emptyUser({
      id: contractLike.tenantId ?? '',
      fullName: contractLike.tenantName ?? '',
      email: contractLike.tenantEmail ?? '',
      role: 'TENANT',
    }),
    moveInDate: contractLike.moveInDate ?? '',
    moveOutDate: contractLike.moveOutDate,
    status: contractLike.status ?? 'ACTIVE',
    depositAmount: contractLike.depositAmount ?? 0,
    notes: contractLike.notes,
    fileUrl: contractLike.fileUrl,
    createdAt: contractLike.createdAt ?? '',
    updatedAt: contractLike.updatedAt ?? '',
  }
}
