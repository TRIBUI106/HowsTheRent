package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Contract;
import chez1s.htrbackend.dto.request.CreateContractRequest;
import chez1s.htrbackend.dto.request.RenewContractRequest;
import chez1s.htrbackend.dto.response.ContractResponse;
import chez1s.htrbackend.security.ActorContext;
import chez1s.htrbackend.security.OwnerScopeResolver;
import chez1s.htrbackend.service.ContractService;
import chez1s.htrbackend.service.RoomService;
import chez1s.htrbackend.service.StorageService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class ContractController {

    private final ContractService contractService;
    private final RoomService roomService;
    private final StorageService storageService;
    private final OwnerScopeResolver ownerScopeResolver;

    @GetMapping("/contracts")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<List<ContractResponse>> listAll(Authentication authentication) {
        ActorContext actor = ActorContext.require(authentication);
        List<Contract> contracts = actor.isPlatformAdmin()
                ? contractService.listAll()
                : contractService.listByOwner(ownerScopeResolver.requireOwnerId(actor));
        return ResponseEntity.ok(contracts.stream().map(ContractResponse::from).toList());
    }

    @GetMapping("/rooms/{roomId}/contracts")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<List<ContractResponse>> listByRoom(Authentication authentication, @PathVariable UUID roomId) {
        ActorContext actor = ActorContext.require(authentication);
        List<Contract> contracts = contractService.listByRoom(roomId);
        if (!actor.isPlatformAdmin()) {
            UUID ownerId = ownerScopeResolver.requireOwnerId(actor);
            contracts = contracts.stream()
                    .filter(contract -> contract.getRoom().getProperty().getOwner().getId().equals(ownerId))
                    .toList();
        }
        return ResponseEntity.ok(contracts.stream().map(ContractResponse::from).toList());
    }

    @GetMapping("/contracts/mine")
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<List<ContractResponse>> listMine(Authentication auth) {
        UUID tenantId = (UUID) auth.getPrincipal();
        return ResponseEntity.ok(contractService.listByTenant(tenantId).stream().map(ContractResponse::from).toList());
    }

    @GetMapping("/contracts/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN','TENANT','TECHNICIAN')")
    public ResponseEntity<ContractResponse> getById(Authentication authentication, @PathVariable UUID id) {
        ActorContext actor = ActorContext.require(authentication);
        Contract contract = actor.role() == chez1s.htrbackend.domain.enums.UserRole.TENANT
                ? contractService.getByIdForTenant(id, actor.userId())
                : actor.isPlatformAdmin()
                    ? contractService.getById(id)
                    : contractService.getByIdForOwner(id, ownerScopeResolver.requireOwnerId(actor));
        return ResponseEntity.ok(ContractResponse.from(contract));
    }

    @PostMapping("/rooms/{roomId}/contracts")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<ContractResponse> create(Authentication authentication,
                                                   @PathVariable UUID roomId,
                                                   @Valid @RequestBody CreateContractRequest req) {
        requireRoomAccess(ActorContext.require(authentication), roomId);
        return ResponseEntity.status(HttpStatus.CREATED).body(ContractResponse.from(contractService.create(roomId, req)));
    }

    @PostMapping("/contracts/{id}/terminate")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<ContractResponse> terminate(Authentication authentication, @PathVariable UUID id) {
        requireContractAccess(ActorContext.require(authentication), id);
        return ResponseEntity.ok(ContractResponse.from(contractService.terminate(id)));
    }

    @PostMapping("/contracts/{id}/upload")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<ContractResponse> uploadFile(Authentication authentication,
                                                       @PathVariable UUID id,
                                                       @RequestParam("file") MultipartFile file) {
        Contract contract = requireContractAccess(ActorContext.require(authentication), id);
        String url = storageService.upload("contracts/" + id, file);
        contract.setFileUrl(url);
        return ResponseEntity.ok(ContractResponse.from(contractService.save(contract)));
    }

    @PostMapping("/contracts/{id}/renew")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<ContractResponse> renew(Authentication authentication,
                                                  @PathVariable UUID id,
                                                  @Valid @RequestBody RenewContractRequest req) {
        requireContractAccess(ActorContext.require(authentication), id);
        return ResponseEntity.ok(ContractResponse.from(contractService.renew(id, req)));
    }

    private Contract requireContractAccess(ActorContext actor, UUID contractId) {
        return actor.isPlatformAdmin()
                ? contractService.getById(contractId)
                : contractService.getByIdForOwner(contractId, ownerScopeResolver.requireOwnerId(actor));
    }

    private void requireRoomAccess(ActorContext actor, UUID roomId) {
        if (actor.isPlatformAdmin()) {
            return;
        }
        UUID ownerId = ownerScopeResolver.requireOwnerId(actor);
        var room = roomService.getById(roomId);
        if (!room.getProperty().getOwner().getId().equals(ownerId)) {
            throw new chez1s.htrbackend.exception.BusinessException("Room is outside the actor owner scope");
        }
    }
}
