package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.enums.InvoiceStatus;
import chez1s.htrbackend.domain.enums.MaintenanceStatus;
import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.repository.InvoiceRepository;
import chez1s.htrbackend.domain.repository.MaintenanceRequestRepository;
import chez1s.htrbackend.domain.repository.RoomRepository;
import chez1s.htrbackend.service.PropertyService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.TextStyle;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final PropertyService propertyService;
    private final RoomRepository roomRepository;
    private final InvoiceRepository invoiceRepository;
    private final MaintenanceRequestRepository maintenanceRepository;

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Map<String, Object>> getDashboard(Authentication auth) {
        UUID ownerId = (UUID) auth.getPrincipal();
        var properties = propertyService.listByOwner(ownerId);

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

        long pendingInvoices = invoiceRepository.countByStatus(InvoiceStatus.PENDING);
        long overdueInvoices = invoiceRepository.countByStatus(InvoiceStatus.OVERDUE);
        long openMaintenance = maintenanceRepository.countByStatus(MaintenanceStatus.OPEN);
        long inProgressMaintenance = maintenanceRepository.countByStatus(MaintenanceStatus.IN_PROGRESS);
        BigDecimal revenueThisMonth = invoiceRepository.sumPaidAmountByMonth(
                LocalDate.now().withDayOfMonth(1));

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
        return ResponseEntity.ok(dashboard);
    }

    @GetMapping("/revenue")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<Map<String, Object>>> getMonthlyRevenue(
            Authentication auth,
            @RequestParam(defaultValue = "12") int months) {
        UUID ownerId = (UUID) auth.getPrincipal();
        var properties = propertyService.listByOwner(ownerId);
        List<Map<String, Object>> result = new ArrayList<>();
        LocalDate today = LocalDate.now();
        for (int i = months - 1; i >= 0; i--) {
            LocalDate month = today.minusMonths(i);
            BigDecimal amount = invoiceRepository.sumPaidAmountByMonthAndPropertyIds(
                month, properties.stream().map(p -> p.getId()).toList());
            Map<String, Object> entry = new LinkedHashMap<>();
            entry.put("month", month.toString());
            entry.put("label", month.getMonth().getDisplayName(TextStyle.SHORT, Locale.forLanguageTag("vi")));
            entry.put("amount", amount);
            result.add(entry);
        }
        return ResponseEntity.ok(result);
    }
}
