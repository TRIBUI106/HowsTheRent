package chez1s.htrbackend.controller;

import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.MethodSource;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.access.prepost.PreAuthorize;

import java.lang.reflect.Method;
import java.util.UUID;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;

@ExtendWith(MockitoExtension.class)
class PreAuthorizeHardeningTest {

    private static final String EXPECTED =
            "hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN','TENANT','TECHNICIAN')";

    static Stream<Method> hardenedMethods() throws NoSuchMethodException {
        return Stream.of(
                PropertyController.class.getMethod("getById", UUID.class),
                ContractController.class.getMethod("getById",
                        org.springframework.security.core.Authentication.class, UUID.class),
                InvoiceController.class.getMethod("getById",
                        org.springframework.security.core.Authentication.class, UUID.class),
                MaintenanceController.class.getMethod("listMaterials", UUID.class),
                MaintenanceController.class.getMethod("listNotes", UUID.class),
                MaintenanceController.class.getMethod("addNote",
                        org.springframework.security.core.Authentication.class, UUID.class, String.class),
                MaintenanceReportController.class.getMethod("getTechnicianReviews", UUID.class),
                MaintenanceReportController.class.getMethod("getAllReviews"),
                MaintenanceReportController.class.getMethod("getAllSlaRules"),
                NotificationController.class.getMethod("stream",
                        org.springframework.security.core.Authentication.class),
                NotificationController.class.getMethod("list",
                        org.springframework.security.core.Authentication.class,
                        org.springframework.data.domain.Pageable.class),
                NotificationController.class.getMethod("markAsRead", UUID.class),
                NotificationController.class.getMethod("markAllAsRead",
                        org.springframework.security.core.Authentication.class),
                UserController.class.getMethod("getMe",
                        org.springframework.security.core.Authentication.class)
        );
    }

    @ParameterizedTest
    @MethodSource("hardenedMethods")
    void everyPreviouslyOpenEndpointNowExcludesGuest(Method method) {
        PreAuthorize annotation = method.getAnnotation(PreAuthorize.class);
        assertThat(annotation)
                .as("%s.%s must carry @PreAuthorize excluding GUEST", method.getDeclaringClass().getSimpleName(), method.getName())
                .isNotNull();
        assertThat(annotation.value()).isEqualTo(EXPECTED);
    }
}
