package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.MaintenanceRequest;
import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.enums.MaintenanceCategory;
import chez1s.htrbackend.domain.enums.MaintenancePriority;
import chez1s.htrbackend.domain.enums.MaintenanceStatus;
import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.repository.MaintenanceRequestRepository;
import chez1s.htrbackend.domain.repository.RoomRepository;
import chez1s.htrbackend.dto.request.CreateRoomRequest;
import chez1s.htrbackend.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class RoomService {

    private final RoomRepository roomRepository;
    private final PropertyService propertyService;
    private final MaintenanceRequestRepository maintenanceRepository;
    private final NotificationService notificationService;
    private final SlaService slaService;

    public List<Room> listByProperty(UUID propertyId) {
        return roomRepository.findByPropertyId(propertyId);
    }

    public Room getById(UUID id) {
        return roomRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Room", id));
    }

    public Room getById(UUID propertyId, UUID id) {
        return roomRepository.findByIdAndPropertyId(id, propertyId)
                .orElseThrow(() -> new ResourceNotFoundException("Room", id));
    }

    @Transactional
    public Room create(UUID propertyId, CreateRoomRequest req) {
        Property property = propertyService.getById(propertyId);
        Room room = Room.builder()
                .property(property)
                .roomNumber(req.getRoomNumber())
                .floor(req.getFloor())
                .areaM2(req.getAreaM2())
                .maxPeople(req.getMaxPeople())
                .rentOverride(req.getRentOverride())
                .status(RoomStatus.EMPTY)
                .build();
        return roomRepository.save(room);
    }

    @Transactional
    public Room update(UUID propertyId, UUID id, CreateRoomRequest req) {
        Room room = getById(propertyId, id);
        room.setRoomNumber(req.getRoomNumber());
        room.setFloor(req.getFloor());
        room.setAreaM2(req.getAreaM2());
        room.setMaxPeople(req.getMaxPeople());
        room.setRentOverride(req.getRentOverride());
        return roomRepository.save(room);
    }

    @Transactional
    public Room updateStatus(UUID propertyId, UUID id, RoomStatus status) {
        return applyStatusChange(getById(propertyId, id), status);
    }

    @Transactional
    public Room updateStatus(UUID id, RoomStatus status) {
        return applyStatusChange(getById(id), status);
    }

    private Room applyStatusChange(Room room, RoomStatus newStatus) {
        room.setStatus(newStatus);
        Room saved = roomRepository.save(room);

        if (newStatus == RoomStatus.MAINTENANCE) {
            long activeTickets = maintenanceRepository.countByRoomIdAndStatusNotIn(
                    saved.getId(),
                    List.of(MaintenanceStatus.DONE, MaintenanceStatus.COMPLETED, MaintenanceStatus.CANCELLED)
            );
            if (activeTickets == 0) {
                MaintenanceRequest req = MaintenanceRequest.builder()
                        .room(saved)
                        .tenant(saved.getProperty().getOwner())
                        .ticketCode("MNT-ROOM-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase())
                        .title("Bảo trì phòng " + saved.getRoomNumber())
                        .description("Phòng chuyển sang trạng thái bảo trì từ trang Quản lý phòng.")
                        .status(MaintenanceStatus.OPEN)
                        .priority(MaintenancePriority.NORMAL)
                        .category(MaintenanceCategory.OTHER)
                        .expectedResolvedAt(slaService.calculateExpectedResolvedAt(MaintenancePriority.NORMAL, MaintenanceCategory.OTHER))
                        .build();
                req = maintenanceRepository.save(req);
                notificationService.create(
                        saved.getProperty().getOwner().getId(),
                        "Phòng chuyển sang bảo trì",
                        "Đã tạo phiếu " + req.getTicketCode() + " cho phòng " + saved.getRoomNumber(),
                        "MAINTENANCE",
                        req.getId()
                );
                notificationService.publishEvent(
                        saved.getProperty().getOwner().getId(),
                        "maintenance-update",
                        chez1s.htrbackend.dto.response.MaintenanceRequestResponse.from(req)
                );
            }
        }
        return saved;
    }

    @Transactional
    public void delete(UUID propertyId, UUID id) {
        Room room = getById(propertyId, id);
        roomRepository.delete(room);
    }

    @Transactional
    public Room save(Room room) {
        return roomRepository.save(room);
    }
}
