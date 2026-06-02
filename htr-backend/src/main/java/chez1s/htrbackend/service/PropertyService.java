package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.*;
import chez1s.htrbackend.domain.repository.*;
import chez1s.htrbackend.dto.request.CreatePropertyRequest;
import chez1s.htrbackend.dto.request.UpdateFeeConfigRequest;
import chez1s.htrbackend.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PropertyService {

    private final PropertyRepository propertyRepository;
    private final FeeConfigRepository feeConfigRepository;
    private final RoomRepository roomRepository;
    private final UserRepository userRepository;
    private final PropertyTypeService propertyTypeService;

    public List<Property> listByOwner(UUID ownerId) {
        return propertyRepository.findByOwnerId(ownerId);
    }

    public List<Property> listAll() {
        return propertyRepository.findAll();
    }

    public Property getById(UUID id) {
        return propertyRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Property", id));
    }

    @Transactional
    public Property create(UUID ownerId, CreatePropertyRequest req) {
        User owner = userRepository.findById(ownerId)
                .orElseThrow(() -> new ResourceNotFoundException("User", ownerId));
        Property property = Property.builder()
                .owner(owner)
                .name(req.getName())
                .address(req.getAddress())
                .type(propertyTypeService.getActiveById(req.getPropertyTypeId()))
                .description(req.getDescription())
                .build();
        property = propertyRepository.save(property);

        FeeConfig feeConfig = FeeConfig.builder()
                .property(property)
                .rentDefault(BigDecimal.ZERO)
                .elecPrice(BigDecimal.ZERO)
                .waterMode(chez1s.htrbackend.domain.enums.WaterMode.PERSON)
                .waterPrice(BigDecimal.ZERO)
                .serviceFee(BigDecimal.ZERO)
                .vehicleProRata(false)
                .serviceProRata(false)
                .motorbikePrice(BigDecimal.ZERO)
                .carPrice(BigDecimal.ZERO)
                .bicyclePrice(BigDecimal.ZERO)
                .build();
        feeConfig = feeConfigRepository.save(feeConfig);

        return property;
    }

    @Transactional
    public Property update(UUID id, CreatePropertyRequest req) {
        Property property = getById(id);
        property.setName(req.getName());
        property.setAddress(req.getAddress());
        property.setType(propertyTypeService.getActiveById(req.getPropertyTypeId()));
        property.setDescription(req.getDescription());
        return propertyRepository.save(property);
    }

    @Transactional
    public void delete(UUID id) {
        getById(id);
        roomRepository.deleteByPropertyId(id);
        feeConfigRepository.deleteByPropertyId(id);
        propertyRepository.deleteById(id);
    }

    public FeeConfig getFeeConfig(UUID propertyId) {
        return feeConfigRepository.findByPropertyId(propertyId)
                .orElseThrow(() -> new ResourceNotFoundException("FeeConfig", propertyId));
    }

    @Transactional
    public FeeConfig updateFeeConfig(UUID propertyId, UpdateFeeConfigRequest req) {
        FeeConfig config = getFeeConfig(propertyId);
        config.setRentDefault(req.getRentDefault());
        config.setElecPrice(req.getElecPrice());
        config.setWaterMode(req.getWaterMode());
        config.setWaterPrice(req.getWaterPrice());
        config.setServiceFee(req.getServiceFee());
        config.setVehicleProRata(req.isVehicleProRata());
        config.setServiceProRata(req.isServiceProRata());
        config.setMotorbikePrice(req.getMotorbikePrice());
        config.setCarPrice(req.getCarPrice());
        config.setBicyclePrice(req.getBicyclePrice());
        return feeConfigRepository.save(config);
    }
}
