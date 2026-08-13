package chez1s.htrbackend.security;

import chez1s.htrbackend.domain.enums.UserRole;
import chez1s.htrbackend.exception.BusinessException;
import org.junit.jupiter.api.Test;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class OwnerScopeResolverTest {

    private final OwnerScopeResolver resolver = new OwnerScopeResolver();

    @Test
    void resolvesLandlordOwnerIdFromAuthenticatedActor() {
        UUID landlordId = UUID.randomUUID();
        ActorContext actor = new ActorContext(landlordId, UserRole.LANDLORD_ADMIN, 0);

        assertThat(resolver.requireOwnerId(actor)).isEqualTo(landlordId);
        assertThat(resolver.canAccessOwner(actor, landlordId)).isTrue();
        assertThat(resolver.canAccessOwner(actor, UUID.randomUUID())).isFalse();
    }

    @Test
    void platformAndLegacyAdminsCanAccessAnyOwner() {
        UUID ownerId = UUID.randomUUID();

        assertThat(resolver.canAccessOwner(
                new ActorContext(UUID.randomUUID(), UserRole.PLATFORM_ADMIN, 0), ownerId
        )).isTrue();
        assertThat(resolver.canAccessOwner(
                new ActorContext(UUID.randomUUID(), UserRole.ADMIN, 0), ownerId
        )).isTrue();
    }

    @Test
    void nonAdministrativeActorsAreDeniedOwnerScope() {
        ActorContext tenant = new ActorContext(UUID.randomUUID(), UserRole.TENANT, 0);

        assertThatThrownBy(() -> resolver.requireOwnerId(tenant))
                .isInstanceOf(BusinessException.class);
        assertThatThrownBy(() -> resolver.requireAdministrativeRole(tenant))
                .isInstanceOf(BusinessException.class);
        assertThat(resolver.canAccessOwner(tenant, UUID.randomUUID())).isFalse();
    }
}
