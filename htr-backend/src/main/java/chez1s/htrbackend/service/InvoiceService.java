package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.*;
import chez1s.htrbackend.domain.enums.ContractStatus;
import chez1s.htrbackend.domain.enums.InvoiceStatus;
import chez1s.htrbackend.domain.enums.PaymentMethod;
import chez1s.htrbackend.domain.repository.*;
import chez1s.htrbackend.dto.response.InvoiceResponse;
import chez1s.htrbackend.dto.response.PageResponse;
import chez1s.htrbackend.exception.BusinessException;
import chez1s.htrbackend.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Slf4j
public class InvoiceService {

    private final InvoiceRepository invoiceRepository;
    private final ContractRepository contractRepository;
    private final FeeConfigRepository feeConfigRepository;
    private final VehicleConfigRepository vehicleConfigRepository;
    private final MeterReadingRepository meterReadingRepository;
    private final VehicleRecordRepository vehicleRecordRepository;
    private final BillingService billingService;
    private final NotificationService notificationService;

    public List<Invoice> listAll() {
        return invoiceRepository.findAll();
    }

    public PageResponse<InvoiceResponse> listAll(Pageable pageable) {
        return PageResponse.from(invoiceRepository.findAll(pageable).map(InvoiceResponse::from));
    }

    public List<Invoice> listByTenant(UUID tenantId) {
        return invoiceRepository.findByContractTenantIdOrderByInvoiceMonthDesc(tenantId);
    }

    public PageResponse<InvoiceResponse> listByTenant(UUID tenantId, Pageable pageable) {
        return PageResponse.from(invoiceRepository.findByContractTenantId(tenantId, pageable).map(InvoiceResponse::from));
    }

    public Invoice getById(UUID id) {
        return invoiceRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Invoice", id));
    }

    @Transactional
    public Invoice generateForContract(Contract contract, YearMonth targetMonth) {
        UUID roomId = contract.getRoom().getId();
        LocalDate monthDate = targetMonth.atDay(1);

        if (invoiceRepository.existsByRoomIdAndInvoiceMonth(roomId, monthDate)) {
            log.info("Invoice already exists for room {} month {}", roomId, monthDate);
            return null;
        }

        UUID propertyId = contract.getRoom().getProperty().getId();
        FeeConfig feeConfig = feeConfigRepository.findByPropertyId(propertyId)
                .orElseThrow(() -> new BusinessException("Fee config not found for property " + propertyId));

        MeterReading reading = meterReadingRepository
                .findByRoomIdAndReadingMonth(roomId, monthDate)
                .orElse(null);
        if (reading == null) {
            log.warn("No meter reading for room {} month {}. Skipping invoice.", roomId, monthDate);
            return null;
        }

        VehicleConfig vehicleConfig = vehicleConfigRepository.findByPropertyId(propertyId).orElse(null);
        VehicleRecord vehicleRecord = vehicleRecordRepository
                .findByRoomIdAndRecordMonth(roomId, monthDate).orElse(null);

        BigDecimal rent = billingService.calcRent(contract, targetMonth, feeConfig);
        BigDecimal elec = billingService.calcElec(reading, feeConfig);
        BigDecimal water = billingService.calcWater(reading, feeConfig, contract.getRoom().getMaxPeople());
        BigDecimal vehicle = billingService.calcVehicle(vehicleRecord, vehicleConfig);
        BigDecimal service = billingService.calcService(feeConfig);
        BigDecimal total = rent.add(elec).add(water).add(vehicle).add(service);

        boolean isProRata = billingService.isProRataMonth(contract, targetMonth);
        Integer daysUsed = isProRata ? billingService.calcDaysUsed(contract.getMoveInDate()) : null;

        Invoice invoice = Invoice.builder()
                .room(contract.getRoom())
                .contract(contract)
                .invoiceMonth(monthDate)
                .proRata(isProRata)
                .daysUsed(daysUsed)
                .rentAmount(rent)
                .elecAmount(elec)
                .waterAmount(water)
                .vehicleAmount(vehicle)
                .serviceAmount(service)
                .totalAmount(total)
                .status(InvoiceStatus.PENDING)
                .dueDate(monthDate.withDayOfMonth(Math.min(10, targetMonth.lengthOfMonth())))
                .build();
        invoice = invoiceRepository.save(invoice);

        notificationService.create(contract.getTenant().getId(),
                "New Invoice", "Invoice for " + targetMonth + " is ready",
                "INVOICE", invoice.getId());

        return invoice;
    }

    @Transactional
    public void generateAllForMonth(YearMonth targetMonth) {
        List<Contract> activeContracts = contractRepository.findByStatus(ContractStatus.ACTIVE);
        for (Contract contract : activeContracts) {
            try {
                generateForContract(contract, targetMonth);
            } catch (Exception e) {
                log.error("Failed to generate invoice for contract {}: {}", contract.getId(), e.getMessage());
            }
        }
    }

    @Transactional
    public Invoice save(Invoice invoice) {
        return invoiceRepository.save(invoice);
    }

    @Transactional
    public Invoice markPaidCash(UUID invoiceId) {
        Invoice invoice = getById(invoiceId);
        if (invoice.getStatus() == InvoiceStatus.PAID) {
            throw new BusinessException("Invoice is already paid");
        }
        invoice.setStatus(InvoiceStatus.PAID);
        invoice.setPaymentMethod(PaymentMethod.CASH);
        invoice.setPaidAt(LocalDateTime.now());
        return invoiceRepository.save(invoice);
    }

    @Transactional
    public Invoice markPaidPayOS(String paymentLinkId, String transactionId) {
        Invoice invoice = invoiceRepository.findByPaymentLinkId(paymentLinkId)
                .orElseThrow(() -> new ResourceNotFoundException("Invoice by paymentLinkId", paymentLinkId));
        if (invoice.getStatus() == InvoiceStatus.PAID) {
            return invoice;
        }
        invoice.setStatus(InvoiceStatus.PAID);
        invoice.setPaymentMethod(PaymentMethod.PAYOS);
        invoice.setTransactionId(transactionId);
        invoice.setPaidAt(LocalDateTime.now());
        return invoiceRepository.save(invoice);
    }

    @Transactional
    public void markOverdue() {
        List<Invoice> overdue = invoiceRepository.findByStatusAndDueDateBefore(
                InvoiceStatus.PENDING, LocalDate.now());
        for (Invoice inv : overdue) {
            inv.setStatus(InvoiceStatus.OVERDUE);
            invoiceRepository.save(inv);
            notificationService.create(inv.getContract().getTenant().getId(),
                    "Invoice Overdue", "Your invoice for " + inv.getInvoiceMonth() + " is overdue",
                    "INVOICE", inv.getId());
        }
    }
}
