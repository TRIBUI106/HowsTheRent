package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.Invoice;
import chez1s.htrbackend.exception.BusinessException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.math.BigDecimal;
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
        payOSService = new PayOSService("client-id", "api-key", CHECKSUM_KEY,
                "http://localhost:5173/payment/success", "http://localhost:5173/payment/cancel", invoiceService);
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

    // ---- validateAmount ----

    private Invoice invoiceWithAmount(BigDecimal amount) {
        return Invoice.builder().totalAmount(amount).build();
    }

    @Test
    void validateAmount_wholeAmount_returnsItUnchanged() {
        assertThat(payOSService.validateAmount(invoiceWithAmount(new BigDecimal("223667"))))
                .isEqualTo(223667);
    }

    // Regression test: VND has no subdivision, so an invoice carrying residual sub-đồng
    // fractions (e.g. from an uneven pro-rata division, or one generated before that rounding
    // fix) must still be payable — round to the nearest whole đồng instead of rejecting it.
    @Test
    void validateAmount_residualFraction_roundsToNearestDong() {
        assertThat(payOSService.validateAmount(invoiceWithAmount(new BigDecimal("1258064.52"))))
                .isEqualTo(1258065);
        assertThat(payOSService.validateAmount(invoiceWithAmount(new BigDecimal("1258064.49"))))
                .isEqualTo(1258064);
    }

    @Test
    void validateAmount_zeroOrNegative_throwsBusinessException() {
        assertThatThrownBy(() -> payOSService.validateAmount(invoiceWithAmount(BigDecimal.ZERO)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("lớn hơn 0");
        assertThatThrownBy(() -> payOSService.validateAmount(invoiceWithAmount(new BigDecimal("-100"))))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("lớn hơn 0");
    }

    @Test
    void validateAmount_nullAmount_throwsBusinessException() {
        assertThatThrownBy(() -> payOSService.validateAmount(invoiceWithAmount(null)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("lớn hơn 0");
    }

    @Test
    void validateAmount_exceedsIntRange_throwsBusinessException() {
        BigDecimal tooLarge = BigDecimal.valueOf(Integer.MAX_VALUE).add(BigDecimal.ONE);
        assertThatThrownBy(() -> payOSService.validateAmount(invoiceWithAmount(tooLarge)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("vượt quá giới hạn");
    }
}
