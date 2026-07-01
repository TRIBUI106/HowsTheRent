package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.Contract;
import chez1s.htrbackend.domain.enums.ContractStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ContractRepository extends JpaRepository<Contract, UUID> {
    @Override
    @EntityGraph(attributePaths = {"room", "room.property", "tenant"})
    List<Contract> findAll();

    @Override
    @EntityGraph(attributePaths = {"room", "room.property", "tenant"})
    Page<Contract> findAll(Pageable pageable);

    @EntityGraph(attributePaths = {"room", "room.property", "tenant"})
    List<Contract> findByRoomId(UUID roomId);

    @EntityGraph(attributePaths = {"room", "room.property", "tenant"})
    List<Contract> findByTenantId(UUID tenantId);

    @EntityGraph(attributePaths = {"room", "room.property", "tenant"})
    List<Contract> findByStatus(ContractStatus status);

    boolean existsByRoomIdAndStatus(UUID roomId, ContractStatus status);
    boolean existsByTenantIdAndRoomIdAndStatus(UUID tenantId, UUID roomId, ContractStatus status);

    @EntityGraph(attributePaths = {"room", "room.property", "tenant"})
    Optional<Contract> findFirstByTenantIdAndStatusOrderByCreatedAtDesc(UUID tenantId, ContractStatus status);

    @Override
    @EntityGraph(attributePaths = {"room", "room.property", "tenant"})
    Optional<Contract> findById(UUID id);
}
