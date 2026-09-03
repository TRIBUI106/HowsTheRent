package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.UserRole;
import chez1s.htrbackend.domain.repository.InvoiceRepository;
import chez1s.htrbackend.domain.repository.MaintenanceRequestRepository;
import chez1s.htrbackend.domain.repository.RoomRepository;
import chez1s.htrbackend.domain.repository.UserRepository;
import chez1s.htrbackend.security.ActorContext;
import chez1s.htrbackend.service.PropertyService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class DashboardControllerTest {

    @Mock
    private PropertyService propertyService;
    @Mock
    private RoomRepository roomRepository;
    @Mock
    private InvoiceRepository invoiceRepository;
    @Mock
    private MaintenanceRequestRepository maintenanceRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private Authentication authentication;

    private DashboardController controller;
    private final UUID adminId = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        controller = new DashboardController(propertyService, roomRepository, invoiceRepository, maintenanceRepository, userRepository);
        lenient().when(authentication.getDetails()).thenReturn(new ActorContext(adminId, UserRole.ADMIN, 1L));
        lenient().when(authentication.getPrincipal()).thenReturn(adminId);
        lenient().when(userRepository.findById(adminId)).thenReturn(Optional.of(User.builder().id(adminId).role(UserRole.ADMIN).build()));
        lenient().when(propertyService.listAll()).thenReturn(List.of(Property.builder().id(UUID.randomUUID()).build()));
        lenient().when(invoiceRepository.sumPaidAmountByMonthAndPropertyIds(any(LocalDate.class), anyList()))
                .thenReturn(BigDecimal.ZERO);
    }

    // Regression test for the blank "Dòng tiền theo tháng" chart: Invoice.invoiceMonth is a
    // monthly billing key always stored as YYYY-MM-01. The controller used LocalDate.now() (today's
    // day-of-month) and so asked the exact-date SUM query for e.g. 2026-09-03, which never matches
    // an invoice stored as 2026-09-01; all six bars came back zero-height. Every query must now use
    // the first day of its respective month.
    @Test
    void getMonthlyRevenue_queriesEachInvoiceMonthUsingTheFirstDayOfMonth() {
        ResponseEntity<List<Map<String, Object>>> response = controller.getMonthlyRevenue(authentication, 3);

        ArgumentCaptor<LocalDate> monthCaptor = ArgumentCaptor.forClass(LocalDate.class);
        org.mockito.Mockito.verify(invoiceRepository, org.mockito.Mockito.times(3))
                .sumPaidAmountByMonthAndPropertyIds(monthCaptor.capture(), anyList());

        List<LocalDate> queriedMonths = monthCaptor.getAllValues();
        assertThat(queriedMonths).hasSize(3);
        assertThat(queriedMonths).allMatch(month -> month.getDayOfMonth() == 1);
        assertThat(queriedMonths).containsExactly(
                LocalDate.now().withDayOfMonth(1).minusMonths(2),
                LocalDate.now().withDayOfMonth(1).minusMonths(1),
                LocalDate.now().withDayOfMonth(1)
        );
        assertThat(response.getBody()).hasSize(3);
    }
}
