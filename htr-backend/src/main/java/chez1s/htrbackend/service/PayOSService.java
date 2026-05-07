package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.Invoice;
import chez1s.htrbackend.exception.BusinessException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;
import java.util.TreeMap;

@Service
@Slf4j
public class PayOSService {

    private static final String PAYOS_API = "https://api.payos.vn";
    private final InvoiceService invoiceService;
    private final String clientId;
    private final String apiKey;
    private final String checksumKey;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    public PayOSService(@Value("${payos.client-id}") String clientId,
                        @Value("${payos.api-key}") String apiKey,
                        @Value("${payos.checksum-key}") String checksumKey,
                        InvoiceService invoiceService) {
        this.clientId = clientId;
        this.apiKey = apiKey;
        this.checksumKey = checksumKey;
        this.invoiceService = invoiceService;
        this.restTemplate = new RestTemplate();
        this.objectMapper = new ObjectMapper();
    }

    public String createPaymentLink(Invoice invoice) {
        long orderCode = Math.abs(invoice.getId().hashCode());
        int amount = invoice.getTotalAmount().multiply(BigDecimal.valueOf(100)).intValue();

        Map<String, Object> body = new HashMap<>();
        body.put("orderCode", orderCode);
        body.put("amount", amount);
        body.put("description", "Thanh toan hoa don " + invoice.getInvoiceMonth());
        body.put("buyerName", invoice.getContract().getTenant().getFullName());
        body.put("buyerEmail", invoice.getContract().getTenant().getEmail());
        body.put("returnUrl", "http://localhost:5173/payment/success");
        body.put("cancelUrl", "http://localhost:5173/payment/cancel");

        Map<String, Object> item = new HashMap<>();
        item.put("name", "Hoa don " + invoice.getInvoiceMonth());
        item.put("quantity", 1);
        item.put("price", amount);
        body.put("items", new Object[]{item});

        String response = callPayOS("/payment-v1/payment/create", body);
        try {
            JsonNode root = objectMapper.readTree(response);
            JsonNode data = root.get("data");
            String checkoutUrl = data.get("checkoutUrl").asText();

            invoice.setPaymentLinkId(String.valueOf(orderCode));
            invoice.setCheckoutUrl(checkoutUrl);
            invoiceService.save(invoice);
            return checkoutUrl;
        } catch (Exception e) {
            throw new BusinessException("PayOS error: " + response);
        }
    }

    public void handleWebhook(Map<String, Object> payload) {
        @SuppressWarnings("unchecked")
        Map<String, Object> data = (Map<String, Object>) payload.get("data");
        String signature = payload.get("signature") != null ? payload.get("signature").toString() : null;

        if (data == null || signature == null) {
            throw new BusinessException("Invalid webhook payload");
        }

        String computedSignature = computeHmac(data);
        if (!computedSignature.equals(signature)) {
            throw new BusinessException("Invalid webhook signature");
        }

        String code = String.valueOf(data.get("code"));
        if (!"00".equals(code)) {
            log.info("PayOS non-success code: {}", code);
            return;
        }

        String orderCode = String.valueOf(data.get("orderCode"));
        String transactionId = data.containsKey("reference") ? String.valueOf(data.get("reference")) : orderCode;
        invoiceService.markPaidPayOS(orderCode, transactionId);
        log.info("PayOS payment confirmed: {}", orderCode);
    }

    private String callPayOS(String path, Map<String, Object> body) {
        try {
            String url = PAYOS_API + path;
            String json = objectMapper.writeValueAsString(body);
            String signature = computeHmac(new TreeMap<>(body));
            String auth = Base64.getEncoder().encodeToString((clientId + ":" + apiKey).getBytes());

            return restTemplate.postForObject(url, null, String.class);
        } catch (Exception e) {
            throw new BusinessException("PayOS API call failed: " + e.getMessage());
        }
    }

    private String computeHmac(Map<String, Object> data) {
        TreeMap<String, String> sorted = new TreeMap<>();
        for (Map.Entry<String, Object> e : data.entrySet()) {
            sorted.put(e.getKey(), String.valueOf(e.getValue()));
        }
        StringBuilder sb = new StringBuilder();
        for (Map.Entry<String, String> e : sorted.entrySet()) {
            if (sb.length() > 0) sb.append("&");
            sb.append(e.getKey()).append("=").append(e.getValue());
        }
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(checksumKey.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] hash = mac.doFinal(sb.toString().getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder();
            for (byte b : hash) hex.append(String.format("%02x", b));
            return hex.toString();
        } catch (Exception e) {
            throw new RuntimeException("HMAC failed", e);
        }
    }
}
