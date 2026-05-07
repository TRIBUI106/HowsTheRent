package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.enums.RoomStatus;
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

    public List<Room> listByProperty(UUID propertyId) {
        return roomRepository.findByPropertyId(propertyId);
    }

    public Room getById(UUID id) {
        return roomRepository.findById(id)
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
    public Room update(UUID id, CreateRoomRequest req) {
        Room room = getById(id);
        room.setRoomNumber(req.getRoomNumber());
        room.setFloor(req.getFloor());
        room.setAreaM2(req.getAreaM2());
        room.setMaxPeople(req.getMaxPeople());
        room.setRentOverride(req.getRentOverride());
        return roomRepository.save(room);
    }

    @Transactional
    public Room updateStatus(UUID id, RoomStatus status) {
        Room room = getById(id);
        room.setStatus(status);
        return roomRepository.save(room);
    }

    @Transactional
    public Room save(Room room) {
        return roomRepository.save(room);
    }
}
