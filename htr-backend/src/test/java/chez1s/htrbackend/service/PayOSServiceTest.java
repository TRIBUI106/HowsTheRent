package chez1s.htrbackend.service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.lang.reflect.Method;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import java.util.TreeMap;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PayOSServiceTest {

    @Mock
    private InvoiceService invoiceService;

    private PayOSService payOSService;

    private static final String CHECKSUM_KEY = "test-checksum-key-1234";

    @BeforeEach
    void setUp() {
        payOSService = new PayOSService("client-id", "api-key", CHECKSUM_KEY, invoiceService);
    }

    private String computeExpectedHmac(Map<String, Object> data) throws Exception {
        TreeMap<String, String> sorted = new TreeMap<>();
        for (Map.Entry<String, Object> e : data.entrySet()) {
            sorted.put(e.getKey(), String.valueOf(e.getValue()));
        }
        StringBuilder sb = new StringBuilder();
        for (Map.Entry<String, String> e : sorted.entrySet()) {
            if (sb.length() > 0) sb.append("&");
            sb.append(e.getKey()).append("=").append(e.getValue());
        }
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(CHECKSUM_KEY.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        byte[] hash = mac.doFinal(sb.toString().getBytes(StandardCharsets.UTF_8));
        StringBuilder hex = new StringBuilder();
        for (byte b : hash) hex.append(String.format("%02x", b));
        return hex.toString();
    }

    @Test
    void handleWebhook_validSignature_callsMarkPaid() throws Exception {
        Map<String, Object> data = new HashMap<>();
        data.put("orderCode", "123456");
        data.put("code", "00");
        data.put("reference", "TXN-ABC");

        String validSig = computeExpectedHmac(data);

        Map<String, Object> payload = new HashMap<>();
        payload.put("data", data);
        payload.put("signature", validSig);

        payOSService.handleWebhook(payload);

        verify(invoiceService).markPaidPayOS("123456", "TXN-ABC");
    }

    @Test
    void handleWebhook_invalidSignature_throwsBusinessException() {
        Map<String, Object> data = new HashMap<>();
        data.put("orderCode", "123456");
        data.put("code", "00");

        Map<String, Object> payload = new HashMap<>();
        payload.put("data", data);
        payload.put("signature", "invalid-signature");

        assertThatThrownBy(() -> payOSService.handleWebhook(payload))
                .hasMessageContaining("Invalid webhook signature");
    }

    @Test
    void handleWebhook_missingSignature_throwsBusinessException() {
        Map<String, Object> payload = new HashMap<>();
        payload.put("data", Map.of("orderCode", "123456"));
        // no signature key

        assertThatThrownBy(() -> payOSService.handleWebhook(payload))
                .hasMessageContaining("Invalid webhook payload");
    }

    @Test
    void handleWebhook_nonSuccessCode_doesNotMarkPaid() throws Exception {
        Map<String, Object> data = new HashMap<>();
        data.put("orderCode", "123456");
        data.put("code", "01"); // non-success

        String validSig = computeExpectedHmac(data);

        Map<String, Object> payload = new HashMap<>();
        payload.put("data", data);
        payload.put("signature", validSig);

        payOSService.handleWebhook(payload);

        verify(invoiceService, never()).markPaidPayOS(any(), any());
    }

    @Test
    void handleWebhook_nullData_throwsBusinessException() {
        Map<String, Object> payload = new HashMap<>();
        payload.put("data", null);
        payload.put("signature", "any");

        assertThatThrownBy(() -> payOSService.handleWebhook(payload))
                .hasMessageContaining("Invalid webhook payload");
    }
}
