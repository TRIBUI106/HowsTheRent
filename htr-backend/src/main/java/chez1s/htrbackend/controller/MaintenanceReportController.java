package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.request.CreateMaintenanceReviewRequest;
import chez1s.htrbackend.dto.request.CreateOrUpdateSlaRuleRequest;
import chez1s.htrbackend.dto.response.*;
import chez1s.htrbackend.service.MaintenanceReportService;
import chez1s.htrbackend.service.SlaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/maintenance")
@RequiredArgsConstructor
public class MaintenanceReportController {

    private final MaintenanceReportService reportService;
    private final SlaService slaService;

    @GetMapping("/reports/summary")
    @PreAuthorize("hasAnyRole('ADMIN', 'LANDLORD')")
    public ResponseEntity<MaintenanceReportResponse> getSummary(Authentication auth) {
        UUID ownerId = (UUID) auth.getPrincipal();
        return ResponseEntity.ok(reportService.getSummary(ownerId));
    }

    @GetMapping("/reports/technician-performance")
    @PreAuthorize("hasAnyRole('ADMIN', 'LANDLORD')")
    public ResponseEntity<List<TechnicianPerformanceDto>> getTechnicianPerformance() {
        return ResponseEntity.ok(reportService.listTechnicianPerformance());
    }

    @GetMapping("/reports/export")
    @PreAuthorize("hasAnyRole('ADMIN', 'LANDLORD')")
    public ResponseEntity<byte[]> exportReportCsv(Authentication auth) {
        UUID ownerId = (UUID) auth.getPrincipal();
        MaintenanceReportResponse summary = reportService.getSummary(ownerId);

        StringBuilder csv = new StringBuilder();
        csv.append("BAO CAO TONG QUAN BAO TRI\n");
        csv.append("Ngay xuat: ").append(LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss"))).append("\n\n");
        csv.append("CHIPHI / THONG KE CHUNG\n");
        csv.append("Tong so phieu,Hoan tat,Dang mo,Dang xu ly,Qua han SLA,Thoi gian xu ly TB (gio)\n");
        csv.append(String.format("%d,%d,%d,%d,%d,%.1f\n\n",
                summary.getTotalTickets(), summary.getCompletedTickets(), summary.getOpenTickets(),
                summary.getInProgressTickets(), summary.getOverdueSlaTickets(), summary.getAvgResolutionHours()));

        csv.append("THEO DANH MUC\n");
        csv.append("Danh muc,So luong\n");
        for (Map.Entry<String, Long> entry : summary.getByCategory().entrySet()) {
            csv.append(entry.getKey()).append(",").append(entry.getValue()).append("\n");
        }
        csv.append("\n");

        csv.append("HIEU SUAT KY THUAT VIEN\n");
        csv.append("ID KTV,Ten KTV,Chuyen mon,Đa giao,Đang lam,Hoan tat,Qua han SLA,Đanh gia TB (sao),So luot đanh gia\n");
        for (TechnicianPerformanceDto tech : summary.getTechnicianPerformance()) {
            csv.append(String.format("%s,\"%s\",\"%s\",%d,%d,%d,%d,%.1f,%d\n",
                    tech.getTechnicianId(), tech.getTechnicianName(), tech.getSpecialties(),
                    tech.getAssignedCount(), tech.getActiveCount(), tech.getCompletedCount(),
                    tech.getOverdueSlaCount(), tech.getAvgRatingStars(), tech.getTotalReviews()));
        }

        byte[] bytes = csv.toString().getBytes(StandardCharsets.UTF_8);
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.parseMediaType("text/csv; charset=UTF-8"));
        headers.setContentDispositionFormData("attachment", "maintenance_report_" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss")) + ".csv");

        return new ResponseEntity<>(bytes, headers, HttpStatus.OK);
    }

    @PostMapping("/{id}/reviews")
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<MaintenanceReviewResponse> createReview(
            @PathVariable UUID id,
            @Valid @RequestBody CreateMaintenanceReviewRequest req,
            Authentication auth) {
        UUID tenantId = (UUID) auth.getPrincipal();
        MaintenanceReviewResponse res = reportService.createReview(tenantId, id, req);
        return ResponseEntity.status(HttpStatus.CREATED).body(res);
    }

    @GetMapping("/reviews/technician/{techId}")
    public ResponseEntity<List<MaintenanceReviewResponse>> getTechnicianReviews(@PathVariable UUID techId) {
        return ResponseEntity.ok(reportService.listReviewsByTechnician(techId));
    }

    @GetMapping("/reviews")
    public ResponseEntity<List<MaintenanceReviewResponse>> getAllReviews() {
        return ResponseEntity.ok(reportService.listAllReviews());
    }

    @GetMapping("/sla-rules")
    public ResponseEntity<List<SlaRuleResponse>> getAllSlaRules() {
        return ResponseEntity.ok(slaService.listAllRules());
    }

    @PostMapping("/sla-rules")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<SlaRuleResponse> createOrUpdateSlaRule(@Valid @RequestBody CreateOrUpdateSlaRuleRequest req) {
        return ResponseEntity.ok(slaService.createOrUpdateRule(req));
    }

    @DeleteMapping("/sla-rules/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deleteSlaRule(@PathVariable UUID id) {
        slaService.deleteRule(id);
        return ResponseEntity.noContent().build();
    }
}
