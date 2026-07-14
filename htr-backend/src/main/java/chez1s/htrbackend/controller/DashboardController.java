package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.enums.InvoiceStatus;
import chez1s.htrbackend.domain.enums.MaintenancePriority;
import chez1s.htrbackend.domain.enums.MaintenanceStatus;
import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.enums.UserRole;
import chez1s.htrbackend.domain.repository.InvoiceRepository;
import chez1s.htrbackend.domain.repository.MaintenanceRequestRepository;
import chez1s.htrbackend.domain.repository.RoomRepository;
import chez1s.htrbackend.domain.repository.UserRepository;
import chez1s.htrbackend.service.PropertyService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.TextStyle;
import java.util.*;

@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final PropertyService propertyService;
    private final RoomRepository roomRepository;
    private final InvoiceRepository invoiceRepository;
    private final MaintenanceRequestRepository maintenanceRepository;
    private final UserRepository userRepository;

    private boolean isAdmin(UUID userId) {
        return userRepository.findById(userId)
                .map(u -> u.getRole() == UserRole.ADMIN)
                .orElse(false);
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getDashboard(Authentication auth) {
        UUID ownerId = (UUID) auth.getPrincipal();
        boolean admin = isAdmin(ownerId);
        var properties = admin ? propertyService.listAll() : propertyService.listByOwner(ownerId);
        var propertyIds = properties.stream().map(p -> p.getId()).toList();

        long totalRooms = 0;
        long occupiedRooms = 0;
        long emptyRooms = 0;
        for (var prop : properties) {
            UUID pid = prop.getId();
            totalRooms += roomRepository.countByPropertyIdAndStatus(pid, RoomStatus.EMPTY)
                    + roomRepository.countByPropertyIdAndStatus(pid, RoomStatus.RENTED)
                    + roomRepository.countByPropertyIdAndStatus(pid, RoomStatus.MAINTENANCE);
            occupiedRooms += roomRepository.countByPropertyIdAndStatus(pid, RoomStatus.RENTED);
            emptyRooms += roomRepository.countByPropertyIdAndStatus(pid, RoomStatus.EMPTY);
        }

        long pendingInvoices = admin
                ? invoiceRepository.countByStatus(InvoiceStatus.PENDING)
                : invoiceRepository.countByRoomPropertyOwnerIdAndStatus(ownerId, InvoiceStatus.PENDING);
        long overdueInvoices = admin
                ? invoiceRepository.countByStatus(InvoiceStatus.OVERDUE)
                : invoiceRepository.countByRoomPropertyOwnerIdAndStatus(ownerId, InvoiceStatus.OVERDUE);

        List<MaintenanceStatus> inProgressStatuses = List.of(MaintenanceStatus.IN_PROGRESS, MaintenanceStatus.PENDING_PAYMENT, MaintenanceStatus.PENDING_REVIEW);
        List<MaintenanceStatus> closedStatuses = List.of(MaintenanceStatus.DONE, MaintenanceStatus.COMPLETED, MaintenanceStatus.CANCELLED);

        long openMaintenance = admin
                ? maintenanceRepository.countByStatusNotIn(closedStatuses)
                : maintenanceRepository.countByRoomPropertyOwnerIdAndStatusNotIn(ownerId, closedStatuses);
        long inProgressMaintenance = admin
                ? maintenanceRepository.countByStatusIn(inProgressStatuses)
                : maintenanceRepository.countByRoomPropertyOwnerIdAndStatusIn(ownerId, inProgressStatuses);
        long urgentMaintenance = admin
                ? maintenanceRepository.countByPriorityInAndStatusNotIn(List.of(MaintenancePriority.URGENT), closedStatuses)
                : maintenanceRepository.countByRoomPropertyOwnerIdAndPriorityInAndStatusNotIn(ownerId, List.of(MaintenancePriority.URGENT), closedStatuses);
        long overdueUrgentMaintenance = admin
                ? maintenanceRepository.countByPriorityAndIsOverdueSlaTrueAndStatusNotIn(MaintenancePriority.URGENT, closedStatuses)
                : maintenanceRepository.countByRoomPropertyOwnerIdAndPriorityAndIsOverdueSlaTrueAndStatusNotIn(ownerId, MaintenancePriority.URGENT, closedStatuses);

        BigDecimal revenueThisMonth = propertyIds.isEmpty()
                ? BigDecimal.ZERO
                : invoiceRepository.sumPaidAmountByMonthAndPropertyIds(LocalDate.now().withDayOfMonth(1), propertyIds);

        Map<String, Object> dashboard = new LinkedHashMap<>();
        dashboard.put("totalProperties", properties.size());
        dashboard.put("totalRooms", totalRooms);
        dashboard.put("occupiedRooms", occupiedRooms);
        dashboard.put("emptyRooms", emptyRooms);
        dashboard.put("occupancyRate", totalRooms > 0 ? (double) occupiedRooms / totalRooms * 100 : 0);
        dashboard.put("pendingInvoices", pendingInvoices);
        dashboard.put("overdueInvoices", overdueInvoices);
        dashboard.put("revenueThisMonth", revenueThisMonth);
        dashboard.put("openMaintenance", openMaintenance);
        dashboard.put("inProgressMaintenance", inProgressMaintenance);
        dashboard.put("urgentMaintenance", urgentMaintenance);
        dashboard.put("overdueUrgentMaintenance", overdueUrgentMaintenance);
        return ResponseEntity.ok(dashboard);
    }

    @GetMapping("/revenue")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<Map<String, Object>>> getMonthlyRevenue(
            Authentication auth,
            @RequestParam(defaultValue = "12") int months) {
        UUID ownerId = (UUID) auth.getPrincipal();
        boolean admin = isAdmin(ownerId);
        var properties = admin ? propertyService.listAll() : propertyService.listByOwner(ownerId);
        var propertyIds = properties.stream().map(p -> p.getId()).toList();
        List<Map<String, Object>> result = new ArrayList<>();
        LocalDate today = LocalDate.now();
        for (int i = months - 1; i >= 0; i--) {
            LocalDate month = today.minusMonths(i);
            BigDecimal amount = propertyIds.isEmpty()
                    ? BigDecimal.ZERO
                    : invoiceRepository.sumPaidAmountByMonthAndPropertyIds(month, propertyIds);
            Map<String, Object> entry = new LinkedHashMap<>();
            entry.put("month", month.toString());
            entry.put("label", month.getMonth().getDisplayName(TextStyle.SHORT, Locale.forLanguageTag("vi")));
            entry.put("amount", amount);
            result.add(entry);
        }
        return ResponseEntity.ok(result);
    }
}
