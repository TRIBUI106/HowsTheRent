package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.repository.RoomRepository;
import chez1s.htrbackend.dto.response.VacancyResponse;
import chez1s.htrbackend.service.PropertyService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PublicPropertyControllerTest {

    @Mock PropertyService propertyService;
    @Mock RoomRepository roomRepository;

    private PublicPropertyController controller;
    private UUID propertyId;

    @BeforeEach
    void setup() {
        controller = new PublicPropertyController(propertyService, roomRepository);
        propertyId = UUID.randomUUID();
        when(propertyService.getById(propertyId)).thenReturn(Property.builder().id(propertyId).build());
    }

    @Test
    void vacancyReturnsCountsByStatus() {
        when(roomRepository.countByPropertyIdAndStatus(propertyId, RoomStatus.EMPTY)).thenReturn(2L);
        when(roomRepository.countByPropertyIdAndStatus(propertyId, RoomStatus.RENTED)).thenReturn(5L);
        when(roomRepository.countByPropertyIdAndStatus(propertyId, RoomStatus.MAINTENANCE)).thenReturn(1L);

        ResponseEntity<VacancyResponse> result = controller.vacancy(propertyId);

        assertThat(result.getBody().emptyCount()).isEqualTo(2L);
        assertThat(result.getBody().rentedCount()).isEqualTo(5L);
        assertThat(result.getBody().totalCount()).isEqualTo(8L);
    }
}
