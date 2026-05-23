package chez1s.htrbackend.config;

import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@Order(2)
@RequiredArgsConstructor
public class PropertyTypeMigration implements CommandLineRunner {

    private final EntityManager entityManager;

    @Override
    @Transactional
    public void run(String... args) {
        entityManager.createNativeQuery("""
                update properties p
                set property_type_id = pt.id
                from property_types pt
                where p.property_type_id is null
                  and pt.code = coalesce(p.type, 'BOARDING_HOUSE')
                """).executeUpdate();
    }
}
