package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.*;
import chez1s.htrbackend.domain.enums.ContractStatus;
import chez1s.htrbackend.domain.enums.InvoiceStatus;
import chez1s.htrbackend.domain.enums.WaterMode;
import chez1s.htrbackend.domain.repository.*;
import chez1s.htrbackend.exception.BusinessException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class InvoiceIdempotencyTest {

    @Mock InvoiceRepository invoiceRepository;
    @Mock ContractRepository contractRepository;
    @Mock FeeConfigRepository feeConfigRepository;
    @Mock MeterReadingRepository meterReadingRepository;
    @Mock VehicleRecordRepository vehicleRecordRepository;
    @Mock BillingService billingService;
    @Mock NotificationService notificationService;

    @InjectMocks InvoiceService invoiceService;

    private UUID roomId;
    private UUID propertyId;
    private Contract contract;
    private FeeConfig feeConfig;
    private MeterReading reading;
    private YearMonth targetMonth;

    @BeforeEach
    void setUp() {
        roomId = UUID.randomUUID();
        propertyId = UUID.randomUUID();
        targetMonth = YearMonth.of(2025, 6);

        Property property = new Property();
        property.setId(propertyId);

        Room room = new Room();
        room.setId(roomId);
        room.setProperty(property);
        room.setMaxPeople(2);

        User tenant = new User();
        tenant.setId(UUID.randomUUID());
        tenant.setFullName("Test Tenant");
        tenant.setEmail("tenant@test.com");

        contract = Contract.builder()
                .id(UUID.randomUUID())
                .room(room)
                .tenant(tenant)
                .moveInDate(LocalDate.of(2025, 1, 1))
                .status(ContractStatus.ACTIVE)
                .depositAmount(new BigDecimal("5000000"))
                .build();

        feeConfig = FeeConfig.builder()
                .rentDefault(new BigDecimal("3000000"))
                .elecPrice(new BigDecimal("3500"))
                .waterMode(WaterMode.CUBIC)
                .waterPrice(new BigDecimal("15000"))
                .serviceFee(new BigDecimal("50000"))
                .vehicleProRata(false)
                .serviceProRata(false)
                .motorbikePrice(BigDecimal.ZERO)
                .carPrice(BigDecimal.ZERO)
                .bicyclePrice(BigDecimal.ZERO)
                .build();

        reading = new MeterReading();
        reading.setElecOld(100L);
        reading.setElecNew(200L);
        reading.setWaterOld(10L);
        reading.setWaterNew(15L);
    }

    @Test
    void generateForContract_alreadyExists_returnsNull() {
        when(invoiceRepository.existsByRoomIdAndInvoiceMonth(roomId, targetMonth.atDay(1))).thenReturn(true);

        Invoice result = invoiceService.generateForContract(contract, targetMonth);

        assertThat(result).isNull();
        verify(invoiceRepository, never()).save(any());
    }

    @Test
    void generateForContract_noMeterReading_returnsNull() {
        when(invoiceRepository.existsByRoomIdAndInvoiceMonth(any(), any())).thenReturn(false);
        when(feeConfigRepository.findByPropertyId(propertyId)).thenReturn(Optional.of(feeConfig));
        when(meterReadingRepository.findByRoomIdAndReadingMonth(any(), any())).thenReturn(Optional.empty());

        Invoice result = invoiceService.generateForContract(contract, targetMonth);

        assertThat(result).isNull();
        verify(invoiceRepository, never()).save(any());
    }

    @Test
    void generateForContract_noFeeConfig_throwsBusinessException() {
        when(invoiceRepository.existsByRoomIdAndInvoiceMonth(any(), any())).thenReturn(false);
        when(feeConfigRepository.findByPropertyId(propertyId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> invoiceService.generateForContract(contract, targetMonth))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("Fee config not found");
    }

    @Test
    void generateForContract_firstTime_savesInvoice() {
        when(invoiceRepository.existsByRoomIdAndInvoiceMonth(any(), any())).thenReturn(false);
        when(feeConfigRepository.findByPropertyId(propertyId)).thenReturn(Optional.of(feeConfig));
        when(meterReadingRepository.findByRoomIdAndReadingMonth(any(), any())).thenReturn(Optional.of(reading));
        when(vehicleRecordRepository.findByRoomIdAndRecordMonth(any(), any())).thenReturn(Optional.empty());
        when(billingService.calcRent(any(), any(), any())).thenReturn(new BigDecimal("3000000"));
        when(billingService.calcElec(any(), any())).thenReturn(new BigDecimal("350000"));
        when(billingService.calcWater(any(), any(), anyInt())).thenReturn(new BigDecimal("75000"));
        when(billingService.calcVehicle(any(), any())).thenReturn(BigDecimal.ZERO);
        when(billingService.calcService(any())).thenReturn(new BigDecimal("50000"));
        when(billingService.isProRataMonth(any(), any())).thenReturn(false);

        Invoice saved = Invoice.builder()
                .id(UUID.randomUUID())
                .room(contract.getRoom())
                .contract(contract)
                .invoiceMonth(targetMonth.atDay(1))
                .status(InvoiceStatus.PENDING)
                .totalAmount(new BigDecimal("3475000"))
                .build();
        when(invoiceRepository.save(any())).thenReturn(saved);

        Invoice result = invoiceService.generateForContract(contract, targetMonth);

        assertThat(result).isNotNull();
        assertThat(result.getStatus()).isEqualTo(InvoiceStatus.PENDING);
        verify(invoiceRepository).save(any());
        verify(notificationService).create(any(), any(), any(), any(), any());
    }

    @Test
    void markPaidCash_alreadyPaid_throwsBusinessException() {
        Invoice invoice = Invoice.builder()
                .id(UUID.randomUUID())
                .status(InvoiceStatus.PAID)
                .build();
        when(invoiceRepository.findById(invoice.getId())).thenReturn(Optional.of(invoice));

        assertThatThrownBy(() -> invoiceService.markPaidCash(invoice.getId()))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("already paid");
    }

    @Test
    void markPaidPayOS_idempotent_secondCallReturnsWithoutSave() {
        Invoice invoice = Invoice.builder()
                .id(UUID.randomUUID())
                .status(InvoiceStatus.PAID)
                .build();
        when(invoiceRepository.findByPaymentLinkId("LINK-001")).thenReturn(Optional.of(invoice));

        Invoice result = invoiceService.markPaidPayOS("LINK-001", "TXN-001");

        assertThat(result.getStatus()).isEqualTo(InvoiceStatus.PAID);
        verify(invoiceRepository, never()).save(any());
    }
}
