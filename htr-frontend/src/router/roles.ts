// Role sets shared between the admin route guards (adminRoutes.tsx) and the
// sidebar nav filtering (navItems.ts) so the two can't drift out of sync.
export const ADMIN_ROLES = ['ADMIN', 'PLATFORM_ADMIN', 'LANDLORD_ADMIN']
export const PLATFORM_ADMIN_ROLES = ['ADMIN', 'PLATFORM_ADMIN']
