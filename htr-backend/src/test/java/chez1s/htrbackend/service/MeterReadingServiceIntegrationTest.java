package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.MeterReading;
import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.entity.PropertyType;
import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.enums.UserRole;
import chez1s.htrbackend.domain.repository.MeterReadingRepository;
import chez1s.htrbackend.domain.repository.UserRepository;
import chez1s.htrbackend.domain.repository.VehicleRecordRepository;
import chez1s.htrbackend.dto.request.CreateMeterReadingRequest;
import org.hibernate.Hibernate;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.boot.jdbc.test.autoconfigure.AutoConfigureTestDatabase;
import org.springframework.boot.jpa.test.autoconfigure.TestEntityManager;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.Mockito.when;

/**
 * Exercises {@link MeterReadingService#create} against a real Hibernate session
 * (a pure-Mockito test cannot catch either of these):
 *
 * <ol>
 *   <li>Re-saving an existing room+month reading (the "edit" path) must not throw.</li>
 *   <li>The returned entity's {@code recordedBy} must be a fully-initialized
 *       instance, not a lazy proxy — {@link chez1s.htrbackend.dto.response.MeterReadingResponse#from}
 *       reads {@code recordedBy.getFullName()} from the controller, after this
 *       {@code @Transactional} method's session has already closed
 *       ({@code open-in-view=false}). Using {@code UserRepository.getReferenceById}
 *       here previously threw {@code LazyInitializationException} at that point —
 *       caught live via a manual smoke test, not by static analysis.</li>
 * </ol>
 */
@DataJpaTest
@ActiveProfiles("test")
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Import(MeterReadingService.class)
class MeterReadingServiceIntegrationTest {

    @Autowired
    private TestEntityManager entityManager;

    @Autowired
    private MeterReadingRepository meterReadingRepository;

    @Autowired
    private VehicleRecordRepository vehicleRecordRepository;

    @Autowired
    private MeterReadingService meterReadingService;

    @MockitoBean
    private RoomService roomService;

    @Test
    void create_reSavingSameRoomMonth_doesNotThrow_andRecordedByIsFullyInitialized() {
        PropertyType type = PropertyType.builder().code("BOARDING_HOUSE").name("Nhà trọ").build();
        entityManager.persist(type);

        User admin = User.builder()
                .fullName("Admin")
                .email("admin@test.com")
                .passwordHash("hash")
                .role(UserRole.ADMIN)
                .build();
        entityManager.persist(admin);

        Property property = Property.builder()
                .owner(admin)
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

        entityManager.flush();
        entityManager.clear();

        when(roomService.getById(room.getId())).thenReturn(room);

        CreateMeterReadingRequest req = new CreateMeterReadingRequest();
        req.setReadingMonth(LocalDate.of(2026, 7, 1));
        req.setElecOld(100L);
        req.setElecNew(150L);

        MeterReading first = meterReadingService.create(room.getId(), admin.getId(), req);
        assertThat(Hibernate.isInitialized(first.getRecordedBy())).isTrue();
        assertThat(first.getRecordedBy().getFullName()).isEqualTo("Admin");

        // Re-save (edit) for the SAME room+month, SAME recordedById.
        req.setElecNew(175L);
        assertThatCode(() -> meterReadingService.create(room.getId(), admin.getId(), req))
                .doesNotThrowAnyException();

        MeterReading saved = meterReadingRepository
                .findByRoomIdAndReadingMonth(room.getId(), LocalDate.of(2026, 7, 1))
                .orElseThrow();
        assertThat(saved.getElecNew()).isEqualTo(175L);
        assertThat(Hibernate.isInitialized(saved.getRecordedBy())).isTrue();
    }
}
