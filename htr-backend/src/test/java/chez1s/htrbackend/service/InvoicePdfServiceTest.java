package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.Contract;
import chez1s.htrbackend.domain.entity.Invoice;
import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.InvoiceStatus;
import chez1s.htrbackend.domain.enums.PaymentMethod;
import chez1s.htrbackend.domain.enums.UserRole;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;

class InvoicePdfServiceTest {

    private InvoicePdfService service;

    @BeforeEach
    void setUp() {
        service = new InvoicePdfService();
    }

    private Invoice invoiceWith(InvoiceStatus status, PaymentMethod paymentMethod, LocalDateTime paidAt) {
        User tenant = User.builder()
                .fullName("Nguyễn Thị Bích")
                .email("bich@example.com")
                .phone("0901234567")
                .role(UserRole.TENANT)
                .build();
        Property property = Property.builder()
                .name("Nhà trọ Xanh")
                .address("12 Lê Lợi, Quận 1")
                .build();
        Room room = Room.builder()
                .property(property)
                .roomNumber("A101")
                .maxPeople(2)
                .build();
        Contract contract = Contract.builder()
                .room(room)
                .tenant(tenant)
                .moveInDate(LocalDate.of(2026, 1, 1))
                .build();
        return Invoice.builder()
                .room(room)
                .contract(contract)
                .invoiceMonth(LocalDate.of(2026, 9, 1))
                .rentAmount(new BigDecimal("3000000"))
                .elecAmount(new BigDecimal("525000"))
                .waterAmount(new BigDecimal("150000"))
                .vehicleAmount(new BigDecimal("100000"))
                .serviceAmount(new BigDecimal("50000"))
                .totalAmount(new BigDecimal("3825000"))
                .status(status)
                .paymentMethod(paymentMethod)
                .paidAt(paidAt)
                .dueDate(LocalDate.of(2026, 9, 5))
                .build();
    }

    @Test
    void generate_pendingInvoice_producesNonEmptyPdf() {
        byte[] pdf = service.generate(invoiceWith(InvoiceStatus.PENDING, null, null));

        assertThat(pdf).isNotEmpty();
        // %PDF- magic header — confirms this is an actual PDF stream, not garbage bytes.
        assertThat(new String(pdf, 0, 5, StandardCharsets.US_ASCII)).isEqualTo("%PDF-");
    }

    @Test
    void generate_overdueInvoice_alsoProducesAValidPdf() {
        byte[] pdf = service.generate(invoiceWith(InvoiceStatus.OVERDUE, null, null));

        assertThat(pdf).isNotEmpty();
        assertThat(new String(pdf, 0, 5, StandardCharsets.US_ASCII)).isEqualTo("%PDF-");
    }

    @Test
    void generate_paidInvoice_includesPaymentInfoWithoutThrowing() {
        byte[] pdf = service.generate(invoiceWith(
                InvoiceStatus.PAID, PaymentMethod.PAYOS, LocalDateTime.of(2026, 9, 3, 10, 15)));

        assertThat(pdf).isNotEmpty();
        assertThat(new String(pdf, 0, 5, StandardCharsets.US_ASCII)).isEqualTo("%PDF-");
    }

    @Test
    void generate_zeroFeeComponents_doesNotThrow() {
        Invoice invoice = invoiceWith(InvoiceStatus.PENDING, null, null);
        invoice.setElecAmount(BigDecimal.ZERO);
        invoice.setWaterAmount(BigDecimal.ZERO);
        invoice.setVehicleAmount(BigDecimal.ZERO);

        byte[] pdf = service.generate(invoice);

        assertThat(pdf).isNotEmpty();
    }
}
