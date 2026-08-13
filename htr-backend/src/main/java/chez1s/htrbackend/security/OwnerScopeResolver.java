package chez1s.htrbackend.security;

import chez1s.htrbackend.domain.enums.UserRole;
import chez1s.htrbackend.exception.BusinessException;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
public class OwnerScopeResolver {
    public UUID requireOwnerId(ActorContext actor) {
        if (!actor.isLandlordAdmin()) {
            throw new BusinessException("Owner scope is not available for this actor");
        }
        return actor.userId();
    }

    public void requireAdministrativeRole(ActorContext actor) {
        if (!actor.isPlatformAdmin() && !actor.isLandlordAdmin()) {
            throw new BusinessException("Administrative access required");
        }
    }

    public boolean canAccessOwner(ActorContext actor, UUID ownerId) {
        return actor.isPlatformAdmin() || (actor.role() == UserRole.LANDLORD_ADMIN && actor.userId().equals(ownerId));
    }
}
