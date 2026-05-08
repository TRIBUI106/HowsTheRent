package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Contract;
import chez1s.htrbackend.dto.request.CreateContractRequest;
import chez1s.htrbackend.security.JwtTokenProvider;
import chez1s.htrbackend.service.ContractService;
import chez1s.htrbackend.service.StorageService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
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
    private final JwtTokenProvider jwtTokenProvider;

    @GetMapping("/contracts")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<Contract>> listAll() {
        return ResponseEntity.ok(contractService.listAll());
    }

    @GetMapping("/rooms/{roomId}/contracts")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<Contract>> listByRoom(@PathVariable UUID roomId) {
        return ResponseEntity.ok(contractService.listByRoom(roomId));
    }

    @GetMapping("/contracts/mine")
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<List<Contract>> listMine(@RequestHeader("Authorization") String authHeader) {
        UUID tenantId = jwtTokenProvider.getUserId(authHeader.replace("Bearer ", ""));
        return ResponseEntity.ok(contractService.listByTenant(tenantId));
    }

    @GetMapping("/contracts/{id}")
    public ResponseEntity<Contract> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(contractService.getById(id));
    }

    @PostMapping("/rooms/{roomId}/contracts")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Contract> create(@PathVariable UUID roomId,
                                           @Valid @RequestBody CreateContractRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED).body(contractService.create(roomId, req));
    }

    @PostMapping("/contracts/{id}/terminate")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Contract> terminate(@PathVariable UUID id) {
        return ResponseEntity.ok(contractService.terminate(id));
    }

    @PostMapping("/contracts/{id}/upload")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Contract> uploadFile(@PathVariable UUID id,
                                               @RequestParam("file") MultipartFile file) {
        String url = storageService.upload("contracts/" + id, file);
        Contract contract = contractService.getById(id);
        contract.setFileUrl(url);
        return ResponseEntity.ok(contractService.save(contract));
    }
}
