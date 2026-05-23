package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.PropertyType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PropertyTypeRepository extends JpaRepository<PropertyType, UUID> {
    List<PropertyType> findAllByOrderByNameAsc();
    List<PropertyType> findByActiveTrueOrderByNameAsc();
    Optional<PropertyType> findByCode(String code);
    boolean existsByCode(String code);
}
