package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Invoice;
import chez1s.htrbackend.domain.enums.InvoiceStatus;
import chez1s.htrbackend.dto.response.InvoiceGenerationResponse;
import chez1s.htrbackend.dto.response.InvoiceResponse;
import chez1s.htrbackend.dto.response.PageResponse;
import chez1s.htrbackend.security.ActorContext;
import chez1s.htrbackend.security.OwnerScopeResolver;
import chez1s.htrbackend.service.InvoicePdfService;
import chez1s.htrbackend.service.InvoiceService;
import chez1s.htrbackend.service.PayOSService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.YearMonth;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/invoices")
@RequiredArgsConstructor
public class InvoiceController {

    private final InvoiceService invoiceService;
    private final PayOSService payOSService;
    private final InvoicePdfService invoicePdfService;
    private final OwnerScopeResolver ownerScopeResolver;

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<PageResponse<InvoiceResponse>> listAll(
            Authentication authentication,
            @RequestParam(required = false) InvoiceStatus status,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        ActorContext actor = ActorContext.require(authentication);
        return ResponseEntity.ok(actor.isPlatformAdmin()
                ? invoiceService.listAll(pageable, status)
                : invoiceService.listAllByOwner(ownerScopeResolver.requireOwnerId(actor), pageable, status));
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
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN','TENANT','TECHNICIAN')")
    public ResponseEntity<InvoiceResponse> getById(Authentication authentication, @PathVariable UUID id) {
        return ResponseEntity.ok(InvoiceResponse.from(requireInvoiceAccess(ActorContext.require(authentication), id)));
    }

    @PostMapping("/generate")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<InvoiceGenerationResponse> generateAll(Authentication authentication,
                                                                 @RequestParam int year,
                                                                 @RequestParam int month) {
        ActorContext actor = ActorContext.require(authentication);
        YearMonth targetMonth = YearMonth.of(year, month);
        return ResponseEntity.ok(actor.isPlatformAdmin()
                ? invoiceService.generateAllForMonth(targetMonth)
                : invoiceService.generateAllForMonthByOwner(targetMonth, ownerScopeResolver.requireOwnerId(actor)));
    }

    @PostMapping("/{id}/pay-cash")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<InvoiceResponse> markPaidCash(Authentication authentication, @PathVariable UUID id) {
        requireInvoiceAccess(ActorContext.require(authentication), id);
        return ResponseEntity.ok(InvoiceResponse.from(invoiceService.markPaidCash(id)));
    }

    @PostMapping("/{id}/request-cash")
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<InvoiceResponse> requestCash(Authentication auth, @PathVariable UUID id) {
        return ResponseEntity.ok(InvoiceResponse.from(invoiceService.requestCashPayment(id, (UUID) auth.getPrincipal())));
    }

    @PostMapping("/{id}/pay-online")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN','TENANT')")
    public ResponseEntity<Map<String, String>> createPaymentLink(Authentication authentication, @PathVariable UUID id) {
        Invoice invoice = requireInvoiceAccess(ActorContext.require(authentication), id);
        String checkoutUrl = payOSService.createPaymentLink(invoice);
        return ResponseEntity.ok(Map.of("checkoutUrl", checkoutUrl));
    }

    // PayOS confirms payment to us only via its async webhook (PayOSService.handleWebhook) — the
    // browser redirect back from checkout (returnUrl) is purely a UI navigation and carries no
    // guarantee the webhook has already landed and been processed. A tenant who lands back on the
    // invoices list within that race window sees stale PENDING/OVERDUE and gets prompted to pay
    // again; clicking pay again reuses the existing PaymentIntent's checkoutUrl (see
    // PayOSService.createPaymentLink), so PayOS itself then correctly reports the order as already
    // paid. This endpoint actively closes that window by querying PayOS's own status API
    // (PayOSService.reconcile, previously wired up but never called from anywhere) instead of
    // passively waiting on the webhook — called from the tenant success page right after PayOS
    // redirects back, before the invoices list is shown.
    @PostMapping("/{id}/reconcile-payment")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN','TENANT')")
    public ResponseEntity<InvoiceResponse> reconcilePayment(Authentication authentication, @PathVariable UUID id) {
        Invoice invoice = requireInvoiceAccess(ActorContext.require(authentication), id);
        if (invoice.getStatus() != InvoiceStatus.PAID && invoice.getPaymentLinkId() != null) {
            payOSService.reconcile(invoice.getPaymentLinkId());
            invoice = requireInvoiceAccess(ActorContext.require(authentication), id);
        }
        return ResponseEntity.ok(InvoiceResponse.from(invoice));
    }

    // Available for any invoice status, not just PAID — a tenant can also download it as a plain
    // bill before paying; once PAID, the same layout doubles as the receipt (see
    // InvoicePdfService). @Transactional here (not just on the service) because
    // requireInvoiceAccess's PLATFORM_ADMIN branch never touches contract.tenant/room.property —
    // only the owner/tenant-scoping branches incidentally do — so without a transaction spanning
    // both the access check and generate(), a platform admin's request would hit
    // LazyInitializationException while a landlord admin's or tenant's request would not.
    @GetMapping("/{id}/pdf")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN','TENANT')")
    @Transactional(readOnly = true)
    public ResponseEntity<byte[]> downloadReceipt(Authentication authentication, @PathVariable UUID id) {
        Invoice invoice = requireInvoiceAccess(ActorContext.require(authentication), id);
        byte[] pdf = invoicePdfService.generate(invoice);
        String filename = "hoa-don-" + invoice.getInvoiceMonth() + ".pdf";
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + filename + "\"")
                .body(pdf);
    }

    private Invoice requireInvoiceAccess(ActorContext actor, UUID invoiceId) {
        if (actor.isPlatformAdmin()) {
            return invoiceService.getById(invoiceId);
        }
        if (actor.isLandlordAdmin()) {
            return invoiceService.getByIdForOwner(invoiceId, ownerScopeResolver.requireOwnerId(actor));
        }
        if (actor.role() == chez1s.htrbackend.domain.enums.UserRole.TENANT) {
            return invoiceService.getByIdForTenant(invoiceId, actor.userId());
        }
        throw new chez1s.htrbackend.exception.BusinessException("Invoice access denied");
    }
}
