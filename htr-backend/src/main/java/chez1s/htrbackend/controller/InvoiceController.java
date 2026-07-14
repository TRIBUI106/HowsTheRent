package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Invoice;
import chez1s.htrbackend.domain.enums.InvoiceStatus;
import chez1s.htrbackend.dto.response.InvoiceGenerationResponse;
import chez1s.htrbackend.dto.response.InvoiceResponse;
import chez1s.htrbackend.dto.response.PageResponse;
import chez1s.htrbackend.service.InvoiceService;
import chez1s.htrbackend.service.PayOSService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.YearMonth;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/invoices")
@RequiredArgsConstructor
public class InvoiceController {

    private final InvoiceService invoiceService;
    private final PayOSService payOSService;

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<PageResponse<InvoiceResponse>> listAll(
            Authentication auth,
            @RequestParam(required = false) InvoiceStatus status,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        UUID ownerId = (UUID) auth.getPrincipal();
        return ResponseEntity.ok(invoiceService.listAllByOwner(ownerId, pageable, status));
    }

    @GetMapping("/mine")
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<PageResponse<InvoiceResponse>> listMine(
            Authentication auth,
            @PageableDefault(size = 20, sort = "invoiceMonth", direction = Sort.Direction.DESC) Pageable pageable) {
        UUID tenantId = (UUID) auth.getPrincipal();
        return ResponseEntity.ok(invoiceService.listByTenant(tenantId, pageable));
    }

    @GetMapping("/{id}")
    public ResponseEntity<InvoiceResponse> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(InvoiceResponse.from(invoiceService.getById(id)));
    }

    @PostMapping("/generate")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<InvoiceGenerationResponse> generateAll(@RequestParam int year, @RequestParam int month) {
        YearMonth targetMonth = YearMonth.of(year, month);
        return ResponseEntity.ok(invoiceService.generateAllForMonth(targetMonth));
    }

    @PostMapping("/{id}/pay-cash")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<InvoiceResponse> markPaidCash(@PathVariable UUID id) {
        return ResponseEntity.ok(InvoiceResponse.from(invoiceService.markPaidCash(id)));
    }

    @PostMapping("/{id}/request-cash")
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<InvoiceResponse> requestCash(Authentication auth, @PathVariable UUID id) {
        return ResponseEntity.ok(InvoiceResponse.from(invoiceService.requestCashPayment(id, (UUID) auth.getPrincipal())));
    }

    @PostMapping("/{id}/pay-online")
    @PreAuthorize("hasAnyRole('ADMIN','TENANT')")
    public ResponseEntity<Map<String, String>> createPaymentLink(Authentication auth, @PathVariable UUID id) {
        Invoice invoice = invoiceService.getById(id);
        boolean isAdmin = auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"));
        if (!isAdmin && !invoice.getContract().getTenant().getId().equals((UUID) auth.getPrincipal())) {
            throw new chez1s.htrbackend.exception.BusinessException("Bạn không có quyền thanh toán hóa đơn này");
        }
        String checkoutUrl = payOSService.createPaymentLink(invoice);
        return ResponseEntity.ok(Map.of("checkoutUrl", checkoutUrl));
    }
}
