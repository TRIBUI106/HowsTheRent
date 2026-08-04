package chez1s.htrbackend.exception;

import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.web.multipart.MaxUploadSizeExceededException;

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

    @Test
    void dataIntegrityViolationReturnsConflictWithFriendlyMessage() {
        GlobalExceptionHandler handler = new GlobalExceptionHandler();
        DataIntegrityViolationException exception = new DataIntegrityViolationException("FK constraint violation");

        var response = handler.handleDataIntegrity(exception);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CONFLICT);
        assertThat(response.getBody()).containsEntry("status", HttpStatus.CONFLICT.value());
        assertThat(response.getBody()).containsEntry("message", "Không thể thực hiện vì dữ liệu đang được sử dụng ở nơi khác.");
        assertThat(response.getBody()).containsKey("timestamp");
    }

    @Test
    void maxUploadSizeExceededReturnsPayloadTooLargeWithFriendlyMessage() {
        GlobalExceptionHandler handler = new GlobalExceptionHandler();
        MaxUploadSizeExceededException exception = new MaxUploadSizeExceededException(25L * 1024 * 1024);

        var response = handler.handleMaxUpload(exception);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.PAYLOAD_TOO_LARGE);
        assertThat(response.getBody()).containsEntry("status", HttpStatus.PAYLOAD_TOO_LARGE.value());
        assertThat(response.getBody()).containsEntry("message", "Kích thước file vượt quá giới hạn cho phép (tối đa 25MB mỗi file).");
        assertThat(response.getBody()).containsKey("timestamp");
    }
}
