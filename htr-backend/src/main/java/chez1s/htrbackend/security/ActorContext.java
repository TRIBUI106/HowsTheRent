package chez1s.htrbackend.security;

import chez1s.htrbackend.domain.enums.UserRole;

import org.springframework.security.core.Authentication;

import java.util.UUID;

public record ActorContext(UUID userId, UserRole role, long authVersion) {
    public static ActorContext require(Authentication authentication) {
        if (authentication != null && authentication.getDetails() instanceof ActorContext actor) {
            return actor;
        }
        throw new IllegalStateException("Authenticated actor context is unavailable");
    }
    public boolean isPlatformAdmin() {
        return role == UserRole.PLATFORM_ADMIN || role == UserRole.ADMIN;
    }

    public boolean isLandlordAdmin() {
        return role == UserRole.LANDLORD_ADMIN;
    }
}
