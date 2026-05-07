package chez1s.htrbackend.controller;

import chez1s.htrbackend.service.PayOSService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/payment")
@RequiredArgsConstructor
@Slf4j
public class PaymentController {

    private final PayOSService payOSService;

    @PostMapping("/callback")
    public ResponseEntity<Map<String, String>> handleCallback(@RequestBody Map<String, Object> payload) {
        log.info("PayOS callback received");
        payOSService.handleWebhook(payload);
        return ResponseEntity.ok(Map.of("status", "ok"));
    }
}
