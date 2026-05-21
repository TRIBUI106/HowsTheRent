package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Invoice;
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
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        return ResponseEntity.ok(invoiceService.listAll(pageable));
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
    public ResponseEntity<Map<String, String>> generateAll(@RequestParam int year, @RequestParam int month) {
        YearMonth targetMonth = YearMonth.of(year, month);
        invoiceService.generateAllForMonth(targetMonth);
        return ResponseEntity.ok(Map.of("message", "Invoices generated for " + targetMonth));
    }

    @PostMapping("/{id}/pay-cash")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<InvoiceResponse> markPaidCash(@PathVariable UUID id) {
        return ResponseEntity.ok(InvoiceResponse.from(invoiceService.markPaidCash(id)));
    }

    @PostMapping("/{id}/pay-online")
    @PreAuthorize("hasAnyRole('ADMIN','TENANT')")
    public ResponseEntity<Map<String, String>> createPaymentLink(@PathVariable UUID id) {
        Invoice invoice = invoiceService.getById(id);
        String checkoutUrl = payOSService.createPaymentLink(invoice);
        return ResponseEntity.ok(Map.of("checkoutUrl", checkoutUrl));
    }
}
