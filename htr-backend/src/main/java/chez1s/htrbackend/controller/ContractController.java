package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Contract;
import chez1s.htrbackend.dto.request.CreateContractRequest;
import chez1s.htrbackend.dto.request.RenewContractRequest;
import chez1s.htrbackend.dto.response.ContractResponse;
import chez1s.htrbackend.dto.response.PageResponse;
import chez1s.htrbackend.service.ContractService;
import chez1s.htrbackend.service.StorageService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
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
    private final StorageService storageService;

    @GetMapping("/contracts")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<ContractResponse>> listAll() {
        return ResponseEntity.ok(contractService.listAll().stream().map(ContractResponse::from).toList());
    }

    @GetMapping("/rooms/{roomId}/contracts")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<ContractResponse>> listByRoom(@PathVariable UUID roomId) {
        return ResponseEntity.ok(contractService.listByRoom(roomId).stream().map(ContractResponse::from).toList());
    }

    @GetMapping("/contracts/mine")
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<List<ContractResponse>> listMine(Authentication auth) {
        UUID tenantId = (UUID) auth.getPrincipal();
        return ResponseEntity.ok(contractService.listByTenant(tenantId).stream().map(ContractResponse::from).toList());
    }

    @GetMapping("/contracts/{id}")
    public ResponseEntity<ContractResponse> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(ContractResponse.from(contractService.getById(id)));
    }

    @PostMapping("/rooms/{roomId}/contracts")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ContractResponse> create(@PathVariable UUID roomId,
                                                   @Valid @RequestBody CreateContractRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ContractResponse.from(contractService.create(roomId, req)));
    }

    @PostMapping("/contracts/{id}/terminate")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ContractResponse> terminate(@PathVariable UUID id) {
        return ResponseEntity.ok(ContractResponse.from(contractService.terminate(id)));
    }

    @PostMapping("/contracts/{id}/upload")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ContractResponse> uploadFile(@PathVariable UUID id,
                                                       @RequestParam("file") MultipartFile file) {
        String url = storageService.upload("contracts/" + id, file);
        Contract contract = contractService.getById(id);
        contract.setFileUrl(url);
        return ResponseEntity.ok(ContractResponse.from(contractService.save(contract)));
    }

    @PostMapping("/contracts/{id}/renew")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ContractResponse> renew(@PathVariable UUID id, @Valid @RequestBody RenewContractRequest req) {
        return ResponseEntity.ok(ContractResponse.from(contractService.renew(id, req)));
    }
}
