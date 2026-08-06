package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.MaintenanceRequest;
import chez1s.htrbackend.dto.request.CreateMaintenanceRequest;
import chez1s.htrbackend.exception.BadRequestException;
import chez1s.htrbackend.exception.StorageException;
import chez1s.htrbackend.service.MaintenanceService;
import chez1s.htrbackend.service.StorageService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.core.Authentication;

import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class MaintenanceControllerTest {

    @Mock
    private MaintenanceService maintenanceService;
    @Mock
    private StorageService storageService;
    @Mock
    private Authentication authentication;

    private MaintenanceController controller;

    @BeforeEach
    void setup() {
        controller = new MaintenanceController(maintenanceService, storageService);
        lenient().when(authentication.getPrincipal()).thenReturn(UUID.randomUUID());
    }

    @Test
    void createWithImages_UploadFails_DoesNotCreateTicket() {
        MockMultipartFile goodImage = new MockMultipartFile("images", "photo.jpg", "image/jpeg", "img-bytes".getBytes());
        MockMultipartFile badImage = new MockMultipartFile("images", "photo2.jpg", "image/jpeg", "img-bytes-2".getBytes());

        when(storageService.upload(startsWith("maintenance/pending-"), eq(goodImage)))
                .thenReturn("https://storage/photo.jpg");
        when(storageService.upload(startsWith("maintenance/pending-"), eq(badImage)))
                .thenThrow(new StorageException("Dịch vụ tải ảnh hiện không khả dụng.", new RuntimeException("connect refused")));

        assertThrows(StorageException.class, () -> controller.createWithImages(
                authentication, "Leak", "Water leaking from sink", null, null, null,
                List.of(goodImage, badImage), null));

        verify(maintenanceService, never()).create(any(), any());
    }

    @Test
    void createWithImages_RejectsNonImageContentTypeAndDoesNotUploadOrCreate() {
        MockMultipartFile notAnImage = new MockMultipartFile("images", "doc.pdf", "application/pdf", "pdf-bytes".getBytes());

        assertThrows(BadRequestException.class, () -> controller.createWithImages(
                authentication, "Leak", "Water leaking from sink", null, null, null,
                List.of(notAnImage), null));

        verify(storageService, never()).upload(anyString(), any());
        verify(maintenanceService, never()).create(any(), any());
    }

    @Test
    void createWithImages_AllUploadsSucceed_CreatesTicketWithUrls() {
        MockMultipartFile image = new MockMultipartFile("images", "photo.jpg", "image/jpeg", "img-bytes".getBytes());
        UUID createdId = UUID.randomUUID();
        MaintenanceRequest created = MaintenanceRequest.builder().id(createdId).build();

        when(storageService.upload(startsWith("maintenance/pending-"), eq(image)))
                .thenReturn("https://storage/photo.jpg");
        when(maintenanceService.create(any(), any(CreateMaintenanceRequest.class))).thenReturn(created);
        when(maintenanceService.getById(createdId)).thenReturn(created);
        when(maintenanceService.getResponseById(createdId)).thenReturn(mock(chez1s.htrbackend.dto.response.MaintenanceRequestResponse.class));

        controller.createWithImages(authentication, "Leak", "Water leaking from sink", null, null, null,
                List.of(image), null);

        verify(maintenanceService).create(any(), argThat(req -> req.getImages().equals(List.of("https://storage/photo.jpg"))));
    }

    @Test
    void addCompletionImages_UploadFailsMidBatch_DoesNotPersistAnyImage() {
        UUID requestId = UUID.randomUUID();
        MockMultipartFile first = new MockMultipartFile("images", "done1.jpg", "image/jpeg", "bytes1".getBytes());
        MockMultipartFile second = new MockMultipartFile("images", "done2.jpg", "image/jpeg", "bytes2".getBytes());

        when(storageService.upload(eq("maintenance/" + requestId + "/completion"), eq(first)))
                .thenReturn("https://storage/done1.jpg");
        when(storageService.upload(eq("maintenance/" + requestId + "/completion"), eq(second)))
                .thenThrow(new StorageException("Dịch vụ tải ảnh hiện không khả dụng.", new RuntimeException("timeout")));

        assertThrows(StorageException.class, () -> controller.addCompletionImages(requestId, List.of(first, second)));

        verify(maintenanceService, never()).addCompletionImages(any(), any());
        verify(maintenanceService, never()).addCompletionImage(any(), any());
    }

    @Test
    void addCompletionImages_RejectsNonImageAndSkipsUploadEntirely() {
        UUID requestId = UUID.randomUUID();
        MockMultipartFile notAnImage = new MockMultipartFile("images", "clip.mp4", "video/mp4", "video-bytes".getBytes());

        assertThrows(BadRequestException.class, () -> controller.addCompletionImages(requestId, List.of(notAnImage)));

        verify(storageService, never()).upload(anyString(), any());
        verify(maintenanceService, never()).addCompletionImages(any(), any());
    }
}
