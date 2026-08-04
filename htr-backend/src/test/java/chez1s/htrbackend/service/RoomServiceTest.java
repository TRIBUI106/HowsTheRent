package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.MaintenanceRequest;
import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.MaintenanceStatus;
import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.repository.ContractRepository;
import chez1s.htrbackend.domain.repository.InvoiceRepository;
import chez1s.htrbackend.domain.repository.MaintenanceRequestRepository;
import chez1s.htrbackend.domain.repository.MeterReadingRepository;
import chez1s.htrbackend.domain.repository.RoomNoteRepository;
import chez1s.htrbackend.domain.repository.RoomRepository;
import chez1s.htrbackend.domain.repository.VehicleRecordRepository;
import chez1s.htrbackend.exception.BusinessException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
class RoomServiceTest {

    @Mock RoomRepository roomRepository;
    @Mock PropertyService propertyService;
    @Mock MaintenanceRequestRepository maintenanceRepository;
    @Mock NotificationService notificationService;
    @Mock SlaService slaService;
    @Mock ContractRepository contractRepository;
    @Mock InvoiceRepository invoiceRepository;
    @Mock MeterReadingRepository meterReadingRepository;
    @Mock VehicleRecordRepository vehicleRecordRepository;
    @Mock RoomNoteRepository roomNoteRepository;

    @InjectMocks RoomService roomService;

    private Room roomWithId(UUID propertyId, UUID roomId) {
        Room room = Room.builder().id(roomId).property(Property.builder().id(propertyId).build()).build();
        when(roomRepository.findByIdAndPropertyId(roomId, propertyId)).thenReturn(Optional.of(room));
        return room;
    }

    @Test
    void delete_removesRoomWhenNoDependentsExist() {
        UUID propertyId = UUID.randomUUID();
        UUID roomId = UUID.randomUUID();
        Room room = roomWithId(propertyId, roomId);

        roomService.delete(propertyId, roomId);

        verify(roomRepository).delete(room);
    }

    @Test
    void delete_throwsWhenContractsExist() {
        UUID propertyId = UUID.randomUUID();
        UUID roomId = UUID.randomUUID();
        roomWithId(propertyId, roomId);
        when(contractRepository.countByRoomId(roomId)).thenReturn(2L);

        assertThatThrownBy(() -> roomService.delete(propertyId, roomId))
                .isInstanceOf(BusinessException.class)
                .hasMessage("Không thể xóa phòng vì còn 2 hợp đồng liên quan");
        verify(roomRepository, never()).delete(any(Room.class));
    }

    @Test
    void delete_throwsWhenInvoicesExist() {
        UUID propertyId = UUID.randomUUID();
        UUID roomId = UUID.randomUUID();
        roomWithId(propertyId, roomId);
        when(invoiceRepository.countByRoomId(roomId)).thenReturn(3L);

        assertThatThrownBy(() -> roomService.delete(propertyId, roomId))
                .isInstanceOf(BusinessException.class)
                .hasMessage("Không thể xóa phòng vì còn 3 hóa đơn liên quan");
        verify(roomRepository, never()).delete(any(Room.class));
    }

    @Test
    void delete_throwsWhenMaintenanceRequestsExist() {
        UUID propertyId = UUID.randomUUID();
        UUID roomId = UUID.randomUUID();
        roomWithId(propertyId, roomId);
        when(maintenanceRepository.countByRoomId(roomId)).thenReturn(1L);

        assertThatThrownBy(() -> roomService.delete(propertyId, roomId))
                .isInstanceOf(BusinessException.class)
                .hasMessage("Không thể xóa phòng vì còn 1 yêu cầu bảo trì liên quan");
        verify(roomRepository, never()).delete(any(Room.class));
    }

    @Test
    void delete_throwsWhenMeterReadingsExist() {
        UUID propertyId = UUID.randomUUID();
        UUID roomId = UUID.randomUUID();
        roomWithId(propertyId, roomId);
        when(meterReadingRepository.countByRoomId(roomId)).thenReturn(4L);

        assertThatThrownBy(() -> roomService.delete(propertyId, roomId))
                .isInstanceOf(BusinessException.class)
                .hasMessage("Không thể xóa phòng vì còn 4 chỉ số đồng hồ liên quan");
        verify(roomRepository, never()).delete(any(Room.class));
    }

    @Test
    void delete_throwsWhenVehicleRecordsExist() {
        UUID propertyId = UUID.randomUUID();
        UUID roomId = UUID.randomUUID();
        roomWithId(propertyId, roomId);
        when(vehicleRecordRepository.countByRoomId(roomId)).thenReturn(5L);

        assertThatThrownBy(() -> roomService.delete(propertyId, roomId))
                .isInstanceOf(BusinessException.class)
                .hasMessage("Không thể xóa phòng vì còn 5 hồ sơ xe liên quan");
        verify(roomRepository, never()).delete(any(Room.class));
    }

    @Test
    void delete_throwsWhenRoomNotesExist() {
        UUID propertyId = UUID.randomUUID();
        UUID roomId = UUID.randomUUID();
        roomWithId(propertyId, roomId);
        when(roomNoteRepository.countByRoomId(roomId)).thenReturn(6L);

        assertThatThrownBy(() -> roomService.delete(propertyId, roomId))
                .isInstanceOf(BusinessException.class)
                .hasMessage("Không thể xóa phòng vì còn 6 ghi chú liên quan");
        verify(roomRepository, never()).delete(any(Room.class));
    }

    @Test
    void updateStatus_toMaintenanceCreatesTicketWhenNoneActive() {
        UUID roomId = UUID.randomUUID();
        User owner = User.builder().id(UUID.randomUUID()).build();
        Property property = Property.builder().id(UUID.randomUUID()).owner(owner).build();
        Room room = Room.builder().id(roomId).property(property).roomNumber("A1").build();
        when(roomRepository.findById(roomId)).thenReturn(Optional.of(room));
        when(roomRepository.save(room)).thenReturn(room);
        when(maintenanceRepository.countByRoomIdAndStatusNotIn(eq(roomId), anyList())).thenReturn(0L);
        when(maintenanceRepository.save(any(MaintenanceRequest.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        Room result = roomService.updateStatus(roomId, RoomStatus.MAINTENANCE);

        assertThat(result.getStatus()).isEqualTo(RoomStatus.MAINTENANCE);
        verify(maintenanceRepository).save(any(MaintenanceRequest.class));
    }

    @Test
    void updateStatus_toMaintenanceSkipsTicketWhenActiveTicketExists() {
        UUID roomId = UUID.randomUUID();
        User owner = User.builder().id(UUID.randomUUID()).build();
        Property property = Property.builder().id(UUID.randomUUID()).owner(owner).build();
        Room room = Room.builder().id(roomId).property(property).roomNumber("A1").build();
        when(roomRepository.findById(roomId)).thenReturn(Optional.of(room));
        when(roomRepository.save(room)).thenReturn(room);
        when(maintenanceRepository.countByRoomIdAndStatusNotIn(eq(roomId), anyList())).thenReturn(1L);

        Room result = roomService.updateStatus(roomId, RoomStatus.MAINTENANCE);

        assertThat(result.getStatus()).isEqualTo(RoomStatus.MAINTENANCE);
        verify(maintenanceRepository, never()).save(any(MaintenanceRequest.class));
    }
}
