package chez1s.htrbackend.config;

import chez1s.htrbackend.domain.entity.PropertyType;
import chez1s.htrbackend.domain.repository.PropertyTypeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

@Component
@Order(1)
@RequiredArgsConstructor
public class PropertyTypeSeeder implements CommandLineRunner {

    private final PropertyTypeRepository propertyTypeRepository;

    @Override
    public void run(String... args) {
        seed("BOARDING_HOUSE", "Nhà trọ");
        seed("CONDO", "Chung cư");
    }

    private void seed(String code, String name) {
        propertyTypeRepository.findByCode(code)
                .orElseGet(() -> propertyTypeRepository.save(PropertyType.builder()
                        .code(code)
                        .name(name)
                        .active(true)
                        .build()));
    }
}
