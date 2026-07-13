package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.UserRole;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
    List<User> findByRole(UserRole role);
    List<User> findByRoleAndActiveTrue(UserRole role);
}
