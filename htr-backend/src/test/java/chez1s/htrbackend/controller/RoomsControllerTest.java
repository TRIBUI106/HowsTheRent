package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.enums.UserRole;
import chez1s.htrbackend.domain.repository.RoomRepository;
import chez1s.htrbackend.security.ActorContext;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.Authentication;

import java.util.List;
import java.util.UUID;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class RoomsControllerTest {

    @Mock
    private RoomRepository roomRepository;
    @Mock
    private Authentication authentication;

    private RoomsController controller;
    private UUID actorId;

    @BeforeEach
    void setup() {
        controller = new RoomsController(roomRepository);
        actorId = UUID.randomUUID();
        when(authentication.getPrincipal()).thenReturn(actorId);
    }

    @Test
    void listRented_PlatformAdminSeesAllRentedRooms() {
        when(authentication.getDetails()).thenReturn(new ActorContext(actorId, UserRole.PLATFORM_ADMIN, 1L));
        when(roomRepository.findByStatus(RoomStatus.RENTED)).thenReturn(List.of());

        controller.listRented(authentication);

        verify(roomRepository).findByStatus(RoomStatus.RENTED);
    }

    @Test
    void listRented_AdminSeesAllRentedRooms() {
        when(authentication.getDetails()).thenReturn(new ActorContext(actorId, UserRole.ADMIN, 1L));
        when(roomRepository.findByStatus(RoomStatus.RENTED)).thenReturn(List.of());

        controller.listRented(authentication);

        verify(roomRepository).findByStatus(RoomStatus.RENTED);
    }

    @Test
    void listRented_LandlordAdminSeesOnlyOwnRentedRooms() {
        when(authentication.getDetails()).thenReturn(new ActorContext(actorId, UserRole.LANDLORD_ADMIN, 1L));
        when(roomRepository.findByPropertyOwnerIdAndStatus(actorId, RoomStatus.RENTED)).thenReturn(List.of());

        controller.listRented(authentication);

        verify(roomRepository).findByPropertyOwnerIdAndStatus(actorId, RoomStatus.RENTED);
    }
}
