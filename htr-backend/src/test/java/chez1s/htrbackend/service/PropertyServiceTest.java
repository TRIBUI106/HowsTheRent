package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.repository.FeeConfigRepository;
import chez1s.htrbackend.domain.repository.PropertyRepository;
import chez1s.htrbackend.domain.repository.RoomRepository;
import chez1s.htrbackend.domain.repository.UserRepository;
import chez1s.htrbackend.exception.BusinessException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PropertyServiceTest {

    @Mock PropertyRepository propertyRepository;
    @Mock FeeConfigRepository feeConfigRepository;
    @Mock RoomRepository roomRepository;
    @Mock UserRepository userRepository;
    @Mock PropertyTypeService propertyTypeService;

    @InjectMocks PropertyService propertyService;

    @Test
    void delete_removesPropertyAndFeeConfigWhenNoRoomsExist() {
        UUID propertyId = UUID.randomUUID();
        Property property = Property.builder().id(propertyId).build();
        when(propertyRepository.findById(propertyId)).thenReturn(Optional.of(property));
        when(roomRepository.countByPropertyId(propertyId)).thenReturn(0L);

        propertyService.delete(propertyId);

        verify(feeConfigRepository).deleteByPropertyId(propertyId);
        verify(propertyRepository).deleteById(propertyId);
    }

    @Test
    void delete_throwsWhenRoomsExist() {
        UUID propertyId = UUID.randomUUID();
        Property property = Property.builder().id(propertyId).build();
        when(propertyRepository.findById(propertyId)).thenReturn(Optional.of(property));
        when(roomRepository.countByPropertyId(propertyId)).thenReturn(3L);

        assertThatThrownBy(() -> propertyService.delete(propertyId))
                .isInstanceOf(BusinessException.class)
                .hasMessage("Không thể xóa tài sản vì còn 3 phòng liên quan. Vui lòng xóa hết phòng trước.");
        verify(feeConfigRepository, never()).deleteByPropertyId(propertyId);
        verify(propertyRepository, never()).deleteById(propertyId);
    }
}
