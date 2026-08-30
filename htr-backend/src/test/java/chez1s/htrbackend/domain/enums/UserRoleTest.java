package chez1s.htrbackend.domain.enums;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class UserRoleTest {

    @Test
    void guestRoleExists() {
        assertThat(UserRole.valueOf("GUEST")).isEqualTo(UserRole.GUEST);
    }
}
