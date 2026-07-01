package chez1s.htrbackend.config;

import jakarta.persistence.EntityManager;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Component
@Order(2)
@RequiredArgsConstructor
public class PropertyTypeMigration implements CommandLineRunner {

    private final EntityManager entityManager;

    @Override
    @Transactional
    public void run(String... args) {
        if (!hasLegacyTypeColumn()) {
            return;
        }

        ensureUuidTypeColumn();
        fillMissingTypeIds();
        finalizeTypeColumn();
    }

    private boolean hasLegacyTypeColumn() {
        List<?> results = entityManager.createNativeQuery("""
                select data_type
                from information_schema.columns
                where table_name = 'properties'
                  and column_name = 'type'
                """).getResultList();

        if (results.isEmpty()) {
            return false;
        }
        Object result = results.getFirst();
        return result != null && !"uuid".equalsIgnoreCase(result.toString());
    }

    private void ensureUuidTypeColumn() {
        entityManager.createNativeQuery("""
                alter table properties
                add column if not exists type_uuid uuid
                """).executeUpdate();

        entityManager.createNativeQuery("""
                update properties p
                set type_uuid = pt.id
                from property_types pt
                where p.type_uuid is null
                  and upper(trim(p.type)) = pt.code
                """).executeUpdate();

        entityManager.createNativeQuery("""
                update properties p
                set type_uuid = pt.id
                from property_types pt
                where p.type_uuid is null
                  and pt.code = 'BOARDING_HOUSE'
                """).executeUpdate();
    }

    private void fillMissingTypeIds() {
        entityManager.createNativeQuery("""
                update properties p
                set type_uuid = pt.id
                from property_types pt
                where p.type is null
                  and p.type_uuid is null
                  and pt.code = 'BOARDING_HOUSE'
                """).executeUpdate();
    }

    private void finalizeTypeColumn() {
        entityManager.createNativeQuery("""
                alter table properties
                drop column type
                """).executeUpdate();

        entityManager.createNativeQuery("""
                alter table properties
                rename column type_uuid to type
                """).executeUpdate();
    }
}
