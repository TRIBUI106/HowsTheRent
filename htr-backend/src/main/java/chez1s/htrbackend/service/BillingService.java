package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.*;
import chez1s.htrbackend.domain.enums.WaterMode;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;

@Service
public class BillingService {

    public BigDecimal calcRent(Contract contract, YearMonth targetMonth, FeeConfig config) {
        BigDecimal fullRent = contract.getRoom().getRentOverride() != null
                ? contract.getRoom().getRentOverride()
                : config.getRentDefault();
        YearMonth moveInMonth = YearMonth.from(contract.getMoveInDate());
        if (moveInMonth.equals(targetMonth)) {
            return calcProRata(fullRent, contract.getMoveInDate());
        }
        return fullRent;
    }

    public BigDecimal calcElec(MeterReading reading, FeeConfig config) {
        long usage = reading.getElecNew() - reading.getElecOld();
        return BigDecimal.valueOf(usage).multiply(config.getElecPrice())
                .setScale(2, RoundingMode.HALF_UP);
    }

    public BigDecimal calcWater(MeterReading reading, FeeConfig config, int tenantCount) {
        if (config.getWaterMode() == WaterMode.PERSON) {
            return BigDecimal.valueOf(tenantCount).multiply(config.getWaterPrice())
                    .setScale(2, RoundingMode.HALF_UP);
        }
        if (reading.getWaterOld() == null || reading.getWaterNew() == null) {
            return BigDecimal.ZERO;
        }
        long usage = reading.getWaterNew() - reading.getWaterOld();
        return BigDecimal.valueOf(usage).multiply(config.getWaterPrice())
                .setScale(2, RoundingMode.HALF_UP);
    }

    public BigDecimal calcVehicle(VehicleRecord record, FeeConfig feeConfig) {
        if (record == null || feeConfig == null) {
            return BigDecimal.ZERO;
        }
        BigDecimal moto = BigDecimal.valueOf(record.getMotorbikeCount()).multiply(feeConfig.getMotorbikePrice());
        BigDecimal car = BigDecimal.valueOf(record.getCarCount()).multiply(feeConfig.getCarPrice());
        BigDecimal bicycle = BigDecimal.valueOf(record.getBicycleCount()).multiply(feeConfig.getBicyclePrice());
        return moto.add(car).add(bicycle).setScale(2, RoundingMode.HALF_UP);
    }

    public BigDecimal calcService(FeeConfig config) {
        return config.getServiceFee();
    }

    public BigDecimal calcProRata(BigDecimal fullRent, LocalDate moveInDate) {
        YearMonth ym = YearMonth.from(moveInDate);
        int daysInMonth = ym.lengthOfMonth();
        int daysUsed = daysInMonth - moveInDate.getDayOfMonth() + 1;
        return fullRent.multiply(BigDecimal.valueOf(daysUsed))
                .divide(BigDecimal.valueOf(daysInMonth), 2, RoundingMode.HALF_UP);
    }

    public boolean isProRataMonth(Contract contract, YearMonth targetMonth) {
        return YearMonth.from(contract.getMoveInDate()).equals(targetMonth);
    }

    public int calcDaysUsed(LocalDate moveInDate) {
        YearMonth ym = YearMonth.from(moveInDate);
        return ym.lengthOfMonth() - moveInDate.getDayOfMonth() + 1;
    }
}
