package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.*;
import chez1s.htrbackend.domain.enums.WaterMode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;

import static org.assertj.core.api.Assertions.assertThat;

class BillingServiceTest {

    private BillingService billingService;

    @BeforeEach
    void setUp() {
        billingService = new BillingService();
    }

    private FeeConfig feeConfig(BigDecimal rent, BigDecimal elec, WaterMode mode, BigDecimal water, BigDecimal service) {
        return FeeConfig.builder()
                .rentDefault(rent)
                .elecPrice(elec)
                .waterMode(mode)
                .waterPrice(water)
                .serviceFee(service)
                .vehicleProRata(false)
                .serviceProRata(false)
                .build();
    }

    private Room roomWith(BigDecimal rentOverride, int maxPeople) {
        Room room = new Room();
        room.setRentOverride(rentOverride);
        room.setMaxPeople(maxPeople);
        return room;
    }

    private Contract contract(Room room, LocalDate moveIn) {
        return Contract.builder()
                .room(room)
                .moveInDate(moveIn)
                .build();
    }

    // ---- calcRent ----

    @Test
    void calcRent_fullMonth_returnsDefault() {
        FeeConfig config = feeConfig(new BigDecimal("3000000"), new BigDecimal("3500"), WaterMode.CUBIC, new BigDecimal("15000"), new BigDecimal("50000"));
        Room room = roomWith(null, 2);
        Contract c = contract(room, LocalDate.of(2025, 1, 1));
        BigDecimal result = billingService.calcRent(c, YearMonth.of(2025, 2), config);
        assertThat(result).isEqualByComparingTo(new BigDecimal("3000000"));
    }

    @Test
    void calcRent_fullMonth_usesRoomOverride() {
        FeeConfig config = feeConfig(new BigDecimal("3000000"), new BigDecimal("3500"), WaterMode.CUBIC, new BigDecimal("15000"), new BigDecimal("50000"));
        Room room = roomWith(new BigDecimal("3500000"), 2);
        Contract c = contract(room, LocalDate.of(2025, 1, 1));
        BigDecimal result = billingService.calcRent(c, YearMonth.of(2025, 2), config);
        assertThat(result).isEqualByComparingTo(new BigDecimal("3500000"));
    }

    @Test
    void calcRent_proRataMonth_moveInDay15of31() {
        FeeConfig config = feeConfig(new BigDecimal("3100000"), new BigDecimal("3500"), WaterMode.CUBIC, new BigDecimal("15000"), new BigDecimal("50000"));
        Room room = roomWith(null, 2);
        // Move in Jan 15 → 17 days used out of 31
        Contract c = contract(room, LocalDate.of(2025, 1, 15));
        BigDecimal result = billingService.calcRent(c, YearMonth.of(2025, 1), config);
        // 3100000 * 17 / 31 = 1700000
        BigDecimal expected = new BigDecimal("3100000").multiply(BigDecimal.valueOf(17))
                .divide(BigDecimal.valueOf(31), 2, java.math.RoundingMode.HALF_UP);
        assertThat(result).isEqualByComparingTo(expected);
    }

    @Test
    void calcRent_proRataMonth_moveInDay1_fullRent() {
        FeeConfig config = feeConfig(new BigDecimal("2000000"), new BigDecimal("3500"), WaterMode.CUBIC, new BigDecimal("15000"), new BigDecimal("50000"));
        Room room = roomWith(null, 2);
        Contract c = contract(room, LocalDate.of(2025, 3, 1));
        BigDecimal result = billingService.calcRent(c, YearMonth.of(2025, 3), config);
        assertThat(result).isEqualByComparingTo(new BigDecimal("2000000.00"));
    }

    // ---- calcElec ----

    @Test
    void calcElec_standard() {
        FeeConfig config = feeConfig(BigDecimal.ZERO, new BigDecimal("3500"), WaterMode.CUBIC, BigDecimal.ZERO, BigDecimal.ZERO);
        MeterReading reading = new MeterReading();
        reading.setElecOld(100L);
        reading.setElecNew(250L);
        BigDecimal result = billingService.calcElec(reading, config);
        // 150 * 3500 = 525000
        assertThat(result).isEqualByComparingTo(new BigDecimal("525000.00"));
    }

    @Test
    void calcElec_zeroUsage() {
        FeeConfig config = feeConfig(BigDecimal.ZERO, new BigDecimal("3500"), WaterMode.CUBIC, BigDecimal.ZERO, BigDecimal.ZERO);
        MeterReading reading = new MeterReading();
        reading.setElecOld(100L);
        reading.setElecNew(100L);
        assertThat(billingService.calcElec(reading, config)).isEqualByComparingTo(BigDecimal.ZERO.setScale(2));
    }

    // ---- calcWater (CUBIC) ----

    @Test
    void calcWater_cubic_standard() {
        FeeConfig config = feeConfig(BigDecimal.ZERO, BigDecimal.ZERO, WaterMode.CUBIC, new BigDecimal("15000"), BigDecimal.ZERO);
        MeterReading reading = new MeterReading();
        reading.setWaterOld(10L);
        reading.setWaterNew(20L);
        BigDecimal result = billingService.calcWater(reading, config, 2);
        // 10 * 15000 = 150000
        assertThat(result).isEqualByComparingTo(new BigDecimal("150000.00"));
    }

    @Test
    void calcWater_cubic_nullReadings_returnsZero() {
        FeeConfig config = feeConfig(BigDecimal.ZERO, BigDecimal.ZERO, WaterMode.CUBIC, new BigDecimal("15000"), BigDecimal.ZERO);
        MeterReading reading = new MeterReading();
        reading.setWaterOld(null);
        reading.setWaterNew(null);
        assertThat(billingService.calcWater(reading, config, 2)).isEqualByComparingTo(BigDecimal.ZERO);
    }

    // ---- calcWater (PERSON) ----

    @Test
    void calcWater_person_multipliesByTenantCount() {
        FeeConfig config = feeConfig(BigDecimal.ZERO, BigDecimal.ZERO, WaterMode.PERSON, new BigDecimal("50000"), BigDecimal.ZERO);
        MeterReading reading = new MeterReading();
        BigDecimal result = billingService.calcWater(reading, config, 3);
        // 3 * 50000 = 150000
        assertThat(result).isEqualByComparingTo(new BigDecimal("150000.00"));
    }

    // ---- calcVehicle ----

    @Test
    void calcVehicle_mixed() {
        VehicleConfig vc = VehicleConfig.builder()
                .motorbikePrice(new BigDecimal("100000"))
                .carPrice(new BigDecimal("300000"))
                .bicyclePrice(new BigDecimal("20000"))
                .build();
        VehicleRecord vr = new VehicleRecord();
        vr.setMotorbikeCount(2);
        vr.setCarCount(1);
        vr.setBicycleCount(1);
        BigDecimal result = billingService.calcVehicle(vr, vc);
        // 2*100000 + 300000 + 20000 = 520000
        assertThat(result).isEqualByComparingTo(new BigDecimal("520000.00"));
    }

    @Test
    void calcVehicle_nullRecord_returnsZero() {
        assertThat(billingService.calcVehicle(null, null)).isEqualByComparingTo(BigDecimal.ZERO);
    }

    // ---- calcProRata ----

    @Test
    void calcProRata_moveInDay16of30() {
        // 30-day month: days used = 30-16+1 = 15
        BigDecimal result = billingService.calcProRata(new BigDecimal("3000000"), LocalDate.of(2025, 4, 16));
        BigDecimal expected = new BigDecimal("3000000").multiply(BigDecimal.valueOf(15))
                .divide(BigDecimal.valueOf(30), 2, java.math.RoundingMode.HALF_UP);
        assertThat(result).isEqualByComparingTo(expected);
    }

    // ---- isProRataMonth ----

    @Test
    void isProRataMonth_sameMonth_true() {
        Room room = roomWith(null, 2);
        Contract c = contract(room, LocalDate.of(2025, 5, 10));
        assertThat(billingService.isProRataMonth(c, YearMonth.of(2025, 5))).isTrue();
    }

    @Test
    void isProRataMonth_differentMonth_false() {
        Room room = roomWith(null, 2);
        Contract c = contract(room, LocalDate.of(2025, 5, 10));
        assertThat(billingService.isProRataMonth(c, YearMonth.of(2025, 6))).isFalse();
    }

    // ---- calcDaysUsed ----

    @Test
    void calcDaysUsed_jan15() {
        assertThat(billingService.calcDaysUsed(LocalDate.of(2025, 1, 15))).isEqualTo(17);
    }

    @Test
    void calcDaysUsed_firstDay() {
        assertThat(billingService.calcDaysUsed(LocalDate.of(2025, 1, 1))).isEqualTo(31);
    }

    @Test
    void calcDaysUsed_lastDay() {
        assertThat(billingService.calcDaysUsed(LocalDate.of(2025, 1, 31))).isEqualTo(1);
    }
}
