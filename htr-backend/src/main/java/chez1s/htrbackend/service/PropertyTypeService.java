package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.PropertyType;
import chez1s.htrbackend.domain.repository.PropertyRepository;
import chez1s.htrbackend.domain.repository.PropertyTypeRepository;
import chez1s.htrbackend.dto.request.CreatePropertyTypeRequest;
import chez1s.htrbackend.exception.BusinessException;
import chez1s.htrbackend.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PropertyTypeService {

    private final PropertyTypeRepository propertyTypeRepository;
    private final PropertyRepository propertyRepository;

    public List<PropertyType> listAll() {
        return propertyTypeRepository.findAllByOrderByNameAsc();
    }

    public List<PropertyType> listActive() {
        return propertyTypeRepository.findByActiveTrueOrderByNameAsc();
    }

    public PropertyType getById(UUID id) {
        return propertyTypeRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("PropertyType", id));
    }

    public PropertyType getActiveById(UUID id) {
        PropertyType type = getById(id);
        if (!type.isActive()) {
            throw new BusinessException("Loại tài sản đã bị vô hiệu hoá");
        }
        return type;
    }

    @Transactional
    public PropertyType create(CreatePropertyTypeRequest req) {
        String code = normalizeCode(req.getCode());
        if (propertyTypeRepository.existsByCode(code)) {
            throw new BusinessException("Mã loại tài sản đã tồn tại");
        }
        return propertyTypeRepository.save(PropertyType.builder()
                .code(code)
                .name(req.getName().trim())
                .description(req.getDescription())
                .active(true)
                .build());
    }

    @Transactional
    public PropertyType update(UUID id, CreatePropertyTypeRequest req) {
        PropertyType type = getById(id);
        String code = normalizeCode(req.getCode());
        propertyTypeRepository.findByCode(code)
                .filter(existing -> !existing.getId().equals(id))
                .ifPresent(existing -> { throw new BusinessException("Mã loại tài sản đã tồn tại"); });
        type.setCode(code);
        type.setName(req.getName().trim());
        type.setDescription(req.getDescription());
        return propertyTypeRepository.save(type);
    }

    @Transactional
    public PropertyType updateActive(UUID id, boolean active) {
        PropertyType type = getById(id);
        type.setActive(active);
        return propertyTypeRepository.save(type);
    }

    @Transactional
    public void delete(UUID id) {
        PropertyType type = getById(id);
        if (propertyRepository.existsByTypeId(id)) {
            throw new BusinessException("Loại tài sản đang được sử dụng");
        }
        propertyTypeRepository.delete(type);
    }

    private String normalizeCode(String code) {
        return code.trim().toUpperCase().replace(' ', '_');
    }
}
