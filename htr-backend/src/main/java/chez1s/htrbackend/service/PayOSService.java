package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.Invoice;
import chez1s.htrbackend.domain.entity.PaymentEventReceipt;
import chez1s.htrbackend.domain.entity.PaymentIntent;
import chez1s.htrbackend.domain.repository.PaymentEventReceiptRepository;
import chez1s.htrbackend.domain.repository.PaymentIntentRepository;
import chez1s.htrbackend.exception.BusinessException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.transaction.annotation.Transactional;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.math.BigDecimal;
import java.math.RoundingMode;
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
    private final String returnUrl;
    private final String cancelUrl;
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;
    private final PaymentIntentRepository paymentIntentRepository;
    private final PaymentEventReceiptRepository paymentEventReceiptRepository;

    public PayOSService(String clientId, String apiKey, String checksumKey, String returnUrl,
                        String cancelUrl, InvoiceService invoiceService) {
        this.clientId = clientId;
        this.apiKey = apiKey;
        this.checksumKey = checksumKey;
        this.returnUrl = returnUrl;
        this.cancelUrl = cancelUrl;
        this.invoiceService = invoiceService;
        this.restTemplate = new RestTemplate();
        this.objectMapper = new ObjectMapper();
        this.paymentIntentRepository = null;
        this.paymentEventReceiptRepository = null;
    }
    @Autowired
    public PayOSService(@Value("${payos.client-id}") String clientId,
                        @Value("${payos.api-key}") String apiKey,
                        @Value("${payos.checksum-key}") String checksumKey,
                        @Value("${payos.return-url}") String returnUrl,
                        @Value("${payos.cancel-url}") String cancelUrl,
                        InvoiceService invoiceService,
                        PaymentIntentRepository paymentIntentRepository,
                        PaymentEventReceiptRepository paymentEventReceiptRepository) {
        this.clientId = clientId;
        this.apiKey = apiKey;
        this.checksumKey = checksumKey;
        this.returnUrl = returnUrl;
        this.cancelUrl = cancelUrl;
        this.invoiceService = invoiceService;
        this.restTemplate = new RestTemplate();
        this.objectMapper = new ObjectMapper();
        this.paymentIntentRepository = paymentIntentRepository;
        this.paymentEventReceiptRepository = paymentEventReceiptRepository;
    }

    public String createPaymentLink(Invoice invoice) {
        validateCredentials();
        long orderCode = createOrderCode(invoice);
        int amount = validateAmount(invoice);
        String orderCodeText = String.valueOf(orderCode);
        PaymentIntent intent = paymentIntentRepository == null ? PaymentIntent.builder().invoice(invoice).orderCode(orderCodeText).status("CREATED").build()
                : paymentIntentRepository.findByOrderCode(orderCodeText)
                    .orElseGet(() -> paymentIntentRepository.save(PaymentIntent.builder()
                            .invoice(invoice).orderCode(orderCodeText).status("CREATED").build()));
        if (intent.getCheckoutUrl() != null && !intent.getCheckoutUrl().isBlank()) return intent.getCheckoutUrl();

        Map<String, Object> body = new HashMap<>();
        body.put("orderCode", orderCode);
        body.put("amount", amount);
        body.put("description", "Hoa don " + invoice.getInvoiceMonth().toString().substring(0, 7));
        body.put("buyerName", invoice.getContract().getTenant().getFullName());
        body.put("buyerEmail", invoice.getContract().getTenant().getEmail());
        body.put("returnUrl", returnUrl);
        body.put("cancelUrl", cancelUrl);
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

            intent.setCheckoutUrl(checkoutUrl);
            intent.setStatus("LINK_CREATED");
            if (paymentIntentRepository != null) paymentIntentRepository.save(intent);
            invoice.setPaymentLinkId(orderCodeText);
            invoice.setCheckoutUrl(checkoutUrl);
            invoiceService.save(invoice);
            return checkoutUrl;
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            throw new BusinessException("PayOS error: " + response);
        }
    }

    @Transactional
    public void handleWebhook(Map<String, Object> payload) {
        @SuppressWarnings("unchecked")
        Map<String, Object> data = (Map<String, Object>) payload.get("data");
        String signature = payload.get("signature") != null ? payload.get("signature").toString() : null;

        if (data == null || signature == null) {
            throw new BusinessException("Invalid webhook payload");
        }

        String computedSignature = computeHmac(data);
        if (!computedSignature.equals(signature)) {
            log.warn("PayOS webhook signature mismatch");
            throw new BusinessException("Invalid webhook signature");
        }

        String code = String.valueOf(data.get("code"));
        if (!"00".equals(code)) {
            log.info("PayOS non-success code: {}", code);
            return;
        }

        String orderCode = String.valueOf(data.get("orderCode"));
        String transactionId = data.containsKey("reference") ? String.valueOf(data.get("reference")) : orderCode;
        String eventKey = orderCode + ":" + transactionId;
        if (paymentEventReceiptRepository != null && paymentEventReceiptRepository.existsByEventKey(eventKey)) return;
        PaymentEventReceipt receipt = paymentEventReceiptRepository == null ? null : paymentEventReceiptRepository.save(PaymentEventReceipt.builder()
                .eventKey(eventKey).orderCode(orderCode).transactionId(transactionId).applied(false).build());
        invoiceService.markPaidPayOS(orderCode, transactionId);
        if (receipt != null) {
            receipt.setApplied(true);
            paymentEventReceiptRepository.save(receipt);
        }
        if (paymentIntentRepository != null) paymentIntentRepository.findByOrderCode(orderCode).ifPresent(intent -> {
            intent.setStatus("PAID");
            paymentIntentRepository.save(intent);
        });
        log.info("PayOS payment confirmed: {}", orderCode);
    }

    @Transactional
    public String reconcile(String orderCode) {
        validateCredentials();
        PaymentIntent intent = paymentIntentRepository.findByOrderCode(orderCode)
                .orElseThrow(() -> new BusinessException("Payment intent not found"));
        try {
            String response = callPayOSGet("/v2/payment-requests/" + orderCode);
            JsonNode root = objectMapper.readTree(response);
            JsonNode data = root.path("data");
            String status = data.path("status").asText("UNKNOWN");
            if ("PAID".equalsIgnoreCase(status)) {
                String transactionId = data.path("reference").asText(orderCode);
                invoiceService.markPaidPayOS(orderCode, transactionId);
                intent.setStatus("PAID");
            } else {
                intent.setStatus(status);
            }
            paymentIntentRepository.save(intent);
            return intent.getStatus();
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            throw new BusinessException("Unable to verify payment status");
        }
    }

    private String callPayOSGet(String path) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.set("x-client-id", clientId);
            headers.set("x-api-key", apiKey);
            return restTemplate.exchange(PAYOS_API + path, org.springframework.http.HttpMethod.GET,
                    new HttpEntity<>(headers), String.class).getBody();
        } catch (Exception e) {
            throw new BusinessException("PayOS status verification failed");
        }
    }

    private void validateCredentials() {
        if (clientId.isBlank() || apiKey.isBlank() || checksumKey.isBlank()) {
            throw new BusinessException("PayOS credentials are not configured");
        }
    }

    private long createOrderCode(Invoice invoice) {
        long mixed = invoice.getId().getMostSignificantBits() ^ invoice.getId().getLeastSignificantBits();
        long orderCode = Long.remainderUnsigned(mixed, 9_000_000_000_000_000L);
        return orderCode == 0 ? 1 : orderCode;
    }

    // Package-private (not private) so PayOSServiceTest can exercise it directly.
    int validateAmount(Invoice invoice) {
        BigDecimal totalAmount = invoice.getTotalAmount();
        if (totalAmount == null || totalAmount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new BusinessException("Số tiền hóa đơn phải lớn hơn 0");
        }
        if (totalAmount.compareTo(BigDecimal.valueOf(Integer.MAX_VALUE)) > 0) {
            throw new BusinessException("Số tiền hóa đơn vượt quá giới hạn PayOS");
        }
        // VND has no subdivision — round to the nearest whole đồng rather than rejecting the
        // payment outright. BillingService now generates whole-VND amounts for new invoices, but
        // this also keeps invoices created before that fix (or via any other path) payable instead
        // of surfacing a confusing "Số tiền hóa đơn phải là số nguyên hợp lệ" 400 to the tenant.
        try {
            return totalAmount.setScale(0, RoundingMode.HALF_UP).intValueExact();
        } catch (ArithmeticException e) {
            throw new BusinessException("Số tiền hóa đơn vượt quá giới hạn PayOS");
        }
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
            Object value = e.getValue();
            String stringValue = value == null ? "" : String.valueOf(value);
            if ("null".equals(stringValue) || "undefined".equals(stringValue)) {
                stringValue = "";
            }
            sorted.put(e.getKey(), stringValue);
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
