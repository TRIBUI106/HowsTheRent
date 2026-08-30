package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.service.RoomService;
import chez1s.htrbackend.service.StorageService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class RoomControllerTest {

    @Mock
    private RoomService roomService;
    @Mock
    private StorageService storageService;

    private RoomController controller;
    private UUID propertyId;
    private UUID roomId;

    @BeforeEach
    void setup() {
        controller = new RoomController(roomService, storageService);
        propertyId = UUID.randomUUID();
        roomId = UUID.randomUUID();
    }

    @Test
    void deleteImage_RemovesUrlFromRoomAndCallsStorageDelete() {
        String keepUrl = "https://storage.example.com/rooms/" + roomId + "/keep.jpg";
        String removeUrl = "https://storage.example.com/rooms/" + roomId + "/remove.jpg";
        Room room = Room.builder()
                .id(roomId)
                .images(new ArrayList<>(List.of(keepUrl, removeUrl)))
                .build();
        when(roomService.getById(roomId)).thenReturn(room);
        when(roomService.save(room)).thenReturn(room);

        ResponseEntity<List<String>> response = controller.deleteImage(propertyId, roomId, removeUrl);

        assertThat(room.getImages()).containsExactly(keepUrl);
        assertThat(response.getBody()).containsExactly(keepUrl);
        verify(roomService).save(room);
        verify(storageService).delete(removeUrl);
    }

    @Test
    void deleteImage_UnknownUrlLeavesImagesUnchanged() {
        String existingUrl = "https://storage.example.com/rooms/" + roomId + "/existing.jpg";
        Room room = Room.builder()
                .id(roomId)
                .images(new ArrayList<>(List.of(existingUrl)))
                .build();
        when(roomService.getById(roomId)).thenReturn(room);
        when(roomService.save(room)).thenReturn(room);

        controller.deleteImage(propertyId, roomId, "https://storage.example.com/rooms/" + roomId + "/not-there.jpg");

        assertThat(room.getImages()).containsExactly(existingUrl);
        verify(storageService).delete(any());
    }
}
