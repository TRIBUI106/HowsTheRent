package chez1s.htrbackend.config;

import chez1s.htrbackend.domain.enums.AuditAction;
import chez1s.htrbackend.security.JwtTokenProvider;
import chez1s.htrbackend.service.AuditService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.util.UUID;

@Component
@RequiredArgsConstructor
public class AuditInterceptor implements HandlerInterceptor {

    private final AuditService auditService;
    private final JwtTokenProvider jwtTokenProvider;

    @Override
    public void afterCompletion(HttpServletRequest request, HttpServletResponse response,
                                Object handler, Exception ex) {
        String path = request.getRequestURI();
        if (!path.startsWith("/api")) return;
        if (path.startsWith("/api/auth") || path.startsWith("/api/payment/callback")) return;

        String method = request.getMethod();
        if (!"POST".equals(method) && !"PUT".equals(method) && !"DELETE".equals(method)) return;

        String authHeader = request.getHeader("Authorization");
        UUID userId = null;
        String userEmail = null;
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.replace("Bearer ", "");
            if (jwtTokenProvider.validateToken(token)) {
                try {
                    userId = jwtTokenProvider.getUserId(token);
                    userEmail = jwtTokenProvider.parseToken(token).get("email", String.class);
                } catch (Exception ignored) {}
            }
        }

        AuditAction action = mapMethodToAction(method, path);
        String entityType = extractEntityType(path);
        String ip = request.getRemoteAddr();

        auditService.log(action, entityType, null, userId, userEmail,
                method + " " + path, method, path, ip);
    }

    private AuditAction mapMethodToAction(String method, String path) {
        if ("DELETE".equals(method)) return AuditAction.DELETE;
        if (path.contains("/terminate")) return AuditAction.TERMINATE;
        if (path.contains("/renew")) return AuditAction.RENEW;
        if (path.contains("/upload")) return AuditAction.UPLOAD;
        if (path.contains("/assign")) return AuditAction.ASSIGN;
        if (path.contains("/resolve")) return AuditAction.RESOLVE;
        if (path.contains("/pay")) return AuditAction.PAYMENT;
        if ("POST".equals(method)) return AuditAction.CREATE;
        return AuditAction.UPDATE;
    }

    private String extractEntityType(String path) {
        if (path.contains("/properties")) return "Property";
        if (path.contains("/rooms")) return "Room";
        if (path.contains("/contracts")) return "Contract";
        if (path.contains("/invoices")) return "Invoice";
        if (path.contains("/maintenance")) return "MaintenanceRequest";
        if (path.contains("/meter-readings")) return "MeterReading";
        if (path.contains("/users")) return "User";
        if (path.contains("/notifications")) return "Notification";
        if (path.contains("/fee-config")) return "FeeConfig";
        if (path.contains("/vehicle")) return "VehicleRecord";
        if (path.contains("/audit")) return "AuditLog";
        return "Unknown";
    }
}
