package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.Invoice;
import chez1s.htrbackend.exception.BusinessException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import java.util.TreeMap;

@Service
@Slf4j
public class PayOSService {

    private static final String PAYOS_API = "https://api-merchant.payos.vn";
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
        int amount = invoice.getTotalAmount().intValueExact();
        if (amount <= 0) {
            throw new BusinessException("Số tiền hóa đơn phải lớn hơn 0");
        }

        Map<String, Object> body = new HashMap<>();
        body.put("orderCode", orderCode);
        body.put("amount", amount);
        body.put("description", "Hoa don " + invoice.getInvoiceMonth().toString().substring(0, 7));
        body.put("buyerName", invoice.getContract().getTenant().getFullName());
        body.put("buyerEmail", invoice.getContract().getTenant().getEmail());
        body.put("returnUrl", "http://localhost:5173/payment/success");
        body.put("cancelUrl", "http://localhost:5173/payment/cancel");
        body.put("signature", computePaymentRequestSignature(body));

        Map<String, Object> item = new HashMap<>();
        item.put("name", "Hóa đơn " + invoice.getInvoiceMonth());
        item.put("quantity", 1);
        item.put("price", amount);
        body.put("items", new Object[]{item});

        String response = callPayOS("/v2/payment-requests", body);
        try {
            JsonNode root = objectMapper.readTree(response);
            JsonNode data = root.path("data");
            String checkoutUrl = data.path("checkoutUrl").asText();
            if (!"00".equals(root.path("code").asText()) || checkoutUrl.isBlank()) {
                throw new BusinessException("PayOS không trả về liên kết thanh toán: " + root.path("desc").asText());
            }

            invoice.setPaymentLinkId(String.valueOf(orderCode));
            invoice.setCheckoutUrl(checkoutUrl);
            invoiceService.save(invoice);
            return checkoutUrl;
        } catch (BusinessException e) {
            throw e;
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
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("x-client-id", clientId);
            headers.set("x-api-key", apiKey);
            return restTemplate.postForObject(url, new HttpEntity<>(body, headers), String.class);
        } catch (Exception e) {
            throw new BusinessException("PayOS API call failed: " + e.getMessage());
        }
    }

    private String computePaymentRequestSignature(Map<String, Object> body) {
        Map<String, Object> signatureData = new TreeMap<>();
        signatureData.put("amount", body.get("amount"));
        signatureData.put("cancelUrl", body.get("cancelUrl"));
        signatureData.put("description", body.get("description"));
        signatureData.put("orderCode", body.get("orderCode"));
        signatureData.put("returnUrl", body.get("returnUrl"));
        return computeHmac(signatureData);
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
