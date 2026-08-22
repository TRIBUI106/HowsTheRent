package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Contract;
import chez1s.htrbackend.domain.entity.MaintenanceRequest;
import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.ContractStatus;
import chez1s.htrbackend.domain.enums.UserRole;
import chez1s.htrbackend.domain.repository.ContractRepository;
import chez1s.htrbackend.dto.request.CreateMaintenanceRequest;
import chez1s.htrbackend.exception.BadRequestException;
import chez1s.htrbackend.exception.BusinessException;
import chez1s.htrbackend.exception.StorageException;
import chez1s.htrbackend.security.ActorContext;
import chez1s.htrbackend.security.OwnerScopeResolver;
import chez1s.htrbackend.service.MaintenanceService;
import chez1s.htrbackend.service.RoomService;
import chez1s.htrbackend.service.StorageService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.core.Authentication;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class MaintenanceControllerTest {

    @Mock
    private MaintenanceService maintenanceService;
    @Mock
    private StorageService storageService;
    @Mock
    private RoomService roomService;
    @Mock
    private OwnerScopeResolver ownerScopeResolver;
    @Mock
    private ContractRepository contractRepository;
    @Mock
    private Authentication authentication;

    private MaintenanceController controller;
    private UUID callerId;

    @BeforeEach
    void setup() {
        controller = new MaintenanceController(maintenanceService, storageService, roomService, ownerScopeResolver, contractRepository);
        callerId = UUID.randomUUID();
        lenient().when(authentication.getPrincipal()).thenReturn(callerId);
        lenient().when(authentication.getDetails()).thenReturn(new ActorContext(callerId, UserRole.TENANT, 1L));
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
    void createWithImages_CreateFails_CleansUploadedFiles() {
        MockMultipartFile image = new MockMultipartFile("images", "photo.jpg", "image/jpeg", "img-bytes".getBytes());
        when(storageService.upload(startsWith("maintenance/pending-"), eq(image)))
                .thenReturn("https://storage/photo.jpg");
        when(maintenanceService.create(any(), any(CreateMaintenanceRequest.class)))
                .thenThrow(new BadRequestException("Mô tả yêu cầu bảo trì tối thiểu 10 ký tự."));

        assertThrows(BadRequestException.class, () -> controller.createWithImages(
                authentication, "Leak", "short", null, null, null, List.of(image), null));

        verify(storageService).delete("https://storage/photo.jpg");
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

        verify(storageService).delete("https://storage/done1.jpg");
        verify(maintenanceService, never()).addCompletionImages(any(), any());
        verify(maintenanceService, never()).addCompletionImage(any(), any());
    }

    @Test
    void addCompletionImages_PersistFails_CleansUploadedFiles() {
        UUID requestId = UUID.randomUUID();
        MockMultipartFile image = new MockMultipartFile("images", "done.jpg", "image/jpeg", "bytes".getBytes());
        when(storageService.upload(eq("maintenance/" + requestId + "/completion"), eq(image)))
                .thenReturn("https://storage/done.jpg");
        doThrow(new BusinessException("Request not found"))
                .when(maintenanceService).addCompletionImages(requestId, List.of("https://storage/done.jpg"));

        assertThrows(BusinessException.class, () -> controller.addCompletionImages(requestId, List.of(image)));

        verify(storageService).delete("https://storage/done.jpg");
    }

    @Test
    void addCompletionImages_RejectsNonImageAndSkipsUploadEntirely() {
        UUID requestId = UUID.randomUUID();
        MockMultipartFile notAnImage = new MockMultipartFile("images", "clip.mp4", "video/mp4", "video-bytes".getBytes());

        assertThrows(BadRequestException.class, () -> controller.addCompletionImages(requestId, List.of(notAnImage)));

        verify(storageService, never()).upload(anyString(), any());
        verify(maintenanceService, never()).addCompletionImages(any(), any());
    }

    @Test
    void addCompletionImages_WithValidVideo_UploadsVideoAndSetsIt() {
        UUID requestId = UUID.randomUUID();
        MockMultipartFile image = new MockMultipartFile("images", "done.jpg", "image/jpeg", "bytes".getBytes());
        MockMultipartFile video = new MockMultipartFile("video", "clip.mp4", "video/mp4", "video-bytes".getBytes());

        when(storageService.upload(eq("maintenance/" + requestId + "/completion"), eq(image)))
                .thenReturn("https://storage/done.jpg");
        when(storageService.upload(eq("maintenance/" + requestId + "/completion/video"), eq(video)))
                .thenReturn("https://storage/clip.mp4");
        when(maintenanceService.getById(requestId)).thenReturn(MaintenanceRequest.builder().id(requestId).build());
        when(maintenanceService.getResponseById(requestId)).thenReturn(mock(chez1s.htrbackend.dto.response.MaintenanceRequestResponse.class));

        controller.addCompletionImages(requestId, List.of(image), video);

        verify(maintenanceService).addCompletionImages(requestId, List.of("https://storage/done.jpg"));
        verify(maintenanceService).setCompletionVideo(requestId, "https://storage/clip.mp4");
    }

    @Test
    void addCompletionImages_RejectsNonVideoContentTypeAndSkipsUploadEntirely() {
        UUID requestId = UUID.randomUUID();
        MockMultipartFile image = new MockMultipartFile("images", "done.jpg", "image/jpeg", "bytes".getBytes());
        MockMultipartFile notAVideo = new MockMultipartFile("video", "clip.txt", "text/plain", "not-a-video".getBytes());

        assertThrows(BadRequestException.class, () -> controller.addCompletionImages(requestId, List.of(image), notAVideo));

        verify(storageService, never()).upload(anyString(), any());
        verify(maintenanceService, never()).addCompletionImages(any(), any());
        verify(maintenanceService, never()).setCompletionVideo(any(), any());
    }

    @Test
    void addCompletionImages_VideoUploadFails_CleansUpImagesAndDoesNotPersist() {
        UUID requestId = UUID.randomUUID();
        MockMultipartFile image = new MockMultipartFile("images", "done.jpg", "image/jpeg", "bytes".getBytes());
        MockMultipartFile video = new MockMultipartFile("video", "clip.mp4", "video/mp4", "video-bytes".getBytes());

        when(storageService.upload(eq("maintenance/" + requestId + "/completion"), eq(image)))
                .thenReturn("https://storage/done.jpg");
        when(storageService.upload(eq("maintenance/" + requestId + "/completion/video"), eq(video)))
                .thenThrow(new StorageException("Dịch vụ tải ảnh hiện không khả dụng.", new RuntimeException("timeout")));

        assertThrows(StorageException.class, () -> controller.addCompletionImages(requestId, List.of(image), video));

        verify(storageService).delete("https://storage/done.jpg");
        verify(maintenanceService, never()).addCompletionImages(any(), any());
        verify(maintenanceService, never()).setCompletionVideo(any(), any());
    }

    @Test
    void create_Tenant_UsesOwnIdAndNeverConsultsRoomOwnerScope() {
        CreateMaintenanceRequest req = new CreateMaintenanceRequest();
        req.setTitle("Leak");
        req.setDescription("Water leaking badly in bathroom");

        UUID createdId = UUID.randomUUID();
        MaintenanceRequest created = MaintenanceRequest.builder().id(createdId).build();
        when(maintenanceService.create(eq(callerId), any(CreateMaintenanceRequest.class))).thenReturn(created);
        when(maintenanceService.getResponseById(createdId)).thenReturn(mock(chez1s.htrbackend.dto.response.MaintenanceRequestResponse.class));

        controller.create(authentication, req);

        verify(maintenanceService).create(eq(callerId), any(CreateMaintenanceRequest.class));
        verifyNoInteractions(roomService, ownerScopeResolver, contractRepository);
    }

    @Test
    void create_TenantWithMatchingRoomId_UsesOwnId() {
        UUID roomId = UUID.randomUUID();
        CreateMaintenanceRequest req = new CreateMaintenanceRequest();
        req.setRoomId(roomId);
        req.setTitle("Leak");
        req.setDescription("Water leaking badly in bathroom");

        Contract activeContract = Contract.builder()
                .id(UUID.randomUUID())
                .tenant(User.builder().id(callerId).build())
                .room(Room.builder().id(roomId).build())
                .status(ContractStatus.ACTIVE)
                .build();
        when(contractRepository.findFirstByTenantIdAndStatusOrderByCreatedAtDesc(callerId, ContractStatus.ACTIVE))
                .thenReturn(Optional.of(activeContract));

        UUID createdId = UUID.randomUUID();
        MaintenanceRequest created = MaintenanceRequest.builder().id(createdId).build();
        when(maintenanceService.create(eq(callerId), any(CreateMaintenanceRequest.class))).thenReturn(created);
        when(maintenanceService.getResponseById(createdId)).thenReturn(mock(chez1s.htrbackend.dto.response.MaintenanceRequestResponse.class));

        controller.create(authentication, req);

        verify(maintenanceService).create(eq(callerId), any(CreateMaintenanceRequest.class));
        verifyNoInteractions(roomService, ownerScopeResolver);
    }

    @Test
    void create_TenantWithOtherRoomId_ThrowsBusinessExceptionAndCreatesNoTicket() {
        UUID requestedRoomId = UUID.randomUUID();
        UUID activeRoomId = UUID.randomUUID();
        CreateMaintenanceRequest req = new CreateMaintenanceRequest();
        req.setRoomId(requestedRoomId);
        req.setTitle("Leak");
        req.setDescription("Water leaking badly in bathroom");

        Contract activeContract = Contract.builder()
                .id(UUID.randomUUID())
                .tenant(User.builder().id(callerId).build())
                .room(Room.builder().id(activeRoomId).build())
                .status(ContractStatus.ACTIVE)
                .build();
        when(contractRepository.findFirstByTenantIdAndStatusOrderByCreatedAtDesc(callerId, ContractStatus.ACTIVE))
                .thenReturn(Optional.of(activeContract));

        BusinessException exception = assertThrows(BusinessException.class, () -> controller.create(authentication, req));

        assertEquals("Room is outside the tenant active contract", exception.getMessage());
        verify(maintenanceService, never()).create(any(), any());
        verifyNoInteractions(roomService, ownerScopeResolver);
    }

    @Test
    void create_AdminWithValidRoomId_ResolvesTenantFromRoomActiveContract() {
        UUID adminId = UUID.randomUUID();
        UUID roomId = UUID.randomUUID();
        UUID resolvedTenantId = UUID.randomUUID();
        when(authentication.getDetails()).thenReturn(new ActorContext(adminId, UserRole.PLATFORM_ADMIN, 1L));

        CreateMaintenanceRequest req = new CreateMaintenanceRequest();
        req.setRoomId(roomId);
        req.setTitle("Leak");
        req.setDescription("Water leaking badly in bathroom");

        User tenant = User.builder().id(resolvedTenantId).fullName("Tenant Name").build();
        Contract contract = Contract.builder().id(UUID.randomUUID()).tenant(tenant).status(ContractStatus.ACTIVE).build();
        when(contractRepository.findFirstByRoomIdAndStatusOrderByCreatedAtDesc(roomId, ContractStatus.ACTIVE))
                .thenReturn(Optional.of(contract));

        UUID createdId = UUID.randomUUID();
        MaintenanceRequest created = MaintenanceRequest.builder().id(createdId).build();
        when(maintenanceService.create(eq(resolvedTenantId), any(CreateMaintenanceRequest.class))).thenReturn(created);
        when(maintenanceService.getResponseById(createdId)).thenReturn(mock(chez1s.htrbackend.dto.response.MaintenanceRequestResponse.class));

        controller.create(authentication, req);

        verify(maintenanceService).create(eq(resolvedTenantId), any(CreateMaintenanceRequest.class));
        // Platform admins are not scoped to a single owner, so ownership checks must not run.
        verifyNoInteractions(roomService, ownerScopeResolver);
    }

    @Test
    void create_AdminMissingRoomId_ThrowsBadRequestAndCreatesNoTicket() {
        UUID adminId = UUID.randomUUID();
        when(authentication.getDetails()).thenReturn(new ActorContext(adminId, UserRole.ADMIN, 1L));

        CreateMaintenanceRequest req = new CreateMaintenanceRequest();
        req.setTitle("Leak");
        req.setDescription("Water leaking badly in bathroom");

        assertThrows(BadRequestException.class, () -> controller.create(authentication, req));
        verify(maintenanceService, never()).create(any(), any());
    }

    @Test
    void create_AdminRoomWithoutActiveContract_ThrowsBadRequestAndCreatesNoTicket() {
        UUID adminId = UUID.randomUUID();
        UUID roomId = UUID.randomUUID();
        when(authentication.getDetails()).thenReturn(new ActorContext(adminId, UserRole.PLATFORM_ADMIN, 1L));

        CreateMaintenanceRequest req = new CreateMaintenanceRequest();
        req.setRoomId(roomId);
        req.setTitle("Leak");
        req.setDescription("Water leaking badly in bathroom");

        when(contractRepository.findFirstByRoomIdAndStatusOrderByCreatedAtDesc(roomId, ContractStatus.ACTIVE))
                .thenReturn(Optional.empty());

        assertThrows(BadRequestException.class, () -> controller.create(authentication, req));
        verify(maintenanceService, never()).create(any(), any());
    }

    @Test
    void create_LandlordAdminOutsideOwnerScope_ThrowsBusinessExceptionAndCreatesNoTicket() {
        UUID landlordAdminId = UUID.randomUUID();
        UUID roomId = UUID.randomUUID();
        UUID landlordOwnerId = UUID.randomUUID();
        UUID actualRoomOwnerId = UUID.randomUUID();
        when(authentication.getDetails()).thenReturn(new ActorContext(landlordAdminId, UserRole.LANDLORD_ADMIN, 1L));

        CreateMaintenanceRequest req = new CreateMaintenanceRequest();
        req.setRoomId(roomId);
        req.setTitle("Leak");
        req.setDescription("Water leaking badly in bathroom");

        Room room = Room.builder().id(roomId)
                .property(Property.builder().id(UUID.randomUUID())
                        .owner(User.builder().id(actualRoomOwnerId).build()).build())
                .build();
        when(roomService.getById(roomId)).thenReturn(room);
        when(ownerScopeResolver.requireOwnerId(any(ActorContext.class))).thenReturn(landlordOwnerId);

        assertThrows(BusinessException.class, () -> controller.create(authentication, req));
        verify(maintenanceService, never()).create(any(), any());
        verify(contractRepository, never()).findFirstByRoomIdAndStatusOrderByCreatedAtDesc(any(), any());
    }
}
