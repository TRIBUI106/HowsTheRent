package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Contract;
import chez1s.htrbackend.domain.entity.Invoice;
import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.enums.InvoiceStatus;
import chez1s.htrbackend.domain.enums.PaymentMethod;
import chez1s.htrbackend.domain.enums.UserRole;
import chez1s.htrbackend.security.ActorContext;
import chez1s.htrbackend.security.OwnerScopeResolver;
import chez1s.htrbackend.dto.response.InvoiceResponse;
import chez1s.htrbackend.service.InvoicePdfService;
import chez1s.htrbackend.service.InvoiceService;
import chez1s.htrbackend.service.PayOSService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class InvoiceControllerTest {

    @Mock
    private InvoiceService invoiceService;
    @Mock
    private PayOSService payOSService;
    @Mock
    private InvoicePdfService invoicePdfService;
    @Mock
    private OwnerScopeResolver ownerScopeResolver;
    @Mock
    private Authentication authentication;

    private InvoiceController controller;

    @BeforeEach
    void setUp() {
        controller = new InvoiceController(invoiceService, payOSService, invoicePdfService, ownerScopeResolver);
        lenient().when(authentication.getDetails())
                .thenReturn(new ActorContext(UUID.randomUUID(), UserRole.PLATFORM_ADMIN, 1L));
    }

    private Invoice invoiceWith(UUID id, InvoiceStatus status, String paymentLinkId) {
        return Invoice.builder()
                .id(id)
                .room(Room.builder().id(UUID.randomUUID()).roomNumber("101").build())
                .contract(Contract.builder().id(UUID.randomUUID()).build())
                .status(status)
                .paymentLinkId(paymentLinkId)
                .build();
    }

    // Regression test for the tenant-facing bug: browser redirect from PayOS checkout carries no
    // guarantee the async webhook already landed, so a still-PENDING invoice with a payment link
    // must be actively reconciled against PayOS's own status API rather than left to the webhook.
    @Test
    void reconcilePayment_pendingInvoiceWithPaymentLink_callsReconcileAndReturnsUpdatedInvoice() {
        UUID id = UUID.randomUUID();
        Invoice beforeReconcile = invoiceWith(id, InvoiceStatus.PENDING, "123456");
        Invoice afterReconcile = invoiceWith(id, InvoiceStatus.PAID, "123456");
        afterReconcile.setPaymentMethod(PaymentMethod.PAYOS);
        when(invoiceService.getById(id)).thenReturn(beforeReconcile, afterReconcile);

        ResponseEntity<InvoiceResponse> response = controller.reconcilePayment(authentication, id);

        verify(payOSService).reconcile("123456");
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().status()).isEqualTo("PAID");
    }

    // Already-settled invoices skip the PayOS round trip entirely — nothing to reconcile.
    @Test
    void reconcilePayment_alreadyPaidInvoice_skipsReconcileCall() {
        UUID id = UUID.randomUUID();
        Invoice paid = invoiceWith(id, InvoiceStatus.PAID, "123456");
        when(invoiceService.getById(id)).thenReturn(paid);

        ResponseEntity<InvoiceResponse> response = controller.reconcilePayment(authentication, id);

        verify(payOSService, never()).reconcile(org.mockito.ArgumentMatchers.anyString());
        assertThat(response.getBody().status()).isEqualTo("PAID");
    }

    // No payment link means the tenant never actually started a PayOS checkout for this invoice —
    // nothing exists on PayOS's side to reconcile against, and PayOSService.reconcile() would
    // throw ("Payment intent not found") if called anyway.
    @Test
    void reconcilePayment_noPaymentLinkYet_skipsReconcileCall() {
        UUID id = UUID.randomUUID();
        Invoice pending = invoiceWith(id, InvoiceStatus.PENDING, null);
        when(invoiceService.getById(id)).thenReturn(pending);

        ResponseEntity<InvoiceResponse> response = controller.reconcilePayment(authentication, id);

        verify(payOSService, never()).reconcile(org.mockito.ArgumentMatchers.anyString());
        assertThat(response.getBody().status()).isEqualTo("PENDING");
    }
}
