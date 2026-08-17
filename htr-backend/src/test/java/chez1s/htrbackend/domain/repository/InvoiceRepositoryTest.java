package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.Contract;
import chez1s.htrbackend.domain.entity.Invoice;
import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.entity.PropertyType;
import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.ContractStatus;
import chez1s.htrbackend.domain.enums.InvoiceStatus;
import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.enums.UserRole;
import org.hibernate.Hibernate;
import org.junit.jupiter.api.Test;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.boot.jpa.test.autoconfigure.TestEntityManager;
import org.springframework.boot.jdbc.test.autoconfigure.AutoConfigureTestDatabase;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@ActiveProfiles("test")
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class InvoiceRepositoryTest {

    @org.springframework.beans.factory.annotation.Autowired
    private TestEntityManager entityManager;

    @org.springframework.beans.factory.annotation.Autowired
    private InvoiceRepository invoiceRepository;

    @Test
    void findAll_eagerFetchesRoomAndContractAssociations() {
        PropertyType type = PropertyType.builder()
                .code("APARTMENT")
                .name("Apartment")
                .build();
        entityManager.persist(type);

        User owner = User.builder()
                .fullName("Owner")
                .email("owner@test.com")
                .passwordHash("hash")
                .role(UserRole.LANDLORD_ADMIN)
                .build();
        entityManager.persist(owner);

        User tenant = User.builder()
                .fullName("Tenant")
                .email("tenant@test.com")
                .passwordHash("hash")
                .role(UserRole.TENANT)
                .build();
        entityManager.persist(tenant);

        Property property = Property.builder()
                .owner(owner)
                .name("Property")
                .address("123 Street")
                .type(type)
                .build();
        entityManager.persist(property);

        Room room = Room.builder()
                .property(property)
                .roomNumber("101")
                .maxPeople(2)
                .status(RoomStatus.RENTED)
                .build();
        entityManager.persist(room);

        Contract contract = Contract.builder()
                .room(room)
                .tenant(tenant)
                .moveInDate(LocalDate.of(2025, 1, 1))
                .status(ContractStatus.ACTIVE)
                .depositAmount(new BigDecimal("5000000"))
                .build();
        entityManager.persist(contract);

        Invoice invoice = Invoice.builder()
                .room(room)
                .contract(contract)
                .invoiceMonth(LocalDate.of(2025, 6, 1))
                .proRata(false)
                .rentAmount(new BigDecimal("3000000"))
                .elecAmount(new BigDecimal("350000"))
                .waterAmount(new BigDecimal("75000"))
                .vehicleAmount(BigDecimal.ZERO)
                .serviceAmount(new BigDecimal("50000"))
                .totalAmount(new BigDecimal("3475000"))
                .status(InvoiceStatus.PENDING)
                .dueDate(LocalDate.of(2025, 6, 10))
                .build();
        entityManager.persist(invoice);

        entityManager.flush();
        entityManager.clear();

        Pageable pageable = PageRequest.of(0, 20);
        Invoice found = invoiceRepository.findAll(pageable).getContent().get(0);

        assertThat(Hibernate.isInitialized(found.getRoom())).isTrue();
        assertThat(Hibernate.isInitialized(found.getRoom().getProperty())).isTrue();
        assertThat(Hibernate.isInitialized(found.getContract())).isTrue();
        assertThat(Hibernate.isInitialized(found.getContract().getTenant())).isTrue();
    }
}
