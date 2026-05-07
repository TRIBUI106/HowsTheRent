package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Invoice;
import chez1s.htrbackend.security.JwtTokenProvider;
import chez1s.htrbackend.service.InvoiceService;
import chez1s.htrbackend.service.PayOSService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
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
    private final JwtTokenProvider jwtTokenProvider;

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<Invoice>> listAll() {
        return ResponseEntity.ok(invoiceService.listAll());
    }

    @GetMapping("/mine")
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<List<Invoice>> listMine(@RequestHeader("Authorization") String authHeader) {
        UUID tenantId = jwtTokenProvider.getUserId(authHeader.replace("Bearer ", ""));
        return ResponseEntity.ok(invoiceService.listByTenant(tenantId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Invoice> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(invoiceService.getById(id));
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
    public ResponseEntity<Invoice> markPaidCash(@PathVariable UUID id) {
        return ResponseEntity.ok(invoiceService.markPaidCash(id));
    }

    @PostMapping("/{id}/pay-online")
    @PreAuthorize("hasAnyRole('ADMIN','TENANT')")
    public ResponseEntity<Map<String, String>> createPaymentLink(@PathVariable UUID id) {
        Invoice invoice = invoiceService.getById(id);
        String checkoutUrl = payOSService.createPaymentLink(invoice);
        return ResponseEntity.ok(Map.of("checkoutUrl", checkoutUrl));
    }
}
