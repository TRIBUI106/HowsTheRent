package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.PropertyType;
import chez1s.htrbackend.domain.repository.PropertyRepository;
import chez1s.htrbackend.domain.repository.PropertyTypeRepository;
import chez1s.htrbackend.dto.request.CreatePropertyTypeRequest;
import chez1s.htrbackend.exception.BusinessException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class PropertyTypeServiceTest {

    private PropertyTypeRepository propertyTypeRepository;
    private PropertyRepository propertyRepository;
    private PropertyTypeService propertyTypeService;

    @BeforeEach
    void setUp() {
        propertyTypeRepository = mock(PropertyTypeRepository.class);
        propertyRepository = mock(PropertyRepository.class);
        propertyTypeService = new PropertyTypeService(propertyTypeRepository, propertyRepository);
    }

    @Test
    void create_savesActivePropertyTypeWithUppercaseCode() {
        CreatePropertyTypeRequest request = new CreatePropertyTypeRequest();
        request.setCode(" nha_tro ");
        request.setName("Nhà trọ");
        request.setDescription("Dãy phòng cho thuê");
        when(propertyTypeRepository.existsByCode("NHA_TRO")).thenReturn(false);
        when(propertyTypeRepository.save(any(PropertyType.class))).thenAnswer(invocation -> invocation.getArgument(0));

        PropertyType result = propertyTypeService.create(request);

        assertThat(result.getCode()).isEqualTo("NHA_TRO");
        assertThat(result.getName()).isEqualTo("Nhà trọ");
        assertThat(result.getDescription()).isEqualTo("Dãy phòng cho thuê");
        assertThat(result.isActive()).isTrue();
    }

    @Test
    void listActive_returnsOnlyActiveTypes() {
        PropertyType type = PropertyType.builder().code("CONDO").name("Chung cư").active(true).build();
        when(propertyTypeRepository.findByActiveTrueOrderByNameAsc()).thenReturn(List.of(type));

        List<PropertyType> result = propertyTypeService.listActive();

        assertThat(result).containsExactly(type);
    }

    @Test
    void delete_throwsWhenTypeIsUsedByProperty() {
        UUID id = UUID.randomUUID();
        PropertyType type = PropertyType.builder().id(id).code("CONDO").name("Chung cư").active(true).build();
        when(propertyTypeRepository.findById(id)).thenReturn(Optional.of(type));
        when(propertyRepository.existsByTypeId(id)).thenReturn(true);

        assertThatThrownBy(() -> propertyTypeService.delete(id))
                .isInstanceOf(BusinessException.class)
                .hasMessage("Loại tài sản đang được sử dụng");
        verify(propertyTypeRepository, never()).delete(type);
    }
}
