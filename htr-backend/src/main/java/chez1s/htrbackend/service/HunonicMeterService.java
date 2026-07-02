package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.repository.RoomRepository;
import chez1s.htrbackend.dto.response.HunonicMeterPreviewResponse;
import chez1s.htrbackend.dto.response.HunonicMeterSyncResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class HunonicMeterService {

    private static final String NOT_CONFIGURED_MESSAGE = "Chưa cấu hình thiết bị Hunonic cho phòng này. Tạm thời hãy ưu tiên nhập tay.";

    private final RoomRepository roomRepository;
    private final MeterReadingService meterReadingService;

    public List<HunonicMeterPreviewResponse> previewByOwner(UUID ownerId, LocalDate readingMonth) {
        return roomRepository.findByPropertyOwnerIdAndStatus(ownerId, RoomStatus.RENTED).stream()
                .map(room -> {
                    var previousReading = meterReadingService.findLatestBeforeMonth(room.getId(), readingMonth).orElse(null);
                    return new HunonicMeterPreviewResponse(
                            room.getId(),
                            room.getRoomNumber(),
                            room.getProperty().getName(),
                            readingMonth,
                            false,
                            "NOT_CONFIGURED",
                            NOT_CONFIGURED_MESSAGE,
                            previousReading != null ? previousReading.getElecNew() : null,
                            previousReading != null ? previousReading.getWaterNew() : null
                    );
                })
                .toList();
    }

    public HunonicMeterSyncResponse syncRoom(UUID roomId, LocalDate readingMonth) {
        return new HunonicMeterSyncResponse(
                roomId,
                readingMonth,
                false,
                false,
                NOT_CONFIGURED_MESSAGE
        );
    }
}
