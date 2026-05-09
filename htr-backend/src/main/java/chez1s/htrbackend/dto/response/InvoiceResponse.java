package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.Invoice;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

public record InvoiceResponse(
        UUID id,
        UUID roomId,
        String roomNumber,
        UUID contractId,
        LocalDate invoiceMonth,
        boolean proRata,
        Integer daysUsed,
        BigDecimal rentAmount,
        BigDecimal elecAmount,
        BigDecimal waterAmount,
        BigDecimal vehicleAmount,
        BigDecimal serviceAmount,
        BigDecimal totalAmount,
        String status,
        String paymentMethod,
        String paymentLinkId,
        String checkoutUrl,
        String transactionId,
        LocalDate dueDate,
        LocalDateTime paidAt,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
    public static InvoiceResponse from(Invoice i) {
        return new InvoiceResponse(
                i.getId(),
                i.getRoom().getId(),
                i.getRoom().getRoomNumber(),
                i.getContract().getId(),
                i.getInvoiceMonth(),
                i.isProRata(),
                i.getDaysUsed(),
                i.getRentAmount(),
                i.getElecAmount(),
                i.getWaterAmount(),
                i.getVehicleAmount(),
                i.getServiceAmount(),
                i.getTotalAmount(),
                i.getStatus().name(),
                i.getPaymentMethod() != null ? i.getPaymentMethod().name() : null,
                i.getPaymentLinkId(),
                i.getCheckoutUrl(),
                i.getTransactionId(),
                i.getDueDate(),
                i.getPaidAt(),
                i.getCreatedAt(),
                i.getUpdatedAt()
        );
    }
}
