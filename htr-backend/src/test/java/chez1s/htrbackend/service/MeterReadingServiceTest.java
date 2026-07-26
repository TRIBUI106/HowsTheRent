package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.MeterReading;
import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.enums.MeterReadingSource;
import chez1s.htrbackend.domain.repository.MeterReadingRepository;
import chez1s.htrbackend.domain.repository.VehicleRecordRepository;
import chez1s.htrbackend.dto.request.CreateMeterReadingRequest;
import chez1s.htrbackend.exception.BusinessException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class MeterReadingServiceTest {

    @Mock MeterReadingRepository meterReadingRepository;
    @Mock VehicleRecordRepository vehicleRecordRepository;
    @Mock RoomService roomService;

    @InjectMocks MeterReadingService meterReadingService;

    @Test
    void create_existingRoomMonthUpdatesReadingInsteadOfFailing() {
        UUID roomId = UUID.randomUUID();
        UUID recordedById = UUID.randomUUID();
        LocalDate month = LocalDate.of(2026, 7, 1);
        MeterReading existing = MeterReading.builder()
                .id(UUID.randomUUID())
                .room(new Room())
                .readingMonth(month)
                .elecOld(100L)
                .elecNew(150L)
                .waterOld(20L)
                .waterNew(25L)
                .source(MeterReadingSource.MANUAL)
                .build();
        CreateMeterReadingRequest request = new CreateMeterReadingRequest();
        request.setReadingMonth(month);
        request.setElecOld(100L);
        request.setElecNew(175L);
        request.setWaterOld(20L);
        request.setWaterNew(30L);
        request.setSource(MeterReadingSource.MANUAL);

        when(meterReadingRepository.findByRoomIdAndReadingMonth(roomId, month)).thenReturn(Optional.of(existing));
        when(meterReadingRepository.findFirstByRoomIdAndReadingMonthLessThanOrderByReadingMonthDesc(roomId, month)).thenReturn(Optional.empty());
        when(meterReadingRepository.save(existing)).thenReturn(existing);

        MeterReading result = meterReadingService.create(roomId, recordedById, request);

        assertThat(result).isSameAs(existing);
        assertThat(result.getElecOld()).isEqualTo(100L);
        assertThat(result.getElecNew()).isEqualTo(175L);
        assertThat(result.getWaterOld()).isEqualTo(20L);
        assertThat(result.getWaterNew()).isEqualTo(30L);
        verify(meterReadingRepository).save(existing);
    }

    @Test
    void create_rejectsUnreasonableElectricityDelta() {
        UUID roomId = UUID.randomUUID();
        UUID recordedById = UUID.randomUUID();
        LocalDate month = LocalDate.of(2026, 7, 1);
        CreateMeterReadingRequest request = new CreateMeterReadingRequest();
        request.setReadingMonth(month);
        request.setElecOld(100L);
        request.setElecNew(100_101L);

        when(meterReadingRepository.findByRoomIdAndReadingMonth(roomId, month)).thenReturn(Optional.empty());
        when(meterReadingRepository.findFirstByRoomIdAndReadingMonthLessThanOrderByReadingMonthDesc(roomId, month)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> meterReadingService.create(roomId, recordedById, request))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("too far");
    }
}
