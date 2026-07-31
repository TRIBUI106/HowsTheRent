package chez1s.htrbackend.exception;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class GlobalExceptionHandlerTest {

    @Test
    void storageExceptionReturnsServiceUnavailableWithFriendlyMessage() {
        GlobalExceptionHandler handler = new GlobalExceptionHandler();
        StorageException exception = new StorageException("Dịch vụ tải ảnh hiện không khả dụng. Vui lòng thử lại sau.", new RuntimeException("AccessDenied"));

        var response = handler.handleStorage(exception);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        assertThat(response.getBody()).containsEntry("status", HttpStatus.SERVICE_UNAVAILABLE.value());
        assertThat(response.getBody()).containsEntry("message", "Dịch vụ tải ảnh hiện không khả dụng. Vui lòng thử lại sau.");
        assertThat(response.getBody()).containsKey("timestamp");
    }
}
