package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.Contract;
import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.ContractStatus;
import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.repository.ContractRepository;
import chez1s.htrbackend.domain.repository.UserRepository;
import chez1s.htrbackend.dto.request.CreateContractRequest;
import chez1s.htrbackend.exception.BusinessException;
import chez1s.htrbackend.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class ContractService {

    private final ContractRepository contractRepository;
    private final UserRepository userRepository;
    private final RoomService roomService;

    public List<Contract> listByRoom(UUID roomId) {
        return contractRepository.findByRoomId(roomId);
    }

    public List<Contract> listByTenant(UUID tenantId) {
        return contractRepository.findByTenantId(tenantId);
    }

    public Contract getById(UUID id) {
        return contractRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Contract", id));
    }

    @Transactional
    public Contract create(UUID roomId, CreateContractRequest req) {
        if (contractRepository.existsByRoomIdAndStatus(roomId, ContractStatus.ACTIVE)) {
            throw new BusinessException("Room already has an active contract");
        }
        Room room = roomService.getById(roomId);
        User tenant = userRepository.findById(req.getTenantId())
                .orElseThrow(() -> new ResourceNotFoundException("User", req.getTenantId()));
        Contract contract = Contract.builder()
                .room(room)
                .tenant(tenant)
                .moveInDate(req.getMoveInDate())
                .status(ContractStatus.ACTIVE)
                .depositAmount(req.getDepositAmount())
                .notes(req.getNotes())
                .build();
        contract = contractRepository.save(contract);
        roomService.updateStatus(roomId, RoomStatus.RENTED);
        return contract;
    }

    @Transactional
    public Contract save(Contract contract) {
        return contractRepository.save(contract);
    }

    @Transactional
    public Contract terminate(UUID id) {
        Contract contract = getById(id);
        if (contract.getStatus() != ContractStatus.ACTIVE) {
            throw new BusinessException("Contract is not active");
        }
        contract.setStatus(ContractStatus.TERMINATED);
        contract.setMoveOutDate(LocalDate.now());
        contract = contractRepository.save(contract);
        roomService.updateStatus(contract.getRoom().getId(), RoomStatus.EMPTY);
        return contract;
    }
}
